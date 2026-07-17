function [fh, statsTbl] = plot_prediction_error_by_transform(summaryTbl, metricVar, saveFilename, figName)
% plot_prediction_error_by_transform Plot mean error by transform with iteration dots.
%
% Inputs
%   summaryTbl   : table from summarize_model_prediction_error, stacked across transforms/tasks
%   metricVar    : name of numeric metric column, e.g. 'MeanPctError'
%   saveFilename : optional output path for exportgraphics
%   figName      : optional figure name/title
%
% Outputs
%   fh       : figure handle
%   statsTbl : one row per task with the across-transform statistical test

if ~isa(summaryTbl, 'table') || isempty(summaryTbl)
    error('summaryTbl must be a non-empty table.');
end
if ~ismember(metricVar, summaryTbl.Properties.VariableNames)
    error('summaryTbl is missing metric variable %s.', metricVar);
end

if nargin < 3
    saveFilename = '';
end
if nargin < 4 || isempty(figName)
    figName = metricVar;
end

statsTbl = table('Size', [numel(unique(string(summaryTbl.Task), 'stable')), 6], ...
    'VariableNames', {'Task','TestName','NIterations','NTransforms','Statistic','PValue'}, ...
    'VariableTypes', {'string','string','double','double','double','double'});

taskOrder = unique(string(summaryTbl.Task), 'stable');
transformOrder = unique(string(summaryTbl.TransformLabel), 'stable');
allMetricVals = summaryTbl.(metricVar);
yMin = min([0; allMetricVals(:)], [], 'omitnan');
yMax = max(allMetricVals(:), [], 'omitnan');
if ~isfinite(yMin)
    yMin = 0;
end
if ~isfinite(yMax)
    yMax = 1;
end
if yMax <= yMin
    yMax = yMin + 1;
end
yPad = 0.05 * (yMax - yMin);

fh = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.1 0.1 0.5 0.7], 'Name', char(figName));
tiledlayout(1, numel(taskOrder), 'Padding', 'compact', 'TileSpacing', 'compact');

for t = 1:numel(taskOrder)
    ax = nexttile;
    hold(ax, 'on');

    taskMask = string(summaryTbl.Task) == taskOrder(t);
    taskTbl = summaryTbl(taskMask, :);
    barHeights = nan(1, numel(transformOrder));

    for k = 1:numel(transformOrder)
        mask = string(taskTbl.TransformLabel) == transformOrder(k);
        barHeights(k) = mean(taskTbl.(metricVar)(mask), 'omitnan');
    end

    b = bar(ax, 1:numel(transformOrder), barHeights, 0.75, 'FaceColor', [0.7 0.7 0.7], ...
        'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 1.2);
 
    for k = 1:numel(transformOrder)
        mask = string(taskTbl.TransformLabel) == transformOrder(k);
        y = taskTbl.(metricVar)(mask);
        if isempty(y)
            continue;
        end
        n = numel(y);
        if n == 1
            x = k;
        else
            x = linspace(k - 0.14, k + 0.14, n);
        end
        scatter(ax, x, y, 36, 'k', 'filled', 'MarkerFaceAlpha', 0.75, 'MarkerEdgeAlpha', 0.75);
    end

    [pVal, testStat, nItrUsed, nTransformsUsed, testName] = local_compare_transforms(taskTbl, metricVar, transformOrder);
    statsTbl.Task(t) = taskOrder(t);
    statsTbl.TestName(t) = string(testName);
    statsTbl.NIterations(t) = nItrUsed;
    statsTbl.NTransforms(t) = nTransformsUsed;
    statsTbl.Statistic(t) = testStat;
    statsTbl.PValue(t) = pVal;

    set(ax, 'XTick', 1:numel(transformOrder), ...
        'XTickLabel', cellstr(transformOrder), ...
        'XTickLabelRotation', 25, ...
        'FontName', 'Avenir', ...
        'FontSize', 14);
    xlim(ax, [0.4 numel(transformOrder) + 0.6]);
    ylim(ax, [yMin - yPad yMax + yPad]);
    box off
    ax.GridAlpha = 0.2;
    if isfinite(pVal)
        title(ax, sprintf('%s\n%s p=%.2e', char(taskOrder(t)), char(testName), pVal), ...
            'FontName', 'Avenir', 'FontSize', 16, 'FontWeight', 'normal');
    else
        title(ax, sprintf('%s\n%s unavailable', char(taskOrder(t)), char(testName)), ...
            'FontName', 'Avenir', 'FontSize', 16, 'FontWeight', 'normal');
    end
    xlabel(ax, 'Elevation Transform', 'FontName', 'Avenir', 'FontSize', 24);

    switch metricVar
        case 'MeanPctError'
            ylabel(ax, 'Mean % error', 'FontName', 'Avenir', 'FontSize', 24);
        case 'MeanSqError'
            ylabel(ax, 'Mean squared error', 'FontName', 'Avenir', 'FontSize', 24);
        case 'MeanAbsError'
            ylabel(ax, 'Mean absolute error', 'FontName', 'Avenir', 'FontSize', 24);
        otherwise
            ylabel(ax, metricVar, 'Interpreter', 'none', 'FontName', 'Avenir', 'FontSize', 24);
    end
end

linkaxes(findall(fh,'Type','axes'),'xy');
sgtitle(figName, 'FontName', 'Avenir', 'FontSize', 16,'Interpreter', 'none');

if exist('saveFilename', 'var') && ~isempty(saveFilename)
    exportgraphics(fh, saveFilename, 'Resolution', 600);
end
end

function [pVal, testStat, nItrUsed, nTransformsUsed, testName] = local_compare_transforms(taskTbl, metricVar, transformOrder)
% Compare iteration-wise errors across transforms.

testName = 'Friedman';
pVal = NaN;
testStat = NaN;
nItrUsed = 0;
nTransformsUsed = numel(transformOrder);

if ~ismember('Iteration', taskTbl.Properties.VariableNames)
    return;
end

uItr = unique(taskTbl.Iteration, 'stable');
Y = nan(numel(uItr), numel(transformOrder));

for i = 1:numel(uItr)
    itrMask = taskTbl.Iteration == uItr(i);
    itrTbl = taskTbl(itrMask, :);
    for k = 1:numel(transformOrder)
        mask = string(itrTbl.TransformLabel) == transformOrder(k);
        vals = itrTbl.(metricVar)(mask);
        if ~isempty(vals)
            Y(i,k) = vals(1);
        end
    end
end

goodRows = all(isfinite(Y), 2);
Y = Y(goodRows, :);
nItrUsed = size(Y,1);

if size(Y,1) >= 2 && size(Y,2) >= 2
    [pVal, tbl] = friedman(Y, 1, 'off');
    if size(tbl,1) >= 2 && size(tbl,2) >= 5
        testStat = tbl{2,5};
    end
end
end
