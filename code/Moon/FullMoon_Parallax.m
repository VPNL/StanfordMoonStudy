function [models, lme_PM_by_parallax_and_task, tablewithParallax, ...
    sorteduniqueIDD, figHandles] = ...
    FullMoon_Parallax(dataDir, datafile, task, ResultsDir, saveLME)
% FullMoon_Parallax Linear perceived-parallax analyses for Full Moon data.
%
% The selected task supplies the left parallax-by-elevation panel. The two
% right panels show task-specific PM-by-parallax models. No log models are
% fitted. A combined RI model tests the parallax-by-task interaction.

if nargin < 3 || isempty(task), task = 'Perceptual'; end
if nargin < 4 || isempty(ResultsDir), ResultsDir = pwd; end
if nargin < 5 || isempty(saveLME), saveLME = true; end
if ~exist(ResultsDir, 'dir'), mkdir(ResultsDir); end

[dataPath, tableName] = local_data_path(dataDir, datafile);
tablewithParallax = FullMoon_Parallax_prepare_table(dataPath, []);
taskData = tablewithParallax(strcmpi(string(tablewithParallax.Task), string(task)), :);
perceptualData = tablewithParallax(strcmpi(string(tablewithParallax.Task), 'Perceptual'), :);
adjustedData = tablewithParallax(strcmpi(string(tablewithParallax.Task), 'Adjusted'), :);
if isempty(taskData) || isempty(perceptualData) || isempty(adjustedData)
    error('Selected, Perceptual, and Adjusted task rows are required.');
end

models = struct();
models.parallaxByElevationRI = fitlme(taskData, ...
    'PerceivedParallax ~ Elevation + (1|ID)');
models.parallaxByElevationRS = fitlme(taskData, ...
    'PerceivedParallax ~ Elevation + (Elevation|ID)');
models.parallaxByElevationRIvsRS = compare( ...
    models.parallaxByElevationRI, models.parallaxByElevationRS);

models.perceptualRI = fitlme(perceptualData, ...
    'Ratio_Visual_Angle ~ PerceivedParallax + (1|ID)');
models.perceptualRS = fitlme(perceptualData, ...
    ['Ratio_Visual_Angle ~ PerceivedParallax + ' ...
     '(PerceivedParallax|ID)']);
models.perceptualRIvsRS = compare(models.perceptualRI, models.perceptualRS);

models.adjustedRI = fitlme(adjustedData, ...
    'Ratio_Visual_Angle ~ PerceivedParallax + (1|ID)');
models.adjustedRS = fitlme(adjustedData, ...
    ['Ratio_Visual_Angle ~ PerceivedParallax + ' ...
     '(PerceivedParallax|ID)']);
models.adjustedRIvsRS = compare(models.adjustedRI, models.adjustedRS);

lme_PM_by_parallax_and_task = fitlme(tablewithParallax, ...
    'Ratio_Visual_Angle ~ PerceivedParallax*Task + (1|ID)');
models.pmByParallaxAndTaskRI = lme_PM_by_parallax_and_task;

uniqueIDs = unique(taskData.ID);
sorteduniqueIDD = local_sort_ids_by_intercept( ...
    models.parallaxByElevationRS, uniqueIDs, 'Elevation');
taskColors = local_subject_colors(taskData.ID, sorteduniqueIDD);
perceptualColors = local_subject_colors(perceptualData.ID, sorteduniqueIDD);
adjustedColors = local_subject_colors(adjustedData.ID, sorteduniqueIDD);
nSubjects = numel(uniqueIDs);
yMax = max(tablewithParallax.Ratio_Visual_Angle) * 1.05;

figHandles = gobjects(3, 1);
figHandles(1) = local_make_figure('RI', 'RI', taskData, perceptualData, adjustedData, ...
    models.parallaxByElevationRI, models.perceptualRI, models.adjustedRI, ...
    taskColors, perceptualColors, adjustedColors, sorteduniqueIDD, task, yMax);
figHandles(2) = local_make_figure('RS', 'RS', taskData, perceptualData, adjustedData, ...
    models.parallaxByElevationRS, models.perceptualRS, models.adjustedRS, ...
    taskColors, perceptualColors, adjustedColors, sorteduniqueIDD, task, yMax);
figHandles(3) = local_make_figure('RS', 'RI', taskData, perceptualData, adjustedData, ...
    models.parallaxByElevationRS, models.perceptualRI, models.adjustedRI, ...
    taskColors, perceptualColors, adjustedColors, sorteduniqueIDD, task, yMax);

modeNames = {'RI','RS','ParallaxRS_PMRI'};
for iFigure = 1:3
    outputName = sprintf('%s_%s_FullMoon_PerceivedParallaxvsElevation_%s_%d.png', ...
        tableName, char(string(task)), modeNames{iFigure}, nSubjects);
    local_hide_axes_toolbars(figHandles(iFigure));
    exportgraphics(figHandles(iFigure), fullfile(ResultsDir, outputName), ...
        'Resolution', 600);
end

if saveLME
    reportFile = fullfile(ResultsDir, sprintf('%s_%s_FullMoon_Parallax_models.txt', ...
        tableName, char(string(task))));
    local_write_report(reportFile, models, tablewithParallax, taskData, dataPath, task);
end
end

function figHandle = local_make_figure(parallaxMode, pmMode, taskData, perceptualData, ...
    adjustedData, parallaxModel, perceptualModel, adjustedModel, taskColors, ...
    perceptualColors, adjustedColors, sortedIDs, task, yMax)
figHandle = figure('Color', 'w', 'Units', 'normalized', ...
    'Position', [0 0 .95 .62], ...
    'Name', ['FullMoon_Parallax_' parallaxMode '_PM_' pmMode]);

% Keep the PM panels visually grouped and separate the physical-elevation
% experiment with a larger first-to-second panel gap.
ax1 = axes(figHandle, 'Position', [.055 .13 .255 .64]);
local_plot_parallax(ax1, taskData, parallaxModel, taskColors, sortedIDs, ...
    task, parallaxMode);
ax2 = axes(figHandle, 'Position', [.405 .13 .245 .64]);
local_plot_pm(ax2, perceptualData, perceptualModel, perceptualColors, ...
    sortedIDs, 'Perceptual', pmMode, yMax, false);
ax3 = axes(figHandle, 'Position', [.695 .13 .245 .64]);
local_plot_pm(ax3, adjustedData, adjustedModel, adjustedColors, ...
    sortedIDs, 'Adjusted', pmMode, yMax, true);
end

function local_plot_parallax(ax, tbl, lme, colors, sortedIDs, task, modeName)
hold(ax, 'on');
if strcmp(modeName, 'RS')
    local_plot_subject_lines(ax, tbl, lme, sortedIDs, ...
        'Elevation', 'PerceivedParallax');
end
local_plot_fixed_line(ax, tbl, lme, 'Elevation', strcmp(modeName, 'RI'));
scatter(ax, tbl.Elevation, tbl.PerceivedParallax, 42, colors, 'filled');
xlim(ax, [0 max(tbl.Elevation) * 1.05]);
ylim(ax, [0 max(tbl.PerceivedParallax) * 1.05]);
xlabel(ax, 'Elevation [deg]');
ylabel(ax, 'Perceived Parallax [deg]');
title(ax, local_title('', lme, 'Elevation'), 'FontSize', 16);
local_style(ax);
end

function local_plot_pm(ax, tbl, lme, colors, sortedIDs, taskName, ...
    modeName, yMax, hideYAxis)
hold(ax, 'on');
if strcmp(modeName, 'RS')
    local_plot_subject_lines(ax, tbl, lme, sortedIDs, ...
        'PerceivedParallax', 'Ratio_Visual_Angle');
end
local_plot_fixed_line(ax, tbl, lme, 'PerceivedParallax', strcmp(modeName, 'RI'));
scatter(ax, tbl.PerceivedParallax, tbl.Ratio_Visual_Angle, 42, colors, 'filled');
yline(ax, 1, 'Color', [.82 .82 .82], 'LineWidth', 2);
xlim(ax, [0 max(tbl.PerceivedParallax) * 1.05]);
ylim(ax, [0 yMax]);
xlabel(ax, 'Perceived Parallax [deg]');
if hideYAxis
    ylabel(ax, '');
    ax.YColor = 'w';
else
    ylabel(ax, 'Perceptual Magnification');
end
title(ax, local_title(taskName, lme, 'PerceivedParallax'), 'FontSize', 16);
local_style(ax);
if hideYAxis, ax.YColor = 'w'; end
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

function local_plot_subject_lines(ax, tbl, lme, sortedIDs, xName, ~)
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
    y = fixed(i0) + random(r0) + (fixed(iSlope) + random(rSlope)) .* x;
    plot(ax, x, y, '-', 'Color', cmap(iID, :), 'LineWidth', 1.6);
end
end

function titleText = local_title(taskName, lme, xName)
[beta, ~, stats] = fixedEffects(lme);
names = string(lme.CoefficientNames(:));
i0 = find(names == "(Intercept)", 1);
iSlope = find(names == string(xName), 1);
if strlength(string(taskName)) == 0
    titleText = sprintf('intercept=%.2f\nslope=%.2f %s\nn=%d', ...
        beta(i0), beta(iSlope), local_format_p(stats.pValue(iSlope)), ...
        numel(unique(lme.Variables.ID)));
else
    titleText = sprintf('%s\nintercept=%.2f\nslope=%.2f %s\nn=%d', ...
        char(string(taskName)), beta(i0), beta(iSlope), ...
        local_format_p(stats.pValue(iSlope)), numel(unique(lme.Variables.ID)));
end
end

function sortedIDs = local_sort_ids_by_intercept(lme, uniqueIDs, ~)
[random, names] = randomEffects(lme);
values = nan(numel(uniqueIDs), 1);
for iID = 1:numel(uniqueIDs)
    idx = find(string(names.Level) == string(uniqueIDs(iID)) & ...
        string(names.Name) == "(Intercept)", 1);
    if ~isempty(idx), values(iID) = random(idx); end
end
[~, order] = sort(values);
sortedIDs = uniqueIDs(order);
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

function local_write_report(reportFile, models, allData, taskData, dataPath, task)
opts = struct();
opts.ReportTitle = 'Full Moon Perceived Parallax and PM Report';
opts.GeneratedBy = 'FullMoon_Parallax';
opts.SourceFile = dataPath;
opts.ModelLabel = 'Linear perceived parallax by elevation RI';
opts.Task = task;
opts.SummaryLines = {
    'PerceivedParallax = Disparity_VA - Real_Visual_Angle'
    sprintf('Participants: %d', numel(unique(allData.ID)))
    sprintf('Selected-task rows: %d', height(taskData))
    sprintf('Rows across both tasks: %d', height(allData))
    'All models use untransformed linear variables; no log models are fitted.'
    'Colors are ordered by the selected-task parallax-by-elevation RS random intercept.'
    'Perceptual is the baseline in the RI task-interaction model.'
    };
opts.Models = {
    models.parallaxByElevationRI
    models.parallaxByElevationRS
    models.perceptualRI
    models.perceptualRS
    models.adjustedRI
    models.adjustedRS
    models.pmByParallaxAndTaskRI
    };
opts.ModelLabels = {
    'PerceivedParallax ~ Elevation + (1|ID)'
    'PerceivedParallax ~ Elevation + (Elevation|ID)'
    'Perceptual RI: Ratio_Visual_Angle ~ PerceivedParallax + (1|ID)'
    'Perceptual RS: Ratio_Visual_Angle ~ PerceivedParallax + (PerceivedParallax|ID)'
    'Adjusted RI: Ratio_Visual_Angle ~ PerceivedParallax + (1|ID)'
    'Adjusted RS: Ratio_Visual_Angle ~ PerceivedParallax + (PerceivedParallax|ID)'
    'Task interaction RI: Ratio_Visual_Angle ~ PerceivedParallax*Task + (1|ID)'
    };
opts.Comparisons = {
    models.parallaxByElevationRIvsRS
    models.perceptualRIvsRS
    models.adjustedRIvsRS
    };
opts.ComparisonLabels = {
    'Parallax-by-elevation RI vs RS'
    'Perceptual PM-by-parallax RI vs RS'
    'Adjusted PM-by-parallax RI vs RS'
    };
opts.RemoveGroupError = false;
write_lme_stats_report(models.parallaxByElevationRI, reportFile, opts);
end

function local_style(ax)
set(ax, 'FontName', 'Avenir', 'FontSize', 18, 'Box', 'off');
end

function value = local_format_p(p)
if p < .001, value = sprintf('p=%.2e', p); else, value = sprintf('p=%.3f', p); end
end

function local_hide_axes_toolbars(figHandle)
for ax = reshape(findall(figHandle, 'Type', 'axes'), 1, [])
    try, ax.Toolbar.Visible = 'off'; catch, end
end
drawnow;
end

function [dataPath, tableName] = local_data_path(dataDir, datafile)
if isfile(datafile), dataPath = datafile; else, dataPath = fullfile(dataDir, datafile); end
if ~isfile(dataPath) && isfile([dataPath '.csv']), dataPath = [dataPath '.csv']; end
if ~isfile(dataPath), error('Could not find input table: %s', dataPath); end
[~, tableName] = fileparts(dataPath);
end
