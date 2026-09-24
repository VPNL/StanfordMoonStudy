function [lmeByAngle, figH] = Quad_PerceivedSize_by_task_table( ...
    tbl, tblName, task, resultsDir, saveLME, colorConfig)
%QUAD_PERCEIVEDSIZE_BY_TASK_TABLE Plot perceived versus physical size.
%
% [lmeByAngle, figH] = Quad_PerceivedSize_by_task_table( ...
%     tbl, tblName, task, resultsDir, saveLME, colorConfig)
%
% Inputs
%   tbl         - Quad table already restricted to the desired analysis
%                 group. It may contain one or both tasks.
%   tblName     - Output filename stem and report dataset label.
%   task        - Task to plot, typically 'Perceptual' or 'Adjusted'.
%   resultsDir  - Directory for the PNG and optional statistics report.
%   saveLME     - When true, write a formatted LME report.
%   colorConfig - Participant color configuration returned by
%                 Quad_build_participant_color_config. The same config can
%                 be passed for both tasks to preserve participant colors.
%
% Outputs
%   lmeByAngle  - Zero-intercept random-slope LME relating reported to real
%                 visual angle.
%   figH        - Figure handle for the perceived-size plot.

% Model
%   Reported_Visual_Angle ~ -1 + Real_Visual_Angle +
%                           (-1 + Real_Visual_Angle | ID)

% Example
%   colorConfig = Quad_build_participant_color_config(groupTbl, ...
%       resultsDir, 'StereoTypical', 'stereoscore', true);
%   Quad_PerceivedSize_by_task_table(groupTbl, ...
%       'StereoTypical_Perceptual', 'Perceptual', resultsDir, true, ...
%       colorConfig);

requiredVars = {'ID', 'Task', 'Real_Visual_Angle', 'Reported_Visual_Angle'};
missingVars = setdiff(requiredVars, tbl.Properties.VariableNames);
if ~isempty(missingVars)
    error('QuadPerceivedSizeTable:MissingVariables', ...
        'tbl is missing required variable(s): %s', strjoin(missingVars, ', '));
end
if nargin < 6 || isempty(colorConfig)
    error('QuadPerceivedSizeTable:MissingColorConfig', ...
        'A participant color configuration is required.');
end
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

taskRows = strcmpi(string(tbl.Task), string(task));
taskTbl = tbl(taskRows, :);
validRows = isfinite(taskTbl.Real_Visual_Angle) & ...
    taskTbl.Real_Visual_Angle > 0 & ...
    isfinite(taskTbl.Reported_Visual_Angle) & ...
    taskTbl.Reported_Visual_Angle > 0;
taskTbl = taskTbl(validRows, :);
if isempty(taskTbl)
    error('QuadPerceivedSizeTable:NoTaskRows', ...
        'No valid %s rows were found in tbl.', char(string(task)));
end

lmeByAngle = fitlme(taskTbl, [ ...
    'Reported_Visual_Angle ~ -1 + Real_Visual_Angle + ' ...
    '(-1 + Real_Visual_Angle|ID)']);

participantIDs = unique(string(taskTbl.ID), 'stable');
subjectSlopes = Quad_extract_subject_model_coefficient( ...
    lmeByAngle, 'Real_Visual_Angle', participantIDs);
pointColors = Quad_colors_for_participant_ids(taskTbl.ID, colorConfig);
lineColors = Quad_colors_for_participant_ids(participantIDs, colorConfig);

maxAngle = max([taskTbl.Real_Visual_Angle; taskTbl.Reported_Visual_Angle]);
xGrid = linspace(0, maxAngle, 200)';
coefTbl = lmeByAngle.Coefficients;
slopeRow = strcmp(string(coefTbl.Name), 'Real_Visual_Angle');
fixedSlope = coefTbl.Estimate(slopeRow);
lowerSlope = coefTbl.Lower(slopeRow);
upperSlope = coefTbl.Upper(slopeRow);
pValue = coefTbl.pValue(slopeRow);

figH = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.12 0.08 0.68 0.82], ...
    'Name', sprintf('%s_%s_perceived_size', tblName, task), ...
    'Visible', 'on');
ax = axes(figH);
hold(ax, 'on');

fill(ax, [xGrid; flipud(xGrid)], ...
    [lowerSlope*xGrid; flipud(upperSlope*xGrid)], [0.75 0.75 0.75], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.55);
plot(ax, xGrid, xGrid, ':', 'Color', [0.65 0.65 0.65], 'LineWidth', 3);
for participantIdx = 1:numel(participantIDs)
    plot(ax, xGrid, subjectSlopes(participantIdx)*xGrid, ':', ...
        'Color', lineColors(participantIdx, :), 'LineWidth', 1.2);
end
plot(ax, xGrid, fixedSlope*xGrid, 'k-', 'LineWidth', 5);
scatter(ax, taskTbl.Real_Visual_Angle, taskTbl.Reported_Visual_Angle, ...
    50, pointColors, 'filled');

xlim(ax, [0 maxAngle]);
ylim(ax, [0 maxAngle]);
axis(ax, 'square');
xlabel(ax, 'Physical Visual Angle [degrees]');
ylabel(ax, 'Perceived Angular Size [degrees]');
set(ax, 'FontSize', 26, 'FontName', 'Avenir', 'XTickLabelRotation', 0);
title(ax, sprintf('%s\nslope=%.2f, p=%s, n=%d', ...
    char(string(task)), fixedSlope, Quad_format_pvalue(pValue), ...
    numel(participantIDs)), 'FontWeight', 'normal', 'FontSize', 26);
box(ax, 'off');
Quad_finish_group_color_key(ax, colorConfig);

fileStem = sprintf('%s_%s_ReportedVsRealVisualAngle', ...
    char(string(tblName)), char(string(task)));
exportgraphics(figH, fullfile(resultsDir, [fileStem '.png']), ...
    'Resolution', 600);

if saveLME
    reportOpts = struct();
    reportOpts.ReportTitle = sprintf( ...
        'Quad Perceived Size LME Report: %s task', char(string(task)));
    reportOpts.GeneratedBy = mfilename;
    reportOpts.SourceFile = sprintf('%s (input table)', char(string(tblName)));
    reportOpts.ModelLabel = ...
        'Reported visual angle predicted by real visual angle';
    reportOpts.Task = char(string(task));
    reportOpts.SummaryLines = { ...
        sprintf('Rows in task model: %d', height(taskTbl)), ...
        sprintf('Participants in task: %d', numel(participantIDs)), ...
        sprintf('Participant coloring: %s', char(string(colorConfig.Mode)))};
    write_lme_stats_report(lmeByAngle, ...
        fullfile(resultsDir, [fileStem '.txt']), reportOpts);
end
end
