function [lmeRI, lmeRS, taskData, figHandle] = ...
    SMS_FullMoon_PM_by_task_log_Fig4b(dataDir, datafile, ResultsDir, ...
    task, sortSourceDir, sortSourceBasename, saveLME)
%SMS_FULLMOON_PM_BY_TASK_LOG_FIG4B Fit and plot only the Fig. 4b models.
%   Fits log2(PM) by log2(1 + elevation) RI and RS mixed-effects models,
%   plots both models, and uses the participant ordering saved by Figure 1.

if nargin < 7 || isempty(saveLME)
    saveLME = true;
end

if ~isfolder(ResultsDir)
    mkdir(ResultsDir);
end

dataPath = fullfile(dataDir, datafile);
allData = readtable(dataPath);
validRows = isfinite(allData.Reported_Visual_Angle) & ...
    isfinite(allData.Ratio_Visual_Angle) & ...
    allData.Ratio_Visual_Angle > 0 & ...
    isfinite(allData.Elevation) & allData.Elevation > -1 & ...
    strcmpi(string(allData.Task), string(task));
taskData = allData(validRows, :);
taskData.logRatio = log2(taskData.Ratio_Visual_Angle);
taskData.logElevation = log2(1 + taskData.Elevation);

if isempty(taskData)
    error('FullMoon:EmptyTask', 'No valid rows found for task "%s".', task);
end

lmeRI = fitlme(taskData, 'logRatio ~ logElevation + (1|ID)');
lmeRS = fitlme(taskData, ...
    'logRatio ~ logElevation + (logElevation|ID)');
modelComparison = compare(lmeRI, lmeRS);

basename = erase(datafile, '.csv');
if saveLME
    summaryLines = {
        sprintf('Task: %s', task)
        sprintf('Rows: %d', height(taskData))
        sprintf('Subjects: %d', numel(unique(taskData.ID)))
        sprintf('Median matched size: %.2f', ...
            median(taskData.Reported_Visual_Angle, 'omitnan'))
        sprintf('Mean matched size: %.2f', ...
            mean(taskData.Reported_Visual_Angle, 'omitnan'))
        sprintf('Matched-size SD: %.2f', ...
            std(taskData.Ratio_Visual_Angle, 'omitnan'))
        };
    reportStem = fullfile(ResultsDir, ...
        [basename '_' char(task) '_lme_moon_logRatio_by_Elevation']);
    reportTitle = sprintf( ...
        'Moon log perceptual magnification by log elevation: %s %s', ...
        datafile, task);

    write_moon_lme_report([reportStem '_RI.txt'], ...
        [reportTitle ' - random-intercept model'], summaryLines, ...
        {lmeRI}, ...
        {'Random-intercept model: logRatio ~ logElevation + (1|ID)'}, ...
        {}, {});
    write_moon_lme_report([reportStem '_RS.txt'], ...
        [reportTitle ' - random-slope model'], summaryLines, ...
        {lmeRS}, ...
        {'Random-slope model: logRatio ~ logElevation + (logElevation|ID)'}, ...
        {}, {});
    comparisonLines = [summaryLines; {
        'Random-intercept formula: logRatio ~ logElevation + (1|ID)'
        ['Random-slope formula: logRatio ~ logElevation + ' ...
         '(logElevation|ID)']
        }];
    write_moon_lme_report([reportStem '_RI_vs_RS_comparison.txt'], ...
        [reportTitle ' - RI versus RS model comparison'], ...
        comparisonLines, {}, {}, {modelComparison}, ...
        {'Random-intercept versus random-slope model comparison'});
end

uniqueID = unique(taskData.ID);
nSubjects = numel(uniqueID);
sortFile = fullfile(sortSourceDir, [sortSourceBasename '_sortedidx.mat']);
if ~isfile(sortFile)
    error('FullMoon:MissingFigure1Sort', ...
        'Figure 1 participant ordering was not found: %s', sortFile);
end
sortData = load(sortFile, 'sorted_idx_log');
if ~isfield(sortData, 'sorted_idx_log') || ...
        ~isequal(sort(sortData.sorted_idx_log(:)), (1:nSubjects)')
    error('FullMoon:InvalidFigure1Sort', ...
        ['Figure 1 ordering must be a permutation of 1:%d. ' ...
         'Regenerate Figure 1 before Figure 4b.'], nSubjects);
end
sortedIdx = sortData.sorted_idx_log(:);

cmap = jet(nSubjects);
subjectColor = zeros(height(taskData), 3);
for rank = 1:nSubjects
    subjectID = uniqueID(sortedIdx(rank));
    subjectColor(taskData.ID == subjectID, :) = repmat( ...
        cmap(rank, :), sum(taskData.ID == subjectID), 1);
end

figHandle = figure('Color', 'w', 'Units', 'normalized', ...
    'Position', [0 0 0.7 0.6], ...
    'Name', sprintf('Figure 4b %s log-log RI and RS models', task));
layout = tiledlayout(figHandle, 1, 2, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

local_plot_model(nexttile(layout), taskData, subjectColor, cmap, ...
    uniqueID, sortedIdx, lmeRI, false, task, 'RI model');
local_plot_model(nexttile(layout), taskData, subjectColor, cmap, ...
    uniqueID, sortedIdx, lmeRS, true, task, 'RS model');

outputFile = fullfile(ResultsDir, sprintf( ...
    'Fig4b_LogLog_RI_RS_%s_%s_%d.png', basename, task, nSubjects));
exportgraphics(figHandle, outputFile, 'Resolution', 600);
end

function local_plot_model(ax, taskData, subjectColor, cmap, uniqueID, ...
    sortedIdx, model, showSubjectLines, task, modelLabel)
hold(ax, 'on');
markerSize = 36;
xGridRaw = linspace(min(taskData.Elevation), ...
    max(taskData.Elevation), 150)';
xGridModel = log2(1 + xGridRaw);

[fixedBeta, ~, fixedStats] = fixedEffects(model);
intercept = fixedBeta(1);
slope = fixedBeta(2);
yFit = 2 .^ (intercept + slope .* xGridModel);
yLower = 2 .^ (intercept + fixedStats.Lower(2) .* xGridModel);
yUpper = 2 .^ (intercept + fixedStats.Upper(2) .* xGridModel);
fill(ax, [xGridRaw; flipud(xGridRaw)], [yLower; flipud(yUpper)], ...
    [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.8);

if showSubjectLines
    [randomBeta, randomNames] = randomEffects(model);
    for rank = 1:numel(uniqueID)
        subjectIndex = sortedIdx(rank);
        subjectID = uniqueID(subjectIndex);
        levelRows = strcmp(string(randomNames.Level), string(subjectID));
        subjectEffects = randomBeta(levelRows);
        if numel(subjectEffects) >= 2
            ySubject = 2 .^ ((intercept + subjectEffects(1)) + ...
                (slope + subjectEffects(2)) .* xGridModel);
            plot(ax, xGridRaw, ySubject, ':', 'Color', cmap(rank, :), ...
                'LineWidth', 1);
        end
    end
end

scatter(ax, taskData.Elevation, taskData.Ratio_Visual_Angle, markerSize, ...
    subjectColor, 'filled');
plot(ax, xGridRaw, yFit, 'k-', 'LineWidth', 4);
yline(ax, 1, 'Color', [0.8 0.8 0.8], 'LineWidth', 3);

maxElevation = max(taskData.Elevation);
xlim(ax, [0 maxElevation]);
ylim(ax, [0 max(taskData.Ratio_Visual_Angle) * 1.03]);
set(ax, 'FontSize', 20, 'FontName', 'Avenir');
xlabel(ax, 'Moon Elevation (degrees)');
ylabel(ax, 'Perceptual Magnification');

pValue = fixedStats.pValue(2);
if pValue < 0.001
    pText = sprintf('p=%.2e', pValue);
else
    pText = sprintf('p=%.4f', pValue);
end
title(ax, sprintf(['%s Matching: %s\n' ...
    'intercept=%.2f slope=%.3f\n%s, n=%d'], ...
    task, modelLabel, 2 ^ intercept, slope, pText, numel(uniqueID)), ...
    'FontSize', 16, 'FontName', 'Avenir');
end
