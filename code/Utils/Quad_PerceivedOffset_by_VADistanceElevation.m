function [lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logDistanceNElevation, ...
    lme_logPM_by_logAngleDistanceElevation, ...
    lme_logPM_by_logAngleElevation, ...
    lme_logPM_by_logAngleDistance] = ...
    Quad_PerceivedOffset_by_VADistanceElevation(tbl, tblName, ResultsDir, ...
    saveLME, mycolormap, sorted_idx, modelTransform, degreeFlag, ...
    fullUniqueID, removeOutlierParticipants, secondYAxisColor, colorConfig)

% QUAD_PERCEIVEDOFFSET_BY_VADISTANCEELEVATION
% Fit interocular-offset visual-angle/distance/elevation LME models and plot RI fits.

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
if nargin < 11 || isempty(secondYAxisColor)
    secondYAxisColor = 'k';
end
if nargin < 12
    colorConfig = [];
end

sourceCsv = local_source_file_label(tbl, tblName);
tbl.h_va = compute_h_va_from_table_geometry(tbl);

tbl = Quad_prepare_perceived_disparity_table(tbl, modelTransform, removeOutlierParticipants);

angleFormula = 'log2mean_disparity ~ log2h_va + (1|ID)';
distanceFormula = 'log2mean_disparity ~ log2distance + (1|ID)';
elevationFormula = 'log2mean_disparity ~ log2elevation + (1|ID)';
distanceElevationFormula = 'log2mean_disparity ~ log2distance + log2elevation + (1|ID)';
angleElevationFormula = 'log2mean_disparity ~ log2h_va + log2elevation + (1|ID)';
angleDistanceFormula = 'log2mean_disparity ~ log2h_va + log2distance + (1|ID)';
angleDistanceElevationFormula = 'log2mean_disparity ~ log2h_va + log2distance + log2elevation + (1|ID)';

lme_logPM_by_logAngle = local_try_fitlme(tbl, angleFormula); % 1
lme_logPM_by_logDistance = local_try_fitlme(tbl, distanceFormula); %2
lme_logPM_by_logElevation = local_try_fitlme(tbl, elevationFormula); %3
lme_logPM_by_logDistanceNElevation = local_try_fitlme(tbl, distanceElevationFormula); %4
lme_logPM_by_logAngleDistance = local_try_fitlme(tbl, angleDistanceFormula); %5
lme_logPM_by_logAngleElevation = local_try_fitlme(tbl, angleElevationFormula); % 6
lme_logPM_by_logAngleDistanceElevation = local_try_fitlme(tbl, angleDistanceElevationFormula);%7

if saveLME
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    savelmefile = fullfile(ResultsDir, [tblName '_VA_Distance_Elevation_RI_models.txt']);
    local_write_model_report(savelmefile, tbl, tblName, sourceCsv, ...
        modelTransform, ...
        {lme_logPM_by_logAngle, ... %1
        lme_logPM_by_logDistance, ... %2
        lme_logPM_by_logElevation, ... %3
        lme_logPM_by_logDistanceNElevation, ...%4
        lme_logPM_by_logAngleDistance, ... %5
        lme_logPM_by_logAngleElevation, ... %6
        lme_logPM_by_logAngleDistanceElevation}, ... %7
        {angleFormula, distanceFormula, elevationFormula,...
        distanceElevationFormula, ...
        angleDistanceFormula, ...
        angleElevationFormula, ...
        angleDistanceElevationFormula});
end

subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID);
minDisp = max(0.01, min(tbl.MeanDisparity));
maxDisp = max(tbl.MeanDisparity);
nIDs = numel(categories(removecats(tbl.ID)));

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

figFull = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 1 .80], 'Name', [tblName '_full_VA_D_E_RI'], ...
    'Visible', 'off');
tFull = tiledlayout(1,3,'Padding','compact','TileSpacing','loose');
tFull.Position = [0.07 0.18 0.77 0.70];
fullModelTitle = local_full_model_title(lme_logPM_by_logAngleDistanceElevation, ...
    modelTransform, true, nIDs);
titleHandle = title(tFull, fullModelTitle);
titleHandle.FontName = 'Avenir';
titleHandle.FontSize = 11;
titleHandle.FontWeight = 'bold';
titleHandle.Interpreter = 'tex';
axFullA = nexttile;
local_plot_full_model_panel(axFullA, tbl, subjectcolor, ...
    lme_logPM_by_logAngleDistanceElevation, 'A', minDisp, maxDisp, ...
    modelTransform, true);
axFullD = nexttile;
local_plot_full_model_panel(axFullD, tbl, subjectcolor, ...
    lme_logPM_by_logAngleDistanceElevation, 'D', minDisp, maxDisp, ...
    modelTransform, false);
axFullE = nexttile;
local_plot_full_model_panel(axFullE, tbl, subjectcolor, ...
    lme_logPM_by_logAngleDistanceElevation, 'E', minDisp, maxDisp, ...
    modelTransform, false, secondYAxisColor);
local_add_subject_colorbar(figFull, mycolormap, nIDs, ...
    local_colorbar_label(colorConfig), colorConfig, axFullE);
exportgraphics(figFull, fullfile(ResultsDir, [tblName '_full_VA_D_E_RI.png']), ...
    'Resolution', 600);
close(figFull);
end

function local_write_model_report(reportFile, tbl, tblName, sourceCsv, ...
    modelTransform, models, formulas)
modelLabels = cellfun(@(f) ['Model: ' f], formulas, 'UniformOutput', false);
validModel = ~cellfun(@isempty, models);
if ~any(validModel)
    local_write_empty_report(reportFile, tblName, sourceCsv, formulas);
    return;
end

[comparisons, comparisonLabels] = local_model_comparisons(models, formulas);

reportOpts = struct();
reportOpts.ReportTitle = sprintf('Quad Interocular Offset h_va/Distance/Elevation LME Report: %s', ...
    char(string(tblName)));
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = sourceCsv;
reportOpts.ModelLabel = 'Interocular offset predicted by h_va, distance, and elevation';
reportOpts.SummaryLines = { ...
    sprintf('Experiment: Quad'), ...
    sprintf('Rows in model table: %d', height(tbl)), ...
    sprintf('Participants in model table: %d', numel(categories(removecats(tbl.ID)))), ...
    sprintf('Elevation transform: %s', local_transform_label(modelTransform)), ...
    sprintf('Fit method: ML'), ...
    sprintf('All formulas are fit with random intercepts by participant.'), ...
    sprintf('h_va parameter: h_va = visualangle(Width, Observer_Distance).'), ...
    sprintf('Log models use transformed elevation through log2elevation.')};
reportOpts.Models = models(validModel);
reportOpts.ModelLabels = modelLabels(validModel);
reportOpts.Comparisons = comparisons;
reportOpts.ComparisonLabels = comparisonLabels;
reportOpts.RemoveGroupError = false;
write_lme_stats_report(models{find(validModel, 1, 'first')}, reportFile, reportOpts);
end

function [comparisons, comparisonLabels] = local_model_comparisons(models, formulas)
comparisons = {};
comparisonLabels = {};

comparisonPairs = { ...
    3, 6, 'Add h_va to elevation-only model'; ...
    2, 5, 'Add h_va to distance-only model'; ...
    3, 4, 'Add distance to elevation-only model'; ...
    2, 4, 'Add elevation to distance-only model'; ...
    1, 6, 'Add elevation to h_va-only model'; ...
    1, 5, 'Add distance to h_va-only model'; ...
    4, 7, 'Add h_va to distance+elevation model'; ...
    5, 7, 'Add elevation to h_va+distance model'; ...
    6, 7, 'Add distance to h_va+elevation model'; ...
    3, 7, 'Add distance and h_va to elevation-only model'};

for iPair = 1:size(comparisonPairs, 1)
    baseIdx = comparisonPairs{iPair, 1};
    fullIdx = comparisonPairs{iPair, 2};
    [comparisonTbl, ok] = local_try_compare(models{baseIdx}, models{fullIdx});
    if ok
        comparisons{end + 1} = comparisonTbl;
        comparisonLabels{end + 1} = sprintf('%s: %s vs %s', ...
            comparisonPairs{iPair, 3}, formulas{baseIdx}, formulas{fullIdx});
    end
end

[fitStatsTbl, ok] = local_fit_stat_table( ...
    models, formulas, ...
    ["Log h_va"; "Log D"; "Log E"; "Log D+E"; ...
    "Log h_va+D"; "Log h_va+E"; "Log h_va+D+E"], ...
    ["log2mean_disparity"; "log2mean_disparity"; "log2mean_disparity"; ...
    "log2mean_disparity"; "log2mean_disparity"; "log2mean_disparity"; ...
    "log2mean_disparity"]);
if ok
    comparisons{end + 1} = fitStatsTbl;
    comparisonLabels{end + 1} = ...
        'AIC/BIC summary: log h_va/distance/elevation models';
end
end

function [comparisonTbl, ok] = local_try_compare(lme1, lme2)
comparisonTbl = [];
ok = false;
if isempty(lme1) || isempty(lme2)
    return;
end

try
    comparisonTbl = compare(lme1, lme2);
    ok = true;
catch ME
    fprintf('Skipping model comparison: %s\n', ME.message);
end
end

function [fitStatsTbl, ok] = local_fit_stat_table(models, formulas, labels, responseScales)
valid = ~cellfun(@isempty, models);
models = models(valid);
formulas = formulas(valid);
labels = labels(valid);
responseScales = responseScales(valid);
ok = ~isempty(models);

if ~ok
    fitStatsTbl = table();
    return;
end

nModels = numel(models);
nObs = nan(nModels, 1);
logLikelihood = nan(nModels, 1);
aic = nan(nModels, 1);
bic = nan(nModels, 1);
deviance = nan(nModels, 1);

for iModel = 1:nModels
    nObs(iModel) = models{iModel}.NumObservations;
    logLikelihood(iModel) = models{iModel}.LogLikelihood;
    aic(iModel) = models{iModel}.ModelCriterion.AIC;
    bic(iModel) = models{iModel}.ModelCriterion.BIC;
    deviance(iModel) = -2 * models{iModel}.LogLikelihood;
end

fitStatsTbl = table(labels(:), string(formulas(:)), responseScales(:), ...
    nObs, logLikelihood, aic, bic, deviance, ...
    'VariableNames', {'Model','Formula','Response','N','LogLikelihood','AIC','BIC','Deviance'});
end

function local_write_empty_report(reportFile, tblName, sourceCsv, formulas)
[reportDir, ~, ~] = fileparts(reportFile);
if ~isempty(reportDir) && ~exist(reportDir, 'dir')
    mkdir(reportDir);
end
[fid, msg] = fopen(reportFile, 'w');
if fid == -1
    error('Could not open report file %s: %s', reportFile, msg);
end
cleanupObj = onCleanup(@() fclose(fid));

reportTitle = sprintf('Quad Interocular Offset h_va/Distance/Elevation LME Report: %s', ...
    char(string(tblName)));
fprintf(fid, '%s\n', reportTitle);
fprintf(fid, '%s\n\n', repmat('=', 1, numel(reportTitle)));
fprintf(fid, 'Generated: %s\n', char(string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"))));
fprintf(fid, 'Generated by: %s\n', mfilename);
fprintf(fid, 'Source CSV: %s\n\n', sourceCsv);
fprintf(fid, 'No models were fit successfully.\n\n');
fprintf(fid, 'Attempted formulas:\n');
for iFormula = 1:numel(formulas)
    fprintf(fid, '    %s\n', formulas{iFormula});
end
end

function sourceCsv = local_source_file_label(tbl, tblName)
sourceCsv = char(string(tblName));
try
    if isstruct(tbl.Properties.UserData) && isfield(tbl.Properties.UserData, 'SourceFile')
        sourceCsv = char(string(tbl.Properties.UserData.SourceFile));
    end
catch
end

if ~endsWith(string(sourceCsv), ".csv", "IgnoreCase", true)
    sourceCsv = sprintf('%s.csv (inferred from tblName; function input is a table)', sourceCsv);
end
end

function transformLabel = local_transform_label(modelTransform)
switch modelTransform
    case 1
        transformLabel = 'Elevation';
    case 2
        transformLabel = 'absElevation';
    case 5
        transformLabel = 'ElevationD90';
    case 6
        transformLabel = 'absElevationD90';
    otherwise
        transformLabel = sprintf('modelTransform %d', modelTransform);
end
end

function titleLines = local_full_model_title(lme, modelTransform, includeVisualAngle, nIDs)
if nargin < 3
    includeVisualAngle = false;
end
if nargin < 4
    nIDs = nan;
end
if isempty(lme)
    titleLines = {'Full RI model', 'Model unavailable'};
    return;
end

b0 = local_coef_estimate(lme, '(Intercept)');
bD = local_coef_estimate(lme, 'log2distance');
bE = local_coef_estimate(lme, 'log2elevation');
p0 = local_coef_pvalue(lme, '(Intercept)');
pD = local_coef_pvalue(lme, 'log2distance');
pE = local_coef_pvalue(lme, 'log2elevation');
scale = 2.^b0;
elevationTerm = local_elevation_equation_term(modelTransform);
elevationLogTerm = local_elevation_log_formula_term(modelTransform);

if includeVisualAngle
    bVA = local_coef_estimate(lme, 'log2h_va');
    pVA = local_coef_pvalue(lme, 'log2h_va');
    modelLine = sprintf(['Full RI model: log_2(Offset) = b_0 + ' ...
        'b_{hVA}log_2(h_{VA}) + b_Dlog_2(D) + b_E%s + (1|ID)'], ...
        elevationLogTerm);
    equationLine = sprintf('Offset = %s h_{VA}^{%s} D^{%s} %s^{%s}', ...
        local_format_title_number(scale), local_format_title_number(bVA), ...
        local_format_title_number(bD), elevationTerm, local_format_title_number(bE));
    statsLine = sprintf('p_{hVA}=%s, p_D=%s, p_E=%s', ...
        local_format_pvalue(pVA), local_format_pvalue(pD), ...
        local_format_pvalue(pE));
    interceptLine = sprintf('p_0=%s, n=%s', ...
        local_format_pvalue(p0), ...
        local_format_title_number(nIDs));
else
    modelLine = sprintf('Full RI model: log_2(Offset) = b_0 + b_Dlog_2(D) + b_E%s + (1|ID)', ...
        elevationLogTerm);
    equationLine = sprintf('Offset = %s D^{%s} %s^{%s}', ...
        local_format_title_number(scale), local_format_title_number(bD), ...
        elevationTerm, local_format_title_number(bE));
    statsLine = sprintf('p_0=%s, p_D=%s, p_E=%s, n=%s', ...
        local_format_pvalue(p0), local_format_pvalue(pD), ...
        local_format_pvalue(pE), local_format_title_number(nIDs));
    interceptLine = '';
end

titleLines = {modelLine, equationLine, statsLine, interceptLine};
titleLines = titleLines(~cellfun(@isempty, titleLines));
end

function estimate = local_coef_estimate(lme, coefName)
estimate = nan;
coefNames = string(lme.Coefficients.Name);
idx = find(coefNames == string(coefName), 1, 'first');
if ~isempty(idx)
    estimate = lme.Coefficients.Estimate(idx);
end
end

function pval = local_coef_pvalue(lme, coefName)
pval = nan;
coefNames = string(lme.Coefficients.Name);
idx = find(coefNames == string(coefName), 1, 'first');
if ~isempty(idx)
    pval = lme.Coefficients.pValue(idx);
end
end

function elevationTerm = local_elevation_equation_term(modelTransform)
switch modelTransform
    case 2
        elevationTerm = '(1+|E|)';
    case 6
        elevationTerm = '(1+|E|/90)';
    otherwise
        elevationTerm = '(1+E/90)';
end
end

function elevationLogTerm = local_elevation_log_formula_term(modelTransform)
switch modelTransform
    case 2
        elevationLogTerm = 'log_2(1+|E|)';
    case 6
        elevationLogTerm = 'log_2(1+|E|/90)';
    otherwise
        elevationLogTerm = 'log_2(1+E/90)';
end
end

function numberText = local_format_title_number(value)
if ~isfinite(value)
    numberText = 'n/a';
elseif abs(value) >= 100
    numberText = sprintf('%.1f', value);
else
    numberText = sprintf('%.2f', value);
end
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

function labelText = local_colorbar_label(colorConfig)
labelText = 'Participant color order';
if ~isstruct(colorConfig) || ~isfield(colorConfig, 'Mode')
    return;
end

switch string(colorConfig.Mode)
    case "stereoscore"
        labelText = 'Normed stereo score';
    case "clinicalnotes"
        labelText = 'Clinical notes';
    case "id"
        labelText = 'Participant ID';
end
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

if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        string(colorConfig.Mode) == "id"
    return;
end

if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        string(colorConfig.Mode) == "clinicalnotes"
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
    cb.FontName = 'Avenir';
    cb.FontSize = 18;
    cb.Label.FontName = 'Avenir';
    cb.Label.FontSize = 20;
    return;
end

nColorLevels = min(size(mycolormap, 1), max(1, nIDs));
displayCmap = mycolormap(1:nColorLevels, :);
cbAx = axes('Parent', figHandle, 'Position', [0.86 0.22 0.010 0.52]);
set(cbAx, 'Visible', 'off', 'YDir', 'normal', 'CLim', [1 nColorLevels], ...
    'Color', 'none', 'XColor', 'none', 'YColor', 'none');
colormap(cbAx, displayCmap);

cb = colorbar(cbAx, 'Position', [0.885 0.22 0.012 0.52]);
cb.FontName = 'Avenir';
cb.FontSize = 12;
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        string(colorConfig.Mode) == "id" && ...
        isfield(colorConfig, 'ColorbarTicks') && ...
        isfield(colorConfig, 'ColorbarTickLabels') && ...
        ~isempty(colorConfig.ColorbarTicks)
    cb.Ticks = max(1, min(nColorLevels, colorConfig.ColorbarTicks(:)'));
    cb.TickLabels = string(colorConfig.ColorbarTickLabels(:)');
else
    cb.Ticks = unique(max(1, min(nColorLevels, [1 nColorLevels])));
    cb.TickLabels = string(cb.Ticks);
end
cb.Label.String = labelText;
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 14;
end

function local_plot_full_model_panel(ax, tbl, subjectcolor, lme, modeChar, ...
    minDisp, maxDisp, modelTransform, showYLabel, hiddenYAxisColor)
if nargin < 9 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 10 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end

hold(ax, 'on');
[x, xlog, xlabelText, tickVals, predictorName, ~] = ...
    local_log_axis_setup(tbl, modeChar, modelTransform);
y = tbl.log2mean_disparity;

if isempty(lme)
    scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
    local_finish_log_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, ...
        showYLabel, hiddenYAxisColor);
    return;
end

pval = local_fixed_effect_pvalue(lme, predictorName);
if isfinite(pval) && pval < 0.05
    xlinerange = linspace(min(xlog), max(xlog), 200)';
    [yFit, yCI, ok] = local_full_model_prediction(lme, tbl, modeChar, xlinerange);
    if ok
        fill(ax, [xlinerange; flipud(xlinerange)], ...
            [yCI(:,1); flipud(yCI(:,2))], 'k', ...
            'EdgeColor', 'none', 'FaceAlpha', 0.22);
        plot(ax, xlinerange, yFit, 'k-', 'LineWidth', 5);
    end
end

scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
local_finish_log_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, ...
    showYLabel, hiddenYAxisColor);
end

function [yFit, yCI, ok] = local_full_model_prediction(lme, tbl, modeChar, xlinerange)
ok = false;
yFit = [];
yCI = [];
nGrid = numel(xlinerange);
newTbl = tbl(ones(nGrid, 1), :);

if ismember('log2h_va', newTbl.Properties.VariableNames)
    newTbl.log2h_va = repmat(mean(tbl.log2h_va, 'omitnan'), nGrid, 1);
end
if ismember('log2distance', newTbl.Properties.VariableNames)
    newTbl.log2distance = repmat(mean(tbl.log2distance, 'omitnan'), nGrid, 1);
end
if ismember('log2elevation', newTbl.Properties.VariableNames)
    newTbl.log2elevation = repmat(mean(tbl.log2elevation, 'omitnan'), nGrid, 1);
end

switch modeChar
    case 'A'
        newTbl.log2h_va = xlinerange;
    case 'D'
        newTbl.log2distance = xlinerange;
    otherwise
        newTbl.log2elevation = xlinerange;
end

try
    [yFit, yCI] = predict(lme, newTbl, 'Conditional', false);
    ok = true;
catch ME
    fprintf('Skipping full-model prediction plot: %s\n', ME.message);
end
end

function pval = local_fixed_effect_pvalue(lme, predictorName)
pval = nan;
if isempty(lme)
    return;
end

coefNames = string(lme.Coefficients.Name);
idx = find(coefNames == string(predictorName), 1, 'first');
if ~isempty(idx)
    pval = lme.Coefficients.pValue(idx);
end
end

function [x, xlog, xlabelText, tickVals, predictorName, predictorLabel] = ...
    local_log_axis_setup(tbl, modeChar, modelTransform)
switch modeChar
    case 'A'
        x = tbl.h_va;
        xlog = tbl.log2h_va;
        xlabelText = 'h_{VA} [deg, log scale]';
        tickVals = local_visual_angle_ticks(min(x), max(x));
        predictorName = "log2h_va";
        predictorLabel = "h_va";
    case 'D'
        x = tbl.Distance;
        xlog = tbl.log2distance;
        xlabelText = 'Distance [m, log scale]';
        tickVals = local_log_ticks(min(x), max(x), false);
        predictorName = "log2distance";
        predictorLabel = "Distance";
    otherwise
        x = tbl.ElevationModel;
        xlog = tbl.log2elevation;
        predictorName = "log2elevation";
        predictorLabel = "Elevation";
        if modelTransform == 2
            xlabelText = '|Elevation| [deg, log scale]';
        elseif modelTransform == 6
            xlabelText = '|Elevation| [deg, log scale]';
        else
            xlabelText = 'Elevation [deg, log scale]';
        end
        tickVals = local_log_ticks(min(x), max(x), true, modelTransform);
end
end

function local_finish_log_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor)
set(ax, 'XTick', tickVals.positions, 'XTickLabel', tickVals.labels, ...
    'YTick', floor(log2(minDisp)):ceil(log2(maxDisp)), ...
    'YTickLabel', string(2.^(floor(log2(minDisp)):ceil(log2(maxDisp)))), ...
    'FontName', 'Avenir', 'FontSize', 12);
xlabel(ax, xlabelText, 'FontSize', 15);
if showYLabel
    ylabel(ax, {'Perceived Interocular Offset [deg]','log scale'}, 'FontSize', 16);
else
    ylabel(ax, '');
    ax.YColor = hiddenYAxisColor;
end
ax.XTickLabelRotation = 0;
xlim(ax, local_expand_log_limits(x));
ylim(ax, [floor(log2(minDisp)) ceil(log2(maxDisp))]);
box(ax, 'off');
grid(ax, 'off');
end

function pStr = local_format_pvalue(pval)
if isnan(pval)
    pStr = 'n/a';
    return;
end
if pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end

function lme = local_try_fitlme(tbl, formulaStr)
try
    lme = fitlme(tbl, formulaStr);
catch ME
    fprintf('Skipping model: %s\nReason: %s\n', formulaStr, ME.message);
    lme = [];
end
end

function tickStruct = local_visual_angle_ticks(minVal, maxVal)
candidateVals = [0.025 0.05 0.1 0.2 0.5 1 1.5 2 3 5 8 10 15];
tickVals = candidateVals(candidateVals >= minVal * 0.95 & candidateVals <= maxVal * 1.02);

if numel(tickVals) < 3
    tickVals = unique(round(logspace(log10(minVal), log10(maxVal), 4), 2));
end

tickStruct = local_finalize_ticks(tickVals(:), log2(tickVals(:)), 0.45);
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
x = x(isfinite(x) & x > 0);
if isempty(x)
    lims = [0 1];
    return;
end

logX = log2(x);
xmin = min(logX);
xmax = max(logX);
span = xmax - xmin;
pad = max(0.06 * span, 0.12);
lims = [xmin - pad xmax + pad];
end

function tickStruct = local_finalize_ticks(labelVals, positions, minSep)
if nargin < 3 || isempty(minSep)
    minSep = 0.18;
end

labelVals = labelVals(:);
positions = positions(:);
valid = isfinite(labelVals) & isfinite(positions);
labelVals = labelVals(valid);
positions = positions(valid);

if isempty(labelVals)
    tickStruct.positions = [];
    tickStruct.labels = strings(0, 1);
    return;
end

[positions, order] = sort(positions);
labelVals = labelVals(order);
roundedVals = round(labelVals, 2);
[~, uniqueIdx] = unique(roundedVals, 'stable');
positions = positions(uniqueIdx);
labelVals = labelVals(uniqueIdx);

if numel(labelVals) <= 2
    tickStruct.positions = positions;
    tickStruct.labels = string(round(labelVals, 2));
    return;
end

keep = true(size(positions));
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
