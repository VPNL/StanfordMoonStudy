function [slopeTbl, comparisonTbl] = ...
    PM_compare_single_RS_across_stereo_groups( ...
    tblTypical, typicalModels, tblDeficient, deficientModels, taskName, ...
    quadBasename, resultsDir, saveFigure, axisLimits, colorConfig)
%PM_COMPARE_SINGLE_RS_ACROSS_STEREO_GROUPS Compare RS slopes by stereo group.
% typicalModels and deficientModels contain Angle, Distance, and Elevation
% single-predictor random-slope LMEs for one task.

if nargin < 8 || isempty(saveFigure)
    saveFigure = true;
end
if nargin < 9
    axisLimits = [];
end
if nargin < 10 || isempty(colorConfig)
    error('QuadGroupSlopes:MissingColorConfig', ...
        'A participant color configuration is required.');
end
if ~isempty(axisLimits) && ~isequal(size(axisLimits), [3 2])
    error('QuadGroupSlopes:InvalidAxisLimits', ...
        'axisLimits must be empty or a 3-by-2 matrix for Angle, Distance, and Elevation.');
end
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

factorNames = ["Angle", "Distance", "Elevation"];
predictorNames = ["log2real_visual_angle", "log2distance", "log2elevation"];
groupOrder = ["StereoTypical", "StereoDeficient"];
typicalIDs = unique(string(tblTypical.ID), 'stable');
deficientIDs = unique(string(tblDeficient.ID), 'stable');
slopeParts = cell(numel(factorNames), 1);
comparisonParts = cell(numel(factorNames), 1);

for factorIdx = 1:numel(factorNames)
    factorName = factorNames(factorIdx);
    typicalSlope = Quad_extract_subject_model_coefficient( ...
        typicalModels.(factorName), predictorNames(factorIdx), typicalIDs);
    deficientSlope = Quad_extract_subject_model_coefficient( ...
        deficientModels.(factorName), predictorNames(factorIdx), deficientIDs);
    groupText = [repmat(groupOrder(1), numel(typicalIDs), 1); ...
        repmat(groupOrder(2), numel(deficientIDs), 1)];
    factorTbl = table(repmat(factorName, numel(groupText), 1), ...
        [typicalIDs; deficientIDs], categorical(groupText, groupOrder, groupOrder), ...
        [typicalSlope; deficientSlope], ...
        'VariableNames', {'Factor', 'ID', 'StereoGroup', 'SubjectSlope'});
    factorTbl = sortrows(factorTbl, {'StereoGroup', 'ID'});
    slopeParts{factorIdx} = factorTbl;

    validRows = isfinite(factorTbl.SubjectSlope);
    comparisonModel = fitlm(factorTbl(validRows, :), 'SubjectSlope ~ StereoGroup');
    comparisonParts{factorIdx} = table(string(taskName), factorName, ...
        sum(factorTbl.StereoGroup == groupOrder(1)), ...
        sum(factorTbl.StereoGroup == groupOrder(2)), ...
        mean(factorTbl.SubjectSlope(factorTbl.StereoGroup == groupOrder(1)), 'omitnan'), ...
        mean(factorTbl.SubjectSlope(factorTbl.StereoGroup == groupOrder(2)), 'omitnan'), ...
        comparisonModel.Coefficients.Estimate(2), ...
        comparisonModel.Coefficients.pValue(2), ...
        'VariableNames', {'Task', 'Factor', 'NTypical', 'NDeficient', ...
        'MeanTypical', 'MeanDeficient', 'DeficientMinusTypical', ...
        'ExploratoryPValue'});
end

slopeTbl = vertcat(slopeParts{:});
comparisonTbl = vertcat(comparisonParts{:});
fileStem = sprintf('%s_%s_PM_single_RSslopes_across_stereo_groups', ...
    quadBasename, taskName);
writetable(slopeTbl, fullfile(resultsDir, [fileStem '_participants.csv']));
writetable(comparisonTbl, fullfile(resultsDir, [fileStem '_comparison.csv']));

if ~saveFigure
    return;
end

figH = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.04 0.10 0.92 0.58], 'Name', fileStem, 'Visible', 'off');
tlo = tiledlayout(figH, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
axList = gobjects(numel(factorNames), 1);
for factorIdx = 1:numel(factorNames)
    factorTbl = slopeParts{factorIdx};
    ax = nexttile(tlo);
    axList(factorIdx) = ax;
    hold(ax, 'on');
    x = Quad_group_plot_x_positions(factorTbl.StereoGroup, groupOrder);
    Quad_plot_group_participant_points(ax, x, factorTbl.SubjectSlope, ...
        factorTbl.ID, colorConfig);
    for groupIdx = 1:numel(groupOrder)
        groupValues = factorTbl.SubjectSlope( ...
            string(factorTbl.StereoGroup) == groupOrder(groupIdx));
        groupMean = mean(groupValues, 'omitnan');
        plot(ax, groupIdx + [-0.22 0.22], [groupMean groupMean], ...
            'k-', 'LineWidth', 4);
    end
    yline(ax, 0, 'k-', 'LineWidth', 1);
    set(ax, 'XLim', [0.5 2.5], 'XTick', 1:2, ...
        'XTickLabel', {'Typical', 'Deficient'}, ...
        'FontName', 'Avenir', 'FontSize', 14);
    if ~isempty(axisLimits)
        ylim(ax, axisLimits(factorIdx, :));
    end
    ylabel(ax, sprintf('%s subject slope', factorNames(factorIdx)), 'FontSize', 17);
    title(ax, sprintf('%s\ntwo-stage p=%s, n=%d vs %d', factorNames(factorIdx), ...
        Quad_format_pvalue(comparisonTbl.ExploratoryPValue(factorIdx)), ...
        comparisonTbl.NTypical(factorIdx), comparisonTbl.NDeficient(factorIdx)), ...
        'FontSize', 14, 'FontWeight', 'normal');
    box(ax, 'off');
    grid(ax, 'off');
end
title(tlo, sprintf('%s: single-factor RS slopes across stereo groups', taskName), ...
    'FontName', 'Avenir', 'FontSize', 18, 'FontWeight', 'normal');
Quad_finish_group_color_key(axList, colorConfig);
exportgraphics(figH, fullfile(resultsDir, [fileStem '.png']), 'Resolution', 600);
close(figH);
end
