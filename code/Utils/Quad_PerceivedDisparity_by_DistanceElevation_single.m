function [lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS] = ...
    Quad_PerceivedDisparity_by_DistanceElevation_single(tbl, tblName, ...
    ResultsDir, saveLME, mycolormap, sorted_idx, modelTransform, ...
    degreeFlag, fullUniqueID, removeOutlierParticipants, colorbarLabel, ...
    secondYAxisColor, plotFixedEffectsRS, colorConfig, runStereoAnalysis)
% QUAD_PERCEIVEDDISPARITY_BY_DISTANCEELEVATION_SINGLE
% Fit and plot single-factor distance/elevation perceived-disparity models
% with random-intercept and random-slope variants.

if nargin < 8 || isempty(degreeFlag)
    degreeFlag = 1; %#ok<NASGU>
end
if nargin < 7 || isempty(modelTransform)
    modelTransform = 2;
end
if nargin < 9 || isempty(fullUniqueID)
    fullUniqueID = [];
end
if nargin < 10 || isempty(removeOutlierParticipants)
    removeOutlierParticipants = false;
end
if nargin < 11 || isempty(colorbarLabel)
    colorbarLabel = 'Participant color order';
end
if nargin < 12 || isempty(secondYAxisColor)
    secondYAxisColor = 'w';
end
if nargin < 13 || isempty(plotFixedEffectsRS)
    plotFixedEffectsRS = false;
end
if nargin < 14
    colorConfig = [];
end
if nargin < 15 || isempty(runStereoAnalysis)
    runStereoAnalysis = true;
end

ResultsDir = fullfile(ResultsDir, 'DistanceElevationModel');
tbl = Quad_prepare_perceived_disparity_table(tbl, modelTransform, removeOutlierParticipants);

lme_logPM_by_logDistance = local_try_fitlme(tbl, 'log2mean_disparity ~ 1 + log2distance + (1|ID)');
lme_logPM_by_logElevation = local_try_fitlme(tbl, 'log2mean_disparity ~ 1 + log2elevation + (1|ID)');
lme_logPM_by_logDistance_RS = local_try_fitlme(tbl, 'log2mean_disparity ~ 1 + log2distance + (log2distance|ID)');
lme_logPM_by_logElevation_RS = local_try_fitlme(tbl, 'log2mean_disparity ~ 1 + log2elevation + (log2elevation|ID)');

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

if saveLME
    savelmefile = fullfile(ResultsDir, [tblName '_distance_elevation_single_RI_RS.txt']);
    diary(savelmefile);
    local_log_model('log2mean_disparity ~ 1 + log2distance + (1|ID)', lme_logPM_by_logDistance)
    local_log_model('log2mean_disparity ~ 1 + log2elevation + (1|ID)', lme_logPM_by_logElevation)
    local_log_model('log2mean_disparity ~ 1 + log2distance + (log2distance|ID)', lme_logPM_by_logDistance_RS)
    local_log_model('log2mean_disparity ~ 1 + log2elevation + (log2elevation|ID)', lme_logPM_by_logElevation_RS)
    local_compare_if_available( ...
        'log2mean_disparity ~ 1 + log2distance + (1|ID)', lme_logPM_by_logDistance, ...
        'log2mean_disparity ~ 1 + log2distance + (log2distance|ID)', lme_logPM_by_logDistance_RS)
    local_compare_if_available( ...
        'log2mean_disparity ~ 1 + log2elevation + (1|ID)', lme_logPM_by_logElevation, ...
        'log2mean_disparity ~ 1 + log2elevation + (log2elevation|ID)', lme_logPM_by_logElevation_RS)
    if runStereoAnalysis
        local_log_stereo_relationships(tbl, lme_logPM_by_logDistance_RS)
    end
    diary off
end

subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID);
minDisp = max(0.01, min(tbl.MeanDisparity));
maxDisp = max(tbl.MeanDisparity);
nIDs = numel(categories(removecats(tbl.ID)));

figRI = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .92 .72], 'Name', [tblName '_RI'], 'Visible', 'off');
tRI = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tRI.Position = [0.10 0.12 0.69 0.64];
axRI1 = nexttile;
local_plot_fixed_only(axRI1, tbl, subjectcolor, lme_logPM_by_logDistance, ...
    'D', minDisp, maxDisp, modelTransform, nIDs, true);
axRI2 = nexttile;
local_plot_fixed_only(axRI2, tbl, subjectcolor, lme_logPM_by_logElevation, ...
    'E', minDisp, maxDisp, modelTransform, nIDs, false, secondYAxisColor);
local_add_subject_colorbar(figRI, mycolormap, nIDs, colorbarLabel, ...
    colorConfig, axRI2);
exportgraphics(figRI, fullfile(ResultsDir, [tblName '_RI.png']), 'Resolution', 600);
close(figRI);

figRS = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .92 .72], 'Name', [tblName '_RS'], 'Visible', 'off');
tRS = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tRS.Position = [0.10 0.12 0.69 0.64];
axRS1 = nexttile;
local_plot_random_slopes(axRS1, tbl, subjectcolor, ...
    lme_logPM_by_logDistance_RS, 'D', minDisp, maxDisp, modelTransform, ...
    nIDs, fullUniqueID, mycolormap, sorted_idx, true, [], plotFixedEffectsRS);
axRS2 = nexttile;
local_plot_random_slopes(axRS2, tbl, subjectcolor, ...
    lme_logPM_by_logElevation_RS, 'E', minDisp, maxDisp, modelTransform, ...
    nIDs, fullUniqueID, mycolormap, sorted_idx, false, ...
    secondYAxisColor, plotFixedEffectsRS);
local_add_subject_colorbar(figRS, mycolormap, nIDs, colorbarLabel, ...
    colorConfig, axRS2);
exportgraphics(figRS, fullfile(ResultsDir, [tblName '_RS.png']), 'Resolution', 600);
close(figRS);

if runStereoAnalysis
    local_plot_stereo_relationship_figure(tbl, lme_logPM_by_logDistance_RS, ResultsDir, tblName, ...
        fullUniqueID, mycolormap, sorted_idx, colorConfig);
end
end

function local_plot_fixed_only(ax, tbl, subjectcolor, lme, modeChar, minDisp, maxDisp, modelTransform, nIDs, showYLabel, hiddenYAxisColor)
if nargin < 9 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 11 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
hold(ax, 'on');
[x, xlog, xlabelText, tickVals, titleFormula] = local_axis_setup(tbl, modeChar, modelTransform);
y = tbl.log2mean_disparity;

if isempty(lme)
    scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
    local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
    title(ax, {'Model unavailable','rank-deficient or singular'}, 'FontSize', 16, 'FontWeight', 'normal');
    return;
end

xlinerange = linspace(min(xlog), max(xlog), 200);
b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);
ciL0 = lme.Coefficients.Lower(1);
ciL1 = lme.Coefficients.Lower(2);
ciU0 = lme.Coefficients.Upper(1);
ciU1 = lme.Coefficients.Upper(2);

yFit = b0 + b1 * xlinerange;
xvector = [xlinerange fliplr(xlinerange)];
yvector = [ciL0 + ciL1 * xlinerange fliplr(ciU0 + ciU1 * xlinerange)];
fill(ax, xvector, yvector, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);
plot(ax, xlinerange, yFit, ':','Color',[.6 .6 .6], 'LineWidth', 5);
scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);

local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
titleStr = sprintf(titleFormula, local_format_number(2.^b0), local_format_number(b1), local_format_pvalue(lme.Coefficients.pValue(2)), nIDs);
title(ax, titleStr, 'FontSize', 15, 'FontWeight', 'normal', 'Units', 'normalized', 'Position', [0.5 1.01 0]);
end

function local_plot_random_slopes(ax, tbl, subjectcolor, lme, modeChar, minDisp, maxDisp, modelTransform, nIDs, fullUniqueID, mycolormap, sorted_idx, showYLabel, hiddenYAxisColor, plotFixedEffectsRS)
if nargin < 13 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 14 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
if nargin < 15 || isempty(plotFixedEffectsRS)
    plotFixedEffectsRS = false;
end
hold(ax, 'on');
[x, xlog, xlabelText, tickVals, titleFormula] = local_axis_setup(tbl, modeChar, modelTransform);
y = tbl.log2mean_disparity;

if isempty(lme)
    scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
    local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
    title(ax, {'Model unavailable','rank-deficient or singular'}, 'FontSize', 16, 'FontWeight', 'normal');
    return;
end

local_plot_subject_lines(ax, tbl, lme, modeChar, fullUniqueID, mycolormap, sorted_idx);

xlinerange = linspace(min(xlog), max(xlog), 200);
b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);

if plotFixedEffectsRS
    yFit = b0 + b1 * xlinerange;
    plot(ax, xlinerange, yFit, ':', 'Color',[ .6 .6 .6], 'LineWidth', 5);
end
scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);

local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
titleStr = sprintf(titleFormula, local_format_number(2.^b0), local_format_number(b1), local_format_pvalue(lme.Coefficients.pValue(2)), nIDs);
title(ax, titleStr, 'FontSize', 15, 'FontWeight', 'normal', 'Units', 'normalized', 'Position', [0.5 1.01 0]);
end

function local_plot_subject_lines(ax, tbl, lme, modeChar, fullUniqueID, mycolormap, sorted_idx)
[reEfx, reNames] = randomEffects(lme);
levels = string(reNames.Level);
names = string(reNames.Name);

if isempty(fullUniqueID)
    uniqueID = string(categories(removecats(tbl.ID)));
else
    uniqueID = string(fullUniqueID(:));
end

if modeChar == 'D'
    slopeName = "log2distance";
    xAll = tbl.log2distance;
else
    slopeName = "log2elevation";
    xAll = tbl.log2elevation;
end

for i = 1:numel(uniqueID)
    subj = uniqueID(i);
    rowMask = string(tbl.ID) == subj;
    if ~any(rowMask)
        continue;
    end

    cindex = find(strcmp(uniqueID, subj), 1, 'first');
    colorRow = local_lookup_color_row(sorted_idx, cindex, numel(uniqueID), size(mycolormap, 1));
    thisColor = mycolormap(colorRow,:);

    reIntercept = 0;
    reSlope = 0;
    idxIntercept = find(levels == subj & names == "(Intercept)", 1, 'first');
    idxSlope = find(levels == subj & names == slopeName, 1, 'first');
    if ~isempty(idxIntercept)
        reIntercept = reEfx(idxIntercept);
    end
    if ~isempty(idxSlope)
        reSlope = reEfx(idxSlope);
    end

    xSub = xAll(rowMask);
    xgrid = linspace(min(xSub), max(xSub), 50);
    ySubFit = (lme.Coefficients.Estimate(1) + reIntercept) + (lme.Coefficients.Estimate(2) + reSlope) * xgrid;
    plot(ax, xgrid, ySubFit, '-', 'Color', thisColor, 'LineWidth', 3);
end
end

function [x, xlog, xlabelText, tickVals, titleFormula] = local_axis_setup(tbl, modeChar, modelTransform)
switch modeChar
    case 'D'
        x = tbl.Distance;
        xlog = tbl.log2distance;
        xlabelText = {'Distance [m]','log scale'};
        tickVals = local_log_ticks(min(x), max(x), false);
        titleFormula = 'Disparity=%s(D)^{%s}\n p=%s\n n=%d';
    otherwise
        x = tbl.ElevationModel;
        xlog = tbl.log2elevation;
        if modelTransform == 2
            xlabelText = {'|Elevation| [deg]','log scale'};
            titleFormula = 'Disparity=%s(1+|E|)^{%s}\n p=%s\n n=%d';
        elseif modelTransform == 6
            xlabelText = {'|Elevation| [deg]','log scale'};
            titleFormula = 'Disparity=%s(1+|E|/90)^{%s}\n p=%s\n n=%d';
        else
            xlabelText = {'Elevation [deg]','log scale'};
            titleFormula = 'Disparity=%s(1+E/90)^{%s}\n p=%s\n n=%d';
        end
        tickVals = local_log_ticks(min(x), max(x), true, modelTransform);
end
end

function local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor)
if nargin < 7 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 8 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
set(ax, 'XTick', tickVals.positions, 'XTickLabel', tickVals.labels, ...
    'YTick', floor(log2(minDisp)):ceil(log2(maxDisp)), ...
    'YTickLabel', string(2.^(floor(log2(minDisp)):ceil(log2(maxDisp)))), ...
    'FontName', 'Avenir', 'FontSize', 18);
xlabel(ax, xlabelText, 'FontSize', 22);
if showYLabel
    ylabel(ax, {'Perceived Disparity [deg]','log scale'}, 'FontSize', 22);
else
    ylabel(ax, '');
    ax.YColor = hiddenYAxisColor;
end
xlim(ax, local_expand_log_limits(x));
ylim(ax, [floor(log2(minDisp)) ceil(log2(maxDisp))]);
box(ax, 'off');
grid(ax, 'off');
end

function subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID)
if isempty(fullUniqueID)
    uniqueID = categories(removecats(tbl.ID));
else
    uniqueID = string(fullUniqueID(:));
end
subjectcolor = zeros(height(tbl), 3);
for c = 1:height(tbl)
    cindex = find(strcmp(uniqueID, char(string(tbl.ID(c)))), 1, 'first');
    colorRow = local_lookup_color_row(sorted_idx, cindex, numel(uniqueID), size(mycolormap, 1));
    subjectcolor(c,:) = mycolormap(colorRow,:);
end
end

function pStr = local_format_pvalue(pval)
if pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end

function numStr = local_format_number(val)
if val ~= 0 && abs(val) < 0.01
    numStr = sprintf('%.2e', val);
else
    numStr = sprintf('%.2f', val);
end
end

function lme = local_try_fitlme(tbl, formulaStr)
try
    lme = fitlme(tbl, formulaStr);
catch ME
    fprintf('Skipping model: %s\n Reason: %s\n', formulaStr, ME.message);
    lme = [];
end
end

function local_log_stereo_relationships(tbl, lmeDistanceRS)
fprintf('\n Stereo score analysis from distance random-slope model\n');
fprintf('----------------------------------------------------\n');

stereoTbl = local_subject_distance_rs_table(tbl, lmeDistanceRS, [], [], []);
if isempty(stereoTbl)
    fprintf('Stereo-score analysis skipped: distance random-slope model unavailable or stereo scores missing. \n \n');
    return;
end

scoreVarLabel = stereoTbl.Properties.UserData.StereoScoreVarName;

lmInterceptContinuous = fitlm(stereoTbl, 'SubjectIntercept ~ StereoScore');
lmSlopeContinuous = fitlm(stereoTbl, 'SubjectSlope ~ StereoScore');

fprintf('Model: SubjectIntercept ~ %s\n', scoreVarLabel);
disp(lmInterceptContinuous)
fprintf('Model: SubjectSlope ~ %s\n', scoreVarLabel);
disp(lmSlopeContinuous)
fprintf('\n');
end

function local_plot_stereo_relationship_figure(tbl, lmeDistanceRS, ...
    ResultsDir, tblName, fullUniqueID, mycolormap, sorted_idx, colorConfig)
stereoTbl = local_subject_distance_rs_table(tbl, lmeDistanceRS, fullUniqueID, mycolormap, sorted_idx);
if isempty(stereoTbl)
    return;
end

scoreVarLabel = stereoTbl.Properties.UserData.StereoScoreVarName;
x = stereoTbl.StereoScore;
xLabel = char(scoreVarLabel);
figSuffix = ['_' char(scoreVarLabel) '.png'];
fitFormulaIntercept = 'SubjectIntercept ~ StereoScore';
fitFormulaSlope = 'SubjectSlope ~ StereoScore';

lmIntercept = fitlm(stereoTbl, fitFormulaIntercept);
lmSlope = fitlm(stereoTbl, fitFormulaSlope);

figStereo = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .8 .6], ...
    'Name', [tblName figSuffix], 'Visible', 'off');
tStereo = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tStereo.Position = [0.08 0.14 0.70 0.72];

ax1 = nexttile;
local_plot_stereo_relationship_panel(ax1, x, stereoTbl.SubjectIntercept, stereoTbl.SubjectColor, ...
    xLabel, 'Subject intercept', lmIntercept);

ax2 = nexttile;
local_plot_stereo_relationship_panel(ax2, x, stereoTbl.SubjectSlope, stereoTbl.SubjectColor, ...
    xLabel, 'Subject slope', lmSlope);

local_add_subject_colorbar(figStereo, mycolormap, numel(stereoTbl.ID), ...
    xLabel, colorConfig, ax2);
exportgraphics(figStereo, fullfile(ResultsDir, [tblName figSuffix]), 'Resolution', 600);
close(figStereo);
end

function local_plot_stereo_relationship_panel(ax, x, y, colors, xLabel, yLabel, lm)
hold(ax, 'on');
markerSize=50;
scatter(ax, x, y, markerSize, colors, 'filled', 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', 'none');

pSlope = lm.Coefficients.pValue(2);
if pSlope < 0.05
    xGrid = linspace(min(x), max(x), 200)';
    [yPred, yCI] = predict(lm, ...
        table(xGrid, 'VariableNames', lm.PredictorNames(1)), 'Alpha', 0.05);
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], 'k', ...
        'FaceAlpha', 0.18, 'EdgeColor', 'none');
    plot(ax, xGrid, yPred, ':', 'Color',[.6 .6 .6] ,'LineWidth', 5);
end

set(ax, 'FontName', 'Avenir', 'FontSize', 18);
xlabel(ax, xLabel, 'FontSize', 20);
ylabel(ax, yLabel, 'FontSize', 20);
box(ax, 'off');
grid(ax, 'off');
title(ax, sprintf('%s \n p=%s, slope=%s', yLabel, ...
    local_format_pvalue(pSlope), local_format_number(lm.Coefficients.Estimate(2))), ...
    'FontSize', 16, 'FontWeight', 'normal');
end

function local_add_subject_colorbar(figHandle, mycolormap, nIDs, ...
    labelText, colorConfig, legendAxes)
if nargin < 4 || isempty(labelText)
    labelText = 'Participant color order';
end
if nargin < 5
    colorConfig = [];
end
if nargin < 6 || isempty(legendAxes)
    legendAxes = findobj(figHandle, 'Type', 'axes', '-not', 'Tag', 'Colorbar');
    legendAxes = legendAxes(1);
end

if isstruct(colorConfig) && string(colorConfig.Mode) == "clinicalnotes"
    legendHandle = Quad_add_clinical_notes_legend(legendAxes, colorConfig);
    legendHandle.FontSize = 11;
    return;
end

if isempty(mycolormap)
    return;
end

labelLower = lower(string(labelText));
isNormedStereoBar = contains(labelLower, 'normed stereo score') || ...
    contains(labelLower, 'normedscore') || ...
    contains(labelLower, 'normedstereoscore');
if isNormedStereoBar
    plotAxes = findall(figHandle, 'Type', 'axes');
    plotAxes = plotAxes(~arrayfun(@(ax) isa(ax, 'matlab.graphics.illustration.ColorBar'), plotAxes));
    if ~isempty(plotAxes)
        apply_stereo_score_colormap(plotAxes);
    end
    cb = add_stereo_score_colorbar(figHandle, labelText, [0.885 0.22 0.012 0.52]);
    cb.FontSize = 12;
    cb.Label.FontSize = 14;
    return;
else
    nColorLevels = min(size(mycolormap, 1), max(1, nIDs));
    displayCmap = mycolormap(1:nColorLevels, :);
end

cbAx = axes('Parent', figHandle, 'Position', [0.86 0.22 0.010 0.52]);
set(cbAx, 'Visible', 'off', 'YDir', 'normal', 'CLim', [1 nColorLevels], ...
    'Color', 'none', 'XColor', 'none', 'YColor', 'none');
colormap(cbAx, displayCmap);

cb = colorbar(cbAx, 'Position', [0.885 0.22 0.012 0.52]);
cb.FontName = 'Avenir';
cb.FontSize = 12;
if isNormedStereoBar
    stereoTickVals = 0:20:100;
    cb.Ticks = 1 + (stereoTickVals ./ 100) * (nColorLevels - 1);
    cb.TickLabels = string(stereoTickVals);
else
    cb.Ticks = unique(max(1, min(nColorLevels, [1 nColorLevels])));
    cb.TickLabels = string(cb.Ticks);
end
cb.Label.String = labelText;
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 14;
end

function stereoTbl = local_subject_distance_rs_table(tbl, lmeDistanceRS, fullUniqueID, mycolormap, sorted_idx)
if nargin < 3
    fullUniqueID = [];
end
if nargin < 4
    mycolormap = [];
end
if nargin < 5
    sorted_idx = [];
end

if isempty(lmeDistanceRS)
    stereoTbl = [];
    return;
end

stereoVar = local_find_first_var(tbl, {'ContinuousStereoScore', 'ContinousStereoScore', 'ContiousStereoScores', 'ContinuousScore', 'ContinousScore', 'NormedStereoScore', 'NormedScore'});
if isempty(stereoVar)
    stereoTbl = [];
    return;
end

[reEfx, reNames] = randomEffects(lmeDistanceRS);
levels = string(reNames.Level);
names = string(reNames.Name);
fixedIntercept = lmeDistanceRS.Coefficients.Estimate(1);
fixedSlope = lmeDistanceRS.Coefficients.Estimate(2);

subjectCats = categories(removecats(tbl.ID));
nSubjects = numel(subjectCats);
subjectID = strings(nSubjects, 1);
subjectIntercept = nan(nSubjects, 1);
subjectSlope = nan(nSubjects, 1);
stereoScore = nan(nSubjects, 1);

for i = 1:nSubjects
    subj = string(subjectCats{i});
    rowMask = string(tbl.ID) == subj;
    subjectID(i) = subj;
    stereoScore(i) = mean(double(tbl.(stereoVar)(rowMask)), 'omitnan');

    idxIntercept = find(levels == subj & names == "(Intercept)", 1, 'first');
    idxSlope = find(levels == subj & names == "log2distance", 1, 'first');

    reIntercept = 0;
    reSlope = 0;
    if ~isempty(idxIntercept)
        reIntercept = reEfx(idxIntercept);
    end
    if ~isempty(idxSlope)
        reSlope = reEfx(idxSlope);
    end

    subjectIntercept(i) = fixedIntercept + reIntercept;
    subjectSlope(i) = fixedSlope + reSlope;
end

validRows = ~isnan(stereoScore) & ~isnan(subjectIntercept) & ~isnan(subjectSlope);

subjectID = subjectID(validRows);
subjectIntercept = subjectIntercept(validRows);
subjectSlope = subjectSlope(validRows);
stereoScore = stereoScore(validRows);

if isempty(mycolormap) || isempty(sorted_idx)
    subjectColor = repmat([0 0 0], numel(subjectID), 1);
else
    subjectColor = local_colors_for_subject_ids(subjectID, fullUniqueID, mycolormap, sorted_idx);
end
stereoTbl = table(subjectID, subjectIntercept, subjectSlope, stereoScore, ...
    subjectColor, ...
    'VariableNames', {'ID', 'SubjectIntercept', 'SubjectSlope', 'StereoScore', 'SubjectColor'});
stereoTbl.Properties.UserData.StereoScoreVarName = string(stereoVar);
end

function varName = local_find_first_var(tbl, candidates)
varName = '';
for i = 1:numel(candidates)
    if ismember(candidates{i}, tbl.Properties.VariableNames)
        varName = candidates{i};
        return;
    end
end
end

function subjectColor = local_colors_for_subject_ids(subjectID, fullUniqueID, mycolormap, sorted_idx)
if isempty(fullUniqueID)
    uniqueID = subjectID(:);
else
    uniqueID = string(fullUniqueID(:));
end

subjectColor = zeros(numel(subjectID), 3);
for i = 1:numel(subjectID)
    cindex = find(strcmp(uniqueID, subjectID(i)), 1, 'first');
    if isempty(cindex)
        cindex = i;
    end
    colorRow = local_lookup_color_row(sorted_idx, cindex, numel(uniqueID), size(mycolormap, 1));
    subjectColor(i, :) = mycolormap(colorRow, :);
end
end

function colorRow = local_lookup_color_row(sorted_idx, cindex, nSubjects, nColors)
if isempty(cindex) || ~isfinite(cindex)
    colorRow = 1;
    return;
end

if local_uses_direct_color_rows(sorted_idx, nSubjects) && cindex <= numel(sorted_idx)
    colorRow = round(sorted_idx(cindex));
else
    colorRow = find(sorted_idx == cindex, 1, 'first');
    if isempty(colorRow)
        colorRow = cindex;
    end
end

colorRow = max(1, min(nColors, colorRow));
end

function tf = local_uses_direct_color_rows(sorted_idx, nSubjects)
if isempty(sorted_idx) || numel(sorted_idx) ~= nSubjects
    tf = false;
    return;
end

idx = round(sorted_idx(:));
tf = ~(all(isfinite(idx)) && isequal(sort(idx)', 1:nSubjects));
end

function local_log_model(formulaStr, lme)
fprintf('Model: %s\n', formulaStr);
if isempty(lme)
    fprintf('Skipped: rank-deficient or singular design.\n \n');
else
    disp(lme);
end
end

function local_compare_if_available(formula1, lme1, formula2, lme2)
if isempty(lme1) || isempty(lme2)
    fprintf('Comparison skipped:\n');
    fprintf('  %s\n', formula1);
    fprintf('  %s\n', formula2);
    fprintf('Reason: one or both models were unavailable.\n \n');
else
    fprintf('Model comparison:\n');
    fprintf('  %s\n', formula1);
    fprintf('  %s\n', formula2);
    cmpTbl = compare(lme1, lme2);
    try
        cmpTbl.Model = string({formula1; formula2});
    catch
    end
    disp(cmpTbl)
end
end

function tickStruct = local_log_ticks(minVal, maxVal, isElevation, modelTransform)
if nargin < 3
    isElevation = false;
end
if nargin < 4
    modelTransform = [];
end

if ~isElevation
    tickVals = unique(round(logspace(log10(minVal), log10(maxVal), 4), 2));
    tickVals = unique([minVal; tickVals(:); maxVal]);
    tickStruct = local_finalize_ticks(tickVals, log2(tickVals));
    return;
end

if modelTransform == 2
    nativeVals = unique(max(0, round(linspace(max(0, minVal - 1), max(0, maxVal - 1), 4), 1)));
    nativeVals = unique([max(0, minVal - 1); nativeVals(:); max(0, maxVal - 1)]);
    tickStruct = local_finalize_ticks(nativeVals, log2(nativeVals + 1));
else
    nativeVals = [-45 -30 -15 -5 0 5 15 30 45 60];
    tickPos = log2(1 + nativeVals/90);
    valid = isfinite(tickPos) & (1 + nativeVals/90) > 0;
    nativeVals = nativeVals(valid);
    dataMinNative = 90 * (minVal - 1);
    dataMaxNative = 90 * (maxVal - 1);
    inRange = nativeVals >= dataMinNative & nativeVals <= dataMaxNative;
    nativeVals = nativeVals(inRange);
    nativeVals = unique([round(dataMinNative, 1) nativeVals round(dataMaxNative, 1)], 'stable');
    tickStruct = local_finalize_ticks(nativeVals, log2(1 + nativeVals/90));
end
end

function lims = local_expand_log_limits(x)
xmin = min(x);
xmax = max(x);
span = xmax - xmin;
if span <= 0
    pad = max(0.01 * max(abs(xmin), 1), 0.01);
else
    pad = max(0.05 * span, 0.005 * max(abs([xmin xmax])));
end
xlow = max(eps, xmin - pad);
xhigh = xmax + pad;
lims = log2([xlow xhigh]);
end

function tickStruct = local_finalize_ticks(labelVals, positions)
labelVals = labelVals(:);
positions = positions(:);
valid = isfinite(labelVals) & isfinite(positions);
labelVals = labelVals(valid);
positions = positions(valid);

if numel(labelVals) <= 2
    tickStruct.positions = positions;
    tickStruct.labels = string(round(labelVals, 2));
    return;
end

keep = true(size(positions));
minSep = 0.18;
for i = 2:numel(positions)-1
    if abs(positions(i) - positions(i-1)) < minSep || abs(positions(i+1) - positions(i)) < minSep
        keep(i) = false;
    end
end

positions = positions(keep);
labelVals = labelVals(keep);

if numel(labelVals) < 2
    positions = [positions(1); positions(end)];
    labelVals = [labelVals(1); labelVals(end)];
end

tickStruct.positions = positions;
tickStruct.labels = string(round(labelVals, 2));
end
