function [lme, interactionStats, modelComparison] = fit_PM_full_VA_D_E_modelbyStereoGroup( ...
    tbl, tblName, ResultsDir, saveModels, mycolormap, sorted_idx, ElevationTransform, colorConfig)
% fit_PM_full_VA_D_E_modelbyStereoGroup
% Fit the full VA/D/E perceptual magnification model with StereoGroup interactions.
%
% This is the StereoGroup companion to fit_PM_full_VA_D_E_modelbytask. It
% uses the full model:
%
%   log2(PM) ~ log2(VA)*StereoGroup + log2(D)*StereoGroup + ...
%              log2(ElevationTerm)*StereoGroup + (1|ID)
%
% StereoTypical is used as the reference group when present. Each
% predictor:StereoGroup term is the slope difference for that group relative
% to the reference group.
%
% Inputs
%   tbl                MATLAB table with ID, StereoGroup, Ratio_Visual_Angle,
%                      Real_Visual_Angle, Distance, and Elevation.
%   tblName            String/char used for figure and output filenames.
%   ResultsDir         Output directory. Set [] or '' to skip saving.
%   saveModels         Logical. If true saves the model and writes the report.
%   mycolormap         N-by-3 subject colormap. Optional.
%   sorted_idx         Subject color ordering. Optional.
%   ElevationTransform Elevation transform ID:
%                      1: log2(1+E)
%                      2: log2(1+abs(E))
%                      5: log2(1+E/90)
%                      6: log2(1+abs(E)/90)
%   colorConfig        Optional output from Quad_build_participant_color_config.
%
% Outputs
%   lme              Fitted LinearMixedModel with VA/D/E by StereoGroup interactions.
%   interactionStats Joint tests for StereoGroup x VA, Distance, and Elevation.
%   modelComparison compare(baseLME, lme), where baseLME has StereoGroup but
%                   no StereoGroup-by-parameter interactions.

if nargin < 2 || isempty(tblName); tblName = 'PM_Full_VA_D_E_ByStereoGroup'; end
if nargin < 3 || isempty(ResultsDir); ResultsDir = ''; end
if nargin < 4 || isempty(saveModels); saveModels = false; end
if nargin < 5; mycolormap = []; end
if nargin < 6; sorted_idx = []; end
if nargin < 7 || isempty(ElevationTransform); ElevationTransform = 1; end
if nargin < 8; colorConfig = []; end

if ~istable(tbl)
    error('fitPMFullVADEStereoGroup:InvalidInput', 'Input tbl must be a MATLAB table.');
end

ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'standard');
if isstruct(mycolormap)
    colorConfig = mycolormap;
    [mycolormap, sorted_idx] = local_color_inputs_from_config(colorConfig, mycolormap, sorted_idx);
end

sourceCsv = local_source_file_label(tbl, tblName);
tbl = local_ensure_log_variables(tbl, ElevationTransform);
[tbl, subjectcolor, nsubjects, groupSummaryLines] = ...
    local_prepare_model_table(tbl, mycolormap, sorted_idx, colorConfig);

baseFormula = ['log2ratio_visual_angle ~ 1 + log2real_angle + log2distance + ' ...
    'log2elevation + StereoGroup + (1|ID)'];
interactionFormula = ['log2ratio_visual_angle ~ 1 + log2real_angle*StereoGroup + ' ...
    'log2distance*StereoGroup + log2elevation*StereoGroup + (1|ID)'];

baseLME = fitlme(tbl, baseFormula, 'FitMethod', 'ML');
lme = fitlme(tbl, interactionFormula, 'FitMethod', 'ML');
modelComparison = compare(baseLME, lme);
interactionStats = local_interaction_stats(lme);

if saveModels && ~isempty(ResultsDir)
    local_write_report(tbl, tblName, ResultsDir, ElevationTransform, ...
        nsubjects, lme, modelComparison, interactionStats, groupSummaryLines, ...
        baseFormula, interactionFormula, sourceCsv);
end

local_plot_full_model_by_stereo_group(tbl, tblName, ResultsDir, subjectcolor, ...
    ElevationTransform, lme, interactionStats);

if saveModels && ~isempty(ResultsDir)
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    save(fullfile(ResultsDir, [char(string(tblName)) '.mat']), ...
        'lme', 'baseLME', 'modelComparison', 'interactionStats', ...
        'interactionFormula', 'baseFormula', 'ElevationTransform', 'nsubjects');
end
end

function local_write_report(tbl, tblName, ResultsDir, ElevationTransform, ...
    nsubjects, lme, modelComparison, interactionStats, groupSummaryLines, ...
    baseFormula, interactionFormula, sourceCsv)
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

reportFile = fullfile(ResultsDir, [char(string(tblName)) '_byStereoGroup.txt']);
groupNames = string(categories(tbl.StereoGroup));
formulaLines = cell(1, numel(groupNames));
for iGroup = 1:numel(groupNames)
    formulaLines{iGroup} = sprintf('%s formula: %s', groupNames(iGroup), ...
        local_group_formula(lme, ElevationTransform, groupNames(iGroup)));
end

reportOpts = struct();
reportOpts.ReportTitle = sprintf('Quad PM Full VA/D/E By-StereoGroup LME Report: %s', char(string(tblName)));
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = sourceCsv;
reportOpts.ModelLabel = 'Log perceptual magnification predicted by VA, distance, elevation, StereoGroup, and StereoGroup interactions';
reportOpts.SummaryLines = [ ...
    {sprintf('Experiment: Quad'), ...
    sprintf('Rows in model table: %d', height(tbl)), ...
    sprintf('Participants in model table: %d', nsubjects), ...
    sprintf('Reference StereoGroup: %s', groupNames(1)), ...
    sprintf('Elevation transform: %s', char(string(ElevationTransform))), ...
    sprintf('Fit method: ML'), ...
    sprintf('Base formula: %s', baseFormula), ...
    sprintf('Interaction formula: %s', interactionFormula)}, ...
    groupSummaryLines, ...
    formulaLines, ...
    local_interaction_summary_lines(interactionStats)];
reportOpts.Models = {lme};
reportOpts.ModelLabels = {['Model: ' interactionFormula]};
reportOpts.Comparisons = {modelComparison};
reportOpts.ComparisonLabels = {'Model comparison: full VA/D/E + StereoGroup base vs StereoGroup interactions'};
reportOpts.RemoveGroupError = false;
write_lme_stats_report(lme, reportFile, reportOpts);
end

function lines = local_interaction_summary_lines(interactionStats)
lines = cell(1, height(interactionStats) + 1);
lines{1} = 'StereoGroup interaction joint p-values:';
for iRow = 1:height(interactionStats)
    termText = strjoin(interactionStats.Terms{iRow}, ', ');
    lines{iRow + 1} = sprintf('  StereoGroup x %s: joint p = %s; terms: %s', ...
        char(string(interactionStats.Parameter(iRow))), ...
        char(string(interactionStats.pText(iRow))), termText);
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

function tbl = local_ensure_log_variables(tbl, ElevationTransform)
if ~ismember('Measurement', tbl.Properties.VariableNames)
    tbl.Measurement = repmat("Measurement", height(tbl), 1);
end

if ~ismember('StereoGroup', tbl.Properties.VariableNames)
    error('fitPMFullVADEStereoGroup:MissingStereoGroup', ...
        'Input table must contain StereoGroup.');
end

if ~ismember('log2ratio_visual_angle', tbl.Properties.VariableNames)
    if ismember('Ratio_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2ratio_visual_angle = log2(double(tbl.Ratio_Visual_Angle));
    elseif all(ismember({'Reported_Visual_Angle', 'Real_Visual_Angle'}, tbl.Properties.VariableNames))
        tbl.log2ratio_visual_angle = log2(double(tbl.Reported_Visual_Angle) ./ ...
            double(tbl.Real_Visual_Angle));
    else
        error('fitPMFullVADEStereoGroup:MissingPM', ...
            'Need Ratio_Visual_Angle or Reported_Visual_Angle and Real_Visual_Angle.');
    end
end

if ~ismember('log2real_angle', tbl.Properties.VariableNames)
    if ismember('log2real_visual_angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = double(tbl.log2real_visual_angle);
    elseif ismember('Real_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = log2(double(tbl.Real_Visual_Angle));
    else
        error('fitPMFullVADEStereoGroup:MissingVA', ...
            'Need Real_Visual_Angle to compute log2real_angle.');
    end
end

if ~ismember('log2distance', tbl.Properties.VariableNames)
    if ismember('Distance', tbl.Properties.VariableNames)
        tbl.log2distance = log2(double(tbl.Distance));
    else
        error('fitPMFullVADEStereoGroup:MissingDistance', ...
            'Need Distance to compute log2distance.');
    end
end

if ~ismember('log2elevation', tbl.Properties.VariableNames)
    if ~ismember('Elevation', tbl.Properties.VariableNames)
        error('fitPMFullVADEStereoGroup:MissingElevation', ...
            'Need Elevation to compute log2elevation.');
    end

    elevation = double(tbl.Elevation);
    switch ElevationTransform
        case 1
            tbl.log2elevation = log2(1 + elevation);
            tbl.ElevationModel = 1 + elevation;
        case 2
            tbl.log2elevation = log2(1 + abs(elevation));
            tbl.ElevationModel = 1 + abs(elevation);
        case 5
            tbl.log2elevation = log2(1 + elevation / 90);
            tbl.ElevationModel = 1 + elevation / 90;
        case 6
            tbl.log2elevation = log2(1 + abs(elevation) / 90);
            tbl.ElevationModel = 1 + abs(elevation) / 90;
        otherwise
            error('fitPMFullVADEStereoGroup:InvalidTransform', ...
                'Unsupported elevation transform %s.', string(ElevationTransform));
    end
elseif ~ismember('ElevationModel', tbl.Properties.VariableNames)
    tbl.ElevationModel = 2 .^ double(tbl.log2elevation);
end
end

function [tbl, subjectcolor, nsubjects, groupSummaryLines] = ...
    local_prepare_model_table(tbl, mycolormap, sorted_idx, colorConfig)
required = {'ID', 'StereoGroup', 'log2ratio_visual_angle', 'log2real_angle', ...
    'log2distance', 'log2elevation'};
missingVars = setdiff(required, tbl.Properties.VariableNames);
if ~isempty(missingVars)
    error('fitPMFullVADEStereoGroup:MissingVariables', ...
        'Input table is missing required variable(s): %s', strjoin(missingVars, ', '));
end

if ~iscategorical(tbl.ID)
    tbl.ID = categorical(tbl.ID);
end
tbl.StereoGroup = local_stereo_group_categorical(tbl.StereoGroup);

goodRows = isfinite(double(tbl.log2ratio_visual_angle)) & ...
    isfinite(double(tbl.log2real_angle)) & ...
    isfinite(double(tbl.log2distance)) & ...
    isfinite(double(tbl.log2elevation)) & ...
    ~isundefined(tbl.ID) & ...
    ~isundefined(tbl.StereoGroup);
tbl = tbl(goodRows, :);
tbl.ID = removecats(tbl.ID);
tbl.StereoGroup = removecats(tbl.StereoGroup);
tbl.StereoGroup = reordercats(tbl.StereoGroup, local_order_categories(categories(tbl.StereoGroup)));

if height(tbl) < 10
    error('fitPMFullVADEStereoGroup:TooFewRows', ...
        'Not enough valid rows after filtering (n=%d).', height(tbl));
end
if numel(categories(tbl.StereoGroup)) < 2
    error('fitPMFullVADEStereoGroup:TooFewGroups', ...
        'The input table must contain at least two StereoGroup levels.');
end

uniqueID = string(categories(tbl.ID));
nsubjects = numel(uniqueID);
[mycolormap, sorted_idx] = local_validate_color_inputs(mycolormap, sorted_idx, nsubjects);
subjectColorByID = local_subject_colors_by_id(uniqueID, mycolormap, sorted_idx, colorConfig);
subjectcolor = local_subject_colors(tbl.ID, uniqueID, subjectColorByID);
groupSummaryLines = local_group_summary_lines(tbl);
end

function stereoGroup = local_stereo_group_categorical(rawGroup)
if isnumeric(rawGroup) || islogical(rawGroup)
    groupValues = double(rawGroup);
    groupText = strings(size(groupValues));
    groupText(~isfinite(groupValues)) = "";
    if all(ismember(unique(groupValues(isfinite(groupValues))), [0 1 2 3]))
        groupText(groupValues == 1) = "StereoTypical";
        groupText(groupValues == 2) = "StereoDeficient";
        groupText(groupValues == 3) = "StereoBlind";
    else
        validRows = isfinite(groupValues);
        groupText(validRows) = "Group" + string(groupValues(validRows));
    end
    stereoGroup = categorical(groupText);
elseif iscategorical(rawGroup)
    stereoGroup = rawGroup;
else
    stereoGroup = categorical(strtrim(string(rawGroup)));
end
stereoGroup = local_standardize_numeric_group_labels(stereoGroup);
stereoGroup = reordercats(stereoGroup, local_order_categories(categories(stereoGroup)));
end

function stereoGroup = local_standardize_numeric_group_labels(stereoGroup)
groupText = string(stereoGroup);
validText = groupText(~ismissing(groupText) & groupText ~= "");
if ~isempty(validText) && all(ismember(validText, ["1", "2", "3"]))
    groupText(groupText == "1") = "StereoTypical";
    groupText(groupText == "2") = "StereoDeficient";
    groupText(groupText == "3") = "StereoBlind";
    stereoGroup = categorical(groupText);
end
end

function orderedCategories = local_order_categories(categoriesIn)
categoriesIn = string(categoriesIn(:));
preferred = ["StereoTypical"; "Typical"; "StereoDeficient"; "Deficient"; ...
    "StereoBlind"; "Blind"];
orderedCategories = strings(0, 1);
for iPreferred = 1:numel(preferred)
    if any(categoriesIn == preferred(iPreferred))
        orderedCategories(end + 1, 1) = preferred(iPreferred); %#ok<AGROW>
    end
end
for iCategory = 1:numel(categoriesIn)
    if ~ismember(categoriesIn(iCategory), orderedCategories)
        orderedCategories(end + 1, 1) = categoriesIn(iCategory); %#ok<AGROW>
    end
end
orderedCategories = cellstr(orderedCategories);
end

function local_plot_full_model_by_stereo_group(tbl, tblName, ResultsDir, subjectcolor, ...
    ElevationTransform, lme, interactionStats)
minRatio = min(2 .^ double(tbl.log2ratio_visual_angle), [], 'omitnan');
maxRatio = max(2 .^ double(tbl.log2ratio_visual_angle), [], 'omitnan');
minPMLim = min(0.25, minRatio);
maxPMLim = max(16, maxRatio);
yLimits = [floor(log2(minPMLim)) ceil(log2(maxPMLim))];
yTicks = yLimits(1):1:yLimits(2);
yTickLabels = string(2 .^ yTicks);

groupNames = string(categories(tbl.StereoGroup));
predictorNames = ["log2real_angle", "log2distance", "log2elevation"];
factorLabels = ["VA", "Distance", "Elevation"];
muX = [mean(double(tbl.log2real_angle), 'omitnan'), ...
    mean(double(tbl.log2distance), 'omitnan'), ...
    mean(double(tbl.log2elevation), 'omitnan')];
muX(~isfinite(muX)) = 0;

figHeight = min(1, max(0.75, 0.32 * numel(groupNames)));
figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 1 figHeight], 'Name', [char(string(tblName)) '_byStereoGroup'], ...
    'Visible', 'off');
axesList = local_create_panel_axes(figHandle, numel(groupNames), numel(predictorNames));

for groupIdx = 1:numel(groupNames)
    groupName = groupNames(groupIdx);
    groupRows = string(tbl.StereoGroup) == groupName;
    for predictorIdx = 1:numel(predictorNames)
        ax = axesList(groupIdx, predictorIdx);
        predictorName = predictorNames(predictorIdx);
        [xLog, xlabelText, xTicks, xTickLabels, xLimits] = ...
            local_axis_info(tbl, predictorName, ElevationTransform);
        pval = local_interaction_pvalue(interactionStats, factorLabels(predictorIdx));

        local_plot_one_group_predictor(ax, tbl, groupRows, subjectcolor, ...
            lme, predictorName, groupName, muX, xLog, xLimits, yLimits, ...
            xTicks, xTickLabels, yTicks, yTickLabels, xlabelText, ...
            factorLabels(predictorIdx), pval, predictorIdx == 1);
    end
end

sgtitle(local_group_formula(lme, ElevationTransform, groupNames(1), true), ...
    'FontSize', 18, 'FontName', 'Avenir', 'FontWeight', 'bold');

if ~isempty(ResultsDir)
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    exportgraphics(figHandle, fullfile(ResultsDir, [char(string(tblName)) '_byStereoGroup.png']), ...
        'Resolution', 600);
end
end

function axesList = local_create_panel_axes(figHandle, nRows, nCols)
left = 0.07;
right = 0.035;
bottom = 0.08;
top = 0.12;
colGap = 0.06;
rowGap = 0.11;
panelWidth = (1 - left - right - (nCols - 1) * colGap) / nCols;
panelHeight = (1 - bottom - top - (nRows - 1) * rowGap) / nRows;

axesList = gobjects(nRows, nCols);
for rowIdx = 1:nRows
    yPos = bottom + (nRows - rowIdx) * (panelHeight + rowGap);
    for colIdx = 1:nCols
        xPos = left + (colIdx - 1) * (panelWidth + colGap);
        axesList(rowIdx, colIdx) = axes(figHandle, ...
            'Position', [xPos, yPos, panelWidth, panelHeight]);
    end
end
end

function local_plot_one_group_predictor(ax, tbl, groupRows, subjectcolor, lme, ...
    predictorName, groupName, muX, xLog, xLimits, yLimits, xTicks, xTickLabels, ...
    yTicks, yTickLabels, xlabelText, factorLabel, interactionP, showYLabel)
hold(ax, 'on');
plot(ax, xLimits, [0 0], 'k:', 'LineWidth', 1);

xgrid = linspace(xLimits(1), xLimits(2), 200)';
predTbl = local_prediction_table(tbl, predictorName, xgrid, groupName, muX);
[yhat, yCI] = predict(lme, predTbl, 'Conditional', false);
local_plot_ci(ax, xgrid, yCI);
plot(ax, xgrid, yhat, 'k-', 'LineWidth', 3);

if any(groupRows)
    scatter_pm_by_measurement(ax, xLog(groupRows), ...
        tbl.log2ratio_visual_angle(groupRows), subjectcolor(groupRows, :), ...
        tbl.Measurement(groupRows), 50);
end

set(ax, 'XLim', xLimits, 'YLim', yLimits, ...
    'XTick', xTicks, 'XTickLabel', xTickLabels, ...
    'YTick', yTicks, 'YTickLabel', yTickLabels, ...
    'FontName', 'Avenir', 'FontSize', 13);
box(ax, 'off');
grid(ax, 'off');
xlabel(ax, xlabelText, 'FontSize', 14);
if showYLabel
    ylabel(ax, {'Perceptual Magnification', 'log scale'}, 'FontSize', 14);
else
    ylabel(ax, '');
end

titlePrefix = sprintf('%s: %s', char(string(groupName)), char(string(factorLabel)));
title(ax, sprintf('%s\n%s', titlePrefix, ...
    local_interaction_title_line(factorLabel, interactionP)), ...
    'FontSize', 12, 'FontWeight', 'normal');
end

function predTbl = local_prediction_table(tbl, predictorName, xgrid, groupName, muX)
nRows = numel(xgrid);
predTbl = table();
predTbl.log2real_angle = repmat(muX(1), nRows, 1);
predTbl.log2distance = repmat(muX(2), nRows, 1);
predTbl.log2elevation = repmat(muX(3), nRows, 1);
predTbl.(char(predictorName)) = xgrid;
predTbl.StereoGroup = categorical(repmat(string(groupName), nRows, 1), categories(tbl.StereoGroup));
predTbl.ID = categorical(repmat(string(tbl.ID(1)), nRows, 1), categories(tbl.ID));
end

function local_plot_ci(ax, xgrid, yCI)
if isempty(yCI) || size(yCI, 2) < 2
    return;
end

validRows = isfinite(xgrid) & isfinite(yCI(:, 1)) & isfinite(yCI(:, 2));
if ~any(validRows)
    return;
end

x = xgrid(validRows);
yLower = yCI(validRows, 1);
yUpper = yCI(validRows, 2);
fill(ax, [x; flipud(x)], [yLower; flipud(yUpper)], ...
    [0.72 0.72 0.72], 'EdgeColor', 'none', 'FaceAlpha', 0.65);
end

function [xLog, xlabelText, xTicks, xTickLabels, xLimits] = ...
    local_axis_info(tbl, predictorName, ElevationTransform)
xLog = double(tbl.(char(predictorName)));
switch char(predictorName)
    case 'log2real_angle'
        rawVals = 2 .^ xLog;
        xlabelText = 'Real VA [deg, log]';
    case 'log2distance'
        rawVals = 2 .^ xLog;
        xlabelText = 'Distance [m, log]';
    otherwise
        rawVals = 2 .^ xLog;
        xlabelText = local_elevation_xlabel(ElevationTransform);
end

if strcmp(char(predictorName), 'log2elevation')
    [xTicks, xTickLabels, xLimits] = local_elevation_ticks_and_limits(rawVals, ElevationTransform);
else
    [xTicks, nativeVals] = local_adaptive_log_ticks(min(rawVals), max(rawVals));
    xTickLabels = local_format_tick_labels(round(nativeVals, 1));
    xLimits = local_log_limits(rawVals);
end
end

function labelText = local_elevation_xlabel(ElevationTransform)
switch ElevationTransform
    case 1
        labelText = 'Elevation [deg, log]';
    case 2
        labelText = '|Elevation| [deg, log]';
    case 5
        labelText = 'Elevation [deg, log]';
    otherwise
        labelText = '|Elevation| [deg, log]';
end
end

function [xTickVals, xTickLabels, xLimits] = local_elevation_ticks_and_limits(modelVals, ElevationTransform)
xmin = min(modelVals);
xmax = max(modelVals);
xTickVals = log2([xmin xmax]);

if any(ElevationTransform == [5 6])
    nativeVals = round(90 * (2 .^ xTickVals - 1), 1);
else
    nativeVals = round(2 .^ xTickVals - 1, 1);
end
xTickLabels = local_format_tick_labels(nativeVals);
xLimits = local_log_limits(modelVals);
end

function xLimits = local_log_limits(rawVals)
finiteVals = rawVals(isfinite(rawVals) & rawVals > 0);
if isempty(finiteVals)
    xLimits = [0 1];
    return;
end

logVals = log2(finiteVals);
logMin = min(logVals);
logMax = max(logVals);
if logMin == logMax
    margin = max(0.05, abs(logMin) * 0.05);
else
    margin = max(0.05 * (logMax - logMin), 0.05);
end
xLimits = [logMin - margin, logMax + margin];
end

function interactionStats = local_interaction_stats(lme)
factorLabels = ["VA"; "Distance"; "Elevation"];
predictorNames = ["log2real_angle"; "log2distance"; "log2elevation"];
terms = cell(numel(factorLabels), 1);
df = nan(numel(factorLabels), 1);
pValue = nan(numel(factorLabels), 1);

coefTbl = lme.Coefficients;
coefNames = string(coefTbl.Name);
for iFactor = 1:numel(factorLabels)
    termIdx = find(contains(coefNames, predictorNames(iFactor)) & ...
        contains(coefNames, "StereoGroup"));
    terms{iFactor} = cellstr(coefNames(termIdx));
    df(iFactor) = numel(termIdx);
    if ~isempty(termIdx)
        H = zeros(numel(termIdx), numel(coefNames));
        for iTerm = 1:numel(termIdx)
            H(iTerm, termIdx(iTerm)) = 1;
        end
        try
            pValue(iFactor) = coefTest(lme, H);
        catch
            pValue(iFactor) = min(double(coefTbl.pValue(termIdx)), [], 'omitnan');
        end
    end
end

pText = strings(numel(factorLabels), 1);
for iFactor = 1:numel(factorLabels)
    pText(iFactor) = string(local_format_title_pvalue(pValue(iFactor)));
end

interactionStats = table(factorLabels, predictorNames, terms, df, pValue, pText, ...
    'VariableNames', {'Parameter', 'Predictor', 'Terms', 'DF', 'pValue', 'pText'});
end

function pval = local_interaction_pvalue(interactionStats, factorLabel)
pval = NaN;
rowIdx = find(string(interactionStats.Parameter) == string(factorLabel), 1, 'first');
if ~isempty(rowIdx)
    pval = interactionStats.pValue(rowIdx);
end
end

function titleLine = local_interaction_title_line(factorLabel, pval)
if isfinite(pval) && pval < 0.05
    titleLine = sprintf('StereoGroup x %s p=%s', char(string(factorLabel)), ...
        local_format_title_pvalue(pval));
elseif isfinite(pval)
    titleLine = sprintf('StereoGroup x %s ns, p=%s', char(string(factorLabel)), ...
        local_format_title_pvalue(pval));
else
    titleLine = sprintf('StereoGroup x %s p=n/a', char(string(factorLabel)));
end
end

function pStr = local_format_title_pvalue(pval)
if ~isfinite(pval)
    pStr = 'n/a';
elseif pval > 0.001
    pStr = sprintf('%.3f', pval);
elseif pval == 0
    pStr = sprintf('<%.2e', realmin);
else
    pStr = sprintf('%.2e', pval);
end
end

function formulaText = local_group_formula(lme, ElevationTransform, groupName, includeGroupLabel)
if nargin < 4 || isempty(includeGroupLabel)
    includeGroupLabel = false;
end

coefNames = string(lme.Coefficients.Name);
beta = double(lme.Coefficients.Estimate);

intercept = local_coef_value(coefNames, beta, "(Intercept)");
va = local_coef_value(coefNames, beta, "log2real_angle");
distance = local_coef_value(coefNames, beta, "log2distance");
elevation = local_coef_value(coefNames, beta, "log2elevation");

referenceGroup = local_reference_group_from_lme(lme);
if string(groupName) ~= referenceGroup
    intercept = intercept + local_group_coef_value(coefNames, beta, groupName, "");
    va = va + local_group_coef_value(coefNames, beta, groupName, "log2real_angle");
    distance = distance + local_group_coef_value(coefNames, beta, groupName, "log2distance");
    elevation = elevation + local_group_coef_value(coefNames, beta, groupName, "log2elevation");
end

switch ElevationTransform
    case 1
        elevationTerm = '(1+E)';
    case 2
        elevationTerm = '(1+|E|)';
    case 5
        elevationTerm = '(1+E/90)';
    otherwise
        elevationTerm = '(1+|E|/90)';
end

formulaText = sprintf('PM=%.2fVA^{%.2f}D^{%.2f}%s^{%.2f}', ...
    2 .^ intercept, va, distance, elevationTerm, elevation);
if includeGroupLabel
    formulaText = sprintf('%s reference: %s', char(string(groupName)), formulaText);
end
end

function referenceGroup = local_reference_group_from_lme(lme)
try
    referenceGroup = string(categories(lme.Variables.StereoGroup));
    referenceGroup = referenceGroup(1);
catch
    referenceGroup = "StereoTypical";
end
end

function value = local_coef_value(coefNames, beta, coefName)
coefIdx = find(coefNames == string(coefName), 1, 'first');
if isempty(coefIdx)
    value = NaN;
else
    value = beta(coefIdx);
end
end

function value = local_group_coef_value(coefNames, beta, groupName, predictorName)
groupTerm = "StereoGroup_" + string(groupName);
if strlength(string(predictorName)) == 0
    coefIdx = find(coefNames == groupTerm, 1, 'first');
else
    predictorName = string(predictorName);
    coefIdx = find(contains(coefNames, groupTerm) & ...
        contains(coefNames, predictorName), 1, 'first');
end

if isempty(coefIdx)
    value = 0;
else
    value = beta(coefIdx);
end
end

function [mycolormap, sorted_idx] = local_validate_color_inputs(mycolormap, sorted_idx, nsubjects)
if isempty(mycolormap)
    mycolormap = lines(max(nsubjects, 1));
end
if isempty(sorted_idx)
    sorted_idx = (1:nsubjects)';
end
if size(mycolormap, 1) < nsubjects
    mycolormap = interp1(linspace(0, 1, size(mycolormap, 1)), mycolormap, ...
        linspace(0, 1, nsubjects), 'linear');
end
end

function subjectColorByID = local_subject_colors_by_id(uniqueID, mycolormap, sorted_idx, colorConfig)
subjectColorByID = nan(numel(uniqueID), 3);
if isstruct(colorConfig) && isfield(colorConfig, 'ID') && isfield(colorConfig, 'Color')
    configID = string(colorConfig.ID(:));
    for subjectIdx = 1:numel(uniqueID)
        configIdx = find(configID == uniqueID(subjectIdx), 1, 'first');
        if ~isempty(configIdx)
            subjectColorByID(subjectIdx, :) = colorConfig.Color(configIdx, :);
        end
    end
end

missingColor = any(isnan(subjectColorByID), 2);
for subjectIdx = find(missingColor)'
    subjectColorByID(subjectIdx, :) = local_subject_color_row(subjectIdx, mycolormap, sorted_idx);
end
end

function subjectcolor = local_subject_colors(idData, uniqueID, subjectColorByID)
subjectcolor = zeros(numel(idData), 3);
idStrings = string(idData);
for rowIdx = 1:numel(idData)
    subjectIdx = find(uniqueID == idStrings(rowIdx), 1, 'first');
    if isempty(subjectIdx)
        subjectIdx = 1;
    end
    subjectcolor(rowIdx, :) = subjectColorByID(subjectIdx, :);
end
end

function thisColor = local_subject_color_row(subjectIdx, mycolormap, sorted_idx)
colorRow = find(sorted_idx == subjectIdx, 1, 'first');
if isempty(colorRow)
    colorRow = subjectIdx;
end
colorRow = min(max(colorRow, 1), size(mycolormap, 1));
thisColor = mycolormap(colorRow, :);
end

function [mycolormap, sorted_idx] = local_color_inputs_from_config(colorConfig, mycolormap, sorted_idx)
if isfield(colorConfig, 'RankCmap')
    mycolormap = colorConfig.RankCmap;
elseif isfield(colorConfig, 'Color')
    mycolormap = colorConfig.Color;
end

if isfield(colorConfig, 'SortedIdx')
    sorted_idx = colorConfig.SortedIdx;
elseif isempty(sorted_idx) && isfield(colorConfig, 'ID')
    sorted_idx = (1:numel(colorConfig.ID))';
end
end

function [tickPos, nativeVals] = local_adaptive_log_ticks(minVal, maxVal)
if ~isfinite(minVal) || ~isfinite(maxVal) || minVal <= 0 || maxVal <= 0
    tickPos = [];
    nativeVals = [];
    return;
end

if minVal == maxVal
    nativeVals = minVal;
else
    logMin = log2(minVal);
    logMax = log2(maxVal);
    logSpan = logMax - logMin;
    if logSpan < 1
        nTicks = 2;
    elseif logSpan < 2.5
        nTicks = 3;
    elseif logSpan < 4.5
        nTicks = 4;
    else
        nTicks = 5;
    end
    nativeVals = 2 .^ linspace(logMin, logMax, nTicks);
    nativeVals(1) = minVal;
    nativeVals(end) = maxVal;
end
nativeVals = unique(nativeVals, 'stable');
tickPos = log2(nativeVals);
end

function labels = local_format_tick_labels(vals)
labels = strings(size(vals));
for iValue = 1:numel(vals)
    if abs(vals(iValue)) > 1000
        labels(iValue) = sprintf('%.1e', vals(iValue));
    else
        labels(iValue) = string(vals(iValue));
    end
end
end

function groupSummaryLines = local_group_summary_lines(tbl)
groupNames = string(categories(tbl.StereoGroup));
groupSummaryLines = cell(1, numel(groupNames) + 1);
groupSummaryLines{1} = 'StereoGroup counts:';
for iGroup = 1:numel(groupNames)
    rowMask = string(tbl.StereoGroup) == groupNames(iGroup);
    groupSummaryLines{iGroup + 1} = sprintf('  %s: %d rows, %d participants', ...
        groupNames(iGroup), sum(rowMask), numel(unique(tbl.ID(rowMask))));
end
end
