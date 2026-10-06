function [models, combinedTable, figHandle, colorOrder] = ...
    Combined_InfinityAdjustedParallax_by_ElevationStudy( ...
    moonFile, quadFile, ResultsDir, saveLME)
% COMBINED_INFINITYADJUSTEDPARALLAX_BY_ELEVATIONSTUDY
% Combine Moon and Quad parallax data and test elevation effects by study.
%
% Infinity parallax is calculated separately for every participant within
% each study using that participant's mean caliper distance:
%   P_infinity = (360/pi) * atan(6.5 / (2 * mean(caliper distance [cm])))
%
% Shared participant IDs remain the same categorical ID across studies.

if nargin < 3 || isempty(ResultsDir), ResultsDir = pwd; end
if nargin < 4 || isempty(saveLME), saveLME = true; end
if ~exist(ResultsDir, 'dir'), mkdir(ResultsDir); end

moonTable = local_prepare_moon(moonFile);
quadTable = local_prepare_quad(quadFile);
combinedTable = [moonTable; quadTable];
combinedTable.ID = categorical(string(combinedTable.ID));
combinedTable.Study = categorical(string(combinedTable.Study), ...
    {'Quad', 'Moon'});

combinedTable.ParticipantMeanCaliperDistance = nan(height(combinedTable), 1);
combinedTable.InfinityParallax = nan(height(combinedTable), 1);
studyNames = categories(combinedTable.Study);
ids = categories(combinedTable.ID);
for iStudy = 1:numel(studyNames)
    for iID = 1:numel(ids)
        rows = combinedTable.Study == studyNames{iStudy} & ...
            combinedTable.ID == ids{iID};
        if ~any(rows), continue; end
        meanCaliperDistance = mean( ...
            combinedTable.Caliper_Distance(rows), 'omitnan');
        combinedTable.ParticipantMeanCaliperDistance(rows) = ...
            meanCaliperDistance;
        combinedTable.InfinityParallax(rows) = ...
            (360 / pi) * atan(6.5 / (2 * meanCaliperDistance));
    end
end
combinedTable.InfinityAdjustedParallax = ...
    combinedTable.PerceivedParallax - combinedTable.InfinityParallax;

models = struct();
models.adjustedAdditiveRS = fitlme(combinedTable, ...
    ['InfinityAdjustedParallax ~ Elevation + Study + ' ...
     '(Elevation|ID)'], 'FitMethod', 'ML');
models.adjustedAdditiveRI = fitlme(combinedTable, ...
    'InfinityAdjustedParallax ~ Elevation + Study + (1|ID)', ...
    'FitMethod', 'ML');
models.adjustedInteractionRI = fitlme(combinedTable, ...
    'InfinityAdjustedParallax ~ 1 + Elevation*Study + (1|ID)', ...
    'FitMethod', 'ML');
models.adjustedInteractionRS = fitlme(combinedTable, ...
    'InfinityAdjustedParallax ~ 1 + Elevation*Study + (Elevation|ID)', ...
    'FitMethod', 'ML');
models.adjustedAdditiveVsInteraction = compare( ...
    models.adjustedAdditiveRI, models.adjustedInteractionRI);
models.adjustedInteractionRIvsRS = compare( ...
    models.adjustedInteractionRI, models.adjustedInteractionRS);
models.adjustedAdditiveVsInteractionRS = compare( ...
    models.adjustedAdditiveRS, models.adjustedInteractionRS);
models.parallaxAdditiveRI = fitlme(combinedTable, ...
    'PerceivedParallax ~ Elevation + Study + (1|ID)', ...
    'FitMethod', 'ML');
models.parallaxInteractionRI = fitlme(combinedTable, ...
    'PerceivedParallax ~ 1 + Study*Elevation + (1|ID)', ...
    'FitMethod', 'ML');
models.parallaxAdditiveVsInteraction = compare( ...
    models.parallaxAdditiveRI, models.parallaxInteractionRI);

[participantMeans, colorOrder] = local_participant_means(combinedTable);
pointValues = local_map_participant_values(combinedTable.ID, ...
    colorOrder, participantMeans);
figHandle = local_plot_models(combinedTable, models, pointValues, ...
    participantMeans);
local_hide_axes_toolbars(figHandle);

[~, moonName] = fileparts(char(string(moonFile)));
[~, quadName] = fileparts(char(string(quadFile)));
prefix = sprintf('combined_%s_%s', moonName, quadName);
exportgraphics(figHandle, fullfile(ResultsDir, ...
    [prefix '_InfinityAdjustedParallax_Elevation_Study.png']), ...
    'Resolution', 600);
writetable(combinedTable, fullfile(ResultsDir, ...
    [prefix '_InfinityAdjustedParallax_data.csv']));

if saveLME
    formulas = {
        ['InfinityAdjustedParallax ~ Elevation + Study + ' ...
         '(Elevation|ID)']
        'InfinityAdjustedParallax ~ Elevation + Study + (1|ID)'
        'InfinityAdjustedParallax ~ 1 + Elevation*Study + (1|ID)'
        ['InfinityAdjustedParallax ~ 1 + Elevation*Study + ' ...
         '(Elevation|ID)']
        'PerceivedParallax ~ Elevation + Study + (1|ID)'
        'PerceivedParallax ~ 1 + Study*Elevation + (1|ID)'
        };
    modelList = {models.adjustedAdditiveRS, models.adjustedAdditiveRI, ...
        models.adjustedInteractionRI, models.adjustedInteractionRS, ...
        models.parallaxAdditiveRI, models.parallaxInteractionRI};
    reportFile = fullfile(ResultsDir, [prefix '_models.txt']);
    local_write_report(reportFile, models, modelList, formulas, ...
        combinedTable, moonFile, quadFile);
    write_lme_fixed_effects_summary_csv(prefix, formulas, modelList, ...
        fullfile(ResultsDir, [prefix '_model_coefficients.csv']));
end
end

function tbl = local_prepare_moon(moonFile)
if ~isfile(moonFile), error('Moon CSV not found: %s', moonFile); end
source = readtable(moonFile, 'VariableNamingRule', 'preserve');
required = {'ID', 'Task', 'Elevation', 'Real_Visual_Angle', ...
    'Disparity_VA', 'Caliper_Distance'};
local_require_variables(source, required, 'Moon');
source = source(strcmpi(string(source.Task), 'Perceptual'), :);
tbl = table();
tbl.ID = string(source.ID);
tbl.Study = repmat("Moon", height(source), 1);
tbl.Elevation = double(source.Elevation);
tbl.PerceivedParallax = double(source.Disparity_VA) - ...
    double(source.Real_Visual_Angle);
tbl.Caliper_Distance = double(source.Caliper_Distance);
tbl = local_keep_valid(tbl);
end

function tbl = local_prepare_quad(quadFile)
if ~isfile(quadFile), error('Quad CSV not found: %s', quadFile); end
source = readtable(quadFile, 'VariableNamingRule', 'preserve');
required = {'ID', 'Observer_Elevation', 'Caliper1_Distance', ...
    'Caliper2_Distance'};
local_require_variables(source, required, 'Quad');
if all(ismember({'Disparity1', 'Disparity2'}, ...
        source.Properties.VariableNames))
    perceivedParallax = mean([double(source.Disparity1), ...
        double(source.Disparity2)], 2, 'omitnan');
elseif ismember('Disparity', source.Properties.VariableNames)
    perceivedParallax = double(source.Disparity);
elseif ismember('MeanDisparity', source.Properties.VariableNames)
    perceivedParallax = double(source.MeanDisparity);
else
    error('Quad data need Disparity1/Disparity2, Disparity, or MeanDisparity.');
end
tbl = table();
tbl.ID = string(source.ID);
tbl.Study = repmat("Quad", height(source), 1);
tbl.Elevation = double(source.Observer_Elevation);
tbl.PerceivedParallax = perceivedParallax;
tbl.Caliper_Distance = mean([double(source.Caliper1_Distance), ...
    double(source.Caliper2_Distance)], 2, 'omitnan');
tbl = local_keep_valid(tbl);
end

function tbl = local_keep_valid(tbl)
keep = ~ismissing(tbl.ID) & tbl.ID ~= "" & ...
    isfinite(tbl.Elevation) & isfinite(tbl.PerceivedParallax) & ...
    isfinite(tbl.Caliper_Distance) & tbl.Caliper_Distance > 0;
tbl = tbl(keep, :);
end

function local_require_variables(tbl, required, label)
missing = required(~ismember(required, tbl.Properties.VariableNames));
if ~isempty(missing)
    error('%s data are missing: %s.', label, strjoin(missing, ', '));
end
end

function [means, sortedIDs] = local_participant_means(tbl)
ids = unique(string(tbl.ID));
means = nan(numel(ids), 1);
for iID = 1:numel(ids)
    means(iID) = mean(tbl.InfinityAdjustedParallax( ...
        string(tbl.ID) == ids(iID)), 'omitnan');
end
[means, order] = sort(means);
sortedIDs = ids(order);
end

function values = local_map_participant_values(ids, sortedIDs, means)
values = nan(numel(ids), 1);
for iID = 1:numel(sortedIDs)
    values(string(ids) == sortedIDs(iID)) = means(iID);
end
end

function fig = local_plot_models(tbl, models, colorValues, participantMeans)
fig = figure('Color', 'w', 'Units', 'normalized', ...
    'Position', [0.04 0.12 0.90 0.64]);
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', ...
    'TileSpacing', 'compact');
cmap = purpleVioletBlueTurquoiseColorMap(256);
colorLimits = [min(participantMeans), max(participantMeans)];
if diff(colorLimits) <= 0, colorLimits = colorLimits + [-0.5 0.5]; end

ax1 = nexttile(t); hold(ax1, 'on');
local_plot_study_lines(ax1, tbl, models.adjustedInteractionRI);
local_scatter_by_study(ax1, tbl, colorValues, ...
    'InfinityAdjustedParallax');
local_set_ylim_ignoring_single_extreme(ax1, ...
    tbl.InfinityAdjustedParallax);
xlabel(ax1, 'Elevation [deg]');
ylabel(ax1, {'Infinity-adjusted Parallax [deg]', ...
    'Perceived - participant P_{infinity}'});
title(ax1, local_model_title(models.adjustedInteractionRI, ...
    'Adjusted parallax elevation x study RI model'), 'Interpreter', 'none');

ax2 = nexttile(t); hold(ax2, 'on');
local_plot_study_lines(ax2, tbl, models.parallaxInteractionRI);
local_scatter_by_study(ax2, tbl, colorValues, 'PerceivedParallax');
xlabel(ax2, 'Elevation [deg]');
ylabel(ax2, 'Perceived Parallax [deg]');
title(ax2, local_model_title(models.parallaxInteractionRI, ...
    'Parallax elevation x study RI model'), 'Interpreter', 'none');

for ax = [ax1 ax2]
    colormap(ax, cmap);
    clim(ax, colorLimits);
    set(ax, 'FontName', 'Avenir', 'FontSize', 15, 'Box', 'off');
end
cb = colorbar(ax2, 'eastoutside');
cb.Label.String = {'Mean participant', 'infinity-adjusted parallax [deg]'};
cb.Label.FontSize = 16;
legend(ax2, 'Location', 'best', 'Box', 'off');
title(t, 'Combined Quad and Moon elevation analyses', ...
    'FontWeight', 'bold', 'FontSize', 18);
end

function local_scatter_by_study(ax, tbl, colorValues, responseName)
isQuad = tbl.Study == 'Quad';
scatter(ax, tbl.Elevation(isQuad), tbl.(responseName)(isQuad), ...
    34, colorValues(isQuad), 'o', 'filled', 'MarkerFaceAlpha', 0.75, ...
    'HandleVisibility', 'off');
scatter(ax, tbl.Elevation(~isQuad), tbl.(responseName)(~isQuad), ...
    42, colorValues(~isQuad), 's', 'filled', 'MarkerFaceAlpha', 0.75, ...
    'HandleVisibility', 'off');
end

function local_plot_study_lines(ax, tbl, lme)
styles = {'-', '--'};
labels = {'Quad fit', 'Moon fit'};
studyNames = {'Quad', 'Moon'};
for iStudy = 1:2
    rows = tbl.Study == studyNames{iStudy};
    xGrid = linspace(min(tbl.Elevation(rows)), ...
        max(tbl.Elevation(rows)), 150)';
    predTbl = tbl(repmat(find(rows, 1), numel(xGrid), 1), :);
    predTbl.Elevation = xGrid;
    predTbl.Study = categorical(repmat(string(studyNames{iStudy}), ...
        numel(xGrid), 1), {'Quad', 'Moon'});
    [yHat, yCI] = predict(lme, predTbl, 'Conditional', false);
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
        [0.72 0.72 0.72], 'FaceAlpha', 0.22, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(ax, xGrid, yHat, styles{iStudy}, 'Color', 'k', ...
        'LineWidth', 2.8, 'DisplayName', labels{iStudy});
end
end

function local_set_ylim_ignoring_single_extreme(ax, y)
y = y(isfinite(y));
if numel(y) < 4, return; end
center = median(y);
robustScale = 1.4826 * median(abs(y - center));
if robustScale <= 0, return; end
[largestDeviation, extremeIndex] = max(abs(y - center));
if largestDeviation <= 6 * robustScale, return; end
y(extremeIndex) = [];
yMin = min(y);
yMax = max(y);
padding = 0.06 * max(yMax - yMin, eps);
ylim(ax, [yMin - padding, yMax + padding]);
end

function textValue = local_model_title(lme, heading)
coef = lme.Coefficients;
elevationRow = strcmp(string(coef.Name), 'Elevation');
interactionRow = contains(string(coef.Name), 'Elevation:Study') | ...
    contains(string(coef.Name), 'Study_Moon:Elevation');
textValue = sprintf('%s\nElevation slope=%.3g, %s\nn=%d', ...
    heading, coef.Estimate(elevationRow), ...
    local_format_p(coef.pValue(elevationRow)), ...
    numel(unique(lme.Variables.ID)));
if any(interactionRow)
    textValue = sprintf('%s\nElevation x Study: %s', textValue, ...
        local_format_p(coef.pValue(interactionRow)));
end
end

function local_write_report(reportFile, models, modelList, formulas, ...
    tbl, moonFile, quadFile)
opts = struct();
opts.ReportTitle = 'Combined Moon and Quad Infinity-Adjusted Parallax Report';
opts.GeneratedBy = 'Combined_InfinityAdjustedParallax_by_ElevationStudy';
opts.SourceFile = sprintf('Moon: %s | Quad: %s', moonFile, quadFile);
opts.ModelLabel = formulas{1};
opts.SummaryLines = {
    sprintf('Combined rows: %d', height(tbl))
    sprintf('Unique participants: %d', numel(unique(tbl.ID)))
    sprintf('Moon rows: %d', nnz(tbl.Study == 'Moon'))
    sprintf('Quad rows: %d', nnz(tbl.Study == 'Quad'))
    ['Shared IDs are treated as the same participant across studies. ' ...
     'Infinity baselines are computed within participant and study.']
    ['Dots are colored by participant mean infinity-adjusted parallax ' ...
     'across both studies.']
    };
opts.Models = modelList;
opts.ModelLabels = formulas;
opts.ComparisonLabels = { ...
    'Infinity-adjusted parallax additive RI vs Elevation x Study RI'
    'Infinity-adjusted parallax Elevation x Study RI vs RS'
    'Infinity-adjusted parallax additive RS vs Elevation x Study RS'
    'Raw parallax additive RI vs Elevation x Study RI'
    };
opts.Comparisons = {
    models.adjustedAdditiveVsInteraction
    models.adjustedInteractionRIvsRS
    models.adjustedAdditiveVsInteractionRS
    models.parallaxAdditiveVsInteraction
    };
opts.RemoveGroupError = false;
write_lme_stats_report(models.adjustedAdditiveRS, reportFile, opts);
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
