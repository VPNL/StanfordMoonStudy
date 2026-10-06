function [models, lme_PM_by_parallax_and_task, tablewithParallax, ...
    sorteduniqueIDD, figHandles] = ...
    FullMoon_InfinityAdjusted_Parallax(dataDir, datafile, task, ...
    ResultsDir, saveLME, sortedIDOrder)
% FULLMOON_INFINITYADJUSTED_PARALLAX Test caliper placement and parallax.
%
% This function fits only models not included in FullMoon_Parallax:
%   Caliper_Distance ~ Elevation + RI/RS by ID
%   InfinityAdjustedParallax ~ Elevation + RI/RS by ID
%
% InfinityParallax is each participant's geometric parallax for VA = 0 and
% distance approaching infinity:
%   (360/pi) * atan(6.5 / (2 * mean participant caliper distance [cm]))

% The second output is retained for interface compatibility with
% FullMoon_Parallax. No PM-by-parallax/task model is fitted here.

if nargin < 3 || isempty(task), task = 'Perceptual'; end
if nargin < 4 || isempty(ResultsDir), ResultsDir = pwd; end
if nargin < 5 || isempty(saveLME), saveLME = true; end
if nargin < 6, sortedIDOrder = []; end
if ~exist(ResultsDir, 'dir'), mkdir(ResultsDir); end

[dataSource, dataPath, tableName] = local_data_source(dataDir, datafile);
tablewithParallax = FullMoon_Parallax_prepare_table(dataSource, []);
if ~ismember('Caliper_Distance', tablewithParallax.Properties.VariableNames)
    error('FullMoon_InfinityAdjusted_Parallax:MissingCaliperDistance', ...
        'Input CSV must contain Caliper_Distance in centimeters.');
end
tablewithParallax.Caliper_Distance = double(tablewithParallax.Caliper_Distance);
taskRows = strcmpi(string(tablewithParallax.Task), string(task)) & ...
    isfinite(tablewithParallax.Caliper_Distance) & ...
    tablewithParallax.Caliper_Distance > 0;
taskData = tablewithParallax(taskRows, :);
if isempty(taskData)
    error('No valid rows were found for task %s.', char(string(task)));
end

taskData.ParticipantMeanCaliperDistance = nan(height(taskData), 1);
taskData.InfinityParallax = nan(height(taskData), 1);
ids = categories(taskData.ID);
for iID = 1:numel(ids)
    rows = taskData.ID == ids{iID};
    meanCaliperDistance = mean(taskData.Caliper_Distance(rows), 'omitnan');
    taskData.ParticipantMeanCaliperDistance(rows) = meanCaliperDistance;
    taskData.InfinityParallax(rows) = ...
        (360 / pi) * atan(6.5 / (2 * meanCaliperDistance));
end
taskData.InfinityAdjustedParallax = ...
    taskData.PerceivedParallax - taskData.InfinityParallax;

% Return the derived columns in the full table for downstream inspection.
tablewithParallax.ParticipantMeanCaliperDistance = ...
    nan(height(tablewithParallax), 1);
tablewithParallax.InfinityParallax = nan(height(tablewithParallax), 1);
tablewithParallax.InfinityAdjustedParallax = nan(height(tablewithParallax), 1);
sourceRows = find(taskRows);
tablewithParallax.ParticipantMeanCaliperDistance(sourceRows) = ...
    taskData.ParticipantMeanCaliperDistance;
tablewithParallax.InfinityParallax(sourceRows) = taskData.InfinityParallax;
tablewithParallax.InfinityAdjustedParallax(sourceRows) = ...
    taskData.InfinityAdjustedParallax;

models = struct();
models.caliperByElevationRI = fitlme(taskData, ...
    'Caliper_Distance ~ Elevation + (1|ID)', 'FitMethod', 'ML');
models.caliperByElevationRS = fitlme(taskData, ...
    'Caliper_Distance ~ Elevation + (Elevation|ID)', 'FitMethod', 'ML');
models.caliperByElevationRIvsRS = compare( ...
    models.caliperByElevationRI, models.caliperByElevationRS);
models.adjustedParallaxByElevationRI = fitlme(taskData, ...
    'InfinityAdjustedParallax ~ Elevation + (1|ID)', 'FitMethod', 'ML');
models.adjustedParallaxByElevationRS = fitlme(taskData, ...
    ['InfinityAdjustedParallax ~ Elevation + ' ...
     '(Elevation|ID)'], 'FitMethod', 'ML');
models.adjustedParallaxByElevationRIvsRS = compare( ...
    models.adjustedParallaxByElevationRI, ...
    models.adjustedParallaxByElevationRS);
lme_PM_by_parallax_and_task = [];

if isempty(sortedIDOrder)
    sorteduniqueIDD = local_sort_ids_by_intercept( ...
        models.adjustedParallaxByElevationRS, ids);
else
    sorteduniqueIDD = categorical(string(sortedIDOrder(:)));
end
colors = local_subject_colors(taskData.ID, sorteduniqueIDD);

figHandles = gobjects(2, 1);
figHandles(1) = local_make_ri_rs_figure(taskData, ...
    models.caliperByElevationRI, models.caliperByElevationRS, colors, ...
    sorteduniqueIDD, 'Caliper_Distance', 'Caliper Distance [cm]', ...
    sprintf('%s: caliper distance by elevation', char(string(task))));
figHandles(2) = local_make_ri_rs_figure(taskData, ...
    models.adjustedParallaxByElevationRI, ...
    models.adjustedParallaxByElevationRS, colors, sorteduniqueIDD, ...
    'InfinityAdjustedParallax', ...
    {'Infinity-adjusted Parallax [deg]', ...
     'Perceived - participant P_{infinity}'}, ...
    sprintf('%s: infinity-adjusted parallax by elevation', ...
    char(string(task))));

outputNames = { ...
    sprintf('%s_%s_caliper_distance_by_elevation_RI_RS.png', ...
        tableName, char(string(task))); ...
    sprintf('%s_%s_infinity_adjusted_parallax_by_elevation_RI_RS.png', ...
        tableName, char(string(task)))};
for iFigure = 1:numel(figHandles)
    local_hide_axes_toolbars(figHandles(iFigure));
    exportgraphics(figHandles(iFigure), ...
        fullfile(ResultsDir, outputNames{iFigure}), 'Resolution', 600);
end

if saveLME
    reportFile = fullfile(ResultsDir, sprintf( ...
        '%s_%s_InfinityAdjustedParallax_models.txt', ...
        tableName, char(string(task))));
    local_write_report(reportFile, models, taskData, dataPath, task);
end
end

function figHandle = local_make_ri_rs_figure(tbl, riModel, rsModel, ...
    colors, sortedIDs, responseName, yLabelText, figureTitle)
figHandle = figure('Color', 'w', 'Units', 'normalized', ...
    'Position', [0.08 0.12 0.82 0.62]);
t = tiledlayout(figHandle, 1, 2, 'Padding', 'compact', ...
    'TileSpacing', 'compact');
models = {riModel, rsModel};
panelNames = {'RI model', 'Elevation RS model'};
for iPanel = 1:2
    ax = nexttile(t); hold(ax, 'on');
    if iPanel == 2
        local_plot_subject_lines(ax, tbl, models{iPanel}, sortedIDs, ...
            'Elevation');
    end
    local_plot_fixed_line(ax, tbl, models{iPanel}, 'Elevation', iPanel == 1);
    scatter(ax, tbl.Elevation, tbl.(responseName), 42, colors, 'filled');
    xlabel(ax, 'Elevation [deg]');
    if iPanel == 1
        ylabel(ax, yLabelText);
    else
        ax.YColor = 'w';
    end
    title(ax, sprintf('%s\n%s', panelNames{iPanel}, ...
        local_title(models{iPanel}, 'Elevation')), 'FontSize', 16);
    local_style(ax);
    if iPanel == 2, ax.YColor = 'w'; end
end
title(t, figureTitle, 'FontWeight', 'bold', 'FontSize', 18);
end

function local_plot_fixed_line(ax, tbl, lme, xName, showCI)
[~, ~, stats] = fixedEffects(lme);
names = string(lme.CoefficientNames(:));
slopeIdx = find(names == string(xName), 1);
if isempty(slopeIdx) || stats.pValue(slopeIdx) >= .05, return; end
xGrid = linspace(min(tbl.(xName)), max(tbl.(xName)), 120)';
newTbl = tbl(repmat(1, numel(xGrid), 1), :);
newTbl.(xName) = xGrid;
[yGrid, yCI] = predict(lme, newTbl, 'Conditional', false);
if showCI
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
        [.75 .75 .75], 'FaceAlpha', .4, 'EdgeColor', 'none');
end
plot(ax, xGrid, yGrid, 'k-', 'LineWidth', 3);
end

function local_plot_subject_lines(ax, tbl, lme, sortedIDs, xName)
[fixed, ~] = fixedEffects(lme);
[random, names] = randomEffects(lme);
coefNames = string(lme.CoefficientNames(:));
i0 = find(coefNames == "(Intercept)", 1);
iSlope = find(coefNames == string(xName), 1);
nameText = string(names.Name);
levelText = string(names.Level);
cmap = purpleVioletBlueTurquoiseColorMap(numel(sortedIDs));
for iID = 1:numel(sortedIDs)
    id = string(sortedIDs(iID));
    rows = string(tbl.ID) == id;
    if nnz(rows) < 2, continue; end
    r0 = find(levelText == id & nameText == "(Intercept)", 1);
    rSlope = find(levelText == id & nameText == string(xName), 1);
    if isempty(r0) || isempty(rSlope), continue; end
    x = [min(tbl.(xName)(rows)), max(tbl.(xName)(rows))];
    y = fixed(i0) + random(r0) + ...
        (fixed(iSlope) + random(rSlope)) .* x;
    plot(ax, x, y, '-', 'Color', cmap(iID, :), 'LineWidth', 1.6);
end
end

function titleText = local_title(lme, xName)
[beta, ~, stats] = fixedEffects(lme);
names = string(lme.CoefficientNames(:));
i0 = find(names == "(Intercept)", 1);
iSlope = find(names == string(xName), 1);
titleText = sprintf('intercept=%.2f\nslope=%.3g %s\nn=%d', ...
    beta(i0), beta(iSlope), local_format_p(stats.pValue(iSlope)), ...
    numel(unique(lme.Variables.ID)));
end

function sortedIDs = local_sort_ids_by_intercept(lme, ids)
[random, names] = randomEffects(lme);
values = nan(numel(ids), 1);
for iID = 1:numel(ids)
    idx = find(string(names.Level) == string(ids{iID}) & ...
        string(names.Name) == "(Intercept)", 1);
    if ~isempty(idx), values(iID) = random(idx); end
end
[~, order] = sort(values);
sortedIDs = categorical(ids(order));
end

function colors = local_subject_colors(ids, sortedIDs)
cmap = purpleVioletBlueTurquoiseColorMap(numel(sortedIDs));
colors = zeros(numel(ids), 3);
for iRow = 1:numel(ids)
    idx = find(string(sortedIDs) == string(ids(iRow)), 1);
    if isempty(idx), idx = 1; end
    colors(iRow, :) = cmap(idx, :);
end
end

function local_write_report(reportFile, models, taskData, dataPath, task)
opts = struct();
opts.ReportTitle = 'Full Moon Infinity-Adjusted Parallax Report';
opts.GeneratedBy = 'FullMoon_InfinityAdjusted_Parallax';
opts.SourceFile = dataPath;
opts.ModelLabel = 'Caliper distance by elevation RI';
opts.Task = task;
opts.SummaryLines = {
    'Caliper_Distance is measured in centimeters.'
    ['InfinityParallax_ID = (360/pi)*atan(6.5/' ...
     '(2*mean(Caliper_Distance_ID))).']
    ['InfinityAdjustedParallax = PerceivedParallax - ' ...
     'InfinityParallax_ID.']
    sprintf('Participants: %d', numel(unique(taskData.ID)))
    sprintf('Selected-task rows: %d', height(taskData))
    ['Only the new caliper-distance and infinity-adjusted models are ' ...
     'fitted; FullMoon_Parallax models are not repeated.']
    };
opts.Models = {
    models.caliperByElevationRI
    models.caliperByElevationRS
    models.adjustedParallaxByElevationRI
    models.adjustedParallaxByElevationRS
    };
opts.ModelLabels = {
    'Caliper_Distance ~ Elevation + (1|ID)'
    'Caliper_Distance ~ Elevation + (Elevation|ID)'
    'InfinityAdjustedParallax ~ Elevation + (1|ID)'
    'InfinityAdjustedParallax ~ Elevation + (Elevation|ID)'
    };
opts.Comparisons = {
    models.caliperByElevationRIvsRS
    models.adjustedParallaxByElevationRIvsRS
    };
opts.ComparisonLabels = {
    'Caliper distance by elevation RI vs RS'
    'Infinity-adjusted parallax by elevation RI vs RS'
    };
opts.RemoveGroupError = false;
write_lme_stats_report(models.caliperByElevationRI, reportFile, opts);
end

function local_style(ax)
set(ax, 'FontName', 'Avenir', 'FontSize', 18, 'Box', 'off');
end

function value = local_format_p(p)
if p < .001
    value = sprintf('p=%.2e', p);
else
    value = sprintf('p=%.3f', p);
end
end

function local_hide_axes_toolbars(figHandle)
for ax = reshape(findall(figHandle, 'Type', 'axes'), 1, [])
    try, ax.Toolbar.Visible = 'off'; catch, end
end
drawnow;
end

function [dataSource, dataPath, tableName] = local_data_source(dataDir, datafile)
if istable(dataDir)
    dataSource = dataDir;
    dataPath = char(string(datafile));
    if isempty(dataPath), dataPath = 'filtered Full Moon table'; end
    [~, tableName] = fileparts(dataPath);
    if isempty(tableName), tableName = 'FullMoonData'; end
    return;
end
if isfile(datafile)
    dataPath = datafile;
else
    dataPath = fullfile(dataDir, datafile);
end
if ~isfile(dataPath) && isfile([dataPath '.csv'])
    dataPath = [dataPath '.csv'];
end
if ~isfile(dataPath), error('Could not find input table: %s', dataPath); end
[~, tableName] = fileparts(dataPath);
dataSource = dataPath;
end
