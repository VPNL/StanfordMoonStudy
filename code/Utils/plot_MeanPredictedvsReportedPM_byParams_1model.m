function [summaryByParam, fh] = plot_MeanPredictedvsReportedPM_byParams_1model(T, predictedCol, paramsToPlot, minNID, saveFilename, figName, errType, Study, rebinTolPct, nLevels)
% plot_MeanPredictedvsReportedPM_byParams_1model
% Plot one predicted-PM model against perceived PM, binned by VA, D, and E.
%
% [summaryByParam, fh] = plot_MeanPredictedvsReportedPM_byParams_1model( ...
%     T, predictedCol, paramsToPlot, minNID, saveFilename, figName, errType, Study)
%
% This utility is a one-model companion to
% plot_MeanPredictedvsReportedPMbyParamwithMpERR_3models. It uses the same
% adaptive binning and color conventions, but plots one model in three
% panels: binned by Real_Visual_Angle, Distance, and Elevation.
%
% Inputs
%   T            : table with Iteration, ID, Ratio_Visual_Angle, paramsToPlot,
%                  and predictedCol.
%   predictedCol : predicted PM column to plot.
%   paramsToPlot : optional list of parameters. Default:
%                  {'Real_Visual_Angle','Distance','Elevation'}.
%   minNID       : minimum target unique IDs per bin. Default 1.
%   saveFilename : optional PNG/PDF/etc output path for the 1 x 3 figure.
%   figName      : optional figure name/title.
%   errType      : 'sd' or 'sem'. Default 'sd'.
%   Study        : study label passed to the existing binning helper. Use
%                  'Quad'/'Combined' to match existing colormap behavior.
%   rebinTolPct  : optional rebinning tolerance passed to the existing
%                  binning helper.
%   nLevels      : optional color-level argument passed through for
%                  compatibility.
%
% Outputs
%   summaryByParam : struct with one field per parameter. Each field contains
%                    SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr,
%                    PctErr_ItrParam, and PctErr_Itr from the binning helper.
%   fh             : handle to the 1 x 3 figure.

if nargin < 3 || isempty(paramsToPlot)
    paramsToPlot = {'Real_Visual_Angle','Distance','Elevation'};
end
if nargin < 4 || isempty(minNID)
    minNID = 1;
end
if nargin < 5
    saveFilename = [];
end
if nargin < 6
    figName = [];
end
if nargin < 7 || isempty(errType)
    errType = 'sd';
end
if nargin < 8 || isempty(Study)
    Study = 'QuadStudy';
end
if nargin < 9
    rebinTolPct = [];
end
if nargin < 10
    nLevels = [];
end

if ~istable(T)
    error('T must be a table.');
end
predictedCol = string(predictedCol);
if ~ismember(predictedCol, string(T.Properties.VariableNames))
    error('Missing predicted PM column: %s', predictedCol);
end

paramsToPlot = string(paramsToPlot);
TOne = local_keep_one_prediction_column(T, predictedCol);
summaryByParam = struct();
plotData = repmat(local_empty_plot_data(), numel(paramsToPlot), 1);

for iParam = 1:numel(paramsToPlot)
    Param = paramsToPlot(iParam);
    [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, tmpFh, tmpViolin, PctErr_ItrParam, PctErr_Itr, tmpPctFh] = ...
        plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNIDbinned( ...
        TOne, char(Param), minNID, [], figName, errType, Study, rebinTolPct, nLevels);

    local_close_if_handle(tmpFh);
    local_close_if_handle(tmpViolin);
    local_close_if_handle(tmpPctFh);

    fieldName = matlab.lang.makeValidName(Param);
    summaryByParam.(fieldName).SummaryItrParam = SummaryItrParam;
    summaryByParam.(fieldName).SummaryParam = SummaryParam;
    summaryByParam.(fieldName).MSE_ItrParam = MSE_ItrParam;
    summaryByParam.(fieldName).MSE_Itr = MSE_Itr;
    summaryByParam.(fieldName).PctErr_ItrParam = PctErr_ItrParam;
    summaryByParam.(fieldName).PctErr_Itr = PctErr_Itr;

    plotData(iParam) = local_extract_plot_data(SummaryParam, predictedCol, Param, errType);

    if ~isempty(saveFilename)
        local_write_param_report(saveFilename, Param, predictedCol, SummaryItrParam, SummaryParam, ...
            PctErr_ItrParam, PctErr_Itr, minNID, rebinTolPct, figName);
    end
end

[minAxis, maxAxis] = local_axis_limits(plotData);
fh = local_make_figure(plotData, paramsToPlot, predictedCol, minAxis, maxAxis, figName, Study);

if ~isempty(saveFilename)
    [outDir,~,~] = fileparts(char(saveFilename));
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    exportgraphics(fh, saveFilename, 'Resolution', 600);
end

end

function TOne = local_keep_one_prediction_column(T, predictedCol)
vnames = string(T.Properties.VariableNames);
allPredCols = vnames(contains(lower(vnames), "predicted_pm"));
if isempty(allPredCols)
    allPredCols = vnames(contains(lower(vnames), "predicted"));
end
nonPredCols = setdiff(vnames, allPredCols, 'stable');
keepCols = [nonPredCols, predictedCol];
TOne = T(:, cellstr(keepCols));
end

function data = local_empty_plot_data()
data = struct( ...
    'Param', "", ...
    'xMean', [], ...
    'xErr', [], ...
    'yMean', [], ...
    'yErr', [], ...
    'binStats', table(), ...
    'nBins', 0);
end

function data = local_extract_plot_data(SummaryParam, predictedCol, Param, errType)
base = matlab.lang.makeValidName(predictedCol);
yMeanName = base + "_MeanAcrossItr";
yStdName = base + "_StdAcrossItr";
yNName = base + "_NItrWithData";

required = ["MeanReported_AcrossItr","StdReported_AcrossItr","NItr_WithData", yMeanName, yStdName, yNName];
missing = setdiff(required, string(SummaryParam.Properties.VariableNames));
if ~isempty(missing)
    error('SummaryParam missing required plotting column(s): %s', strjoin(missing, ', '));
end

xMean = SummaryParam.MeanReported_AcrossItr;
xErr = SummaryParam.StdReported_AcrossItr;
yMean = SummaryParam.(char(yMeanName));
yErr = SummaryParam.(char(yStdName));

if lower(string(errType)) == "sem"
    xErr = xErr ./ sqrt(max(SummaryParam.NItr_WithData, 1));
    yErr = yErr ./ sqrt(max(SummaryParam.(char(yNName)), 1));
end

data = local_empty_plot_data();
data.Param = string(Param);
data.xMean = xMean;
data.xErr = xErr;
data.yMean = yMean;
data.yErr = yErr;
data.binStats = SummaryParam;
data.nBins = height(SummaryParam);
end

function [minAxis, maxAxis] = local_axis_limits(plotData)
allVals = [];
for iParam = 1:numel(plotData)
    data = plotData(iParam);
    allVals = [allVals; ...
        data.xMean(:) - data.xErr(:); ...
        data.xMean(:) + data.xErr(:); ...
        data.yMean(:) - data.yErr(:); ...
        data.yMean(:) + data.yErr(:)]; %#ok<AGROW>
end
allVals = allVals(isfinite(allVals));
if isempty(allVals)
    minAxis = 0;
    maxAxis = 1;
    return;
end
minAxis = min(allVals);
maxAxis = max(allVals);
if minAxis == maxAxis
    minAxis = minAxis - 0.5;
    maxAxis = maxAxis + 0.5;
else
    pad = 0.05 * (maxAxis - minAxis);
    minAxis = minAxis - pad;
    maxAxis = maxAxis + pad;
end
end

function fh = local_make_figure(plotData, paramsToPlot, predictedCol, minAxis, maxAxis, figName, Study)
if isempty(figName)
    figureName = "Predicted vs perceived PM: " + string(predictedCol);
else
    figureName = string(figName);
end

fh = figure('Color','w','Name',figureName,'Units','normalized','Position',[0 0 1 .5]);
tiledlayout(1, numel(paramsToPlot), 'TileSpacing','compact', 'Padding','compact');

fontSize = 18;
lineWidth = 3;
markerSize = 24;
cap = 0.01 * (maxAxis - minAxis);

for iParam = 1:numel(plotData)
    data = plotData(iParam);
    Param = data.Param;
    ax = nexttile;
    hold(ax, 'on');
    plot(ax, [minAxis maxAxis], [minAxis maxAxis], 'k:', 'LineWidth', lineWidth);

    cmap = local_colormap_for_param(Param, max(data.nBins, 2), Study);
    colormap(ax, cmap);
    clim(ax, [1 max(data.nBins, 2)]);
    for iBin = 1:data.nBins
        xp = data.xMean(iBin);
        yp = data.yMean(iBin);
        dx = data.xErr(iBin);
        dy = data.yErr(iBin);
        if ~isfinite(xp) || ~isfinite(yp)
            continue;
        end
        colr = cmap(iBin,:);
        if isfinite(dx) && dx > 0
            plot(ax, [xp-dx xp+dx], [yp yp], 'Color', colr, 'LineWidth', lineWidth);
            plot(ax, [xp-dx xp-dx], [yp-cap yp+cap], 'Color', colr, 'LineWidth', lineWidth);
            plot(ax, [xp+dx xp+dx], [yp-cap yp+cap], 'Color', colr, 'LineWidth', lineWidth);
        end
        if isfinite(dy) && dy > 0
            plot(ax, [xp xp], [yp-dy yp+dy], 'Color', colr, 'LineWidth', lineWidth);
            plot(ax, [xp-cap xp+cap], [yp-dy yp-dy], 'Color', colr, 'LineWidth', lineWidth);
            plot(ax, [xp-cap xp+cap], [yp+dy yp+dy], 'Color', colr, 'LineWidth', lineWidth);
        end
    end

    if data.nBins > 0
        markerColors = cmap(1:data.nBins,:);
        scatter(ax, data.xMean, data.yMean, markerSize, markerColors, 'filled');
    end

    ax.XLim = [minAxis maxAxis];
    ax.YLim = [minAxis maxAxis];
    ax.FontName = 'Avenir';
    ax.FontSize = fontSize;
    local_disable_axes_toolbar(ax);
    axis(ax, 'square');
    box(ax, 'off');
    grid(ax, 'off');
    xlabel(ax, 'Perceived PM');
    ylabel(ax, 'Predicted PM');
    title(ax, local_param_title(Param), 'FontSize', fontSize + 4, 'Interpreter','none');

    cb = colorbar(ax);
    cb.Label.String = local_colorbar_label(Param);
    cb.Label.Interpreter = 'none';
    cb.FontName = 'Avenir';
    cb.FontSize = max(16, fontSize - 4);
    local_set_colorbar_ticks(cb, data.binStats, Param);
end
end

function local_disable_axes_toolbar(ax)
try
    disableDefaultInteractivity(ax);
catch
end
try
    ax.Toolbar.Visible = 'off';
catch
end
end

function cmap = local_colormap_for_param(Param, nBins, Study)
Param = string(Param);
if strcmp(Param, 'Distance')
    cmap = brighten(flipud(turbo(nBins)), 0.4);
elseif strcmp(Param, 'Elevation')
    if contains(lower(string(Study)), 'quad')
        cmap = brighten(earthColormap3(nBins), 0.4);
    else
        cmap = brighten(earthColormapExtended3(nBins), 0.4);
    end
elseif strcmp(Param, 'Real_Visual_Angle')
    cmap = purpleVioletBlueTurquoiseGreenColorMap(ceil(nBins));
else
    cmap = jet(max(nBins, 2));
end
end

function titleText = local_param_title(Param)
switch string(Param)
    case "Real_Visual_Angle"
        titleText = "VA bins";
    case "Distance"
        titleText = "Distance bins";
    case "Elevation"
        titleText = "|Elevation| bins";
    otherwise
        titleText = "Binned by " + string(Param);
end
end

function labelText = local_colorbar_label(Param)
switch string(Param)
    case "Real_Visual_Angle"
        labelText = "Visual angle [deg]";
    case "Distance"
        labelText = "Distance [m]";
    case "Elevation"
        labelText = "|Elevation| [deg]";
    otherwise
        labelText = char(Param);
end
end

function local_set_colorbar_ticks(cb, binStats, Param)
nBins = height(binStats);
if nBins <= 1
    tickBins = 1;
elseif nBins == 2
    tickBins = [1 2];
else
    tickBins = unique(round(linspace(1, nBins, min(6, nBins))));
    tickBins(1) = 1;
    tickBins(end) = nBins;
end
cb.Ticks = tickBins;

labels = strings(size(tickBins));
for iTick = 1:numel(tickBins)
    b = tickBins(iTick);
    if b == 1
        value = binStats.NewParamMinValue(1);
    elseif b == nBins
        value = binStats.NewParamMaxValue(nBins);
    else
        value = binStats.NewParamMeanValue(b);
    end
    if string(Param) == "Elevation"
        value = abs(value);
    end
    labels(iTick) = local_numeric_tick_label(value);
end
cb.TickLabels = cellstr(labels);
end

function label = local_numeric_tick_label(value)
if ~isfinite(value)
    label = "";
elseif abs(value) >= 100
    label = sprintf('%.0f', value);
elseif abs(value) >= 10
    label = sprintf('%.1f', value);
else
    label = sprintf('%.2f', value);
end
end

function local_write_param_report(saveFilename, Param, predictedCol, SummaryItrParam, SummaryParam, PctErr_ItrParam, PctErr_Itr, minNID, rebinTolPct, figName)
reportFilename = local_report_filename(saveFilename, Param);
[reportDir,~,~] = fileparts(reportFilename);
if ~isempty(reportDir) && ~exist(reportDir, 'dir')
    mkdir(reportDir);
end

base = matlab.lang.makeValidName(predictedCol);
pctAcrossParamName = base + "_MeanPctErr_AcrossParam";
if ismember(pctAcrossParamName, string(PctErr_Itr.Properties.VariableNames))
    errorValues = PctErr_Itr.(char(pctAcrossParamName));
else
    errorValues = nan(0, 1);
end
errorValues = errorValues(isfinite(errorValues));
modelLabels = string(predictedCol);
meanAbsPctError = mean(errorValues, 'omitnan');
stdAbsPctError = std(errorValues, 'omitnan');
nIterations = numel(errorValues);
modelErrorSummaryTbl = table(modelLabels, meanAbsPctError, stdAbsPctError, nIterations, ...
    'VariableNames', ["Model", "MeanAbsPctError", "StdAbsPctError", "N_Iterations"]);

signedPctErrTbl = local_signed_error_table(SummaryItrParam, predictedCol);
reportTbl = local_build_bin_error_report_table(PctErr_ItrParam, signedPctErrTbl, SummaryParam, predictedCol);

reportOpts = struct();
reportOpts.Param = Param;
reportOpts.minNID = minNID;
reportOpts.didRebin = any(SummaryParam.NewParamMinValue ~= SummaryParam.NewParamMaxValue);
reportOpts.rebinTolPct = rebinTolPct;
reportOpts.figName = figName;
reportOpts.reportModelLabel = predictedCol;
reportOpts.generatedBy = 'plot_MeanPredictedvsReportedPM_byParams_1model';
write_bin_error_report(reportFilename, modelErrorSummaryTbl, reportTbl, reportOpts);
end

function reportFilename = local_report_filename(saveFilename, Param)
[p, f] = fileparts(char(saveFilename));
paramName = matlab.lang.makeValidName(char(string(Param)));
reportFilename = fullfile(p, sprintf('%s_%s_bin_error_report.txt', f, paramName));
end

function signedPctErrTbl = local_signed_error_table(SummaryItrParam, predictedCol)
base = matlab.lang.makeValidName(predictedCol);
signedName = base + "_MeanSignedPctErrByItrParam";
if ~ismember(signedName, string(SummaryItrParam.Properties.VariableNames))
    signedPctErrTbl = table();
    return
end

Iteration = SummaryItrParam.Iteration;
NewParamGroup = SummaryItrParam.NewParamGroup;
Model = repmat(string(predictedCol), height(SummaryItrParam), 1);
MeanSignedPctError = SummaryItrParam.(char(signedName));
signedPctErrTbl = table(Iteration, NewParamGroup, Model, MeanSignedPctError, ...
    'VariableNames', ["Iteration", "NewParamGroup", "Model", "MeanSignedPctError"]);
end

function reportTbl = local_build_bin_error_report_table(PctErr_ItrParam, SignedPctErr_ItrParam, SummaryParam, reportModel)
if isempty(PctErr_ItrParam)
    reportTbl = table();
    return
end

modelMask = string(PctErr_ItrParam.Model) == string(reportModel);
if ~any(modelMask)
    reportTbl = table();
    return
end

[G, binGroup] = findgroups(PctErr_ItrParam.NewParamGroup(modelMask));
meanAbsPctError = splitapply(@(x) mean(x, 'omitnan'), PctErr_ItrParam.MeanPctError(modelMask), G);
stdAbsPctError = splitapply(@(x) std(x, 'omitnan'), PctErr_ItrParam.MeanPctError(modelMask), G);

meanSignedPctError = nan(size(meanAbsPctError));
if ~isempty(SignedPctErr_ItrParam)
    signedModelMask = string(SignedPctErr_ItrParam.Model) == string(reportModel);
    if any(signedModelMask)
        [Gs, signedBinGroup] = findgroups(SignedPctErr_ItrParam.NewParamGroup(signedModelMask));
        meanSignedPctErrorRaw = splitapply(@(x) mean(x, 'omitnan'), SignedPctErr_ItrParam.MeanSignedPctError(signedModelMask), Gs);
        for ii = 1:numel(binGroup)
            idxSigned = find(signedBinGroup == binGroup(ii), 1, 'first');
            if ~isempty(idxSigned)
                meanSignedPctError(ii) = meanSignedPctErrorRaw(idxSigned);
            end
        end
    end
end
biasLabel = local_bias_label(meanSignedPctError);

binIdx = double(binGroup);
vaRange = local_format_range(local_summary_values(SummaryParam, "Real_Visual_Angle_Min", binIdx), ...
    local_summary_values(SummaryParam, "Real_Visual_Angle_Max", binIdx), '%.2f');
dRange = local_format_range(local_summary_values(SummaryParam, "Distance_Min", binIdx), ...
    local_summary_values(SummaryParam, "Distance_Max", binIdx), '%.1f');
eRange = local_format_range(local_summary_values(SummaryParam, "Elevation_Min", binIdx), ...
    local_summary_values(SummaryParam, "Elevation_Max", binIdx), '%.1f');

reportTbl = table(binIdx, ...
    SummaryParam.NewParamNID(binIdx), ...
    vaRange, dRange, eRange, ...
    meanAbsPctError, stdAbsPctError, biasLabel, ...
    'VariableNames', ["Group", "N_ID", ...
    "VA_Range", "Distance_Range", "Elevation_Range", ...
    "MeanAbsPctError", "StdAbsPctError", "Bias"]);
reportTbl = sortrows(reportTbl, ["MeanAbsPctError", "StdAbsPctError", "Group"], {'ascend','ascend','ascend'});
reportTbl.Rank = (1:height(reportTbl))';
reportTbl = movevars(reportTbl, "Rank", "Before", "Group");
end

function values = local_summary_values(SummaryParam, varName, binIdx)
if ismember(varName, string(SummaryParam.Properties.VariableNames))
    values = SummaryParam.(char(varName))(binIdx);
else
    values = nan(size(binIdx));
end
end

function biasLabel = local_bias_label(meanSignedPctError)
biasLabel = strings(size(meanSignedPctError));
biasLabel(:) = "Balanced";
biasLabel(meanSignedPctError > 0) = "Overpredicts";
biasLabel(meanSignedPctError < 0) = "Underpredicts";
biasLabel(~isfinite(meanSignedPctError)) = "Unknown";
end

function rangeText = local_format_range(minValues, maxValues, formatSpec)
rangeText = strings(size(minValues));
for ii = 1:numel(minValues)
    if isfinite(minValues(ii)) && isfinite(maxValues(ii))
        rangeText(ii) = sprintf('[%s %s]', sprintf(formatSpec, minValues(ii)), sprintf(formatSpec, maxValues(ii)));
    else
        rangeText(ii) = "";
    end
end
end

function local_close_if_handle(fh)
if ~isempty(fh) && all(ishghandle(fh))
    close(fh);
end
end
