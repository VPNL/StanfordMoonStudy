function results = FullMoon_PM_test_elevation_models(dataDir, datafile, ResultsDir, lmeStore, taskOrder, transformOrder)
% FullMoon_PM_test_elevation_models
%
% Build supplemental model-comparison figures for moon PM vs elevation.
% For each task, this function:
%   1) fits linear RI and RS models in PM space
%   2) refits RS log-space elevation models for each transform in lmeStore
%   3) compares RI vs RS within each model family
%   4) builds a leaderboard across the linear and transformed models
%   5) plots a 1 x N figure with one linear PM panel plus log-model panels
%   6) writes readable stats reports and csv outputs

if nargin < 5 || isempty(taskOrder)
    taskOrder = fieldnames(lmeStore);
end
if ischar(taskOrder) || isstring(taskOrder)
    taskOrder = cellstr(taskOrder);
end
if nargin < 6 || isempty(transformOrder)
    transformOrder = {'Elevation','ElevationD90','ElevationRAD'};
end

basename = erase(datafile, '.csv');
all_data = readtable(fullfile(dataDir, datafile));
all_data = all_data(~isnan(all_data.Reported_Visual_Angle), :);
all_data.logRatio = log2(all_data.Ratio_Visual_Angle);
all_data.logElevation = log2(all_data.Elevation + 1);
all_data.ElevationD90 = all_data.Elevation / 90;
all_data.logElevationD90 = log2(all_data.ElevationD90 + 1);
all_data.ElevationRAD = pi * all_data.Elevation / 180;
all_data.logElevationRAD = log2(all_data.ElevationRAD + 1);

comparisonRows = {};
leaderboardRows = {};
results = struct();

for t = 1:numel(taskOrder)
    task = taskOrder{t};
    task_data = all_data(strcmp(all_data.Task, task), :);
    if isempty(task_data)
        continue;
    end

    lme_linear_RI = fitlme(task_data, 'Ratio_Visual_Angle ~ Elevation + (1|ID)');
    lme_linear_RS = fitlme(task_data, 'Ratio_Visual_Angle ~ Elevation + (Elevation|ID)');
    cmp_linear = local_safe_compare(lme_linear_RI, lme_linear_RS);
    comparisonRows(end+1,:) = local_build_compare_row(task, "Linear", lme_linear_RI, lme_linear_RS, cmp_linear); %#ok<AGROW>
    leaderboardRows(end+1,:) = local_build_leaderboard_rows(task, "Linear", "RI", lme_linear_RI); %#ok<AGROW>
    leaderboardRows(end+1,:) = local_build_leaderboard_rows(task, "Linear", "RS", lme_linear_RS); %#ok<AGROW>

    availableTransforms = {};
    riModels = {};
    rsModels = {};
    familyComparisons = {cmp_linear};
    familyComparisonLabels = {'model_comp_Linear'};
    for k = 1:numel(transformOrder)
        tf = transformOrder{k};
        if ~isfield(lmeStore.(task), tf)
            continue;
        end
        availableTransforms{end+1} = tf; %#ok<AGROW>
        riModels{end+1} = lmeStore.(task).(tf); %#ok<AGROW>
        rsModels{end+1} = local_fit_log_rs_model(task_data, tf); %#ok<AGROW>
        cmp_family = local_safe_compare(riModels{end}, rsModels{end});
        comparisonRows(end+1,:) = local_build_compare_row(task, string(tf), riModels{end}, rsModels{end}, cmp_family); %#ok<AGROW>
        familyComparisons{end+1} = cmp_family; %#ok<AGROW>
        familyComparisonLabels{end+1} = sprintf('model_comp_%s', tf); %#ok<AGROW>
        leaderboardRows(end+1,:) = local_build_leaderboard_rows(task, string(tf), "RI", riModels{end}); %#ok<AGROW>
        leaderboardRows(end+1,:) = local_build_leaderboard_rows(task, string(tf), "RS", rsModels{end}); %#ok<AGROW>
    end

    [subjectcolor, cmap, sorted_idx, uniqueID] = local_build_subject_colors(task_data, rsModels, availableTransforms);
    local_plot_elevation_model_comparison(task_data, task, basename, ResultsDir, ...
        lme_linear_RS, rsModels, availableTransforms, subjectcolor, cmap, sorted_idx, uniqueID);

    taskLeaderboard = local_finalize_leaderboard(leaderboardRows, task);
    results.(task).leaderboardTbl = taskLeaderboard;
    results.(task).comparisonTbl = local_finalize_comparison_table(comparisonRows, task);
    writetable(taskLeaderboard, fullfile(ResultsDir, sprintf('%s_%s_Supp_Fig_Elevation_model_leaderboard.csv', basename, task)));
    local_plot_model_leaderboard(taskLeaderboard, ...
        fullfile(ResultsDir, sprintf('%s_%s_Supp_Fig_Elevation_model_leaderboard.png', basename, task)), ...
        sprintf('%s elevation model leaderboard', task));

    summaryLines = {
        sprintf('Task: %s', task)
        sprintf('Subjects: %d', numel(unique(task_data.ID)))
        sprintf('Rows: %d', height(task_data))
        sprintf('Median PM: %.2f', median(task_data.Ratio_Visual_Angle))
        sprintf('Mean PM: %.2f', mean(task_data.Ratio_Visual_Angle))
        sprintf('PM SD: %.2f', std(task_data.Ratio_Visual_Angle))
        sprintf('Best model by AIC: %s', taskLeaderboard.ModelLabel{1})
        sprintf('Best model by BIC: %s', taskLeaderboard.ModelLabel{find(taskLeaderboard.BICRank == 1, 1, 'first')})
        };
    models = [{lme_linear_RI, lme_linear_RS}, riModels, rsModels];
    modelLabels = [{'lme_linear_RI', 'lme_linear_RS'}, ...
        cellfun(@(tf) sprintf('lme_%s_RI', tf), availableTransforms, 'UniformOutput', false), ...
        cellfun(@(tf) sprintf('lme_%s_RS', tf), availableTransforms, 'UniformOutput', false)];

    reportFile = fullfile(ResultsDir, sprintf('%s_%s_Supp_Fig_Elevation_model_comps.txt', basename, task));
    write_moon_lme_report(reportFile, ...
        sprintf('%s Moon elevation model comparisons', task), ...
        summaryLines, models, modelLabels, familyComparisons, familyComparisonLabels);
end

results.comparisonTbl = local_finalize_comparison_table(comparisonRows);
results.leaderboardTbl = local_finalize_leaderboard(leaderboardRows);
writetable(results.comparisonTbl, fullfile(ResultsDir, [basename '_Supp_Fig_Elevation_model_RS_vs_RI.csv']));
writetable(results.leaderboardTbl, fullfile(ResultsDir, [basename '_Supp_Fig_Elevation_model_leaderboard.csv']));
local_plot_model_leaderboard(results.leaderboardTbl, ...
    fullfile(ResultsDir, [basename '_Supp_Fig_Elevation_model_leaderboard.png']), ...
    'Moon elevation model leaderboard');
end

function cmp = local_safe_compare(lme1, lme2)
try
    cmp = compare(lme1, lme2);
catch ME
    cmp = sprintf('Model comparison failed: %s', ME.message);
end
end

function rsModel = local_fit_log_rs_model(task_data, transformLabel)
switch transformLabel
    case 'Elevation'
        rsModel = fitlme(task_data, 'logRatio ~ logElevation + (Elevation|ID)');
    case 'ElevationD90'
        rsModel = fitlme(task_data, 'logRatio ~ logElevationD90 + (logElevationD90|ID)');
    case 'ElevationRAD'
        rsModel = fitlme(task_data, 'logRatio ~ logElevationRAD + (ElevationRAD|ID)');
    otherwise
        error('Unsupported transform label %s.', transformLabel);
end
end

function row = local_build_compare_row(task, familyLabel, lmeRI, lmeRS, cmp)
cmpP = NaN; cmpStat = NaN; cmpDF = NaN;
if isa(cmp, 'table')
    if ismember('pValue', cmp.Properties.VariableNames), cmpP = cmp.pValue(end); end
    if ismember('LRStat', cmp.Properties.VariableNames), cmpStat = cmp.LRStat(end); end
    if ismember('deltaDF', cmp.Properties.VariableNames), cmpDF = cmp.deltaDF(end); end
end
bestAIC = "RI";
bestBIC = "RI";
if lmeRS.ModelCriterion.AIC < lmeRI.ModelCriterion.AIC, bestAIC = "RS"; end
if lmeRS.ModelCriterion.BIC < lmeRI.ModelCriterion.BIC, bestBIC = "RS"; end
row = {string(task), string(familyLabel), ...
    lmeRI.ModelCriterion.AIC, lmeRS.ModelCriterion.AIC, ...
    lmeRI.ModelCriterion.BIC, lmeRS.ModelCriterion.BIC, ...
    bestAIC, bestBIC, cmpStat, cmpDF, cmpP};
end

function rows = local_build_leaderboard_rows(task, familyLabel, effectLabel, lme)
rows = {string(task), string(familyLabel), string(effectLabel), ...
    string(sprintf('%s_%s', familyLabel, effectLabel)), ...
    lme.ModelCriterion.AIC, lme.ModelCriterion.BIC};
end

function tbl = local_finalize_comparison_table(rows, task)
if nargin >= 2
    mask = cellfun(@(x) isequal(string(x), string(task)), rows(:,1));
    rows = rows(mask,:);
end
tbl = cell2table(rows, 'VariableNames', ...
    {'Task','Family','AIC_RI','AIC_RS','BIC_RI','BIC_RS','BestByAIC','BestByBIC','LRStat','deltaDF','pValue'});
end

function tbl = local_finalize_leaderboard(rows, task)
if nargin >= 2
    mask = cellfun(@(x) isequal(string(x), string(task)), rows(:,1));
    rows = rows(mask,:);
end
tbl = cell2table(rows, 'VariableNames', ...
    {'Task','Family','EffectType','ModelLabel','AIC','BIC'});
[~, aicOrder] = sort(tbl.AIC, 'ascend');
[~, bicOrder] = sort(tbl.BIC, 'ascend');
tbl.AICRank = zeros(height(tbl),1);
tbl.BICRank = zeros(height(tbl),1);
tbl.AICRank(aicOrder) = 1:height(tbl);
tbl.BICRank(bicOrder) = 1:height(tbl);
tbl = sortrows(tbl, {'AICRank','BICRank'});
end

function [subjectcolor, cmap, sorted_idx, uniqueID] = local_build_subject_colors(task_data, rsModels, availableTransforms)
ID = task_data.ID;
uniqueID = unique(ID);
nsubjects = numel(uniqueID);
cmap = jet(nsubjects);

refIdx = find(strcmp(availableTransforms, 'Elevation'), 1, 'first');
if isempty(refIdx)
    refIdx = 1;
end
refModel = rsModels{refIdx};
[reEfx, reNames] = randomEffects(refModel);
[feEfx, ~, ~] = fixedEffects(refModel);
individualIntercepts = zeros(nsubjects,1);
for i = 1:nsubjects
    subjectRows = find(strcmp(reNames.Level, num2str(uniqueID(i))));
    individualIntercepts(i) = feEfx(1) + reEfx(subjectRows(1));
end
[~, sorted_idx] = sort(individualIntercepts);

subjectcolor = zeros(height(task_data), 3);
for c = 1:length(ID)
    cindex = find(uniqueID == ID(c), 1, 'first');
    sorted_cindex = find(sorted_idx == cindex, 1, 'first');
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    subjectcolor(c,:) = cmap(sorted_cindex,:);
end
end

function local_plot_elevation_model_comparison(task_data, task, basename, ResultsDir, ...
    lme_linear_RS, rsModels, availableTransforms, subjectcolor, cmap, sorted_idx, uniqueID)
nsubjects = numel(uniqueID);
markerScale = 36;
maxRatio = max(task_data.Ratio_Visual_Angle);

nPanels = 1 + numel(availableTransforms);
fig = figure('Color',[1 1 1], 'Units','normalized', 'Position',[0 0 1 .8], ...
    'Visible','off', 'Name', sprintf('%s_%s_Supp_Fig_Elevation_model_comps', basename, task));

subplot(1, nPanels, 1); hold on
local_plot_linear_panel(gca, task_data, lme_linear_RS, subjectcolor, cmap, sorted_idx, uniqueID, maxRatio, markerScale, task);

for k = 1:numel(availableTransforms)
    subplot(1, nPanels, k+1); hold on
    local_plot_log_panel(gca, task_data, rsModels{k}, availableTransforms{k}, subjectcolor, cmap, sorted_idx, uniqueID, maxRatio, markerScale, task);
end

figFile = fullfile(ResultsDir, sprintf('%s_%s_Supp_Fig_Elevation_model_comps.png', basename, task));
exportgraphics(fig, figFile, 'Resolution', 600);
close(fig);
end

function local_plot_linear_panel(ax, task_data, model, subjectcolor, cmap, sorted_idx, uniqueID, maxRatio, markerScale, task)
[reEfx, reNames] = randomEffects(model);
[feEfx, ~, festats] = fixedEffects(model);
coefCov = model.CoefficientCovariance;
interceptR = feEfx(1);
slopeR = feEfx(2);
pvalR = festats.pValue(2);

xFit = linspace(min(task_data.Elevation), max(task_data.Elevation), 200)';
X = [ones(size(xFit)) xFit];
yFit = X * feEfx;
seFit = sqrt(sum((X * coefCov) .* X, 2));
tCrit = tinv(0.975, max(1, min(festats.DF)));
yLow = yFit - tCrit * seFit;
yHigh = yFit + tCrit * seFit;

individualIntercepts = zeros(numel(uniqueID),1);
individualSlopes = zeros(numel(uniqueID),1);
for i = 1:numel(uniqueID)
    subjectRows = find(strcmp(reNames.Level, num2str(uniqueID(i))));
    individualIntercepts(i) = interceptR + reEfx(subjectRows(1));
    individualSlopes(i) = slopeR + reEfx(subjectRows(2));
end

for s = 1:numel(uniqueID)
    sortedID = sorted_idx(s);
    sindex = find(uniqueID == uniqueID(sortedID), 1, 'first');
    jj = find(task_data.ID == uniqueID(sindex));
    if numel(jj) > 1
        xvectorS = unique(task_data.Elevation(jj));
        xvectorS = sort(xvectorS(:))';
        yvectorS = individualSlopes(sortedID) * xvectorS + individualIntercepts(sortedID);
        plot(ax, xvectorS, yvectorS, ':', 'Color', cmap(s,:), 'LineWidth', 1);
    end
end

scatter(ax, task_data.Elevation, task_data.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
fill(ax, [xFit; flipud(xFit)], [yLow; flipud(yHigh)], 1, 'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot(ax, xFit, yFit, 'k-', 'LineWidth', 4);
plot(ax, [min(task_data.Elevation) max(task_data.Elevation)], [1 1], 'Color',[.8 .8 .8], 'LineWidth',3);
xlabel(ax, 'Moon Elevation (degrees)');
ylabel(ax, 'Perceptual Magnification');
ylim(ax, [0 maxRatio]);
set(ax, 'YTick', 0:1:maxRatio, 'YTickLabel', 0:1:maxRatio, 'FontSize', 16, 'FontName', 'Avenir');
if pvalR < 0.001
    titlestr = sprintf('%s Matching\n PM=%.2f+(%.3f)*Elevation\n p=%.2e\n n=%d', task, interceptR, slopeR, pvalR, numel(uniqueID));
else
    titlestr = sprintf('%s Matching\n PM=%.2f+(%.3f)*Elevation\n p=%.4f\n n=%d', task, interceptR, slopeR, pvalR, numel(uniqueID));
end
title(ax, titlestr, 'FontSize', 14, 'FontName', 'Avenir');
end

function local_plot_log_panel(ax, task_data, model, transformLabel, subjectcolor, cmap, sorted_idx, uniqueID, maxRatio, markerScale, task)
[xData, xLog, xFit, xLabel, formulaTerm, nativeTickFcn] = local_get_transform_spec(task_data, transformLabel);
[reEfx, reNames] = randomEffects(model);
[feEfx, ~, festats] = fixedEffects(model);
coefCov = model.CoefficientCovariance;
interceptL = feEfx(1);
slopeL = feEfx(2);
pvalL = festats.pValue(2);

yFit = interceptL + slopeL * xFit;
seFit = sqrt(sum(([ones(size(xFit)) xFit] * coefCov) .* [ones(size(xFit)) xFit], 2));
tCrit = tinv(0.975, max(1, min(festats.DF)));
yLow = yFit - tCrit * seFit;
yHigh = yFit + tCrit * seFit;

individualIntercepts = zeros(numel(uniqueID),1);
individualSlopes = zeros(numel(uniqueID),1);
for i = 1:numel(uniqueID)
    subjectRows = find(strcmp(reNames.Level, num2str(uniqueID(i))));
    individualIntercepts(i) = interceptL + reEfx(subjectRows(1));
    individualSlopes(i) = slopeL + reEfx(subjectRows(2));
end

for s = 1:numel(uniqueID)
    sortedID = sorted_idx(s);
    sindex = find(uniqueID == uniqueID(sortedID), 1, 'first');
    jj = find(task_data.ID == uniqueID(sindex));
    if numel(jj) > 1
        xvectorS = unique(xLog(jj));
        xvectorS = sort(xvectorS(:))';
        yvectorS = individualSlopes(sortedID) * xvectorS + individualIntercepts(sortedID);
        plot(ax, xvectorS, yvectorS, ':', 'Color', cmap(s,:), 'LineWidth', 1);
    end
end

fill(ax, [xFit; flipud(xFit)], [yLow; flipud(yHigh)], 1, 'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot(ax, xFit, yFit, 'k-', 'LineWidth', 4);
scatter(ax, xLog, task_data.logRatio, markerScale, subjectcolor, 'o', 'filled');
plot(ax, [min(xLog) max(xLog)], [0 0], 'Color',[.8 .8 .8], 'LineWidth',3);
xlabel(ax, xLabel);
ax.YColor = 'w';
set(ax, 'FontSize', 16, 'FontName', 'Avenir');
xticksVals = get(ax, 'XTick');
set(ax, 'XTickLabel', nativeTickFcn(xticksVals));
yticksVals = get(ax, 'YTick');
set(ax, 'YTickLabel', round(2.^yticksVals, 1));
if pvalL < 0.001
    titlestr = sprintf('%s Matching\n PM=%.1f*%s^{%3.2f}\n p=%.2e\n n=%d', task, round(2^interceptL,1), formulaTerm, slopeL, pvalL, numel(uniqueID));
else
    titlestr = sprintf('%s Matching\n PM=%.1f*%s^{%.2f}\n p=%.4f\n n=%d', task, round(2^interceptL,1), formulaTerm, slopeL, pvalL, numel(uniqueID));
end
title(ax, titlestr, 'FontSize', 14, 'FontName', 'Avenir');
end

function [xData, xLog, xFit, xLabel, formulaTerm, nativeTickFcn] = local_get_transform_spec(task_data, transformLabel)
switch transformLabel
    case 'Elevation'
        xData = task_data.Elevation;
        xLog = task_data.logElevation;
        xFit = linspace(min(xLog), max(xLog), 200)';
        xLabel = 'Moon Elevation (degrees), log scale';
        formulaTerm = '(1+Elevation)';
        nativeTickFcn = @(xt) round(2.^xt - 1, 1);
    case 'ElevationD90'
        xData = task_data.Elevation;
        xLog = task_data.logElevationD90;
        xFit = linspace(min(xLog), max(xLog), 200)';
        xLabel = 'Moon Elevation (degrees), log scale';
        formulaTerm = '(1+Elevation/90)';
        nativeTickFcn = @(xt) round(90 * (2.^xt - 1), 1);
    case 'ElevationRAD'
        xData = task_data.ElevationRAD;
        xLog = task_data.logElevationRAD;
        xFit = linspace(min(xLog), max(xLog), 200)';
        xLabel = 'Moon Elevation (radians), log scale';
        formulaTerm = '(1+ElevationRAD)';
        nativeTickFcn = @(xt) round(2.^xt - 1, 2);
    otherwise
        error('Unsupported transform label %s.', transformLabel);
end
end

function local_plot_model_leaderboard(tbl, saveFile, figTitle)
if isempty(tbl) || height(tbl) == 0
    return;
end

fig = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.1 0.1 0.8 0.7], 'Visible', 'off', 'Name', figTitle);

tiledlayout(1,2, 'Padding', 'compact', 'TileSpacing', 'compact');

labels = cellstr(string(tbl.ModelLabel));
ypos = 1:height(tbl);

nexttile; hold on
barh(ypos, tbl.AIC, 0.7, 'FaceColor', [0.3 0.55 0.85], 'EdgeColor', 'none');
set(gca, 'YDir', 'reverse', 'YTick', ypos, 'YTickLabel', labels, ...
    'FontSize', 14, 'FontName', 'Avenir', 'Box', 'off');
xlabel('AIC', 'Interpreter', 'none');
title('AIC leaderboard', 'Interpreter', 'none');

nexttile; hold on
barh(ypos, tbl.BIC, 0.7, 'FaceColor', [0.85 0.55 0.35], 'EdgeColor', 'none');
set(gca, 'YDir', 'reverse', 'YTick', ypos, 'YTickLabel', labels, ...
    'FontSize', 14, 'FontName', 'Avenir', 'Box', 'off');
xlabel('BIC', 'Interpreter', 'none');
title('BIC leaderboard', 'Interpreter', 'none');

sgtitle(figTitle, 'FontSize', 18, 'FontName', 'Avenir', 'Interpreter', 'none');
exportgraphics(fig, saveFile, 'Resolution', 600);
close(fig);
end
