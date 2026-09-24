function [feEfxR, feNamesR, festatsR, reEfxR, reNamesR, reStatsR, models, figHandle, taskData, logFigHandle] = ...
    FullMoon_PMvInterOcularOffset(dataDir, datafile, task, ResultsDir, saveLME, ~, sorteduniqueIDD)
% FullMoon_PMvInterOcularOffset
%
% Combine the full-moon interocular-offset analysis with the PM-vs-offset
% analysis in one reusable function.
%
% Inputs are intentionally kept compatible with FullMoon_ratioVdisparity:
%   dataDir         : directory containing the moon data table
%   datafile        : CSV filename or full path
%   task            : task to analyze, e.g. 'Perceptual' or 'Adjusted'
%   ResultsDir      : output directory for figure and text report
%   saveLME         : if true, write the LME text report
%   subplotNum      : retained for backward compatibility; not used because
%                    this function creates both panels
%   sorteduniqueIDD : optional ID order for coloring participants
%
% Outputs
%   feEfxR, feNamesR, festatsR : fixed effects from the PM-vs-offset
%                                random-slope model
%   reEfxR, reNamesR, reStatsR : random effects from the PM-vs-offset
%                                random-slope model
%   models                    : struct containing fitted models/comparisons
%   figHandle                 : handle to the generated raw-scale figure
%   taskData                  : task-filtered data table used for fitting
%   logFigHandle              : handle to the generated log-scale figure
%
% The first figure has two panels:
%   1. Perceived Interocular Offset vs Elevation
%   2. Perceptual Magnification vs Perceived Interocular Offset
%
% The second figure has two panels:
%   1. log2(Perceived Interocular Offset) vs log2(1 + abs(Elevation))
%   2. log2(Perceptual Magnification) vs log2(Perceived Interocular Offset)
%
% Perceived Interocular Offset is computed as:
%   Disparity_VA - Real_Visual_Angle
%
% KGS/Codex 08/2026

if nargin < 1 || isempty(dataDir)
    dataDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
end
if nargin < 2 || isempty(datafile)
    datafile = 'FullMoonDataLong821.csv';
end
if nargin < 3 || isempty(task)
    task = 'Perceptual';
end
if nargin < 4 || isempty(ResultsDir)
    ResultsDir = 'PaperFig4_821';
end
if nargin < 5 || isempty(saveLME)
    saveLME = true;
end
if nargin < 7
    sorteduniqueIDD = [];
end

[dataPath, basename] = local_resolve_data_path(dataDir, datafile);
ResultsDir = local_resolve_results_dir(dataDir, ResultsDir);
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

allData = readtable(dataPath);
taskData = local_prepare_task_table(allData, task);

uniqueIDD = unique(taskData.ID);
nsubjectsD = numel(uniqueIDD);
markerScale = 36;

models = struct();
models.offsetByElevationRI = local_fit_lme(taskData, ...
    'PerceivedInterocularOffset ~ Elevation + (1|ID)', ...
    'perceived interocular offset by elevation RI');
models.offsetByElevationRS = local_fit_lme(taskData, ...
    'PerceivedInterocularOffset ~ Elevation + (Elevation|ID)', ...
    'perceived interocular offset by elevation RS');
models.offsetByElevationComparison = local_compare_lmes(models.offsetByElevationRI, models.offsetByElevationRS);

models.pmByOffsetRI = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ PerceivedInterocularOffset + (1|ID)', ...
    'PM by perceived interocular offset RI');
models.pmByOffsetRS = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ PerceivedInterocularOffset + (PerceivedInterocularOffset|ID)', ...
    'PM by perceived interocular offset RS');
models.pmByOffsetRIvsRSComparison = local_compare_lmes(models.pmByOffsetRI, models.pmByOffsetRS);
models.pmByElevationRI = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ Elevation + (1|ID)', ...
    'PM by elevation RI');
models.pmByOffsetElevationRI = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ PerceivedInterocularOffset + Elevation + (1|ID)', ...
    'PM by perceived interocular offset and elevation RI');

models.pmByOffsetElevationVsOffsetComparison = local_compare_lmes(models.pmByOffsetRI, models.pmByOffsetElevationRI);
models.pmByOffsetElevationVsElevationComparison = local_compare_lmes(models.pmByElevationRI, models.pmByOffsetElevationRI);

models.pmByOffsetVARI = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ PerceivedInterocularOffset + Real_Visual_Angle + (1|ID)', ...
    'PM by perceived interocular offset and visual angle RI');

models.pmByOffsetVsOffsetVAComparison = local_compare_lmes(models.pmByOffsetRI, models.pmByOffsetVARI);

% now log models

logData = taskData(taskData.PerceivedInterocularOffset > 0 & taskData.Ratio_Visual_Angle > 0, :);
logData.logRatio_Visual_Angle = log2(logData.Ratio_Visual_Angle);
logData.logInterocularOffset = log2(logData.PerceivedInterocularOffset);
logData.logAbsElevation = log2(1 + abs(logData.Elevation));
logData.logVA=log2(logData.Real_Visual_Angle);

models.logOffsetByLogAbsElevationRI = local_fit_lme(logData, ...
    'logInterocularOffset ~ logAbsElevation + (1|ID)', ...
    'log perceived interocular offset by log absolute elevation RI');
models.logOffsetByLogAbsElevationRS = local_fit_lme(logData, ...
    'logInterocularOffset ~ logAbsElevation + (logAbsElevation|ID)', ...
    'log perceived interocular offset by log absolute elevation RS');
models.logOffsetByLogAbsElevationComparison = local_compare_lmes( ...
    models.logOffsetByLogAbsElevationRI, models.logOffsetByLogAbsElevationRS);
models.logPmByLogOffsetRI = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logInterocularOffset + (1|ID)', ...
    'log PM by log perceived interocular offset RI');
models.logPmByLogOffsetRS = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logInterocularOffset + (logInterocularOffset|ID)', ...
    'log PM by log perceived interocular offset RS');
models.logPmByLogOffsetRIvsRSComparison = local_compare_lmes( ...
    models.logPmByLogOffsetRI, models.logPmByLogOffsetRS);
models.logPmByLogAbsElevationRI = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logAbsElevation + (1|ID)', ...
    'log PM by log absolute elevation RI');
models.logPmByLogOffsetElevationRI = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logInterocularOffset + logAbsElevation + (1|ID)', ...
    'log PM by log perceived interocular offset and log absolute elevation RI');
models.logPmByVALogOffsetRI = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logInterocularOffset + logVA + (1|ID)', ...
    'log PM by log perceived interocular offset and log visual angle RI');
models.logPmByVAElevationRI = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logAbsElevation + logVA + (1|ID)', ...
    'log PM by log elevation and log visual angle RI');


models.logPmOffsetElevationVsOffsetComparison = local_compare_lmes(models.logPmByLogOffsetRI, models.logPmByLogOffsetElevationRI);
models.logPmOffsetElevationVsElevationComparison = local_compare_lmes(models.logPmByLogAbsElevationRI, models.logPmByLogOffsetElevationRI);
models.logPmOffsetVAVsOffsetComparison = local_compare_lmes(models.logPmByLogOffsetRI, models.logPmByVALogOffsetRI);
models.logPmVAElevationVsElevationComparison = local_compare_lmes(models.logPmByLogAbsElevationRI, models.logPmByVAElevationRI);

effectsModel = models.pmByOffsetRS;
if isempty(effectsModel)
    effectsModel = models.pmByOffsetRI;
end
[feEfxR, feNamesR, festatsR, reEfxR, reNamesR, reStatsR] = local_effects(effectsModel);

if isempty(sorteduniqueIDD)
    sorteduniqueIDD = local_sorted_ids_from_random_intercepts(models.offsetByElevationRS, uniqueIDD);
end
[subjectcolor, sorted_idx] = local_subject_colors(taskData.ID, sorteduniqueIDD);
[logSubjectColor, ~] = local_subject_colors(logData.ID, sorteduniqueIDD);
save(fullfile(ResultsDir, [basename '_' char(string(task)) '_PMvInterOcularOffset_sortedidx.mat']), ...
    'sorted_idx', 'sorteduniqueIDD');

if saveLME
    reportFile = fullfile(ResultsDir, [basename '_' char(string(task)) '_lme_moon_PMvInterOcularOffset.txt']);
    local_write_report(reportFile, models, taskData, logData, dataPath, task);
end

figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .6 .6], ...
    'Name', [basename '_' char(string(task)) '_PMvInterOcularOffset']);
tiledlayout(figHandle, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_offset_by_elevation(taskData, models.offsetByElevationRS, subjectcolor, ...
    sorteduniqueIDD, markerScale, task);

nexttile;
local_plot_pm_by_offset(taskData, effectsModel, subjectcolor, markerScale, task);

filenamePNG = fullfile(ResultsDir, [basename '_' char(string(task)) '_PMvInterOcularOffset_' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(figHandle);
exportgraphics(figHandle, filenamePNG, 'Resolution', 600);

riFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [basename '_' char(string(task)) '_PMvInterOcularOffset_RI_3panel']);
tiledlayout(riFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_offset_by_elevation(taskData, models.offsetByElevationRI, subjectcolor, ...
    sorteduniqueIDD, markerScale, task, false, true);

nexttile;
local_plot_pm_by_offset(taskData, models.pmByOffsetRI, subjectcolor, markerScale, ...
    task, true);

nexttile;
local_plot_pm_by_elevation(taskData, models.pmByElevationRI, subjectcolor, ...
    markerScale, task, true);

filenameRIPNG = fullfile(ResultsDir, [basename '_' char(string(task)) '_PMvInterOcularOffset_RI_3panel_' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(riFigHandle);
exportgraphics(riFigHandle, filenameRIPNG, 'Resolution', 600);

logFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .6 .6], ...
    'Name', [basename '_' char(string(task)) '_logPMvInterOcularOffset']);
tiledlayout(logFigHandle, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_log_offset_by_log_elevation(logData, models.logOffsetByLogAbsElevationRS, ...
    logSubjectColor, sorteduniqueIDD, markerScale, task);

nexttile;
local_plot_log_pm_by_log_offset(logData, models.logPmByLogOffsetRI, logSubjectColor, markerScale, task);

filenameLogPNG = fullfile(ResultsDir, [basename '_' char(string(task)) '_logPMvInterOcularOffset_' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(logFigHandle);
exportgraphics(logFigHandle, filenameLogPNG, 'Resolution', 600);

logRIFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [basename '_' char(string(task)) '_logPMvInterOcularOffset_RI_3panel']);
tiledlayout(logRIFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_log_offset_by_log_elevation(logData, models.logOffsetByLogAbsElevationRI, ...
    logSubjectColor, sorteduniqueIDD, markerScale, task, false, true);

nexttile;
local_plot_log_pm_by_log_offset(logData, models.logPmByLogOffsetRI, ...
    logSubjectColor, markerScale, task, true);

nexttile;
local_plot_log_pm_by_log_elevation(logData, models.logPmByLogAbsElevationRI, ...
    logSubjectColor, markerScale, task, true);

filenameLogRIPNG = fullfile(ResultsDir, [basename '_' char(string(task)) '_logPMvInterOcularOffset_RI_3panel_' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(logRIFigHandle);
exportgraphics(logRIFigHandle, filenameLogRIPNG, 'Resolution', 600);
end

function local_hide_axes_toolbars(figHandle)
axesHandles = findall(figHandle, 'Type', 'axes');
for iAx = 1:numel(axesHandles)
    try
        axesHandles(iAx).Toolbar.Visible = 'off';
    catch
    end
end
drawnow;
end

function taskData = local_prepare_task_table(allData, task)
requiredVars = {'ID','Task','Reported_Visual_Angle','Ratio_Visual_Angle', ...
    'Elevation','Disparity_VA','Real_Visual_Angle'};
missingVars = setdiff(requiredVars, allData.Properties.VariableNames);
if ~isempty(missingVars)
    error('Input table is missing required variable(s): %s', strjoin(missingVars, ', '));
end

keep = ~isnan(allData.Reported_Visual_Angle) & ...
    isfinite(allData.Ratio_Visual_Angle) & ...
    isfinite(allData.Elevation) & ...
    isfinite(allData.Disparity_VA) & ...
    isfinite(allData.Real_Visual_Angle);
allData = allData(keep, :);

taskRows = strcmpi(string(allData.Task), string(task));
taskData = allData(taskRows, :);
if isempty(taskData)
    error('No rows found for task "%s".', char(string(task)));
end

taskData.ID = categorical(taskData.ID);
taskData.PerceivedInterocularOffset = taskData.Disparity_VA - taskData.Real_Visual_Angle;
taskData = taskData(isfinite(taskData.PerceivedInterocularOffset), :);
end

function lme = local_fit_lme(tbl, formula, label)
if isempty(tbl)
    warning('FullMoonPMvInterOcularOffset:EmptyTable', ...
        'Skipping %s because the input table is empty.', label);
    lme = [];
    return;
end

try
    lme = fitlme(tbl, formula);
catch ME
    warning('FullMoonPMvInterOcularOffset:FitFailed', ...
        'Could not fit %s: %s', label, ME.message);
    lme = [];
end
end

function comparison = local_compare_lmes(lme1, lme2)
if isempty(lme1) || isempty(lme2)
    comparison = [];
    return;
end

try
    comparison = compare(lme1, lme2);
catch ME
    warning('FullMoonPMvInterOcularOffset:CompareFailed', ...
        'Could not compare models: %s', ME.message);
    comparison = [];
end
end

function [feEfx, feNames, festats, reEfx, reNames, reStats] = local_effects(lme)
if isempty(lme)
    feEfx = [];
    feNames = [];
    festats = [];
    reEfx = [];
    reNames = [];
    reStats = [];
    return;
end

[feEfx, feNames, festats] = fixedEffects(lme);
[reEfx, reNames, reStats] = randomEffects(lme);
end

function local_write_report(reportFile, models, taskData, logData, dataPath, task)
[modelList, modelLabels] = local_report_models(models);
[comparisonList, comparisonLabels] = local_report_comparisons(models);

summaryLines = {
    'Experiment: Full Moon'
    sprintf('Participants in task: %d', numel(unique(taskData.ID)))
    sprintf('Rows in task model: %d', height(taskData))
    sprintf('Rows in log-offset model: %d', height(logData))
    'Perceived Interocular Offset = Disparity_VA - Real_Visual_Angle'
    'logInterocularOffset = log2(Perceived Interocular Offset)'
    'logAbsElevation = log2(1 + abs(Elevation))'
    'logRatio_Visual_Angle = log2(Ratio_Visual_Angle)'
    };

reportOpts = struct();
reportOpts.ReportTitle = sprintf('Full Moon PM and Interocular Offset LME Report: %s task', char(string(task)));
reportOpts.GeneratedBy = 'FullMoon_PMvInterOcularOffset';
reportOpts.SourceFile = dataPath;
reportOpts.ModelLabel = 'Perceived interocular offset by elevation and PM by perceived interocular offset';
reportOpts.Task = task;
reportOpts.SummaryLines = summaryLines;
reportOpts.Models = modelList;
reportOpts.ModelLabels = modelLabels;
reportOpts.Comparisons = comparisonList;
reportOpts.ComparisonLabels = comparisonLabels;
reportOpts.RemoveGroupError = false;

write_lme_stats_report(modelList{1}, reportFile, reportOpts);
end

function [modelList, modelLabels] = local_report_models(models)
modelList = {
    models.offsetByElevationRI
    models.offsetByElevationRS
    models.pmByOffsetRI
    models.pmByOffsetRS
    models.pmByElevationRI
    models.pmByOffsetElevationRI
    models.logOffsetByLogAbsElevationRI
    models.logOffsetByLogAbsElevationRS
    models.logPmByLogOffsetRI
    models.logPmByLogOffsetRS
    models.logPmByLogAbsElevationRI
    models.logPmByLogOffsetElevationRI
    models.pmByOffsetVARI
    models.logPmByVALogOffsetRI
    models.logPmByVAElevationRI
    };
modelLabels = {
    'Model: PerceivedInterocularOffset ~ Elevation + (1|ID)'
    'Model: PerceivedInterocularOffset ~ Elevation + (Elevation|ID)'
    'Model: Ratio_Visual_Angle ~ PerceivedInterocularOffset + (1|ID)'
    'Model: Ratio_Visual_Angle ~ PerceivedInterocularOffset + (PerceivedInterocularOffset|ID)'
    'Model: Ratio_Visual_Angle ~ Elevation + (1|ID)'
    'Model: Ratio_Visual_Angle ~ PerceivedInterocularOffset + Elevation + (1|ID)'
    'Model: logInterocularOffset ~ logAbsElevation + (1|ID)'
    'Model: logInterocularOffset ~ logAbsElevation + (logAbsElevation|ID)'
    'Model: logRatio_Visual_Angle ~ logInterocularOffset + (1|ID)'
    'Model: logRatio_Visual_Angle ~ logInterocularOffset + (logInterocularOffset|ID)'
    'Model: logRatio_Visual_Angle ~ logAbsElevation + (1|ID)'
    'Model: logRatio_Visual_Angle ~ logInterocularOffset + logAbsElevation + (1|ID)'
    'Model: Ratio_Visual_Angle ~ PerceivedInterocularOffset + Real_Visual_Angle + (1|ID)'
    'Model: logRatio_Visual_Angle ~ logInterocularOffset + logVA + (1|ID)'
    'Model: logRatio_Visual_Angle ~ logAbsElevation + logVA + (1|ID)'
    };
keep = ~cellfun(@isempty, modelList);
modelList = modelList(keep);
modelLabels = modelLabels(keep);
end

function [comparisonList, comparisonLabels] = local_report_comparisons(models)
comparisonList = {
    models.offsetByElevationComparison
    models.pmByOffsetRIvsRSComparison
    models.logOffsetByLogAbsElevationComparison
    models.logPmByLogOffsetRIvsRSComparison
    models.pmByOffsetElevationVsOffsetComparison
    models.pmByOffsetElevationVsElevationComparison
    models.pmByOffsetVsOffsetVAComparison
    models.logPmOffsetElevationVsOffsetComparison
    models.logPmOffsetElevationVsElevationComparison
    models.logPmOffsetVAVsOffsetComparison
    models.logPmVAElevationVsElevationComparison
    };
comparisonLabels = {
    'Model comparison: interocular offset by elevation RI vs RS'
    'Model comparison: PM by interocular offset RI vs RS'
    'Model comparison: log interocular offset by log absolute elevation RI vs RS'
    'Model comparison: log PM by log interocular offset RI vs RS'
    'Model comparison: PM by interocular offset vs PM by interocular offset plus elevation'
    'Model comparison: PM by elevation vs PM by interocular offset plus elevation'
    'Model comparison: PM by interocular offset vs PM by interocular offset plus visual angle'
    'Model comparison: log PM by log interocular offset vs log PM by log interocular offset plus log absolute elevation'
    'Model comparison: log PM by log absolute elevation vs log PM by log interocular offset plus log absolute elevation'
    'Model comparison: log PM by log interocular offset vs log PM by log interocular offset plus log visual angle'
    'Model comparison: log PM by log absolute elevation vs log PM by log absolute elevation plus log visual angle'
    };
keep = ~cellfun(@isempty, comparisonList);
comparisonList = comparisonList(keep);
comparisonLabels = comparisonLabels(keep);
end

function local_plot_offset_by_elevation(tbl, lme, subjectcolor, sorteduniqueIDD, markerScale, task, plotSubjectLines, onlyIfSignificant)
if nargin < 7 || isempty(plotSubjectLines)
    plotSubjectLines = true;
end
if nargin < 8 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

if plotSubjectLines
    local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, 'Elevation', jet(numel(sorteduniqueIDD)));
end
local_plot_fixed_effect_line(tbl, lme, 'Elevation', 'PerceivedInterocularOffset', true, onlyIfSignificant);

scatter(tbl.Elevation, tbl.PerceivedInterocularOffset, markerScale, subjectcolor, 'o', 'filled');
xlim([0 max(tbl.Elevation) * 1.05]);
ylim([0 max(tbl.PerceivedInterocularOffset) * 1.05]);
xlabel('Elevation [deg]');
ylabel('Perceived Interocular Offset [deg]');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'Elevation'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_pm_by_offset(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant)
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

local_plot_fixed_effect_line(tbl, lme, 'PerceivedInterocularOffset', 'Ratio_Visual_Angle', true, onlyIfSignificant);

scatter(tbl.PerceivedInterocularOffset, tbl.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
yline(1, 'Color', [.8 .8 .8], 'LineWidth', 3);
xlim([0 max(tbl.PerceivedInterocularOffset) * 1.05]);
ylim([0 max(tbl.Ratio_Visual_Angle) * 1.05]);
xlabel('Perceived Interocular Offset [deg]');
ylabel('Perceptual Magnification');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'PerceivedInterocularOffset'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_pm_by_elevation(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant)
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

local_plot_fixed_effect_line(tbl, lme, 'Elevation', 'Ratio_Visual_Angle', true, onlyIfSignificant);

scatter(tbl.Elevation, tbl.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
yline(1, 'Color', [.8 .8 .8], 'LineWidth', 3);
xlim([0 max(tbl.Elevation) * 1.05]);
ylim([0 max(tbl.Ratio_Visual_Angle) * 1.05]);
xlabel('Elevation [deg]');
ylabel('Perceptual Magnification');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'Elevation'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_log_offset_by_log_elevation(tbl, lme, subjectcolor, sorteduniqueIDD, markerScale, task, plotSubjectLines, onlyIfSignificant)
if nargin < 7 || isempty(plotSubjectLines)
    plotSubjectLines = true;
end
if nargin < 8 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

if plotSubjectLines
    local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, 'logAbsElevation', jet(numel(sorteduniqueIDD)));
end
local_plot_fixed_effect_line(tbl, lme, 'logAbsElevation', 'logInterocularOffset', true, onlyIfSignificant);

scatter(tbl.logAbsElevation, tbl.logInterocularOffset, markerScale, subjectcolor, 'o', 'filled');
xlim(local_range_with_padding(tbl.logAbsElevation));
ylim(local_range_with_padding(tbl.logInterocularOffset));
xlabel('log_2(1+|Elevation|)');
ylabel('log_2(Perceived Interocular Offset)');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'logAbsElevation'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_log_pm_by_log_offset(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant)
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

local_plot_fixed_effect_line(tbl, lme, 'logInterocularOffset', 'logRatio_Visual_Angle', true, onlyIfSignificant);

scatter(tbl.logInterocularOffset, tbl.logRatio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
yline(0, 'Color', [.8 .8 .8], 'LineWidth', 3);
xlim(local_range_with_padding(tbl.logInterocularOffset));
ylim(local_range_with_padding(tbl.logRatio_Visual_Angle));
xlabel('log_2(Perceived Interocular Offset)');
ylabel('log_2(Perceptual Magnification)');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'logInterocularOffset'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_log_pm_by_log_elevation(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant)
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

local_plot_fixed_effect_line(tbl, lme, 'logAbsElevation', 'logRatio_Visual_Angle', true, onlyIfSignificant);

scatter(tbl.logAbsElevation, tbl.logRatio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
yline(0, 'Color', [.8 .8 .8], 'LineWidth', 3);
xlim(local_range_with_padding(tbl.logAbsElevation));
ylim(local_range_with_padding(tbl.logRatio_Visual_Angle));
xlabel('log_2(1+|Elevation|)');
ylabel('log_2(Perceptual Magnification)');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'logAbsElevation'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_fixed_effect_line(tbl, lme, xName, yName, showCi, onlyIfSignificant)
if isempty(lme)
    return;
end
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end

[beta, coefNames, coefStats] = fixedEffects(lme);
coefText = local_coef_names(coefNames, lme);
xIdx = find(strcmp(coefText, xName), 1);
if isempty(xIdx) || xIdx > numel(beta)
    return;
end

pValue = coefStats.pValue(xIdx);
if onlyIfSignificant && pValue >= 0.05
    return;
end

interceptIdx = find(strcmp(coefText, '(Intercept)'), 1);
if isempty(interceptIdx)
    interceptIdx = 1;
end

xvectoru = linspace(min(tbl.(xName)), max(tbl.(xName)), 100);
yvectoru = beta(interceptIdx) + beta(xIdx) .* xvectoru;

if showCi && ismember('Lower', local_table_var_names(coefStats)) && ismember('Upper', local_table_var_names(coefStats))
    xvectord = sort(xvectoru, 'descend');
    yvector1 = coefStats.Lower(interceptIdx) + coefStats.Lower(xIdx) .* xvectoru;
    yvector2 = coefStats.Upper(interceptIdx) + coefStats.Upper(xIdx) .* xvectord;
    fill([xvectoru xvectord], [yvector1 yvector2], [.70 .70 .70], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.35);
end

plot(xvectoru, yvectoru, 'k-', 'LineWidth', 3);

if nargin >= 4 && ~isempty(yName)
    ylim([0 max(tbl.(yName)) * 1.05]);
end
end

function rangeVals = local_range_with_padding(values)
values = values(isfinite(values));
if isempty(values)
    rangeVals = [0 1];
    return;
end

minVal = min(values);
maxVal = max(values);
if minVal == maxVal
    pad = max(abs(minVal) * 0.05, 0.5);
else
    pad = 0.05 * (maxVal - minVal);
end
rangeVals = [minVal - pad, maxVal + pad];
end

function local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, xName, cmap)
if isempty(lme)
    return;
end

[feEfx, feNames] = fixedEffects(lme);
[reEfx, reNames] = randomEffects(lme);
feCoefNames = local_coef_names(feNames, lme);
interceptFixedIdx = find(strcmp(feCoefNames, '(Intercept)'), 1);
slopeFixedIdx = find(strcmp(feCoefNames, xName), 1);
if isempty(interceptFixedIdx) || isempty(slopeFixedIdx)
    return;
end

reNameText = string(reNames.Name);
reLevelText = string(reNames.Level);
sortedText = string(sorteduniqueIDD);
idText = string(tbl.ID);

for iSubject = 1:numel(sortedText)
    subjectID = sortedText(iSubject);
    rowIdx = idText == subjectID;
    if nnz(rowIdx) < 2
        continue;
    end

    interceptIdx = find(reLevelText == subjectID & reNameText == "(Intercept)", 1);
    slopeIdx = find(reLevelText == subjectID & reNameText == string(xName), 1);
    if isempty(interceptIdx) || isempty(slopeIdx)
        continue;
    end

    xSubject = tbl.(xName)(rowIdx);
    xSubject = [min(xSubject) max(xSubject)];
    ySubject = (feEfx(interceptFixedIdx) + reEfx(interceptIdx)) + ...
        (feEfx(slopeFixedIdx) + reEfx(slopeIdx)) .* xSubject;
    plot(xSubject, ySubject, ':', 'Color', cmap(iSubject, :), 'LineWidth', 1);
end
end

function titleText = local_panel_title(task, lme, xName)
if isempty(lme)
    titleText = sprintf('%s\nmodel did not fit', char(string(task)));
    return;
end

[beta, coefNames, coefStats] = fixedEffects(lme);
coefText = local_coef_names(coefNames, lme);
xIdx = find(strcmp(coefText, xName), 1);
if isempty(xIdx)
    titleText = char(string(task));
    return;
end

intercept = beta(1);
slope = beta(xIdx);
pValue = coefStats.pValue(xIdx);
titleText = sprintf('%s\nintercept=%.2f\nslope=%.2f %s\nn=%d', ...
    char(string(task)), intercept, slope, local_format_p(pValue), numel(unique(lme.Variables.ID)));
end

function [subjectcolor, sorted_idx] = local_subject_colors(idValues, sorteduniqueIDD)
idText = string(idValues);
sortedText = string(sorteduniqueIDD);
nSubjects = numel(sortedText);
cmap = jet(nSubjects);

subjectcolor = zeros(numel(idText), 3);
sorted_idx = nan(numel(idText), 1);
for iRow = 1:numel(idText)
    colorIdx = find(sortedText == idText(iRow), 1);
    if isempty(colorIdx)
        colorIdx = find(unique(idText, 'stable') == idText(iRow), 1);
        colorIdx = min(colorIdx, nSubjects);
    end
    sorted_idx(iRow) = colorIdx;
    subjectcolor(iRow, :) = cmap(colorIdx, :);
end
end

function sorteduniqueIDD = local_sorted_ids_from_random_intercepts(lme, uniqueIDD)
if isempty(lme)
    sorteduniqueIDD = uniqueIDD;
    return;
end

try
    [reEfx, reNames] = randomEffects(lme);
    idText = string(uniqueIDD);
    randomIntercepts = nan(numel(idText), 1);
    reNameText = string(reNames.Name);
    reLevelText = string(reNames.Level);
    for iID = 1:numel(idText)
        idx = find(reLevelText == idText(iID) & reNameText == "(Intercept)", 1);
        if ~isempty(idx)
            randomIntercepts(iID) = reEfx(idx);
        end
    end
    [~, order] = sort(randomIntercepts);
    sorteduniqueIDD = uniqueIDD(order);
catch
    sorteduniqueIDD = uniqueIDD;
end
end

function coefText = local_coef_names(coefNames, lme)
try
    if istable(coefNames) && ismember('Name', coefNames.Properties.VariableNames)
        coefText = cellstr(string(coefNames.Name));
    elseif isstruct(coefNames) && isfield(coefNames, 'Name')
        coefText = cellstr(string(coefNames.Name));
    elseif iscell(coefNames)
        coefText = cellstr(string(coefNames));
    else
        coefText = cellstr(string(coefNames));
    end
catch
    coefText = cellstr(string(lme.CoefficientNames(:)));
end

coefText = strrep(coefText, '''', '');
coefText = strrep(coefText, '{', '');
coefText = strrep(coefText, '}', '');
end

function varNames = local_table_var_names(tbl)
try
    varNames = cellstr(tbl.Properties.VariableNames);
    return;
catch
end

try
    varNames = cellstr(tbl.Properties.VarNames);
    return;
catch
end

varNames = {};
end

function pText = local_format_p(pValue)
if isnan(pValue)
    pText = 'p=NA';
elseif pValue < 0.001
    pText = sprintf('p=%.2e', pValue);
else
    pText = sprintf('p=%.3f', pValue);
end
end

function [dataPath, basename] = local_resolve_data_path(dataDir, datafile)
dataDir = char(string(dataDir));
datafile = char(string(datafile));
if local_is_absolute_path(datafile)
    dataPath = datafile;
else
    dataPath = fullfile(dataDir, datafile);
end

if ~isfile(dataPath)
    [folder, name, ext] = fileparts(dataPath);
    if isempty(ext)
        csvPath = fullfile(folder, [name '.csv']);
        if isfile(csvPath)
            dataPath = csvPath;
        end
    end
end

if ~isfile(dataPath)
    error('Could not find data file: %s', dataPath);
end

[~, basename, ~] = fileparts(dataPath);
end

function resultsDir = local_resolve_results_dir(dataDir, resultsDir)
dataDir = char(string(dataDir));
resultsDir = char(string(resultsDir));
if ~local_is_absolute_path(resultsDir)
    resultsDir = fullfile(dataDir, resultsDir);
end
end

function tf = local_is_absolute_path(pathText)
pathText = char(string(pathText));
tf = startsWith(pathText, filesep) || ~isempty(regexp(pathText, '^[A-Za-z]:[\\/]', 'once'));
end
