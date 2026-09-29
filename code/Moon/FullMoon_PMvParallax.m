function [feEfxR, feNamesR, festatsR, reEfxR, reNamesR, reStatsR, models, figHandle, taskData] = ...
    FullMoon_PMvParallax(dataDir, datafile, task, ResultsDir, saveLME, ~, sorteduniqueIDD)
% FullMoon_PMvParallax
%
% Combine the full-moon perceived-parallax analysis with the PM-vs-parallax
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
%   feEfxR, feNamesR, festatsR : fixed effects from the PM-vs-parallax
%                                random-slope model
%   reEfxR, reNamesR, reStatsR : random effects from the PM-vs-parallax
%                                random-slope model
%   models                    : struct containing fitted models/comparisons
%   figHandle                 : handle to the generated raw-scale figure
%   taskData                  : task-filtered data table used for fitting
%
% The first figure has two panels:
%   1. Perceived Parallax vs Elevation
%   2. Perceptual Magnification vs Perceived Parallax
%
% The second figure has three panels showing the corresponding random-
% intercept models. All models use untransformed linear-scale variables.
%
% Perceived Parallax is computed as:
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
models.parallaxByElevationRI = local_fit_lme(taskData, ...
    'PerceivedParallax ~ Elevation + (1|ID)', ...
    'perceived parallax by elevation RI');

models.parallaxByElevationRS = local_fit_lme(taskData, ...
    'PerceivedParallax ~ Elevation + (Elevation|ID)', ...
    'perceived parallax by elevation RS');
models.parallaxByElevationComparison = local_compare_lmes(models.parallaxByElevationRI, models.parallaxByElevationRS);

% comparing PM (ratio_visual_angle) as a function of parallax or elevation
models.pmByParallaxRI = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ PerceivedParallax + (1|ID)', ...
    'PM by perceived parallax RI');

models.pmByParallaxRS = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ PerceivedParallax + (PerceivedParallax|ID)', ...
    'PM by perceived parallax RS');
models.pmByParallaxComparison = local_compare_lmes( ...
    models.pmByParallaxRI, models.pmByParallaxRS);

models.pmByElevationRI = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ Elevation + (1|ID)', ...
    'PM by elevation RI');

models.pmByElevationRS = local_fit_lme(taskData, ...
    'Ratio_Visual_Angle ~ Elevation + (Elevation|ID)', ...
    'PM by elevation RS');
models.pmByElevationComparison = local_compare_lmes( ...
    models.pmByElevationRI, models.pmByElevationRS);

effectsModel = models.pmByParallaxRS;
if isempty(effectsModel)
     effectsModel = models.pmByParallaxRI;
end
[feEfxR, feNamesR, festatsR, reEfxR, reNamesR, reStatsR] = local_effects(effectsModel);

% But we saw that a log-log model better matches the data, so test it too.
logData = taskData;
logData.logRatio_Visual_Angle = log2(taskData.Ratio_Visual_Angle);
logData.logParallax = log2(1 + taskData.PerceivedParallax);
logData.logElevation = log2(1 + taskData.Elevation);
logData.logVA = log2(taskData.Real_Visual_Angle);

% Compare log parallax as a function of log elevation.
models.logParallaxbylogElevationRI = local_fit_lme(logData, ...
    'logParallax ~ logElevation + (1|ID)', ...
    'log PM by log perceived parallax RI');

models.logParallaxbylogElevationRS = local_fit_lme(logData, ...
    'logParallax ~ logElevation + (logElevation|ID)', ...
    'log parallax by log elevation RS');
models.logParallaxbylogElevationComparison = local_compare_lmes( ...
    models.logParallaxbylogElevationRI, models.logParallaxbylogElevationRS);

% Compare log PM as a function of log parallax or log elevation.
models.logpmBylogParallaxRI = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logParallax + (1|ID)', ...
    'log PM by log perceived parallax RI');

models.logpmBylogParallaxRS = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logParallax + (logParallax|ID)', ...
    'log PM by log perceived parallax RS');
models.logpmBylogParallaxComparison = local_compare_lmes( ...
    models.logpmBylogParallaxRI, models.logpmBylogParallaxRS);

models.logpmBylogElevationRI = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logElevation + (1|ID)', ...
    'log PM by log elevation RI');

models.logpmBylogElevationRS = local_fit_lme(logData, ...
    'logRatio_Visual_Angle ~ logElevation + (logElevation|ID)', ...
    'log PM by log elevation RS');
models.logpmBylogElevationComparison = local_compare_lmes( ...
    models.logpmBylogElevationRI, models.logpmBylogElevationRS);


if isempty(sorteduniqueIDD)
    sorteduniqueIDD = local_sorted_ids_from_random_intercepts(models.parallaxByElevationRS, uniqueIDD);
end
[subjectcolor, sorted_idx] = local_subject_colors(taskData.ID, sorteduniqueIDD);
save(fullfile(ResultsDir, [basename '_' char(string(task)) '_PMvParallax_sortedidx.mat']), ...
    'sorted_idx', 'sorteduniqueIDD');

if saveLME
    reportFile = fullfile(ResultsDir, [basename '_' char(string(task)) '_lme_moon_PMvParallax.txt']);
    local_write_report(reportFile, models, taskData, dataPath, task);
end

% 2 panelled figure
% plot Parallax vs Elevation & PM vs Parallax
figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .6 .6], ...
    'Name', [basename '_' char(string(task)) '_PMvParallax']);
tiledlayout(figHandle, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_parallax_by_elevation(taskData, models.parallaxByElevationRS, subjectcolor, ...
    sorteduniqueIDD, markerScale, task); % just to illustrate the participant level slopes

nexttile;
local_plot_pm_by_parallax(taskData, effectsModel, subjectcolor, markerScale, task);

filenamePNG = fullfile(ResultsDir, [basename '_' char(string(task)) '_PMvParallax_' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(figHandle);
exportgraphics(figHandle, filenamePNG, 'Resolution', 600);

%% 3 panel figure:
%   Plot log parallax vs elevation, PM vs log parallax, and PM vs elevation.
riFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [basename '_' char(string(task)) '_Parallax_E_PM']);
tiledlayout(riFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_parallax_by_elevation(taskData, models.parallaxByElevationRI, subjectcolor, ...
    sorteduniqueIDD, markerScale, task, false, true); % this is Random intercepts model

nexttile;
local_plot_pm_by_parallax(taskData, models.pmByParallaxRI, subjectcolor, markerScale, ...
    task, true);

nexttile;
local_plot_pm_by_elevation(taskData, models.pmByElevationRI, subjectcolor, ...
    markerScale, task, true);

filenameRIPNG = fullfile(ResultsDir, [basename '_' char(string(task)) '_Parallax_E_PM_RI' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(riFigHandle);
exportgraphics(riFigHandle, filenameRIPNG, 'Resolution', 600);

%% Three-panel RI figure with all three log-log model panels.
% Plot log parallax vs log elevation, log PM vs log parallax, and log PM vs log elevation.

logRIFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [basename '_' char(string(task)) '_PMvParallax_log_RI_3panel']);
tiledlayout(logRIFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_log_parallax_by_log_elevation(logData, ...
    models.logParallaxbylogElevationRI, subjectcolor, markerScale, task, ...
    false, sorteduniqueIDD, true);

nexttile;
local_plot_log_pm_by_log_parallax(logData, models.logpmBylogParallaxRI, ...
    subjectcolor, markerScale, task, true);

nexttile;
local_plot_log_pm_by_log_elevation(logData, models.logpmBylogElevationRI, ...
    subjectcolor, markerScale, task, true);

filenameLogRIPNG = fullfile(ResultsDir, [basename '_' char(string(task)) ...
    '_logParallax_PM_E_RI' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(logRIFigHandle);
exportgraphics(logRIFigHandle, filenameLogRIPNG, 'Resolution', 600);

%% Three-panel random-slope sister figure on linear scales.
rsFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [basename '_' char(string(task)) '_Parallax_E_PM_RS']);
tiledlayout(rsFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_parallax_by_elevation(taskData, models.parallaxByElevationRS, ...
    subjectcolor, sorteduniqueIDD, markerScale, task, true, true);

nexttile;
local_plot_pm_by_parallax_rs(taskData, models.pmByParallaxRS, subjectcolor, ...
    sorteduniqueIDD, markerScale, task, true);

nexttile;
local_plot_pm_by_elevation_rs(taskData, models.pmByElevationRS, subjectcolor, ...
    sorteduniqueIDD, markerScale, task, true);

filenameRSPNG = fullfile(ResultsDir, [basename '_' char(string(task)) ...
    '_Parallax_E_PM_RS' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(rsFigHandle);
exportgraphics(rsFigHandle, filenameRSPNG, 'Resolution', 600);

%% Three-panel random-slope sister figure on log2 scales.
logRSFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [basename '_' char(string(task)) '_PMvParallax_log_RS_3panel']);
tiledlayout(logRSFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_log_parallax_by_log_elevation(logData, ...
    models.logParallaxbylogElevationRS, subjectcolor, markerScale, task, ...
    true, sorteduniqueIDD, true);

nexttile;
local_plot_log_pm_by_log_parallax_rs(logData, models.logpmBylogParallaxRS, ...
    subjectcolor, sorteduniqueIDD, markerScale, task, true);

nexttile;
local_plot_log_pm_by_log_elevation_rs(logData, models.logpmBylogElevationRS, ...
    subjectcolor, sorteduniqueIDD, markerScale, task, true);

filenameLogRSPNG = fullfile(ResultsDir, [basename '_' char(string(task)) ...
    '_PMvParallax_log_RS_3panel_' num2str(nsubjectsD) '.png']);
local_hide_axes_toolbars(logRSFigHandle);
exportgraphics(logRSFigHandle, filenameLogRSPNG, 'Resolution', 600);

%% Mixed-scale three-panel RI figure for Fig4g.
mixedRIFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [char(string(task)) '_Fig4g_PvsE_logPMvlogP_logPMvlogE_' ...
    num2str(nsubjectsD) '_RI']);
tiledlayout(mixedRIFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_parallax_by_elevation(taskData, models.parallaxByElevationRI, ...
    subjectcolor, sorteduniqueIDD, markerScale, task, false, true);

nexttile;
local_plot_log_pm_by_log_parallax(logData, models.logpmBylogParallaxRI, ...
    subjectcolor, markerScale, task, true);

nexttile;
local_plot_log_pm_by_log_elevation(logData, models.logpmBylogElevationRI, ...
    subjectcolor, markerScale, task, true);

filenameMixedRIPNG = fullfile(ResultsDir, [char(string(task)) ...
    '_Fig4g_PvsE_logPMvlogP_logPMvlogE_' num2str(nsubjectsD) '_RI.png']);
local_hide_axes_toolbars(mixedRIFigHandle);
exportgraphics(mixedRIFigHandle, filenameMixedRIPNG, 'Resolution', 600);

%% Mixed-scale three-panel RS figure for Fig4g.
mixedRSFigHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .9 .6], ...
    'Name', [char(string(task)) '_Fig4g_PvsE_logPMvlogP_logPMvlogE_' ...
    num2str(nsubjectsD) '_RS']);
tiledlayout(mixedRSFigHandle, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
local_plot_parallax_by_elevation(taskData, models.parallaxByElevationRS, ...
    subjectcolor, sorteduniqueIDD, markerScale, task, true, true);

nexttile;
local_plot_log_pm_by_log_parallax_rs(logData, models.logpmBylogParallaxRS, ...
    subjectcolor, sorteduniqueIDD, markerScale, task, true);

nexttile;
local_plot_log_pm_by_log_elevation_rs(logData, models.logpmBylogElevationRS, ...
    subjectcolor, sorteduniqueIDD, markerScale, task, true);

filenameMixedRSPNG = fullfile(ResultsDir, [char(string(task)) ...
    '_Fig4g_PvsE_logPMvlogP_logPMvlogE_' num2str(nsubjectsD) '_RS.png']);
local_hide_axes_toolbars(mixedRSFigHandle);
exportgraphics(mixedRSFigHandle, filenameMixedRSPNG, 'Resolution', 600);

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
taskData.PerceivedParallax = taskData.Disparity_VA - taskData.Real_Visual_Angle;
taskData = taskData(isfinite(taskData.PerceivedParallax), :);
end

function lme = local_fit_lme(tbl, formula, label)
if isempty(tbl)
    warning('FullMoonPMvParallax:EmptyTable', ...
        'Skipping %s because the input table is empty.', label);
    lme = [];
    return;
end

try
    lme = fitlme(tbl, formula);
catch ME
    warning('FullMoonPMvParallax:FitFailed', ...
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
    warning('FullMoonPMvParallax:CompareFailed', ...
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

function local_write_report(reportFile, models, taskData, dataPath, task)
[modelList, modelLabels] = local_report_models(models);
[comparisonList, comparisonLabels] = local_report_comparisons(models);

summaryLines = {
    'Experiment: Full Moon'
    sprintf('Participants in task: %d', numel(unique(taskData.ID)))
    sprintf('Rows in task model: %d', height(taskData))
    'Perceived Parallax = Disparity_VA - Real_Visual_Angle'
    'Linear models use original units; log models use log2(1 + predictor) and log2(PM)'
    };

reportOpts = struct();
reportOpts.ReportTitle = sprintf('Full Moon PM and Parallax LME Report: %s task', char(string(task)));
reportOpts.GeneratedBy = 'FullMoon_PMvParallax';
reportOpts.SourceFile = dataPath;
reportOpts.ModelLabel = 'Perceived parallax by elevation and PM by perceived parallax';
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
    models.parallaxByElevationRI
    models.parallaxByElevationRS
    models.pmByParallaxRI
    models.pmByParallaxRS
    models.pmByElevationRI
    models.pmByElevationRS
    models.logParallaxbylogElevationRI
    models.logParallaxbylogElevationRS
    models.logpmBylogParallaxRI
    models.logpmBylogParallaxRS
    models.logpmBylogElevationRI
    models.logpmBylogElevationRS
    };


modelLabels = {
    'Model: PerceivedParallax ~ Elevation + (1|ID)'
    'Model: PerceivedParallax ~ Elevation + (Elevation|ID)'
    'Model: Ratio_Visual_Angle ~ PerceivedParallax + (1|ID)'
    'Model: Ratio_Visual_Angle ~ PerceivedParallax + (PerceivedParallax|ID)'
    'Model: Ratio_Visual_Angle ~ Elevation + (1|ID)'
    'Model: Ratio_Visual_Angle ~ Elevation + (Elevation|ID)'
    'Model: log2(1 + PerceivedParallax) ~ log2(1 + Elevation) + (1|ID)'
    'Model: log2(1 + PerceivedParallax) ~ log2(1 + Elevation) + (log2(1 + Elevation)|ID)'
    'Model: log2(Ratio_Visual_Angle) ~ log2(1 + PerceivedParallax) + (1|ID)'
    'Model: log2(Ratio_Visual_Angle) ~ log2(1 + PerceivedParallax) + (log2(1 + PerceivedParallax)|ID)'
    'Model: log2(Ratio_Visual_Angle) ~ log2(1 + Elevation) + (1|ID)'
    'Model: log2(Ratio_Visual_Angle) ~ log2(1 + Elevation) + (log2(1 + Elevation)|ID)'
    };
keep = ~cellfun(@isempty, modelList);
modelList = modelList(keep);
modelLabels = modelLabels(keep);
end

function [comparisonList, comparisonLabels] = local_report_comparisons(models)
comparisonList = {
    models.parallaxByElevationComparison
    models.pmByParallaxComparison
    models.pmByElevationComparison
    models.logParallaxbylogElevationComparison
    models.logpmBylogParallaxComparison
    models.logpmBylogElevationComparison
    };
comparisonLabels = {
    'Model comparison: parallax by elevation RI vs RS'
    'Model comparison: PM by parallax RI vs RS'
    'Model comparison: PM by elevation RI vs RS'
    'Model comparison: log parallax by log elevation RI vs RS'
    'Model comparison: log PM by log parallax RI vs RS'
    'Model comparison: log PM by log elevation RI vs RS'
    };
keep = ~cellfun(@isempty, comparisonList);
comparisonList = comparisonList(keep);
comparisonLabels = comparisonLabels(keep);
end

function local_plot_parallax_by_elevation(tbl, lme, subjectcolor, sorteduniqueIDD, markerScale, task, plotSubjectLines, onlyIfSignificant)
if nargin < 7 || isempty(plotSubjectLines)
    plotSubjectLines = true;
end
if nargin < 8 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

if plotSubjectLines
    local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, 'Elevation', purpleVioletBlueTurquoiseColorMap(numel(sorteduniqueIDD)));
end
local_plot_fixed_effect_line(tbl, lme, 'Elevation', 'PerceivedParallax', true, onlyIfSignificant);

scatter(tbl.Elevation, tbl.PerceivedParallax, markerScale, subjectcolor, 'o', 'filled');
xlim([0 max(tbl.Elevation) * 1.05]);
ylim([0 max(tbl.PerceivedParallax) * 1.05]);
xlabel('Elevation [deg]');
ylabel('Perceived Parallax [deg]');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'Elevation'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_pm_by_parallax(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant)
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

local_plot_fixed_effect_line(tbl, lme, 'PerceivedParallax', 'Ratio_Visual_Angle', true, onlyIfSignificant);

scatter(tbl.PerceivedParallax, tbl.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
yline(1, 'Color', [.8 .8 .8], 'LineWidth', 3);
xlim([0 max(tbl.PerceivedParallax) * 1.05]);
ylim([0 max(tbl.Ratio_Visual_Angle) * 1.05]);
xlabel('Perceived Parallax [deg]');
ylabel('Perceptual Magnification');
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
title(local_panel_title(task, lme, 'PerceivedParallax'), 'FontSize', 16, 'FontName', 'Avenir');
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

function local_plot_pm_by_parallax_rs(tbl, lme, subjectcolor, sorteduniqueIDD, markerScale, task, onlyIfSignificant)
hold on;
local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, ...
    'PerceivedParallax', purpleVioletBlueTurquoiseColorMap(numel(sorteduniqueIDD)));
local_plot_pm_by_parallax(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant);
end

function local_plot_pm_by_elevation_rs(tbl, lme, subjectcolor, sorteduniqueIDD, markerScale, task, onlyIfSignificant)
hold on;
local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, ...
    'Elevation', purpleVioletBlueTurquoiseColorMap(numel(sorteduniqueIDD)));
local_plot_pm_by_elevation(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant);
end

function local_plot_log_parallax_by_log_elevation(tbl, lme, subjectcolor, markerScale, task, plotSubjectLines, sorteduniqueIDD, onlyIfSignificant)
if nargin < 6 || isempty(plotSubjectLines)
    plotSubjectLines = false;
end
if nargin < 8 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

if plotSubjectLines
    local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, ...
        'logElevation', purpleVioletBlueTurquoiseColorMap(numel(sorteduniqueIDD)));
end
local_plot_fixed_effect_line_unbounded(tbl, lme, 'logElevation', ...
    'logParallax', true, onlyIfSignificant);
scatter(tbl.logElevation, tbl.logParallax, markerScale, subjectcolor, 'o', 'filled');
xlim(local_range_with_padding(tbl.logElevation));
ylim(local_range_with_padding(tbl.logParallax));
xlabel({'Elevation [deg]', 'log scale'});
ylabel({'Perceived Parallax [deg]', 'log scale'});
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
local_apply_original_unit_log_ticks(gca, true, true);
title(local_panel_title(task, lme, 'logElevation'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_log_pm_by_log_parallax(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant)
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

local_plot_fixed_effect_line_unbounded(tbl, lme, 'logParallax', ...
    'logRatio_Visual_Angle', true, onlyIfSignificant);
scatter(tbl.logParallax, tbl.logRatio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
yline(0, 'Color', [.8 .8 .8], 'LineWidth', 3);
xlim(local_range_with_padding(tbl.logParallax));
ylim(local_range_with_padding(tbl.logRatio_Visual_Angle));
xlabel({'Perceived Parallax [deg]', 'log scale'});
ylabel({'Perceptual Magnification', 'log scale'});
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
local_apply_original_unit_log_ticks(gca, true, false);
title(local_panel_title(task, lme, 'logParallax'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_log_pm_by_log_elevation(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant)
if nargin < 6 || isempty(onlyIfSignificant)
    onlyIfSignificant = true;
end
hold on;

local_plot_fixed_effect_line_unbounded(tbl, lme, 'logElevation', ...
    'logRatio_Visual_Angle', true, onlyIfSignificant);
scatter(tbl.logElevation, tbl.logRatio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
yline(0, 'Color', [.8 .8 .8], 'LineWidth', 3);
xlim(local_range_with_padding(tbl.logElevation));
ylim(local_range_with_padding(tbl.logRatio_Visual_Angle));
xlabel({'Elevation [deg]', 'log scale'});
ylabel({'Perceptual Magnification', 'log scale'});
set(gca, 'FontSize', 20, 'FontName', 'Avenir');
local_apply_original_unit_log_ticks(gca, true, false);
title(local_panel_title(task, lme, 'logElevation'), 'FontSize', 16, 'FontName', 'Avenir');
end

function local_plot_log_pm_by_log_parallax_rs(tbl, lme, subjectcolor, sorteduniqueIDD, markerScale, task, onlyIfSignificant)
hold on;
local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, ...
    'logParallax', purpleVioletBlueTurquoiseColorMap(numel(sorteduniqueIDD)));
local_plot_log_pm_by_log_parallax(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant);
end

function local_plot_log_pm_by_log_elevation_rs(tbl, lme, subjectcolor, sorteduniqueIDD, markerScale, task, onlyIfSignificant)
hold on;
local_plot_random_subject_lines(tbl, lme, sorteduniqueIDD, ...
    'logElevation', purpleVioletBlueTurquoiseColorMap(numel(sorteduniqueIDD)));
local_plot_log_pm_by_log_elevation(tbl, lme, subjectcolor, markerScale, task, onlyIfSignificant);
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

function local_plot_fixed_effect_line_unbounded(tbl, lme, xName, yName, showCi, onlyIfSignificant)
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

if showCi && ismember('Lower', local_table_var_names(coefStats)) && ...
        ismember('Upper', local_table_var_names(coefStats))
    xvectord = sort(xvectoru, 'descend');
    yvector1 = coefStats.Lower(interceptIdx) + coefStats.Lower(xIdx) .* xvectoru;
    yvector2 = coefStats.Upper(interceptIdx) + coefStats.Upper(xIdx) .* xvectord;
    fill([xvectoru xvectord], [yvector1 yvector2], [.70 .70 .70], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.35);
end

plot(xvectoru, yvectoru, 'k-', 'LineWidth', 3);
if nargin >= 4 && ~isempty(yName)
    ylim(local_range_with_padding(tbl.(yName)));
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

function local_apply_original_unit_log_ticks(ax, xUsesPlusOne, yUsesPlusOne)
if nargin < 3
    yUsesPlusOne = false;
end
xTickValues = ax.XTick;
if xUsesPlusOne
    xLabels = 2 .^ xTickValues - 1;
else
    xLabels = 2 .^ xTickValues;
end
if yUsesPlusOne
    yLabels = 2 .^ ax.YTick - 1;
else
    yLabels = 2 .^ ax.YTick;
end

ax.XTickLabel = local_numeric_tick_labels(xLabels);
ax.YTickLabel = local_numeric_tick_labels(yLabels);
ax.XTickLabelRotation = 0;
end

function labels = local_numeric_tick_labels(values)
labels = strings(size(values));
for iValue = 1:numel(values)
    value = values(iValue);
    if abs(value) >= 10
        labels(iValue) = string(sprintf('%.0f', value));
    elseif abs(value) >= 1
        labels(iValue) = string(sprintf('%.1f', value));
    else
        labels(iValue) = string(sprintf('%.2f', value));
    end
end
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
cmap = purpleVioletBlueTurquoiseColorMap(nSubjects);

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
