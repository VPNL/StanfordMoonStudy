function [lme, interactionStats, modelComparison] = fit_PM_full_VA_D_E_modelbytask( ...
    tbl, tblName, ResultsDir, saveModels, mycolormap, sorted_idx, ElevationTransform, colorConfig)
% fit_PM_full_VA_D_E_modelbytask
% Fit the full VA/D/E perceptual magnification model with task interactions.
%
% This is the by-task companion to fit_PM_full_VA_D_E_model. It uses the
% full model:
%
%   log2(PM) ~ log2(VA)*Task + log2(D)*Task + log2(ElevationTerm)*Task + (1|ID)
%
% Perceptual is the reference task. The Task_Adjusted coefficient is the
% Adjusted-vs-Perceptual intercept difference, and each predictor:Task term
% is the Adjusted-vs-Perceptual slope difference for that predictor.
%
% Inputs
%   tbl                MATLAB table containing both Perceptual and Adjusted
%                      tasks. Required variables are ID, Task (or task),
%                      Ratio_Visual_Angle, Real_Visual_Angle, Distance, and
%                      Elevation. Existing log2 variables are reused when
%                      present.
%   tblName            String/char used for figure and model filenames.
%   ResultsDir         Output directory. Set [] or '' to skip saving.
%   saveModels         Logical. If true, save the fitted models and
%                      interaction table to <tblName>.mat.
%   mycolormap         N-by-3 subject color map. Optional.
%   sorted_idx         Subject color ordering. Optional.
%   ElevationTransform Elevation transform ID:
%                      1: log2(1+E)
%                      2: log2(1+abs(E))
%                      5: log2(1+E/90)
%                      6: log2(1+abs(E)/90)
%   colorConfig        Optional output from Quad_build_participant_color_config.
%
% Outputs
%   lme              Fitted LinearMixedModel with VA/D/E by Task interactions.
%   interactionStats Table with coefficient statistics for Task x VA,
%                    Task x Distance, and Task x Elevation.
%   modelComparison compare(baseLME, lme), where baseLME has Task but no
%                   Task-by-parameter interactions.
%
% Example
%   [lme, interactionStats] = fit_PM_full_VA_D_E_modelbytask( ...
%       quadTbl, 'Perceptual_Adjusted_full_VA_D_E_by_task', ...
%       ResultsDir, true, cmap, sorted_idx, 2);

if nargin < 2 || isempty(tblName); tblName = 'PM_Full_VA_D_E_ByTask'; end
if nargin < 3 || isempty(ResultsDir); ResultsDir = ''; end
if nargin < 4 || isempty(saveModels); saveModels = false; end
if nargin < 5; mycolormap = []; end
if nargin < 6; sorted_idx = []; end
if nargin < 7 || isempty(ElevationTransform); ElevationTransform = 1; end
if nargin < 8; colorConfig = []; end

if ~istable(tbl)
    error('fitPMFullVADEByTask:InvalidInput', 'Input tbl must be a MATLAB table.');
end

ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'standard');
if isstruct(mycolormap)
    colorConfig = mycolormap;
    [mycolormap, sorted_idx] = local_color_inputs_from_config(colorConfig, mycolormap, sorted_idx);
end

sourceCsv = local_source_file_label(tbl, tblName);
tbl = local_ensure_log_variables(tbl, ElevationTransform);
meanPMTaskTest = compute_paired_mean_pm_task_test(tbl);
fprintf('%s\n', meanPMTaskTest.ReportLine);
[tbl, subjectcolor, nsubjects] = local_prepare_model_table(tbl, mycolormap, sorted_idx, colorConfig);

baseFormula = ['log2ratio_visual_angle ~ 1 + log2real_angle + log2distance + ' ...
    'log2elevation + Task + (1|ID)'];
interactionFormula = ['log2ratio_visual_angle ~ 1 + log2real_angle*Task + ' ...
    'log2distance*Task + log2elevation*Task + (1|ID)'];

baseLME = fitlme(tbl, baseFormula, 'FitMethod', 'ML');
lme = fitlme(tbl, interactionFormula, 'FitMethod', 'ML');
modelComparison = compare(baseLME, lme);
interactionStats = local_interaction_stats(lme);

if saveModels && ~isempty(ResultsDir)
    local_write_report(tbl, tblName, ResultsDir, ElevationTransform, ...
        nsubjects, lme, modelComparison, interactionStats, ...
        baseFormula, interactionFormula, sourceCsv, meanPMTaskTest);
end

local_plot_full_model_by_task(tbl, tblName, ResultsDir, subjectcolor, ...
    ElevationTransform, lme, interactionStats);

if saveModels && ~isempty(ResultsDir)
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    save(fullfile(ResultsDir, [char(string(tblName)) '.mat']), ...
        'lme', 'baseLME', 'modelComparison', 'interactionStats', ...
        'interactionFormula', 'baseFormula', 'ElevationTransform', ...
        'nsubjects', 'meanPMTaskTest');
end
end

function local_write_report(tbl, tblName, ResultsDir, ElevationTransform, ...
    nsubjects, lme, modelComparison, interactionStats, baseFormula, ...
    interactionFormula, sourceCsv, meanPMTaskTest)
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

reportFile = fullfile(ResultsDir, [char(string(tblName)) '.txt']);

reportOpts = struct();
reportOpts.ReportTitle = sprintf('Quad PM Full VA/D/E By-Task LME Report: %s', char(string(tblName)));
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = sourceCsv;
reportOpts.ModelLabel = 'Log perceptual magnification predicted by VA, distance, elevation, task, and task interactions';
reportOpts.SummaryLines = [ ...
    {sprintf('Experiment: Quad'), ...
    sprintf('Rows in model table: %d', height(tbl)), ...
    sprintf('Participants in model table: %d', nsubjects), ...
    sprintf('Reference task: Perceptual'), ...
    sprintf('Compared task: Adjusted'), ...
    sprintf('Paired observers in mean PM task test: %d', ...
    meanPMTaskTest.NPairs), ...
    meanPMTaskTest.ReportLine, ...
    sprintf('Elevation transform: %s', char(string(ElevationTransform))), ...
    sprintf('Fit method: ML'), ...
    sprintf('Base formula: %s', baseFormula), ...
    sprintf('Interaction formula: %s', interactionFormula), ...
    sprintf('Perceptual formula: %s', local_task_formula(lme, ElevationTransform, "Perceptual")), ...
    sprintf('Adjusted formula: %s', local_task_formula(lme, ElevationTransform, "Adjusted"))}, ...
    local_interaction_summary_lines(interactionStats)];
reportOpts.Models = {lme};
reportOpts.ModelLabels = {['Model: ' interactionFormula]};
reportOpts.Comparisons = {modelComparison};
reportOpts.ComparisonLabels = {'Model comparison: full VA/D/E + Task base vs Task interactions'};
reportOpts.RemoveGroupError = false;
write_lme_stats_report(lme, reportFile, reportOpts);
end

function lines = local_interaction_summary_lines(interactionStats)
lines = cell(1, height(interactionStats) + 1);
lines{1} = 'Task interaction coefficient p-values:';
for iRow = 1:height(interactionStats)
    lines{iRow + 1} = sprintf('  Task x %s: Estimate %.4f, SE %.4f, t(%0.0f) = %.4f, p = %s', ...
        char(string(interactionStats.Parameter(iRow))), ...
        interactionStats.Estimate(iRow), interactionStats.SE(iRow), ...
        interactionStats.DF(iRow), interactionStats.tStat(iRow), ...
        char(string(interactionStats.pText(iRow))));
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
if ~ismember('Task', tbl.Properties.VariableNames)
    if ismember('task', tbl.Properties.VariableNames)
        tbl.Task = tbl.task;
    else
        error('fitPMFullVADEByTask:MissingTask', ...
            'Input table must contain Task or task.');
    end
end

if ~ismember('Measurement', tbl.Properties.VariableNames)
    tbl.Measurement = repmat("Measurement", height(tbl), 1);
end

if ~ismember('log2ratio_visual_angle', tbl.Properties.VariableNames)
    if ismember('Ratio_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2ratio_visual_angle = log2(double(tbl.Ratio_Visual_Angle));
    elseif all(ismember({'Reported_Visual_Angle', 'Real_Visual_Angle'}, tbl.Properties.VariableNames))
        tbl.log2ratio_visual_angle = log2(double(tbl.Reported_Visual_Angle) ./ ...
            double(tbl.Real_Visual_Angle));
    else
        error('fitPMFullVADEByTask:MissingPM', ...
            'Need Ratio_Visual_Angle or Reported_Visual_Angle and Real_Visual_Angle.');
    end
end

if ~ismember('Ratio_Visual_Angle', tbl.Properties.VariableNames)
    tbl.Ratio_Visual_Angle = 2 .^ double(tbl.log2ratio_visual_angle);
end

if ~ismember('log2real_angle', tbl.Properties.VariableNames)
    if ismember('log2real_visual_angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = double(tbl.log2real_visual_angle);
    elseif ismember('Real_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = log2(double(tbl.Real_Visual_Angle));
    else
        error('fitPMFullVADEByTask:MissingVA', ...
            'Need Real_Visual_Angle to compute log2real_angle.');
    end
end

if ~ismember('log2distance', tbl.Properties.VariableNames)
    if ismember('Distance', tbl.Properties.VariableNames)
        tbl.log2distance = log2(double(tbl.Distance));
    else
        error('fitPMFullVADEByTask:MissingDistance', ...
            'Need Distance to compute log2distance.');
    end
end

if ~ismember('log2elevation', tbl.Properties.VariableNames)
    if ~ismember('Elevation', tbl.Properties.VariableNames)
        error('fitPMFullVADEByTask:MissingElevation', ...
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
            error('fitPMFullVADEByTask:InvalidTransform', ...
                'Unsupported elevation transform %s.', string(ElevationTransform));
    end
elseif ~ismember('ElevationModel', tbl.Properties.VariableNames)
    tbl.ElevationModel = local_elevation_model_from_log(tbl.log2elevation);
end
end

function elevationModel = local_elevation_model_from_log(logElevation)
elevationModel = 2 .^ double(logElevation);
end

function [tbl, subjectcolor, nsubjects] = local_prepare_model_table(tbl, mycolormap, sorted_idx, colorConfig)
required = {'ID', 'Task', 'log2ratio_visual_angle', 'log2real_angle', ...
    'log2distance', 'log2elevation'};
missingVars = setdiff(required, tbl.Properties.VariableNames);
if ~isempty(missingVars)
    error('fitPMFullVADEByTask:MissingVariables', ...
        'Input table is missing required variable(s): %s', strjoin(missingVars, ', '));
end

if ~iscategorical(tbl.ID)
    tbl.ID = categorical(tbl.ID);
end
tbl.Task = local_task_categorical(tbl.Task);

goodRows = isfinite(double(tbl.log2ratio_visual_angle)) & ...
    isfinite(double(tbl.log2real_angle)) & ...
    isfinite(double(tbl.log2distance)) & ...
    isfinite(double(tbl.log2elevation)) & ...
    ~isundefined(tbl.ID) & ...
    ~isundefined(tbl.Task) & ...
    ismember(string(tbl.Task), ["Perceptual", "Adjusted"]);
tbl = tbl(goodRows, :);
tbl.ID = removecats(tbl.ID);
tbl.Task = removecats(tbl.Task);

if height(tbl) < 10
    error('fitPMFullVADEByTask:TooFewRows', ...
        'Not enough valid rows after filtering (n=%d).', height(tbl));
end
if numel(categories(tbl.Task)) < 2
    error('fitPMFullVADEByTask:TooFewTasks', ...
        'The input table must contain both Perceptual and Adjusted tasks.');
end
tbl.Task = reordercats(tbl.Task, cellstr(["Perceptual", "Adjusted"]));

uniqueID = string(categories(tbl.ID));
nsubjects = numel(uniqueID);
[mycolormap, sorted_idx] = local_validate_color_inputs(mycolormap, sorted_idx, nsubjects);
subjectColorByID = local_subject_colors_by_id(uniqueID, mycolormap, sorted_idx, colorConfig);
subjectcolor = local_subject_colors(tbl.ID, uniqueID, subjectColorByID);
end

function taskCat = local_task_categorical(rawTask)
taskText = string(rawTask);
taskText(strcmpi(taskText, "perceptual")) = "Perceptual";
taskText(strcmpi(taskText, "adjusted")) = "Adjusted";
taskCat = categorical(taskText, ["Perceptual", "Adjusted"]);
end

function local_plot_full_model_by_task(tbl, tblName, ResultsDir, subjectcolor, ...
    ElevationTransform, lme, interactionStats)
minRatio = min(2 .^ double(tbl.log2ratio_visual_angle), [], 'omitnan');
maxRatio = max(2 .^ double(tbl.log2ratio_visual_angle), [], 'omitnan');
minPMLim = min(0.25, minRatio);
maxPMLim = max(16, maxRatio);
yLimits = [floor(log2(minPMLim)) ceil(log2(maxPMLim))];
yTicks = yLimits(1):1:yLimits(2);
yTickLabels = string(2 .^ yTicks);

taskNames = ["Perceptual", "Adjusted"];
predictorNames = ["log2real_angle", "log2distance", "log2elevation"];
factorLabels = ["VA", "Distance", "Elevation"];
muX = [mean(double(tbl.log2real_angle), 'omitnan'), ...
    mean(double(tbl.log2distance), 'omitnan'), ...
    mean(double(tbl.log2elevation), 'omitnan')];
muX(~isfinite(muX)) = 0;

figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 1 1], 'Name', [char(string(tblName)) '_bytask'], ...
    'Visible', 'off');
axesList = local_create_six_panel_axes(figHandle);

for taskIdx = 1:numel(taskNames)
    taskName = taskNames(taskIdx);
    taskRows = string(tbl.Task) == taskName;
    for predictorIdx = 1:numel(predictorNames)
        ax = axesList(taskIdx, predictorIdx);
        predictorName = predictorNames(predictorIdx);
        [xLog, xlabelText, xTicks, xTickLabels, xLimits] = ...
            local_axis_info(tbl, predictorName, ElevationTransform);
        pval = local_interaction_pvalue(interactionStats, factorLabels(predictorIdx));

        local_plot_one_task_predictor(ax, tbl, taskRows, subjectcolor, ...
            lme, predictorName, taskName, muX, xLog, xLimits, yLimits, ...
            xTicks, xTickLabels, yTicks, yTickLabels, xlabelText, ...
            factorLabels(predictorIdx), pval, predictorIdx == 1);
    end
end

sgtitle(local_task_formula(lme, ElevationTransform, "Perceptual", true), ...
    'FontSize', 18, 'FontName', 'Avenir', 'FontWeight', 'bold');
local_add_adjusted_formula(figHandle, axesList, ...
    local_task_formula(lme, ElevationTransform, "Adjusted", true));

if ~isempty(ResultsDir)
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    exportgraphics(figHandle, fullfile(ResultsDir, [char(string(tblName)) '.png']), ...
        'Resolution', 600);
end
end

function axesList = local_create_six_panel_axes(figHandle)
left = 0.07;
bottom = 0.10;
panelWidth = 0.27;
panelHeight = 0.28;
colGap = 0.06;
rowGap = 0.20;

axesList = gobjects(2, 3);
for rowIdx = 1:2
    yPos = bottom + (2 - rowIdx) * (panelHeight + rowGap);
    for colIdx = 1:3
        xPos = left + (colIdx - 1) * (panelWidth + colGap);
        axesList(rowIdx, colIdx) = axes(figHandle, ...
            'Position', [xPos, yPos, panelWidth, panelHeight]);
    end
end
end

function local_add_adjusted_formula(figHandle, axesList, formulaText)
drawnow;
allPositions = vertcat(axesList(:).Position);
topPositions = vertcat(axesList(1, :).Position);
bottomPositions = vertcat(axesList(2, :).Position);
xLeft = min(allPositions(:, 1));
xRight = max(allPositions(:, 1) + allPositions(:, 3));
gapBottom = max(bottomPositions(:, 2) + bottomPositions(:, 4));
gapTop = min(topPositions(:, 2));
textHeight = 0.04;
yPos = gapBottom + max((gapTop - gapBottom - textHeight) / 2, 0.01);
annotation(figHandle, 'textbox', [xLeft, yPos, xRight - xLeft, textHeight], ...
    'String', formulaText, 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'EdgeColor', 'none', ...
    'FontName', 'Avenir', 'FontSize', 18, 'FontWeight', 'bold', ...
    'Interpreter', 'tex');
end

function local_plot_one_task_predictor(ax, tbl, taskRows, subjectcolor, lme, ...
    predictorName, taskName, muX, xLog, xLimits, yLimits, xTicks, xTickLabels, ...
    yTicks, yTickLabels, xlabelText, factorLabel, interactionP, showYLabel)
hold(ax, 'on');
plot(ax, xLimits, [0 0], 'k:', 'LineWidth', 1);

xgrid = linspace(xLimits(1), xLimits(2), 200)';
predTbl = local_prediction_table(tbl, predictorName, xgrid, taskName, muX);
[yhat, yCI] = predict(lme, predTbl, 'Conditional', false);
local_plot_ci(ax, xgrid, yCI);
plot(ax, xgrid, yhat, 'k-', 'LineWidth', 3);

if any(taskRows)
    scatter_pm_by_measurement(ax, xLog(taskRows), ...
        tbl.log2ratio_visual_angle(taskRows), subjectcolor(taskRows, :), ...
        tbl.Measurement(taskRows), 50);
end

set(ax, 'XLim', xLimits, 'YLim', yLimits, ...
    'XTick', xTicks, 'XTickLabel', xTickLabels, ...
    'YTick', yTicks, 'YTickLabel', yTickLabels, ...
    'FontName', 'Avenir', 'FontSize', 14);
box(ax, 'off');
grid(ax, 'off');
xlabel(ax, xlabelText, 'FontSize', 15);
if showYLabel
    ylabel(ax, {'Perceptual Magnification', 'log scale'}, 'FontSize', 15);
else
    ylabel(ax, '');
end

titlePrefix = sprintf('%s: %s', char(string(taskName)), char(string(factorLabel)));
title(ax, sprintf('%s\n%s', titlePrefix, ...
    local_interaction_title_line(factorLabel, interactionP)), ...
    'FontSize', 13, 'FontWeight', 'normal');
end

function predTbl = local_prediction_table(tbl, predictorName, xgrid, taskName, muX)
nRows = numel(xgrid);
predTbl = table();
predTbl.log2real_angle = repmat(muX(1), nRows, 1);
predTbl.log2distance = repmat(muX(2), nRows, 1);
predTbl.log2elevation = repmat(muX(3), nRows, 1);
predTbl.(char(predictorName)) = xgrid;
predTbl.Task = categorical(repmat(string(taskName), nRows, 1), categories(tbl.Task));
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
termNames = strings(numel(factorLabels), 1);
estimate = nan(numel(factorLabels), 1);
se = nan(numel(factorLabels), 1);
df = nan(numel(factorLabels), 1);
tStat = nan(numel(factorLabels), 1);
pValue = nan(numel(factorLabels), 1);

coefTbl = lme.Coefficients;
coefNames = string(coefTbl.Name);
for iFactor = 1:numel(factorLabels)
    termIdx = find(contains(coefNames, predictorNames(iFactor)) & ...
        contains(coefNames, "Task"), 1, 'first');
    if isempty(termIdx)
        continue;
    end

    termNames(iFactor) = coefNames(termIdx);
    estimate(iFactor) = double(coefTbl.Estimate(termIdx));
    se(iFactor) = double(coefTbl.SE(termIdx));
    df(iFactor) = double(coefTbl.DF(termIdx));
    tStat(iFactor) = double(coefTbl.tStat(termIdx));
    pValue(iFactor) = double(coefTbl.pValue(termIdx));
end

pText = strings(numel(factorLabels), 1);
for iFactor = 1:numel(factorLabels)
    pText(iFactor) = string(local_format_title_pvalue(pValue(iFactor)));
end

interactionStats = table(factorLabels, predictorNames, termNames, estimate, se, ...
    df, tStat, pValue, pText, 'VariableNames', ...
    {'Parameter', 'Predictor', 'Term', 'Estimate', 'SE', 'DF', 'tStat', 'pValue', 'pText'});
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
    titleLine = sprintf('Task x %s p=%s', char(string(factorLabel)), ...
        local_format_title_pvalue(pval));
elseif isfinite(pval)
    titleLine = sprintf('Task x %s ns, p=%s', char(string(factorLabel)), ...
        local_format_title_pvalue(pval));
else
    titleLine = sprintf('Task x %s p=n/a', char(string(factorLabel)));
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

function formulaText = local_task_formula(lme, ElevationTransform, taskName, includeTaskLabel)
if nargin < 4 || isempty(includeTaskLabel)
    includeTaskLabel = false;
end

coefNames = string(lme.Coefficients.Name);
beta = double(lme.Coefficients.Estimate);

intercept = local_coef_value(coefNames, beta, "(Intercept)");
va = local_coef_value(coefNames, beta, "log2real_angle");
distance = local_coef_value(coefNames, beta, "log2distance");
elevation = local_coef_value(coefNames, beta, "log2elevation");

if string(taskName) ~= "Perceptual"
    intercept = intercept + local_task_coef_value(coefNames, beta, "Task", taskName, "");
    va = va + local_task_coef_value(coefNames, beta, "Task", taskName, "log2real_angle");
    distance = distance + local_task_coef_value(coefNames, beta, "Task", taskName, "log2distance");
    elevation = elevation + local_task_coef_value(coefNames, beta, "Task", taskName, "log2elevation");
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
if includeTaskLabel
    if string(taskName) == "Perceptual"
        formulaText = sprintf('Perceptual: %s', formulaText);
    else
        formulaText = sprintf('%s: %s', char(string(taskName)), formulaText);
    end
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

function value = local_task_coef_value(coefNames, beta, taskPrefix, taskName, predictorName)
taskPart = sprintf('%s_%s', char(string(taskPrefix)), char(string(taskName)));
if strlength(string(predictorName)) == 0
    coefIdx = find(coefNames == string(taskPart), 1, 'first');
else
    predictorName = char(string(predictorName));
    coefIdx = find((contains(coefNames, string(taskPart)) & ...
        contains(coefNames, string(predictorName))), 1, 'first');
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
