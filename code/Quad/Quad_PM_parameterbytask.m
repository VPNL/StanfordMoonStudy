function [lme_logPM_by_logAngleNTask, lme_logPM_by_logDistanceNTask, ...
    lme_logPM_by_logElevationNTask, modelComparisons] = ...
    Quad_PM_parameterbytask(tbl, tblName, ResultsDir, saveLME, ...
    cmap, sorted_idx, ElevationTransform, colorConfig)
% QUAD_PM_PARAMETERBYTASK_SINGLE
% Fit single-parameter PM models with parameter-by-Task interactions.
%
% Perceptual is used as the reference task, so Adjusted coefficients are
% estimated relative to Perceptual:
%
%   log2ratio_visual_angle ~ predictor*Task + (1|ID)
%
% where predictor is log2real_visual_angle, log2distance, or log2elevation.

if nargin < 4 || isempty(saveLME)
    saveLME = false;
end
if nargin < 5
    cmap = [];
end
if nargin < 6
    sorted_idx = [];
end
if nargin < 7 || isempty(ElevationTransform)
    ElevationTransform = 1;
end
if nargin < 8
    colorConfig = [];
end

ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'standard');
if isstruct(cmap)
    colorConfig = cmap;
    [cmap, sorted_idx] = local_color_inputs_from_config(colorConfig, cmap, sorted_idx);
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

[tbl, nsubjects, subjectcolor, ~, ~, ~, ~] = ...
    local_prepare_table(tbl, cmap, sorted_idx, ElevationTransform, colorConfig);

angleFormula = 'log2ratio_visual_angle ~ log2real_visual_angle*Task + (1|ID)';
distanceFormula = 'log2ratio_visual_angle ~ log2distance*Task + (1|ID)';
elevationFormula = 'log2ratio_visual_angle ~ log2elevation*Task + (1|ID)';

baseAngleFormula = 'log2ratio_visual_angle ~ log2real_visual_angle + Task + (1|ID)';
baseDistanceFormula = 'log2ratio_visual_angle ~ log2distance + Task + (1|ID)';
baseElevationFormula = 'log2ratio_visual_angle ~ log2elevation + Task + (1|ID)';

baseAngleLME = fitlme(tbl, baseAngleFormula, 'FitMethod', 'ML');
baseDistanceLME = fitlme(tbl, baseDistanceFormula, 'FitMethod', 'ML');
baseElevationLME = fitlme(tbl, baseElevationFormula, 'FitMethod', 'ML');

lme_logPM_by_logAngleNTask = fitlme(tbl, angleFormula, 'FitMethod', 'ML');
lme_logPM_by_logDistanceNTask = fitlme(tbl, distanceFormula, 'FitMethod', 'ML');
lme_logPM_by_logElevationNTask = fitlme(tbl, elevationFormula, 'FitMethod', 'ML');

modelComparisons = struct();
modelComparisons.Angle = compare(baseAngleLME, lme_logPM_by_logAngleNTask);
modelComparisons.Distance = compare(baseDistanceLME, lme_logPM_by_logDistanceNTask);
modelComparisons.Elevation = compare(baseElevationLME, lme_logPM_by_logElevationNTask);

if saveLME
    local_write_report(tbl, tblName, ResultsDir, ElevationTransform, nsubjects, ...
        lme_logPM_by_logAngleNTask, lme_logPM_by_logDistanceNTask, ...
        lme_logPM_by_logElevationNTask, modelComparisons, ...
        angleFormula, distanceFormula, elevationFormula);
end

local_plot_parameter_by_task(tbl, tblName, ResultsDir, subjectcolor, ...
    ElevationTransform, lme_logPM_by_logAngleNTask, ...
    lme_logPM_by_logDistanceNTask, lme_logPM_by_logElevationNTask, ...
    modelComparisons);
end

function [tbl, nsubjects, subjectcolor, subjectColorByID, uniqueID, cmap, sorted_idx] = ...
    local_prepare_table(tbl, cmap, sorted_idx, ElevationTransform, colorConfig)
requiredVars = {'ID', 'Task', 'Real_Visual_Angle', 'Ratio_Visual_Angle', ...
    'Distance', 'Elevation'};
missingVars = setdiff(requiredVars, tbl.Properties.VariableNames);
if ~isempty(missingVars)
    error('QuadPMParameterByTask:MissingVariables', ...
        'Input table is missing required variable(s): %s', strjoin(missingVars, ', '));
end

if ~ismember('Measurement', tbl.Properties.VariableNames)
    tbl.Measurement = repmat("Measurement", height(tbl), 1);
end

tbl.Task = local_task_categorical(tbl.Task);
if ~iscategorical(tbl.ID)
    tbl.ID = categorical(tbl.ID);
end

tbl.log2real_visual_angle = log2(double(tbl.Real_Visual_Angle));
tbl.log2ratio_visual_angle = log2(double(tbl.Ratio_Visual_Angle));
tbl.log2distance = log2(double(tbl.Distance));

switch ElevationTransform
    case 1
        tbl.log2elevation = log2(double(tbl.Elevation) + 1);
        tbl.ElevationModel = double(tbl.Elevation) + 1;
    case 2
        tbl.log2elevation = log2(abs(double(tbl.Elevation)) + 1);
        tbl.ElevationModel = abs(double(tbl.Elevation)) + 1;
    case 5
        tbl.log2elevation = log2(double(tbl.Elevation) / 90 + 1);
        tbl.ElevationModel = double(tbl.Elevation) / 90 + 1;
    case 6
        tbl.log2elevation = log2(abs(double(tbl.Elevation)) / 90 + 1);
        tbl.ElevationModel = abs(double(tbl.Elevation)) / 90 + 1;
    otherwise
        error('QuadPMParameterByTask:InvalidTransform', ...
            'Unsupported elevation transform %s.', string(ElevationTransform));
end

keepRows = isfinite(tbl.log2real_visual_angle) & ...
    isfinite(tbl.log2ratio_visual_angle) & ...
    isfinite(tbl.log2distance) & ...
    isfinite(tbl.log2elevation) & ...
    ~isundefined(tbl.ID) & ...
    ~isundefined(tbl.Task) & ...
    ismember(string(tbl.Task), ["Perceptual", "Adjusted"]);
tbl = tbl(keepRows, :);
tbl.ID = removecats(tbl.ID);
tbl.Task = removecats(tbl.Task);
tbl.Task = reordercats(tbl.Task, cellstr(["Perceptual", "Adjusted"]));

if numel(categories(tbl.Task)) < 2
    error('QuadPMParameterByTask:TooFewTasks', ...
        'The input table must contain both Perceptual and Adjusted tasks.');
end

uniqueID = string(categories(tbl.ID));
nsubjects = numel(uniqueID);
[cmap, sorted_idx] = local_validate_color_inputs(cmap, sorted_idx, nsubjects);
subjectColorByID = local_subject_colors_by_id(uniqueID, cmap, sorted_idx, colorConfig);
subjectcolor = local_subject_colors(tbl.ID, uniqueID, subjectColorByID);
end

function local_write_report(tbl, tblName, ResultsDir, ElevationTransform, nsubjects, ...
    lmeAngle, lmeDistance, lmeElevation, modelComparisons, ...
    angleFormula, distanceFormula, elevationFormula)
savelmefile = fullfile(ResultsDir, [char(string(tblName)) '_parameter_by_task.txt']);
sourceCsv = local_source_file_label(tbl, tblName);

taskSummaryLines = local_task_summary_lines(tbl);
reportOpts = struct();
reportOpts.ReportTitle = sprintf('Quad PM Parameter-by-Task Single-Factor LME Report: %s', char(string(tblName)));
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = sourceCsv;
reportOpts.ModelLabel = 'Log perceptual magnification predicted by one log physical factor, Task, and their interaction';
reportOpts.SummaryLines = [ ...
    {sprintf('Experiment: Quad'), ...
    sprintf('Rows in model table: %d', height(tbl)), ...
    sprintf('Participants in model table: %d', nsubjects), ...
    sprintf('Reference task: Perceptual'), ...
    sprintf('Compared task: Adjusted'), ...
    sprintf('Elevation transform: %s', char(string(ElevationTransform))), ...
    sprintf('Fit method: ML')}, ...
    taskSummaryLines];
reportOpts.Models = {lmeAngle, lmeDistance, lmeElevation};
reportOpts.ModelLabels = { ...
    ['Model: ' angleFormula], ...
    ['Model: ' distanceFormula], ...
    ['Model: ' elevationFormula]};
reportOpts.Comparisons = { ...
    modelComparisons.Angle, ...
    modelComparisons.Distance, ...
    modelComparisons.Elevation};
reportOpts.ComparisonLabels = { ...
    'Model comparison: visual angle base vs Task interaction', ...
    'Model comparison: distance base vs Task interaction', ...
    'Model comparison: elevation base vs Task interaction'};
reportOpts.RemoveGroupError = false;
write_lme_stats_report(lmeAngle, savelmefile, reportOpts);
end

function local_plot_parameter_by_task(tbl, tblName, ResultsDir, subjectcolor, ...
    ElevationTransform, lmeAngle, lmeDistance, lmeElevation, modelComparisons)
minRatio = min(double(tbl.Ratio_Visual_Angle));
maxRatio = max(double(tbl.Ratio_Visual_Angle));
minPMLim = min(0.25, minRatio);
maxPMLim = max(16, maxRatio);
yLimits = [floor(log2(minPMLim)) ceil(log2(maxPMLim))];
yTicks = yLimits(1):1:yLimits(2);
yTickLabels = string(2.^yTicks);

taskNames = ["Perceptual", "Adjusted"];
modeChars = ['A', 'D', 'E'];
lmeList = {lmeAngle, lmeDistance, lmeElevation};
comparisonList = {modelComparisons.Angle, modelComparisons.Distance, modelComparisons.Elevation};

figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .5 1], 'Name', [char(string(tblName)) '_parameter_by_task'], ...
    'Visible', 'off');
axesList = local_create_six_panel_axes(figHandle);
local_add_column_headers(figHandle, axesList, taskNames);

for rowIdx = 1:3
    modeChar = modeChars(rowIdx);
    lme = lmeList{rowIdx};
    comparisonTbl = comparisonList{rowIdx};
    [~, xLog, xlabelText, titleTemplate, xTickVals, xTickLabels, xLimits] = ...
        local_axis_info(tbl, modeChar, ElevationTransform);

    for colIdx = 1:2
        taskName = taskNames(colIdx);
        ax = axesList(rowIdx, colIdx);
        taskRows = string(tbl.Task) == taskName;
        local_plot_task_panel(ax, tbl, taskRows, xLog, subjectcolor, ...
            lme, modeChar, taskName, xLimits, xTickVals, xTickLabels, ...
            xlabelText, titleTemplate, yLimits, yTicks, yTickLabels, comparisonTbl);
    end
end

local_export_png(figHandle, fullfile(ResultsDir, ...
    [char(string(tblName)) '_parameter_by_task.png']), 600);
close(figHandle);
end

function axesList = local_create_six_panel_axes(figHandle)
left = 0.13;
bottom = 0.055;
panelWidth = 0.30;
panelHeight = 0.165;
colGap = 0.11;
rowGap = 0.155;

axesList = gobjects(3, 2);
for rowIdx = 1:3
    yPos = bottom + (3 - rowIdx) * (panelHeight + rowGap);
    for colIdx = 1:2
        xPos = left + (colIdx - 1) * (panelWidth + colGap);
        axesList(rowIdx, colIdx) = axes(figHandle, ...
            'Position', [xPos, yPos, panelWidth, panelHeight]);
    end
end
end

function local_add_column_headers(figHandle, axesList, taskNames)
for colIdx = 1:numel(taskNames)
    axisPosition = axesList(1, colIdx).Position;
    xCenter = axisPosition(1) + axisPosition(3) / 2;
    annotation(figHandle, 'textbox', [xCenter - 0.12, 0.955, 0.24, 0.025], ...
        'String', taskNames(colIdx), 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'EdgeColor', 'none', ...
        'FontName', 'Avenir', 'FontSize', 13, 'FontWeight', 'bold');
end
end

function local_plot_task_panel(ax, tbl, taskRows, xLog, subjectcolor, ...
    lme, modeChar, taskName, xLimits, xTickVals, xTickLabels, ...
    xlabelText, titleTemplate, yLimits, yTicks, yTickLabels, comparisonTbl)
hold(ax, 'on');
plot(ax, xLimits, [0 0], 'k:', 'LineWidth', 1);

lineRange = linspace(xLimits(1), xLimits(2), 200)';
predTbl = local_prediction_table(tbl, modeChar, lineRange, taskName);
[yFit, yCI] = predict(lme, predTbl, 'Conditional', false);
local_plot_fixed_effect_ci(ax, lineRange, yCI);
plot(ax, lineRange, yFit, 'k-', 'LineWidth', 2);

if any(taskRows)
    markerSize = 35;
    scatter_pm_by_measurement(ax, xLog(taskRows), tbl.log2ratio_visual_angle(taskRows), ...
        subjectcolor(taskRows, :), tbl.Measurement(taskRows), markerSize);
end

set(ax, 'XTick', xTickVals, 'XTickLabel', xTickLabels, ...
    'YTick', yTicks, 'YTickLabel', yTickLabels, ...
    'FontName', 'Avenir', 'FontSize', 10);
set(ax, 'XLim', xLimits, 'YLim', yLimits);
box(ax, 'off');
grid(ax, 'off');
xlabel(ax, xlabelText, 'FontSize', 11);
if taskName == "Perceptual"
    ylabel(ax, {'Perceptual Magnification','log scale'}, 'FontSize', 11);
else
    ylabel(ax, '');
end

lineStats = local_task_line_stats(lme, modeChar, taskName);
taskMainP = local_task_main_effect_pvalue(lme);
interactionP = local_task_interaction_pvalue(lme, modeChar, comparisonTbl);
nTaskSubjects = numel(unique(tbl.ID(taskRows)));
titleText = sprintf(titleTemplate, 2.^lineStats.Intercept, ...
    lineStats.Slope, local_format_pvalue(lineStats.SlopePValue), nTaskSubjects);
titleText = sprintf('%s\n%s\n%s', titleText, ...
    local_task_main_effect_title_line(taskMainP), ...
    local_task_interaction_title_line(modeChar, interactionP));
title(ax, titleText, 'FontSize', 10, 'FontWeight', 'normal');
end

function local_plot_fixed_effect_ci(ax, lineRange, yCI)
if isempty(yCI) || size(yCI, 2) < 2
    return;
end

validRows = isfinite(lineRange) & isfinite(yCI(:, 1)) & isfinite(yCI(:, 2));
if ~any(validRows)
    return;
end

x = lineRange(validRows);
yLower = yCI(validRows, 1);
yUpper = yCI(validRows, 2);
fill(ax, [x; flipud(x)], [yLower; flipud(yUpper)], ...
    [0.5 0.5 0.5], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
end

function predTbl = local_prediction_table(tbl, modeChar, xGrid, taskName)
nRows = numel(xGrid);
predTbl = table();
idValue = string(categories(tbl.ID));
predTbl.ID = categorical(repmat(idValue(1), nRows, 1), categories(tbl.ID));
predTbl.Task = categorical(repmat(string(taskName), nRows, 1), categories(tbl.Task));

switch modeChar
    case 'A'
        predTbl.log2real_visual_angle = xGrid;
    case 'D'
        predTbl.log2distance = xGrid;
    otherwise
        predTbl.log2elevation = xGrid;
end
end

function lineStats = local_task_line_stats(lme, modeChar, taskName)
predictorName = local_predictor_name(modeChar);
coefNames = string(lme.Coefficients.Name);
beta = double(lme.Coefficients.Estimate);

interceptIdx = find(coefNames == "(Intercept)", 1, 'first');
predictorIdx = find(coefNames == predictorName, 1, 'first');

intercept = beta(interceptIdx);
slope = beta(predictorIdx);
slopeH = zeros(1, numel(beta));
slopeH(predictorIdx) = 1;

if string(taskName) ~= "Perceptual"
    taskRows = contains(coefNames, "Task") & contains(coefNames, string(taskName)) & ...
        ~contains(coefNames, predictorName);
    interactionRows = contains(coefNames, predictorName) & ...
        contains(coefNames, "Task") & contains(coefNames, string(taskName));
    taskIdx = find(taskRows, 1, 'first');
    interactionIdx = find(interactionRows, 1, 'first');
    if ~isempty(taskIdx)
        intercept = intercept + beta(taskIdx);
    end
    if ~isempty(interactionIdx)
        slope = slope + beta(interactionIdx);
        slopeH(interactionIdx) = 1;
    end
end

try
    slopeP = coefTest(lme, slopeH);
catch
    slopeP = NaN;
end

lineStats = struct('Intercept', intercept, 'Slope', slope, 'SlopePValue', slopeP);
end

function pval = local_task_interaction_pvalue(lme, modeChar, comparisonTbl)
predictorName = local_predictor_name(modeChar);
coefNames = string(lme.Coefficients.Name);
interactionRows = contains(coefNames, predictorName) & contains(coefNames, "Task");
if any(interactionRows)
    pval = min(lme.Coefficients.pValue(interactionRows));
elseif ~isempty(comparisonTbl)
    pval = local_comparison_pvalue(comparisonTbl);
else
    pval = NaN;
end
end

function pval = local_task_main_effect_pvalue(lme)
coefNames = string(lme.Coefficients.Name);
taskRows = contains(coefNames, "Task") & ~contains(coefNames, ":");
if any(taskRows)
    pval = min(lme.Coefficients.pValue(taskRows));
else
    pval = NaN;
end
end

function titleLine = local_task_main_effect_title_line(pval)
if isfinite(pval) && pval < 0.05
    titleLine = sprintf('Task p=%s', local_format_scientific_pvalue(pval));
elseif isfinite(pval)
    titleLine = sprintf('Task ns, p=%s', local_format_scientific_pvalue(pval));
else
    titleLine = 'Task ns, p=n/a';
end
end

function titleLine = local_task_interaction_title_line(modeChar, pval)
factorLabel = local_factor_label(modeChar);
if isfinite(pval) && pval < 0.05
    titleLine = sprintf('Task x %s p=%s', factorLabel, local_format_scientific_pvalue(pval));
elseif isfinite(pval)
    titleLine = sprintf('Task x %s ns, p=%s', factorLabel, local_format_scientific_pvalue(pval));
else
    titleLine = sprintf('Task x %s ns, p=n/a', factorLabel);
end
end

function pval = local_comparison_pvalue(comparisonTbl)
pval = NaN;
if isempty(comparisonTbl)
    return;
end

try
    pvals = double(comparisonTbl.pValue);
catch
    return;
end

pvals = pvals(isfinite(pvals));
if ~isempty(pvals)
    pval = pvals(end);
end
end

function taskCat = local_task_categorical(rawTask)
taskText = string(rawTask);
taskText(strcmpi(taskText, "perceptual")) = "Perceptual";
taskText(strcmpi(taskText, "adjusted")) = "Adjusted";
validTasks = ["Perceptual", "Adjusted"];
otherTasks = unique(taskText(~ismember(taskText, validTasks) & ...
    ~ismissing(taskText) & taskText ~= ""), 'stable');
taskCat = categorical(taskText, [validTasks otherTasks]);
end

function [xRaw, xLog, xlabelText, titleTemplate, xTickVals, xTickLabels, xLimits] = ...
    local_axis_info(tbl, modeChar, ElevationTransform)
switch modeChar
    case 'A'
        xRaw = double(tbl.Real_Visual_Angle);
        xLog = tbl.log2real_visual_angle;
        xlabelText = 'Real VA [deg, log]';
        titleTemplate = 'PM=%.2fVA^{%.2f}\np=%s, n=%d';
    case 'D'
        xRaw = double(tbl.Distance);
        xLog = tbl.log2distance;
        xlabelText = 'Distance [m, log]';
        titleTemplate = 'PM=%.2fD^{%.2f}\np=%s, n=%d';
    otherwise
        xRaw = double(tbl.ElevationModel);
        xLog = tbl.log2elevation;
        switch ElevationTransform
            case 1
                xlabelText = 'Elevation [deg, log]';
                titleTemplate = 'PM=%.2f(1+E)^{%.2f}\np=%s, n=%d';
            case 2
                xlabelText = '|Elevation| [deg, log]';
                titleTemplate = 'PM=%.2f(1+|E|)^{%.2f}\np=%s, n=%d';
            case 5
                xlabelText = 'Elevation [deg, log]';
                titleTemplate = 'PM=%.2f(1+E/90)^{%.2f}\np=%s, n=%d';
            otherwise
                xlabelText = '|Elevation| [deg, log]';
                titleTemplate = 'PM=%.2f(1+|E|/90)^{%.2f}\np=%s, n=%d';
        end
end

if modeChar == 'E'
    [xTickVals, xTickLabels, xLimits] = local_elevation_ticks_and_limits(xRaw, ElevationTransform);
else
    [xTickVals, xTickLabels] = local_oldstyle_ticks(xRaw, modeChar, ElevationTransform);
    xLimits = [log2(min(xRaw) * 0.95) log2(max(xRaw) * 1.05)];
end
end

function [xTickVals, xTickLabels] = local_oldstyle_ticks(xRaw, modeChar, ElevationTransform)
minVal = min(xRaw);
maxVal = max(xRaw);
[xTickVals, nativeVals] = local_adaptive_log_ticks(minVal, maxVal);

if modeChar == 'E' && any(ElevationTransform == [5 6])
    nativeVals = round(90 * (nativeVals - 1), 1);
elseif modeChar ~= 'E'
    nativeVals = round(nativeVals, 1);
end
xTickLabels = local_format_tick_labels(nativeVals);
end

function [xTickVals, xTickLabels, xLimits] = local_elevation_ticks_and_limits(xRaw, ElevationTransform)
xmin = min(xRaw);
xmax = max(xRaw);
xTickVals = log2([xmin xmax]);

if any(ElevationTransform == [5 6])
    nativeVals = round(90 * (2.^xTickVals - 1), 1);
else
    nativeVals = round(2.^xTickVals - 1, 1);
end
xTickLabels = local_format_tick_labels(nativeVals);

span = xmax - xmin;
margin = max(0.05 * span, 0.02);
plotMin = max(eps, xmin - margin);
plotMax = xmax + margin;
xLimits = log2([plotMin plotMax]);
end

function [cmap, sorted_idx] = local_validate_color_inputs(cmap, sorted_idx, nsubjects)
if isempty(cmap)
    cmap = lines(max(nsubjects, 1));
end
if isempty(sorted_idx)
    sorted_idx = (1:nsubjects)';
end
if size(cmap, 1) < nsubjects
    cmap = interp1(linspace(0, 1, size(cmap, 1)), cmap, ...
        linspace(0, 1, nsubjects), 'linear');
end
end

function subjectColorByID = local_subject_colors_by_id(uniqueID, cmap, sorted_idx, colorConfig)
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
    subjectColorByID(subjectIdx, :) = local_subject_color_row(subjectIdx, cmap, sorted_idx);
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

function thisColor = local_subject_color_row(subjectIdx, cmap, sorted_idx)
colorRow = find(sorted_idx == subjectIdx, 1, 'first');
if isempty(colorRow)
    colorRow = subjectIdx;
end
colorRow = min(max(colorRow, 1), size(cmap, 1));
thisColor = cmap(colorRow, :);
end

function [cmap, sorted_idx] = local_color_inputs_from_config(colorConfig, cmap, sorted_idx)
if isfield(colorConfig, 'RankCmap')
    cmap = colorConfig.RankCmap;
elseif isfield(colorConfig, 'Color')
    cmap = colorConfig.Color;
end

if isfield(colorConfig, 'SortedIdx')
    sorted_idx = colorConfig.SortedIdx;
elseif isempty(sorted_idx) && isfield(colorConfig, 'ID')
    sorted_idx = (1:numel(colorConfig.ID))';
end
end

function predictorName = local_predictor_name(modeChar)
switch modeChar
    case 'A'
        predictorName = "log2real_visual_angle";
    case 'D'
        predictorName = "log2distance";
    otherwise
        predictorName = "log2elevation";
end
end

function factorLabel = local_factor_label(modeChar)
switch modeChar
    case 'A'
        factorLabel = 'VA';
    case 'D'
        factorLabel = 'Distance';
    otherwise
        factorLabel = 'Elevation';
end
end

function pStr = local_format_pvalue(pval)
if ~isfinite(pval)
    pStr = 'n/a';
elseif pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end

function pStr = local_format_scientific_pvalue(pval)
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

function labels = local_format_tick_labels(vals)
labels = strings(size(vals));
for i = 1:numel(vals)
    if abs(vals(i)) > 1000
        labels(i) = sprintf('%.1e', vals(i));
    else
        labels(i) = string(vals(i));
    end
end
end

function [tickPos, nativeVals] = local_adaptive_log_ticks(minVal, maxVal)
if ~isfinite(minVal) || ~isfinite(maxVal) || minVal <= 0 || maxVal <= 0
    tickPos = [];
    nativeVals = [];
    return
end

if maxVal < minVal
    tmp = minVal;
    minVal = maxVal;
    maxVal = tmp;
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
        nTicks = 2;
    end

    nativeVals = 2.^linspace(logMin, logMax, nTicks);
    nativeVals(1) = minVal;
    nativeVals(end) = maxVal;
end

nativeVals = unique(nativeVals, 'stable');
tickPos = log2(nativeVals);
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

function taskSummaryLines = local_task_summary_lines(tbl)
taskNames = ["Perceptual", "Adjusted"];
taskSummaryLines = cell(1, numel(taskNames) + 1);
taskSummaryLines{1} = 'Task counts:';
for iTask = 1:numel(taskNames)
    rowMask = string(tbl.Task) == taskNames(iTask);
    taskSummaryLines{iTask + 1} = sprintf('  %s: %d rows, %d participants', ...
        taskNames(iTask), sum(rowMask), numel(unique(tbl.ID(rowMask))));
end
end

function local_export_png(figHandle, outFile, dpi)
if nargin < 3 || isempty(dpi)
    dpi = 600;
end
set(figHandle, 'PaperPositionMode', 'auto');
print(figHandle, outFile, '-dpng', sprintf('-r%d', dpi));
end
