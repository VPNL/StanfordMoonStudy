function fh = plot_elevation_transform_leaderboard(leaderboardTbl, detailTbl, saveDir, savePrefix)
% plot_elevation_transform_leaderboard Plot mean ranks with evidence dots.

if ~isa(leaderboardTbl, 'table') || isempty(leaderboardTbl)
    error('leaderboardTbl must be a non-empty table.');
end
if ~isa(detailTbl, 'table') || isempty(detailTbl)
    error('detailTbl must be a non-empty table.');
end
if nargin < 3
    saveDir = '';
end
if nargin < 4 || isempty(savePrefix)
    savePrefix = 'elevation_transform_leaderboard';
end

familyOrder = cellstr(string(leaderboardTbl.TransformFamily));
x = 1:numel(familyOrder);

fh = figure('Color',[1 1 1], 'Units','normalized', ...
    'Position',[0.12 0.16 0.55 0.52], 'Name', 'Elevation Transform Leaderboard');
ax = axes(fh);
hold(ax, 'on');

bar(ax, x, leaderboardTbl.MeanRank, 0.72, ...
    'FaceColor', [0.78 0.78 0.78], 'EdgeColor', 'none');

for i = 1:numel(familyOrder)
    idx = string(detailTbl.TransformFamily) == string(familyOrder{i});
    y = detailTbl.Rank(idx);
    y = y(~isnan(y));
    if isempty(y)
        continue;
    end
    xjit = x(i) + linspace(-0.12, 0.12, numel(y));
    scatter(ax, xjit, y, 40, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.8, 'MarkerEdgeAlpha', 0.8);
end

set(ax, 'XTick', x, 'XTickLabel', familyOrder, ...
    'FontName', 'Avenir', 'FontSize', 13, ...
    'XTickLabelRotation', 15);
yMax = max(max(leaderboardTbl.MeanRank), max(detailTbl.Rank, [], 'omitnan'));
if ~isfinite(yMax)
    yMax = 3;
end
ylim(ax, [0.8, yMax + 0.4]);
xlim(ax, [0.4, numel(familyOrder) + 0.6]);
xlabel(ax, 'Aligned Elevation Transform Family', 'FontName', 'Avenir', 'FontSize', 14);
ylabel(ax, 'Mean Rank Across Evidence Sources', 'FontName', 'Avenir', 'FontSize', 14);
title(ax, 'Cross-Dataset Elevation Transform Leaderboard', ...
    'FontName', 'Avenir', 'FontSize', 17, 'FontWeight', 'normal');
box(ax, 'off');
grid(ax, 'off');

if ~isempty(saveDir)
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    print(fh, fullfile(saveDir, [savePrefix '.png']), '-dpng', '-r600');
end
end
