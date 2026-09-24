function [lme_by_logRatio_ElevationbyTask, lme_by_logRatio_Elevation, ...
    modelcomp, all_data, figHandle] = SMS_FullMoon_PM_logElevationbyTask( ...
    dataDir, datafile, ResultsDir, saveLME, cmap, sorted_idx)
% SMS_FullMoon_PM_logElevationbyTask
% Compare Moon perceptual magnification by elevation across tasks.
%
% This function fits:
%   logRatio ~ logElevation*Task + (1|ID)
%
% and compares it to the task-free model:
%   logRatio ~ logElevation + (1|ID)
%
% Perceptual is used as the reference task. The figure plots Perceptual and
% Adjusted data side by side with the same ID color order used by sorted_idx.
%
% Inputs
%   dataDir    Directory containing datafile.
%   datafile   FullMoonDataLong-style CSV file.
%   ResultsDir Output directory for the figure and stats report.
%   saveLME    Logical. If true, write the LME report text file.
%   cmap       Optional N-by-3 colormap for subject IDs.
%   sorted_idx Optional subject sort order. If omitted, the function tries
%              to load <basename>_sortedidx from ResultsDir and otherwise
%              sorts by mean PM.
%
% Outputs
%   lme_by_logRatio_ElevationbyTask Fitted interaction LinearMixedModel.
%   lme_by_logRatio_Elevation       Fitted no-task LinearMixedModel.
%   modelcomp                       compare(no-task model, interaction model).
%   all_data                        Processed table used for fitting.
%   figHandle                       Side-by-side task figure handle.

if nargin < 1 || isempty(dataDir)
    dataDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
end
if nargin < 2 || isempty(datafile)
    datafile = 'FullMoonDataLong090225.csv';
end
if nargin < 3 || isempty(ResultsDir)
    ResultsDir = fullfile(dataDir, 'PaperFigures');
end
if nargin < 4 || isempty(saveLME)
    saveLME = true;
end
if nargin < 5
    cmap = [];
end
if nargin < 6
    sorted_idx = [];
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

dataPath = fullfile(dataDir, datafile);
basename = erase(datafile, '.csv');

all_data = readtable(dataPath);
all_data.Properties.UserData.SourceFile = dataPath;
all_data = local_prepare_table(all_data);

uniqueID = unique(all_data.ID);
[cmap, sorted_idx] = local_color_inputs(all_data, uniqueID, cmap, sorted_idx, ResultsDir, basename);
subjectcolor = local_subject_colors(all_data.ID, uniqueID, cmap, sorted_idx);

lme_by_logRatio_ElevationbyTask = fitlme(all_data, ...
    'logRatio ~ logElevation*Task + (1|ID)');
lme_by_logRatio_Elevation = fitlme(all_data, ...
    'logRatio ~ logElevation + (1|ID)');
modelcomp = compare(lme_by_logRatio_Elevation, lme_by_logRatio_ElevationbyTask);

if saveLME
    local_write_lme_report(ResultsDir, basename, dataPath, all_data, ...
        lme_by_logRatio_ElevationbyTask, lme_by_logRatio_Elevation, modelcomp);
end

figHandle = local_plot_by_task(all_data, subjectcolor, ...
    lme_by_logRatio_ElevationbyTask, basename, ResultsDir);
end

function all_data = local_prepare_table(all_data)
requiredVars = {'ID', 'Task', 'Reported_Visual_Angle', ...
    'Ratio_Visual_Angle', 'Elevation'};
missingVars = setdiff(requiredVars, all_data.Properties.VariableNames);
if ~isempty(missingVars)
    error('SMSFullMoonPMLogElevationByTask:MissingVariables', ...
        'Input table is missing required variable(s): %s', strjoin(missingVars, ', '));
end

validRows = ~isnan(double(all_data.Reported_Visual_Angle)) & ...
    isfinite(double(all_data.Ratio_Visual_Angle)) & ...
    double(all_data.Ratio_Visual_Angle) > 0 & ...
    isfinite(double(all_data.Elevation)) & ...
    double(all_data.Elevation) >= 0;
all_data = all_data(validRows, :);

taskText = strtrim(string(all_data.Task));
taskText(strcmpi(taskText, "perceptual")) = "Perceptual";
taskText(strcmpi(taskText, "adjusted")) = "Adjusted";
all_data.Task = categorical(taskText, ["Perceptual", "Adjusted"]);

if ~iscategorical(all_data.ID)
    all_data.ID = categorical(all_data.ID);
end

keepTasks = ismember(string(all_data.Task), ["Perceptual", "Adjusted"]) & ...
    ~isundefined(all_data.Task) & ~isundefined(all_data.ID);
all_data = all_data(keepTasks, :);
all_data.ID = removecats(all_data.ID);
all_data.Task = removecats(all_data.Task);

if numel(categories(all_data.Task)) < 2
    error('SMSFullMoonPMLogElevationByTask:TooFewTasks', ...
        'The input table must contain both Perceptual and Adjusted tasks.');
end
all_data.Task = reordercats(all_data.Task, {'Perceptual', 'Adjusted'});

all_data.logRatio = log2(double(all_data.Ratio_Visual_Angle));
all_data.logElevation = log2(double(all_data.Elevation) + 1);
end

function [cmap, sorted_idx] = local_color_inputs(all_data, uniqueID, cmap, sorted_idx, ResultsDir, basename)
nsubjects = numel(uniqueID);
if isempty(cmap)
    cmap = jet(nsubjects);
end
if size(cmap, 1) < nsubjects
    cmap = interp1(linspace(0, 1, size(cmap, 1)), cmap, ...
        linspace(0, 1, nsubjects), 'linear');
end

if isempty(sorted_idx)
    sortFile = fullfile(ResultsDir, [basename '_sortedidx.mat']);
    if exist(sortFile, 'file')
        loadedSort = load(sortFile);
        if isfield(loadedSort, 'sorted_idx_log')
            sorted_idx = loadedSort.sorted_idx_log;
        elseif isfield(loadedSort, 'sorted_idx')
            sorted_idx = loadedSort.sorted_idx;
        end
    end
end

if isempty(sorted_idx)
    meanPM = nan(nsubjects, 1);
    for iID = 1:nsubjects
        idRows = all_data.ID == uniqueID(iID);
        meanPM(iID) = mean(all_data.Ratio_Visual_Angle(idRows), 'omitnan');
    end
    [~, sorted_idx] = sort(meanPM);
end
sorted_idx = sorted_idx(:);
end

function subjectcolor = local_subject_colors(idData, uniqueID, cmap, sorted_idx)
subjectcolor = zeros(numel(idData), 3);
for iRow = 1:numel(idData)
    subjectIdx = find(uniqueID == idData(iRow), 1, 'first');
    colorIdx = find(sorted_idx == subjectIdx, 1, 'first');
    if isempty(colorIdx)
        colorIdx = subjectIdx;
    end
    colorIdx = min(max(colorIdx, 1), size(cmap, 1));
    subjectcolor(iRow, :) = cmap(colorIdx, :);
end
end

function local_write_lme_report(ResultsDir, basename, dataPath, all_data, ...
    lmeTask, lmeNoTask, modelcomp)
reportFile = fullfile(ResultsDir, ...
    [basename '_PM_logElevation_byTask.txt']);

taskSummary = local_task_summary_lines(all_data);
reportOpts = struct();
reportOpts.ReportTitle = sprintf('Moon PM Log-Elevation By-Task LME Report: %s', basename);
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = dataPath;
reportOpts.ModelLabel = 'Log perceptual magnification predicted by log moon elevation, task, and their interaction';
reportOpts.SummaryLines = [ ...
    {sprintf('Experiment: Moon'), ...
    sprintf('Rows in model table: %d', height(all_data)), ...
    sprintf('Participants in model table: %d', numel(unique(all_data.ID))), ...
    sprintf('Reference task: Perceptual'), ...
    sprintf('Compared task: Adjusted'), ...
    sprintf('Elevation transform: log2(Elevation + 1)')}, ...
    taskSummary];
reportOpts.Models = {lmeTask, lmeNoTask};
reportOpts.ModelLabels = { ...
    'Model: logRatio ~ logElevation*Task + (1|ID)', ...
    'Model: logRatio ~ logElevation + (1|ID)'};
reportOpts.Comparisons = {modelcomp};
reportOpts.ComparisonLabels = {'Model comparison: logElevation base vs Task interaction'};
reportOpts.RemoveGroupError = false;
write_lme_stats_report(lmeTask, reportFile, reportOpts);
end

function taskSummary = local_task_summary_lines(all_data)
taskNames = ["Perceptual", "Adjusted"];
taskSummary = cell(1, numel(taskNames) + 1);
taskSummary{1} = 'Task counts:';
for iTask = 1:numel(taskNames)
    taskRows = string(all_data.Task) == taskNames(iTask);
    taskSummary{iTask + 1} = sprintf('  %s: %d rows, %d participants', ...
        taskNames(iTask), sum(taskRows), numel(unique(all_data.ID(taskRows))));
end
end

function figHandle = local_plot_by_task(all_data, subjectcolor, lme, basename, ResultsDir)
taskNames = ["Perceptual", "Adjusted"];
minPM = min(double(all_data.Ratio_Visual_Angle), [], 'omitnan');
maxPM = max(double(all_data.Ratio_Visual_Angle), [], 'omitnan');
yLimits = [floor(log2(min(0.25, minPM))) ceil(log2(max(16, maxPM)))];
yTicks = yLimits(1):1:yLimits(2);
yTickLabels = string(2 .^ yTicks);
xLimits = local_log_elevation_limits(all_data.logElevation);
[xTicks, xTickLabels] = local_log_elevation_ticks(all_data.Elevation);

figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .6 .6], 'Name', [basename '_PM_logElevation_byTask'], ...
    'Visible', 'off');
tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

for iTask = 1:numel(taskNames)
    taskName = taskNames(iTask);
    ax = nexttile;
    taskRows = string(all_data.Task) == taskName;
    local_plot_task_panel(ax, all_data, taskRows, subjectcolor, lme, ...
        taskName, xLimits, xTicks, xTickLabels, yLimits, yTicks, yTickLabels, iTask == 1);
end

outFile = fullfile(ResultsDir, [basename '_PM_logElevation_byTask.png']);
exportgraphics(figHandle, outFile, 'Resolution', 600);
end

function local_plot_task_panel(ax, all_data, taskRows, subjectcolor, lme, taskName, ...
    xLimits, xTicks, xTickLabels, yLimits, yTicks, yTickLabels, showYLabel)
hold(ax, 'on');
plot(ax, xLimits, [0 0], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.5);

xgrid = linspace(xLimits(1), xLimits(2), 200)';
predTbl = local_prediction_table(all_data, xgrid, taskName);
[yhat, yCI] = predict(lme, predTbl, 'Conditional', false);
local_plot_ci(ax, xgrid, yCI);
plot(ax, xgrid, yhat, 'k-', 'LineWidth', 3);

scatter(ax, all_data.logElevation(taskRows), all_data.logRatio(taskRows), ...
    40, subjectcolor(taskRows, :), 'o', 'filled', 'MarkerEdgeColor', 'none');

set(ax, 'XLim', xLimits, 'YLim', yLimits, ...
    'XTick', xTicks, 'XTickLabel', xTickLabels, ...
    'YTick', yTicks, 'YTickLabel', yTickLabels, ...
    'FontName', 'Avenir', 'FontSize', 18);
box(ax, 'off');
grid(ax, 'off');
xlabel(ax, {'Moon Elevation [deg]', 'log scale'}, 'FontSize', 20);
if showYLabel
    ylabel(ax, {'Perceptual Magnification', 'log scale'}, 'FontSize', 20);
else
    ylabel(ax, '');
end

taskStats = local_task_fixed_effect_stats(lme, taskName);
title(ax, sprintf('%s\nPM=%.2f(1+E)^{%.2f}\np=%s, n=%d', ...
    char(taskName), 2 .^ taskStats.Intercept, taskStats.Slope, ...
    local_format_pvalue(taskStats.SlopePValue), numel(unique(all_data.ID(taskRows)))), ...
    'FontSize', 16, 'FontWeight', 'normal');
end

function predTbl = local_prediction_table(all_data, xgrid, taskName)
predTbl = table();
predTbl.logElevation = xgrid;
predTbl.Task = categorical(repmat(string(taskName), numel(xgrid), 1), categories(all_data.Task));
predTbl.ID = categorical(repmat(string(all_data.ID(1)), numel(xgrid), 1), categories(all_data.ID));
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

function taskStats = local_task_fixed_effect_stats(lme, taskName)
coefNames = string(lme.Coefficients.Name);
beta = double(lme.Coefficients.Estimate);

interceptIdx = find(coefNames == "(Intercept)", 1, 'first');
slopeIdx = find(coefNames == "logElevation", 1, 'first');
intercept = beta(interceptIdx);
slope = beta(slopeIdx);
slopeH = zeros(1, numel(beta));
slopeH(slopeIdx) = 1;

if string(taskName) ~= "Perceptual"
    taskIdx = find(contains(coefNames, "Task") & contains(coefNames, string(taskName)) & ...
        ~contains(coefNames, "logElevation"), 1, 'first');
    interactionIdx = find(contains(coefNames, "Task") & contains(coefNames, string(taskName)) & ...
        contains(coefNames, "logElevation"), 1, 'first');
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
taskStats = struct('Intercept', intercept, 'Slope', slope, 'SlopePValue', slopeP);
end

function xLimits = local_log_elevation_limits(logElevation)
finiteVals = logElevation(isfinite(logElevation));
if isempty(finiteVals)
    xLimits = [0 1];
    return;
end
span = max(finiteVals) - min(finiteVals);
margin = max(0.05 * span, 0.05);
xLimits = [min(finiteVals) - margin, max(finiteVals) + margin];
end

function [xTicks, xTickLabels] = local_log_elevation_ticks(elevation)
finiteElevation = elevation(isfinite(elevation) & elevation >= 0);
if isempty(finiteElevation)
    xTicks = [];
    xTickLabels = strings(0);
    return;
end

minE = min(finiteElevation);
maxE = max(finiteElevation);
if minE == maxE
    nativeTicks = minE;
else
    nativeTicks = linspace(minE, maxE, 4);
    nativeTicks(1) = minE;
    nativeTicks(end) = maxE;
end
nativeTicks = unique(round(nativeTicks, 1), 'stable');
xTicks = log2(nativeTicks + 1);
xTickLabels = string(nativeTicks);
end

function pStr = local_format_pvalue(pval)
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
