function [participantTbl, comparisonTbl, figH] = ...
    PM_compare_single_RS_intercepts_slopes_across_stereo_groups( ...
    groupResults, taskName, quadBasename, resultsDir, saveFigure, ...
    slopeAxisLimits, colorConfig)
%PM_COMPARE_SINGLE_RS_INTERCEPTS_SLOPES_ACROSS_STEREO_GROUPS
% Compare single-factor RS parameters across three independent groups.
%
% groupResults must contain StereoTypical, StereoDeficient, and StereoBlind.
% Each field contains Data and SingleRSLME, where SingleRSLME contains the
% Angle, Distance, and Elevation random-slope models.

if nargin < 5 || isempty(saveFigure)
    saveFigure = true;
end
if nargin < 6
    slopeAxisLimits = [];
end
if nargin < 7 || isempty(colorConfig)
    error('QuadGroupRSParameters:MissingColorConfig', ...
        'A participant color configuration is required.');
end
if ~isempty(slopeAxisLimits) && ~isequal(size(slopeAxisLimits), [3 2])
    error('QuadGroupRSParameters:InvalidSlopeLimits', ...
        'slopeAxisLimits must be empty or a 3-by-2 matrix.');
end
groupOrder = ["StereoTypical", "StereoDeficient", "StereoBlind"];
missingGroups = groupOrder(~isfield(groupResults, cellstr(groupOrder)));
if ~isempty(missingGroups)
    error('QuadGroupRSParameters:MissingGroups', ...
        'groupResults is missing: %s', strjoin(cellstr(missingGroups), ', '));
end
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

factorNames = ["Visual Angle", "Distance", "Elevation"];
modelFields = ["Angle", "Distance", "Elevation"];
predictorNames = ["log2real_visual_angle", "log2distance", "log2elevation"];
participantParts = cell(numel(factorNames), 1);
comparisonParts = cell(numel(factorNames), 1);

for factorIdx = 1:numel(factorNames)
    groupParts = cell(numel(groupOrder), 1);
    for groupIdx = 1:numel(groupOrder)
        result = groupResults.(groupOrder(groupIdx));
        participantIDs = unique(string(result.Data.ID), 'stable');
        model = result.SingleRSLME.(modelFields(factorIdx));
        logIntercept = Quad_extract_subject_model_coefficient( ...
            model, '(Intercept)', participantIDs);
        subjectSlope = Quad_extract_subject_model_coefficient( ...
            model, predictorNames(factorIdx), participantIDs);
        groupParts{groupIdx} = table( ...
            repmat(factorNames(factorIdx), numel(participantIDs), 1), ...
            participantIDs, ...
            categorical(repmat(groupOrder(groupIdx), numel(participantIDs), 1), ...
            groupOrder, groupOrder), logIntercept, 2.^logIntercept, subjectSlope, ...
            'VariableNames', {'Factor', 'ID', 'StereoGroup', ...
            'Log2Intercept', 'PowerLawIntercept', 'SubjectSlope'});
    end
    factorTbl = vertcat(groupParts{:});
    factorTbl = sortrows(factorTbl, {'StereoGroup', 'ID'});
    participantParts{factorIdx} = factorTbl;

    interceptModel = fitlm(factorTbl(isfinite(factorTbl.Log2Intercept), :), ...
        'Log2Intercept ~ StereoGroup');
    slopeModel = fitlm(factorTbl(isfinite(factorTbl.SubjectSlope), :), ...
        'SubjectSlope ~ StereoGroup');
    groupN = zeros(1, numel(groupOrder));
    meanIntercept = nan(1, numel(groupOrder));
    meanSlope = nan(1, numel(groupOrder));
    for groupIdx = 1:numel(groupOrder)
        groupRows = string(factorTbl.StereoGroup) == groupOrder(groupIdx);
        groupN(groupIdx) = sum(groupRows);
        meanIntercept(groupIdx) = mean( ...
            factorTbl.PowerLawIntercept(groupRows), 'omitnan');
        meanSlope(groupIdx) = mean(factorTbl.SubjectSlope(groupRows), 'omitnan');
    end
    comparisonParts{factorIdx} = table( ...
        string(taskName), factorNames(factorIdx), ...
        groupN(1), groupN(2), groupN(3), ...
        meanIntercept(1), meanIntercept(2), meanIntercept(3), ...
        local_group_pvalue(interceptModel), ...
        meanSlope(1), meanSlope(2), meanSlope(3), ...
        local_group_pvalue(slopeModel), ...
        'VariableNames', {'Task', 'Factor', 'NTypical', 'NDeficient', ...
        'NBlind', 'MeanPowerLawInterceptTypical', ...
        'MeanPowerLawInterceptDeficient', 'MeanPowerLawInterceptBlind', ...
        'InterceptGroupPValue', 'MeanSlopeTypical', 'MeanSlopeDeficient', ...
        'MeanSlopeBlind', 'SlopeGroupPValue'});
end

participantTbl = vertcat(participantParts{:});
comparisonTbl = vertcat(comparisonParts{:});
fileStem = sprintf('%s_%s_PM_single_RS_parameters_across_stereo_groups', ...
    char(string(quadBasename)), char(string(taskName)));
writetable(participantTbl, fullfile(resultsDir, [fileStem '_participants.csv']));
writetable(comparisonTbl, fullfile(resultsDir, [fileStem '_comparison.csv']));

figH = gobjects(0);
if ~saveFigure
    return;
end
figH = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.03 0.03 0.6 0.9], 'Name', fileStem, 'Visible', 'off');
tlo = tiledlayout(figH, 3, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
axList = gobjects(6, 1);
for factorIdx = 1:numel(factorNames)
    factorTbl = participantParts{factorIdx};
    comparisonRow = comparisonParts{factorIdx};

    interceptAx = nexttile(tlo, 2*factorIdx - 1);
    axList(2*factorIdx - 1) = interceptAx;
    local_plot_group_parameter(interceptAx, factorTbl, ...
        factorTbl.PowerLawIntercept, groupOrder, colorConfig);
    ylabel(interceptAx, sprintf('%s intercept', factorNames(factorIdx)), ...
        'FontSize', 15);
    title(interceptAx, sprintf('StereoGroup: p=%s, n=%d/%d/%d', ...
        Quad_format_pvalue(comparisonRow.InterceptGroupPValue), ...
        comparisonRow.NTypical, comparisonRow.NDeficient, comparisonRow.NBlind), ...
        'FontSize', 13, 'FontWeight', 'normal');

    slopeAx = nexttile(tlo, 2*factorIdx);
    axList(2*factorIdx) = slopeAx;
    local_plot_group_parameter(slopeAx, factorTbl, ...
        factorTbl.SubjectSlope, groupOrder, colorConfig);
    yline(slopeAx, 0, 'k-', 'LineWidth', 1);
    if ~isempty(slopeAxisLimits)
        ylim(slopeAx, slopeAxisLimits(factorIdx, :));
    end
    ylabel(slopeAx, sprintf('%s slope', factorNames(factorIdx)), ...
        'FontSize', 15);
    title(slopeAx, sprintf('Stereo group: p=%s, n=%d/%d/%d', ...
        Quad_format_pvalue(comparisonRow.SlopeGroupPValue), ...
        comparisonRow.NTypical, comparisonRow.NDeficient, comparisonRow.NBlind), ...
        'FontSize', 13, 'FontWeight', 'normal');
end
title(tlo, sprintf('%s: single-factor RS intercepts and slopes across stereo groups', ...
    char(string(taskName))), 'FontName', 'Avenir', 'FontSize', 19, ...
    'FontWeight', 'normal');
Quad_finish_group_color_key(axList, colorConfig);
exportgraphics(figH, fullfile(resultsDir, [fileStem '.png']), ...
    'Resolution', 600);
close(figH);
end

function local_plot_group_parameter(ax, factorTbl, values, groupOrder, colorConfig)
hold(ax, 'on');
x = Quad_group_plot_x_positions(factorTbl.StereoGroup, groupOrder);
Quad_plot_group_participant_points(ax, x, values, factorTbl.ID, colorConfig);
for groupIdx = 1:numel(groupOrder)
    groupValues = values(string(factorTbl.StereoGroup) == groupOrder(groupIdx));
    groupMean = mean(groupValues, 'omitnan');
    plot(ax, groupIdx + [-0.22 0.22], [groupMean groupMean], ...
        'k-', 'LineWidth', 4);
end
set(ax, 'XLim', [0.5 3.5], 'XTick', 1:3, ...
    'XTickLabel', {'StereoTypical', 'StereoDeficient', 'StereoBlind'}, ...
    'FontName', 'Avenir', 'FontSize', 11, 'XTickLabelRotation', 0);
box(ax, 'off');
grid(ax, 'off');
end

function pValue = local_group_pvalue(model)
nCoefficients = height(model.Coefficients);
contrast = [zeros(nCoefficients - 1, 1), eye(nCoefficients - 1)];
pValue = coefTest(model, contrast);
end
