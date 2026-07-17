function fh = plot_lme_criterion_by_transform(criteriaTbl, metricVar, saveFilename, figName)
% plot_lme_criterion_by_transform Plot AIC/BIC by elevation transform.

if ~isa(criteriaTbl, 'table') || isempty(criteriaTbl)
    error('criteriaTbl must be a non-empty table.');
end
if ~ismember(metricVar, criteriaTbl.Properties.VariableNames)
    error('Missing metric variable %s.', metricVar);
end
if nargin < 3
    saveFilename = '';
end
if nargin < 4 || isempty(figName)
    figName = metricVar;
end

taskOrder = unique(string(criteriaTbl.Task), 'stable');
transformOrder = unique(string(criteriaTbl.TransformLabel), 'stable');
metricVals = criteriaTbl.(metricVar);
yMin = min(metricVals, [], 'omitnan');
yMax = max(metricVals, [], 'omitnan');
if ~isfinite(yMin); yMin = 0; end
if ~isfinite(yMax); yMax = 1; end
if yMax <= yMin; yMax = yMin + 1; end
yPad = 0.05 * (yMax - yMin);

fh = figure('Color',[1 1 1], 'Units','normalized', ...
    'Position',[0.1 0.1 0.7 0.45], 'Name', char(figName));
tiledlayout(1, numel(taskOrder), 'Padding', 'compact', 'TileSpacing', 'compact');

for t = 1:numel(taskOrder)
    ax = nexttile;
    hold(ax, 'on');

    taskTbl = criteriaTbl(string(criteriaTbl.Task) == taskOrder(t), :);
    [~, orderIdx] = ismember(string(taskTbl.TransformLabel), transformOrder);
    x = orderIdx;
    y = taskTbl.(metricVar);

    bar(ax, x, y, 0.75, 'FaceColor', [0.75 0.75 0.75], ...
        'EdgeColor', [0.25 0.25 0.25], 'LineWidth', 1.2);
    scatter(ax, x, y, 42, 'k', 'filled');

    [bestVal, bestIdx] = min(y);
    text(ax, x(bestIdx), bestVal, sprintf('  best: %s', taskTbl.TransformLabel(bestIdx)), ...
        'FontName', 'Avenir', 'FontSize', 11, 'VerticalAlignment', 'bottom');

    set(ax, 'XTick', 1:numel(transformOrder), ...
        'XTickLabel', cellstr(transformOrder), ...
        'XTickLabelRotation', 20, ...
        'FontName', 'Avenir', ...
        'FontSize', 13);
    xlim(ax, [0.4 numel(transformOrder) + 0.6]);
    ylim(ax, [yMin - yPad yMax + yPad]);
    box(ax, 'off');
    grid(ax, 'off');
    title(ax, char(taskOrder(t)), 'FontName', 'Avenir', 'FontSize', 16, 'FontWeight', 'normal');
    xlabel(ax, 'Elevation Transform', 'FontName', 'Avenir', 'FontSize', 14);
    ylabel(ax, metricVar, 'FontName', 'Avenir', 'FontSize', 14);
end

sgtitle(figName, 'FontName', 'Avenir', 'FontSize', 18);

if ~isempty(saveFilename)
    print(fh, saveFilename, '-dpng', '-r600');
end
end
