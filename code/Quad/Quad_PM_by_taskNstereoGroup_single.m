function [lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logAngle_RS, lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS, modelComparisons] = ...
    Quad_PM_by_taskNstereoGroup_single(tbl, tblName, ResultsDir, saveLME, cmap, sorted_idx, ElevationTransform, plotResults, plotFixedEffectsRS, colorConfig)
% QUAD_PM_BY_TASKNSTEREOGROUP_SINGLE
% Fit single-factor Quad PM models with factor-by-StereoGroup interactions.
%
% This is a stereo-group variant of Quad_PM_by_task_single. For each physical
% factor, it fits both random-intercept and random-slope LME models:
%
%   log2ratio_visual_angle ~ predictor*StereoGroup + (1|ID)
%   log2ratio_visual_angle ~ predictor*StereoGroup + (predictor|ID)
%
% where predictor is log2real_visual_angle, log2distance, or log2elevation.
% Models use ML fitting so the base-vs-interaction comparisons are appropriate
% for fixed-effect differences.
%
% Inputs match Quad_PM_by_task_single for easy drop-in use.
%
% Optional inputs
%   plotResults        - true/false. If true, save RI and RS model figures.
%                        Default is true.
%   plotFixedEffectsRS - true/false. If true, overlay fixed StereoGroup lines
%                        on the RS panels. Default is false.
%   colorConfig        - optional output from Quad_build_participant_color_config.
%                        When supplied, the right-side key is a 0-100 stereo
%                        score colorbar or a clinical-condition legend.

if nargin < 7 || isempty(ElevationTransform)
    ElevationTransform = 1;
end
ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'standard');

if nargin < 4 || isempty(saveLME)
    saveLME = false;
end
if nargin < 5
    cmap = [];
end
if nargin < 6
    sorted_idx = [];
end
if nargin < 8 || isempty(plotResults)
    plotResults = true;
end
if nargin < 9 || isempty(plotFixedEffectsRS)
    plotFixedEffectsRS = false;
end
if nargin < 10
    colorConfig = [];
end

if isstruct(cmap)
    colorConfig = cmap;
    [cmap, sorted_idx] = local_color_inputs_from_config(colorConfig, cmap, sorted_idx);
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

[tbl, nsubjects, groupSummaryLines, subjectcolor, subjectColorByID, uniqueID, cmap, sorted_idx, colorConfig] = ...
    local_prepare_table(tbl, ElevationTransform, cmap, sorted_idx, colorConfig);

angleFormulaRI = 'log2ratio_visual_angle ~ log2real_visual_angle*StereoGroup + (1|ID)';
distanceFormulaRI = 'log2ratio_visual_angle ~ log2distance*StereoGroup + (1|ID)';
elevationFormulaRI = 'log2ratio_visual_angle ~ log2elevation*StereoGroup + (1|ID)';

angleFormulaRS = 'log2ratio_visual_angle ~ log2real_visual_angle*StereoGroup + (log2real_visual_angle|ID)';
distanceFormulaRS = 'log2ratio_visual_angle ~ log2distance*StereoGroup + (log2distance|ID)';
elevationFormulaRS = 'log2ratio_visual_angle ~ log2elevation*StereoGroup + (log2elevation|ID)';

baseAngleFormulaRI = 'log2ratio_visual_angle ~ log2real_visual_angle + (1|ID)';
baseDistanceFormulaRI = 'log2ratio_visual_angle ~ log2distance + (1|ID)';
baseElevationFormulaRI = 'log2ratio_visual_angle ~ log2elevation + (1|ID)';

baseAngleFormulaRS = 'log2ratio_visual_angle ~ log2real_visual_angle + (log2real_visual_angle|ID)';
baseDistanceFormulaRS = 'log2ratio_visual_angle ~ log2distance + (log2distance|ID)';
baseElevationFormulaRS = 'log2ratio_visual_angle ~ log2elevation + (log2elevation|ID)';

baseAngleLME = fitlme(tbl, baseAngleFormulaRI, 'FitMethod', 'ML');
baseDistanceLME = fitlme(tbl, baseDistanceFormulaRI, 'FitMethod', 'ML');
baseElevationLME = fitlme(tbl, baseElevationFormulaRI, 'FitMethod', 'ML');

baseAngleRSLME = fitlme(tbl, baseAngleFormulaRS, 'FitMethod', 'ML');
baseDistanceRSLME = fitlme(tbl, baseDistanceFormulaRS, 'FitMethod', 'ML');
baseElevationRSLME = fitlme(tbl, baseElevationFormulaRS, 'FitMethod', 'ML');

lme_logPM_by_logAngle = fitlme(tbl, angleFormulaRI, 'FitMethod', 'ML');
lme_logPM_by_logDistance = fitlme(tbl, distanceFormulaRI, 'FitMethod', 'ML');
lme_logPM_by_logElevation = fitlme(tbl, elevationFormulaRI, 'FitMethod', 'ML');

lme_logPM_by_logAngle_RS = fitlme(tbl, angleFormulaRS, 'FitMethod', 'ML');
lme_logPM_by_logDistance_RS = fitlme(tbl, distanceFormulaRS, 'FitMethod', 'ML');
lme_logPM_by_logElevation_RS = fitlme(tbl, elevationFormulaRS, 'FitMethod', 'ML');

modelComparisons = struct();
modelComparisons.Angle.RI = compare(baseAngleLME, lme_logPM_by_logAngle);
modelComparisons.Angle.RS = compare(baseAngleRSLME, lme_logPM_by_logAngle_RS);
modelComparisons.Distance.RI = compare(baseDistanceLME, lme_logPM_by_logDistance);
modelComparisons.Distance.RS = compare(baseDistanceRSLME, lme_logPM_by_logDistance_RS);
modelComparisons.Elevation.RI = compare(baseElevationLME, lme_logPM_by_logElevation);
modelComparisons.Elevation.RS = compare(baseElevationRSLME, lme_logPM_by_logElevation_RS);

if saveLME
    savelmefile = fullfile(ResultsDir, [char(string(tblName)) '_single_byStereoGroup.txt']);
    sourceCsv = local_source_file_label(tbl, tblName);

    reportOpts = struct();
    reportOpts.ReportTitle = sprintf('Quad PM Single-Factor StereoGroup Interaction LME Report: %s', char(string(tblName)));
    reportOpts.GeneratedBy = mfilename;
    reportOpts.SourceFile = sourceCsv;
    reportOpts.ModelLabel = 'Log perceptual magnification predicted by one log physical factor, StereoGroup, and their interaction';
    reportOpts.SummaryLines = [ ...
        {sprintf('Experiment: Quad'), ...
        sprintf('Rows in model table: %d', height(tbl)), ...
        sprintf('Participants in model table: %d', nsubjects), ...
        sprintf('Elevation transform: %s', char(string(ElevationTransform))), ...
        sprintf('Fit method: ML')}, ...
        groupSummaryLines];
    reportOpts.Models = { ...
        lme_logPM_by_logAngle, ...
        lme_logPM_by_logAngle_RS, ...
        lme_logPM_by_logDistance, ...
        lme_logPM_by_logDistance_RS, ...
        lme_logPM_by_logElevation, ...
        lme_logPM_by_logElevation_RS};
    reportOpts.ModelLabels = { ...
        ['Model: ' angleFormulaRI], ...
        ['Model: ' angleFormulaRS], ...
        ['Model: ' distanceFormulaRI], ...
        ['Model: ' distanceFormulaRS], ...
        ['Model: ' elevationFormulaRI], ...
        ['Model: ' elevationFormulaRS]};
    reportOpts.Comparisons = { ...
        modelComparisons.Angle.RI, ...
        modelComparisons.Angle.RS, ...
        modelComparisons.Distance.RI, ...
        modelComparisons.Distance.RS, ...
        modelComparisons.Elevation.RI, ...
        modelComparisons.Elevation.RS};
    reportOpts.ComparisonLabels = { ...
        'Model comparison: visual angle RI base vs StereoGroup interaction', ...
        'Model comparison: visual angle RS base vs StereoGroup interaction', ...
        'Model comparison: distance RI base vs StereoGroup interaction', ...
        'Model comparison: distance RS base vs StereoGroup interaction', ...
        'Model comparison: elevation RI base vs StereoGroup interaction', ...
        'Model comparison: elevation RS base vs StereoGroup interaction'};
    reportOpts.RemoveGroupError = false;
    write_lme_stats_report(lme_logPM_by_logAngle, savelmefile, reportOpts);
end

if plotResults
    local_plot_model_figures(tbl, tblName, ResultsDir, cmap, sorted_idx, ...
        subjectcolor, subjectColorByID, uniqueID, nsubjects, ElevationTransform, colorConfig, ...
        lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
        lme_logPM_by_logAngle_RS, lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS, ...
        plotFixedEffectsRS, modelComparisons);
end
end

function [tbl, nsubjects, groupSummaryLines, subjectcolor, subjectColorByID, uniqueID, cmap, sorted_idx, colorConfig] = ...
    local_prepare_table(tbl, ElevationTransform, cmap, sorted_idx, colorConfig)
requiredVars = {'ID', 'Real_Visual_Angle', 'Ratio_Visual_Angle', ...
    'Distance', 'Elevation', 'StereoGroup'};
missingVars = setdiff(requiredVars, tbl.Properties.VariableNames);
if ~isempty(missingVars)
    error('QuadPMByTaskNStereoGroup:MissingVariables', ...
        'Input table is missing required variable(s): %s', strjoin(missingVars, ', '));
end

tbl.log2real_visual_angle = log2(double(tbl.Real_Visual_Angle));
tbl.log2ratio_visual_angle = log2(double(tbl.Ratio_Visual_Angle));
tbl.log2distance = log2(double(tbl.Distance));

switch ElevationTransform
    case 1
        tbl.log2elevation = log2(double(tbl.Elevation) + 1);
        tbl.ElevationModel = double(tbl.Elevation) + 1;
    case 2
        tbl.log2elevation = log2(abs(double(tbl.Elevation)) + 1);
        tbl.ElevationModel = abs(double(tbl.Elevation)) + 1;
    case 5
        tbl.log2elevation = log2(double(tbl.Elevation) / 90 + 1);
        tbl.ElevationModel = double(tbl.Elevation) / 90 + 1;
    case 6
        tbl.log2elevation = log2(abs(double(tbl.Elevation)) / 90 + 1);
        tbl.ElevationModel = abs(double(tbl.Elevation)) / 90 + 1;
    otherwise
        error('QuadPMByTaskNStereoGroup:InvalidTransform', ...
            'Unsupported elevation transform %s.', string(ElevationTransform));
end

tbl.StereoGroup = local_stereo_group_categorical(tbl.StereoGroup);
if ~iscategorical(tbl.ID)
    tbl.ID = categorical(tbl.ID);
end

keepRows = isfinite(tbl.log2real_visual_angle) & ...
    isfinite(tbl.log2ratio_visual_angle) & ...
    isfinite(tbl.log2distance) & ...
    isfinite(tbl.log2elevation) & ...
    ~isundefined(tbl.ID) & ...
    ~isundefined(tbl.StereoGroup);
tbl = tbl(keepRows, :);
tbl.ID = removecats(tbl.ID);
tbl.StereoGroup = removecats(tbl.StereoGroup);

presentGroups = categories(tbl.StereoGroup);
if numel(presentGroups) < 2
    error('QuadPMByTaskNStereoGroup:TooFewGroups', ...
        'StereoGroup interaction models require at least two groups with valid data.');
end

nsubjects = numel(categories(tbl.ID));
groupSummaryLines = local_group_summary_lines(tbl);
uniqueID = string(categories(tbl.ID));
[cmap, sorted_idx] = local_validate_color_inputs(cmap, sorted_idx, nsubjects);
subjectColorByID = local_subject_colors_by_id(uniqueID, cmap, sorted_idx, colorConfig);
subjectcolor = local_subject_colors(tbl.ID, uniqueID, subjectColorByID);
end

function local_plot_model_figures(tbl, tblName, ResultsDir, cmap, sorted_idx, ...
    subjectcolor, subjectColorByID, uniqueID, nsubjects, ElevationTransform, colorConfig, ...
    lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logAngle_RS, lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS, ...
    plotFixedEffectsRS, modelComparisons)

minRatio = min(double(tbl.Ratio_Visual_Angle));
maxRatio = max(double(tbl.Ratio_Visual_Angle));
maxPMLim = max(16, maxRatio);
minPMLim = min(0.25, minRatio);
subjectLineOrder = local_inverse_rank_subject_order(uniqueID, sorted_idx, colorConfig);
groupLineColors = local_stereo_group_line_colors(tbl, colorConfig);

figRI = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 1 .85], 'Name', [char(string(tblName)) '_single_byStereoGroup_RI'], ...
    'Visible', 'off');
axesList = local_create_three_panel_axes(figRI);
local_plot_pm_panel(axesList(1), tbl, subjectcolor, lme_logPM_by_logAngle, ...
    'A', ElevationTransform, nsubjects, uniqueID, subjectColorByID, ...
    subjectLineOrder, groupLineColors, false, minPMLim, maxPMLim, plotFixedEffectsRS, modelComparisons.Angle.RI);
local_plot_pm_panel(axesList(2), tbl, subjectcolor, lme_logPM_by_logDistance, ...
    'D', ElevationTransform, nsubjects, uniqueID, subjectColorByID, ...
    subjectLineOrder, groupLineColors, false, minPMLim, maxPMLim, plotFixedEffectsRS, modelComparisons.Distance.RI);
rightAx = axesList(3);
local_plot_pm_panel(rightAx, tbl, subjectcolor, lme_logPM_by_logElevation, ...
    'E', ElevationTransform, nsubjects, uniqueID, subjectColorByID, ...
    subjectLineOrder, groupLineColors, false, minPMLim, maxPMLim, plotFixedEffectsRS, modelComparisons.Elevation.RI);
local_add_ri_line_legend(axesList(1), tbl, groupLineColors);
local_add_color_key(rightAx, cmap, nsubjects, colorConfig);
local_export_png(figRI, fullfile(ResultsDir, [char(string(tblName)) '_single_byStereoGroup_RI.png']), 600);
close(figRI);

figRS = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 1 .85], 'Name', [char(string(tblName)) '_single_byStereoGroup_RS'], ...
    'Visible', 'off');
axesList = local_create_three_panel_axes(figRS);
local_plot_pm_panel(axesList(1), tbl, subjectcolor, lme_logPM_by_logAngle_RS, ...
    'A', ElevationTransform, nsubjects, uniqueID, subjectColorByID, ...
    subjectLineOrder, [], true, minPMLim, maxPMLim, plotFixedEffectsRS, modelComparisons.Angle.RS);
local_plot_pm_panel(axesList(2), tbl, subjectcolor, lme_logPM_by_logDistance_RS, ...
    'D', ElevationTransform, nsubjects, uniqueID, subjectColorByID, ...
    subjectLineOrder, [], true, minPMLim, maxPMLim, plotFixedEffectsRS, modelComparisons.Distance.RS);
rightAx = axesList(3);
local_plot_pm_panel(rightAx, tbl, subjectcolor, lme_logPM_by_logElevation_RS, ...
    'E', ElevationTransform, nsubjects, uniqueID, subjectColorByID, ...
    subjectLineOrder, [], true, minPMLim, maxPMLim, plotFixedEffectsRS, modelComparisons.Elevation.RS);
local_add_color_key(rightAx, cmap, nsubjects, colorConfig);
local_export_png(figRS, fullfile(ResultsDir, [char(string(tblName)) '_single_byStereoGroup_RS.png']), 600);
close(figRS);
end

function axesList = local_create_three_panel_axes(figHandle)
left = 0.105;
bottom = 0.24;
panelWidth = 0.230;
panelHeight = 0.58;
gap = 0.035;

axesList = gobjects(1, 3);
for panelIdx = 1:3
    axesList(panelIdx) = axes(figHandle, ...
        'Position', [left + (panelIdx - 1) * (panelWidth + gap), ...
        bottom, panelWidth, panelHeight]);
end
end

function local_plot_pm_panel(ax, tbl, subjectcolor, lme, modeChar, ...
    ElevationTransform, nsubjects, uniqueID, subjectColorByID, ...
    subjectLineOrder, groupLineColors, addSubjectLines, minPMLim, maxPMLim, plotFixedEffectsRS, comparisonTbl)
hold(ax, 'on');
markerSize = 50;
[~, xLog, xlabelText, xTickVals, xTickLabels, xLimits] = ...
    local_axis_info(tbl, modeChar, ElevationTransform);

if addSubjectLines
    plot(ax, xLimits, [0 0], 'k:', 'LineWidth', 2);
else
    plot(ax, xLimits, [0 0], 'k:', 'LineWidth', 1);
end

if addSubjectLines
    local_plot_subject_lines(ax, tbl, lme, modeChar, ElevationTransform, ...
        uniqueID, subjectColorByID, subjectLineOrder);
end

if ~addSubjectLines || plotFixedEffectsRS
    local_plot_stereo_group_fixed_lines(ax, tbl, lme, modeChar, xLimits, addSubjectLines, groupLineColors);
end

scatter_pm_by_measurement(ax, xLog, tbl.log2ratio_visual_angle, ...
    subjectcolor, tbl.Measurement, markerSize);

set(ax, 'XTick', xTickVals, 'XTickLabel', xTickLabels, ...
    'YTick', floor(log2(minPMLim)):1:ceil(log2(maxPMLim)), ...
    'YTickLabel', string(2.^(floor(log2(minPMLim)):1:ceil(log2(maxPMLim)))), ...
    'FontName', 'Avenir', 'FontSize', 20, ...
    'XTickLabelRotation', 0);
set(ax, 'XLim', xLimits, 'YLim', [floor(log2(minPMLim)) ceil(log2(maxPMLim))]);
box(ax, 'off');
grid(ax, 'off');
xlabel(ax, xlabelText, 'FontSize', 24);
if modeChar == 'A'
    yLabelHandle = ylabel(ax, {'Perceptual Magnification', 'log scale'}, 'FontSize', 24);
    yLabelHandle.Units = 'normalized';
    yLabelHandle.Position = [-0.18 0.5 0];
else
    ylabel(ax, '');
    ax.YColor = 'w';
end

[mainEstimate, mainP] = local_main_effect_stats(lme, modeChar);
interactionJointP = local_interaction_joint_pvalue(lme, modeChar, comparisonTbl);
factorLabel = local_factor_label(modeChar);
title(ax, sprintf('%s\nexp=%s, p=%s\n%s x stereo group: p=%s\nn=%d', ...
    factorLabel, local_format_estimate(mainEstimate), ...
    local_format_pvalue(mainP), factorLabel, local_format_pvalue(interactionJointP), nsubjects), ...
    'FontSize', 16, 'FontWeight', 'normal');
end

function local_plot_stereo_group_fixed_lines(ax, tbl, lme, modeChar, xLimits, useRsStyle, groupLineColors)
groupNames = string(categories(tbl.StereoGroup));
[lineStyles, fallbackLineColors] = local_stereo_group_line_style();
lineColors = local_resolve_group_line_colors(groupNames, groupLineColors, fallbackLineColors);
lineWidth = 3;
if useRsStyle
    lineWidth = 2;
end

xGrid = linspace(xLimits(1), xLimits(2), 200)';
idValue = string(categories(tbl.ID));
idValue = idValue(1);

for groupIdx = 1:numel(groupNames)
    predTbl = local_prediction_table(tbl, modeChar, xGrid, groupNames(groupIdx), idValue);
    yFit = predict(lme, predTbl, 'Conditional', false);
    colorIdx = min(groupIdx, size(lineColors, 1));
    plot(ax, xGrid, yFit, lineStyles{1 + mod(groupIdx - 1, numel(lineStyles))}, ...
        'Color', lineColors(colorIdx, :), 'LineWidth', lineWidth);
end
end

function local_add_ri_line_legend(ax, tbl, groupLineColors)
groupNames = string(categories(tbl.StereoGroup));
[lineStyles, fallbackLineColors] = local_stereo_group_line_style();
lineColors = local_resolve_group_line_colors(groupNames, groupLineColors, fallbackLineColors);
legendHandles = gobjects(numel(groupNames) + 1, 1);
legendLabels = strings(numel(groupNames) + 1, 1);

for groupIdx = 1:numel(groupNames)
    colorIdx = min(groupIdx, size(lineColors, 1));
    legendHandles(groupIdx) = plot(ax, NaN, NaN, ...
        lineStyles{1 + mod(groupIdx - 1, numel(lineStyles))}, ...
        'Color', lineColors(colorIdx, :), 'LineWidth', 2);
    legendLabels(groupIdx) = groupNames(groupIdx);
end

legendHandles(end) = plot(ax, NaN, NaN, 'k:', 'LineWidth', 1);
legendLabels(end) = "PM = 1";

legendHandle = legend(ax, legendHandles, legendLabels, ...
    'Location', 'southwest', 'Box', 'off');
legendHandle.FontName = 'Avenir';
legendHandle.FontSize = 12;
legendHandle.AutoUpdate = 'off';
legendHandle.Color = 'none';
end

function [lineStyles, lineColors] = local_stereo_group_line_style()
lineStyles = {'-', '--', ':'};
lineColors = [
    0.00 0.00 0.00
    0.35 0.35 0.35
    0.65 0.65 0.65
    ];
end

function lineColors = local_resolve_group_line_colors(groupNames, groupLineColors, fallbackLineColors)
if isempty(groupLineColors)
    lineColors = fallbackLineColors;
    return;
end

lineColors = fallbackLineColors;
nGroups = numel(groupNames);
if size(lineColors, 1) < nGroups
    lineColors = repmat(lineColors(end, :), nGroups, 1);
end

if size(groupLineColors, 1) >= nGroups
    validRows = all(isfinite(groupLineColors(1:nGroups, :)), 2);
    lineColors(validRows, :) = groupLineColors(validRows, :);
end
end

function lineColors = local_stereo_group_line_colors(tbl, colorConfig)
groupNames = string(categories(tbl.StereoGroup));
lineColors = nan(numel(groupNames), 3);
meanScores = local_mean_stereo_score_by_group(tbl, groupNames, colorConfig);

if ~any(isfinite(meanScores))
    return;
end

scoreCmap = StereoScores(256);
for groupIdx = 1:numel(groupNames)
    score = meanScores(groupIdx);
    if ~isfinite(score)
        continue;
    end
    score = min(max(score, 0), 100);
    colorRow = 1 + round((score / 100) * (size(scoreCmap, 1) - 1));
    colorRow = min(max(colorRow, 1), size(scoreCmap, 1));
    lineColors(groupIdx, :) = scoreCmap(colorRow, :);
end
end

function meanScores = local_mean_stereo_score_by_group(tbl, groupNames, colorConfig)
meanScores = nan(numel(groupNames), 1);
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        lower(string(colorConfig.Mode)) == "stereoscore" && ...
        isfield(colorConfig, 'ID') && isfield(colorConfig, 'StereoScore')
    configID = string(colorConfig.ID(:));
    configScores = double(colorConfig.StereoScore(:));
    idStrings = string(tbl.ID);
    for groupIdx = 1:numel(groupNames)
        groupRows = string(tbl.StereoGroup) == groupNames(groupIdx);
        groupIDs = unique(idStrings(groupRows), 'stable');
        scoreValues = nan(numel(groupIDs), 1);
        for iID = 1:numel(groupIDs)
            configIdx = find(configID == groupIDs(iID), 1, 'first');
            if ~isempty(configIdx)
                scoreValues(iID) = configScores(configIdx);
            end
        end
        meanScores(groupIdx) = mean(scoreValues, 'omitnan');
    end
    return;
end

scoreVar = local_first_existing_var(tbl, ...
    {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
if strlength(scoreVar) == 0
    return;
end

scoreValues = double(tbl.(char(scoreVar)));
for groupIdx = 1:numel(groupNames)
    groupRows = string(tbl.StereoGroup) == groupNames(groupIdx);
    meanScores(groupIdx) = mean(scoreValues(groupRows), 'omitnan');
end
end

function varName = local_first_existing_var(tbl, candidateNames)
varName = "";
for iCandidate = 1:numel(candidateNames)
    if ismember(candidateNames{iCandidate}, tbl.Properties.VariableNames)
        varName = string(candidateNames{iCandidate});
        return;
    end
end
end

function local_plot_subject_lines(ax, tbl, lme, modeChar, ElevationTransform, ...
    uniqueID, subjectColorByID, subjectLineOrder)
[~, xLog, ~, ~, ~, ~] = local_axis_info(tbl, modeChar, ElevationTransform);
groupByID = strings(numel(uniqueID), 1);
for orderIdx = 1:numel(subjectLineOrder)
    iSubject = subjectLineOrder(orderIdx);
    rowMask = string(tbl.ID) == uniqueID(iSubject);
    if ~any(rowMask)
        continue;
    end

    groupByID(iSubject) = string(tbl.StereoGroup(find(rowMask, 1, 'first')));
    xSub = xLog(rowMask);
    xGrid = linspace(min(xSub), max(xSub), 50)';
    predTbl = local_prediction_table(tbl, modeChar, xGrid, ...
        groupByID(iSubject), uniqueID(iSubject));
    yFit = predict(lme, predTbl, 'Conditional', true);
    thisColor = subjectColorByID(iSubject, :);
    plot(ax, xGrid, yFit, '-', 'Color', thisColor, 'LineWidth', 2);
end
end

function predTbl = local_prediction_table(tbl, modeChar, xGrid, groupName, idValue)
nRows = numel(xGrid);
predTbl = table();
predTbl.ID = categorical(repmat(string(idValue), nRows, 1), categories(tbl.ID));
predTbl.StereoGroup = categorical(repmat(string(groupName), nRows, 1), categories(tbl.StereoGroup));

switch modeChar
    case 'A'
        predTbl.log2real_visual_angle = xGrid;
    case 'D'
        predTbl.log2distance = xGrid;
    otherwise
        predTbl.log2elevation = xGrid;
end
end

function [xRaw, xLog, xlabelText, xTickVals, xTickLabels, xLimits] = ...
    local_axis_info(tbl, modeChar, ElevationTransform)
switch modeChar
    case 'A'
        xRaw = double(tbl.Real_Visual_Angle);
        xLog = tbl.log2real_visual_angle;
        xlabelText = {'Visual Angle [deg]','log scale'};
    case 'D'
        xRaw = double(tbl.Distance);
        xLog = tbl.log2distance;
        xlabelText = {'Distance [m]','log scale'};
    otherwise
        xRaw = tbl.ElevationModel;
        xLog = tbl.log2elevation;
        if ElevationTransform == 2 || ElevationTransform == 6
            xlabelText = {'|Elevation| [deg]','log scale'};
        else
            xlabelText = {'Elevation [deg]','log scale'};
        end
end

if modeChar == 'E'
    [xTickVals, xTickLabels, xLimits] = local_elevation_ticks_and_limits(xRaw, ElevationTransform);
else
    [xTickVals, xTickLabels] = local_oldstyle_ticks(xRaw, modeChar, ElevationTransform);
    xLimits = [log2(min(xRaw) * 0.95) log2(max(xRaw) * 1.05)];
end
end

function local_add_color_key(ax, cmap, nsubjects, colorConfig)
if isempty(cmap)
    return;
end

if isstruct(colorConfig) && isfield(colorConfig, 'Mode')
    mode = lower(string(colorConfig.Mode));
    switch mode
        case "stereoscore"
            local_add_stereo_score_key(ax);
            return;
        case "clinicalnotes"
            local_add_clinical_condition_key(ax, colorConfig);
            return;
    end
end

ax.Units = 'normalized';
axisPosition = ax.Position;
colormap(ax, cmap);
clim(ax, [1 max(size(cmap, 1), 2)]);
cb = colorbar(ax, 'Location', 'eastoutside');
ax.Position = axisPosition;
cb.Units = 'normalized';
cb.Position = [axisPosition(1) + axisPosition(3) + 0.018, ...
    axisPosition(2), 0.015, axisPosition(4)];
cb.Label.String = 'Participant color rank';
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 18;
cb.FontName = 'Avenir';
cb.FontSize = 18;

nTicks = min(5, max(2, size(cmap, 1)));
cb.Ticks = linspace(1, size(cmap, 1), nTicks);
cb.TickLabels = string(round(linspace(1, nsubjects, nTicks)));
end

function local_add_stereo_score_key(ax)
axisPosition = ax.Position;
figHandle = ancestor(ax, 'figure');
colorbarPosition = [axisPosition(1) + axisPosition(3) + 0.060, ...
    axisPosition(2), 0.015, axisPosition(4)];
cb = add_stereo_score_colorbar(figHandle, 'Normed stereo score', colorbarPosition);
cb.FontName = 'Avenir';
cb.FontSize = 18;
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 18;
ax.Position = axisPosition;
end

function local_add_clinical_condition_key(ax, colorConfig)
axisPosition = ax.Position;
legendHandle = Quad_add_clinical_notes_legend(ax, colorConfig, 'eastoutside');
ax.Position = axisPosition;
legendHandle.Units = 'normalized';
legendHandle.Position = [axisPosition(1) + axisPosition(3) + 0.025, ...
    axisPosition(2) + 0.13, 0.16, 0.32];
legendHandle.FontSize = 11;
legendHandle.Title.String = 'Clinical condition';
legendHandle.Title.FontName = 'Avenir';
legendHandle.Title.FontSize = 11;
end

function local_export_png(figHandle, outFile, dpi)
if nargin < 3 || isempty(dpi)
    dpi = 600;
end
set(figHandle, 'PaperPositionMode', 'auto');
print(figHandle, outFile, '-dpng', sprintf('-r%d', dpi));
end

function [xTickVals, xTickLabels] = local_oldstyle_ticks(xRaw, modeChar, ElevationTransform)
minVal = min(xRaw);
maxVal = max(xRaw);
[xTickVals, nativeVals] = local_adaptive_log_ticks(minVal, maxVal);

if modeChar == 'E' && any(ElevationTransform == [5 6])
    nativeVals = round(90 * (nativeVals - 1), 1);
elseif modeChar ~= 'E'
    nativeVals = round(nativeVals, 1);
end
xTickLabels = local_format_tick_labels(nativeVals);
end

function [xTickVals, xTickLabels, xLimits] = local_elevation_ticks_and_limits(xRaw, ElevationTransform)
xmin = min(xRaw);
xmax = max(xRaw);
xTickVals = log2([xmin xmax]);

if any(ElevationTransform == [5 6])
    nativeVals = round(90 * (2.^xTickVals - 1), 1);
else
    nativeVals = round(2.^xTickVals - 1, 1);
end
xTickLabels = local_format_tick_labels(nativeVals);

span = xmax - xmin;
margin = max(0.05 * span, 0.02);
plotMin = max(eps, xmin - margin);
plotMax = xmax + margin;
xLimits = log2([plotMin plotMax]);
end

function [cmap, sorted_idx] = local_validate_color_inputs(cmap, sorted_idx, nsubjects)
if isempty(cmap)
    cmap = lines(max(nsubjects, 1));
end
if isempty(sorted_idx)
    sorted_idx = (1:nsubjects)';
end
if size(cmap, 1) < nsubjects
    cmap = interp1(linspace(0, 1, size(cmap, 1)), cmap, ...
        linspace(0, 1, nsubjects), 'linear');
end
end

function subjectColorByID = local_subject_colors_by_id(uniqueID, cmap, sorted_idx, colorConfig)
subjectColorByID = nan(numel(uniqueID), 3);
if isstruct(colorConfig) && isfield(colorConfig, 'ID') && isfield(colorConfig, 'Color')
    configID = string(colorConfig.ID(:));
    for subjectIdx = 1:numel(uniqueID)
        configIdx = find(configID == uniqueID(subjectIdx), 1, 'first');
        if ~isempty(configIdx)
            subjectColorByID(subjectIdx, :) = colorConfig.Color(configIdx, :);
        end
    end
end

missingColor = any(isnan(subjectColorByID), 2);
for subjectIdx = find(missingColor)'
    subjectColorByID(subjectIdx, :) = local_subject_color_row(subjectIdx, cmap, sorted_idx);
end
end

function subjectcolor = local_subject_colors(idData, uniqueID, subjectColorByID)
subjectcolor = zeros(numel(idData), 3);
idStrings = string(idData);
for rowIdx = 1:numel(idData)
    subjectIdx = find(uniqueID == idStrings(rowIdx), 1, 'first');
    if isempty(subjectIdx)
        subjectIdx = 1;
    end
    subjectcolor(rowIdx, :) = subjectColorByID(subjectIdx, :);
end
end

function thisColor = local_subject_color_row(subjectIdx, cmap, sorted_idx)
colorRow = find(sorted_idx == subjectIdx, 1, 'first');
if isempty(colorRow)
    colorRow = subjectIdx;
end
colorRow = min(max(colorRow, 1), size(cmap, 1));
thisColor = cmap(colorRow, :);
end

function [cmap, sorted_idx] = local_color_inputs_from_config(colorConfig, cmap, sorted_idx)
if isfield(colorConfig, 'RankCmap')
    cmap = colorConfig.RankCmap;
elseif isfield(colorConfig, 'Color')
    cmap = colorConfig.Color;
end

if isfield(colorConfig, 'SortedIdx')
    sorted_idx = colorConfig.SortedIdx;
elseif isempty(sorted_idx) && isfield(colorConfig, 'ID')
    sorted_idx = (1:numel(colorConfig.ID))';
end
end

function subjectOrder = local_inverse_rank_subject_order(uniqueID, sorted_idx, colorConfig)
uniqueID = string(uniqueID(:));

if isstruct(colorConfig) && isfield(colorConfig, 'ID') && isfield(colorConfig, 'SortedIdx')
    configID = string(colorConfig.ID(:));
    configSortedIdx = colorConfig.SortedIdx(:);
    configSortedIdx = configSortedIdx(isfinite(configSortedIdx) & ...
        configSortedIdx >= 1 & configSortedIdx <= numel(configID));
    rankedIDs = flipud(configID(configSortedIdx));

    subjectOrder = zeros(0, 1);
    for rankIdx = 1:numel(rankedIDs)
        subjectIdx = find(uniqueID == rankedIDs(rankIdx), 1, 'first');
        if ~isempty(subjectIdx)
            subjectOrder(end + 1, 1) = subjectIdx; %#ok<AGROW>
        end
    end
else
    sorted_idx = sorted_idx(:);
    sorted_idx = sorted_idx(isfinite(sorted_idx) & ...
        sorted_idx >= 1 & sorted_idx <= numel(uniqueID));
    subjectOrder = flipud(sorted_idx);
end

missingSubjects = setdiff((1:numel(uniqueID))', subjectOrder, 'stable');
subjectOrder = [subjectOrder; missingSubjects];
end

function [estimate, pval] = local_main_effect_stats(lme, modeChar)
predictorName = local_predictor_name(modeChar);
coefNames = string(lme.Coefficients.Name);
mainRows = coefNames == predictorName;
if any(mainRows)
    rowIdx = find(mainRows, 1, 'first');
    estimate = lme.Coefficients.Estimate(rowIdx);
    pval = lme.Coefficients.pValue(rowIdx);
else
    estimate = NaN;
    pval = NaN;
end
end

function pval = local_interaction_joint_pvalue(lme, modeChar, comparisonTbl)
pval = local_comparison_pvalue(comparisonTbl);
if isfinite(pval)
    return;
end

predictorName = local_predictor_name(modeChar);
coefNames = string(lme.Coefficients.Name);
interactionRows = contains(coefNames, predictorName) & contains(coefNames, "StereoGroup");
if any(interactionRows)
    pval = min(lme.Coefficients.pValue(interactionRows));
else
    pval = NaN;
end
end

function pval = local_comparison_pvalue(comparisonTbl)
pval = NaN;
if isempty(comparisonTbl)
    return;
end

try
    pvals = double(comparisonTbl.pValue);
catch
    return;
end

pvals = pvals(isfinite(pvals));
if ~isempty(pvals)
    pval = pvals(end);
end
end

function predictorName = local_predictor_name(modeChar)
switch modeChar
    case 'A'
        predictorName = "log2real_visual_angle";
    case 'D'
        predictorName = "log2distance";
    otherwise
        predictorName = "log2elevation";
end
end

function factorLabel = local_factor_label(modeChar)
switch modeChar
    case 'A'
        factorLabel = 'Visual Angle';
    case 'D'
        factorLabel = 'Distance';
    otherwise
        factorLabel = 'Elevation';
end
end

function pStr = local_format_pvalue(pval)
if ~isfinite(pval)
    pStr = 'n/a';
elseif pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end

function estimateStr = local_format_estimate(estimate)
if ~isfinite(estimate)
    estimateStr = 'n/a';
elseif abs(estimate) >= 10
    estimateStr = sprintf('%.2f', estimate);
else
    estimateStr = sprintf('%.3f', estimate);
end
end

function labels = local_format_tick_labels(vals)
labels = strings(size(vals));
for i = 1:numel(vals)
    if abs(vals(i)) > 1000
        labels(i) = sprintf('%.1e', vals(i));
    else
        labels(i) = string(vals(i));
    end
end
end

function [tickPos, nativeVals] = local_adaptive_log_ticks(minVal, maxVal)
if ~isfinite(minVal) || ~isfinite(maxVal) || minVal <= 0 || maxVal <= 0
    tickPos = [];
    nativeVals = [];
    return
end

if maxVal < minVal
    tmp = minVal;
    minVal = maxVal;
    maxVal = tmp;
end

if minVal == maxVal
    nativeVals = minVal;
else
    logMin = log2(minVal);
    logMax = log2(maxVal);
    logSpan = logMax - logMin;

    if logSpan < 1
        nTicks = 2;
    elseif logSpan < 2.5
        nTicks = 3;
    elseif logSpan < 4.5
        nTicks = 4;
    else
        nTicks = 2;
    end

    nativeVals = 2.^linspace(logMin, logMax, nTicks);
    nativeVals(1) = minVal;
    nativeVals(end) = maxVal;
end

nativeVals = unique(nativeVals, 'stable');
tickPos = log2(nativeVals);
end

function stereoGroup = local_stereo_group_categorical(rawGroup)
if isnumeric(rawGroup) || islogical(rawGroup)
    groupValues = double(rawGroup);
    uniqueValues = unique(groupValues(isfinite(groupValues)));
    if all(ismember(uniqueValues, [0 1 2 3]))
        groupText = strings(size(groupValues));
        groupText(groupValues == 1) = "StereoTypical";
        groupText(groupValues == 2) = "StereoDeficient";
        groupText(groupValues == 3) = "StereoBlind";
        stereoGroup = categorical(groupText, ...
            ["StereoTypical", "StereoDeficient", "StereoBlind"], ...
            ["StereoTypical", "StereoDeficient", "StereoBlind"]);
    else
        groupText = "Group" + string(groupValues);
        groupText(~isfinite(groupValues)) = "";
        stereoGroup = categorical(groupText);
    end
elseif iscategorical(rawGroup)
    stereoGroup = rawGroup;
    stereoGroup = local_standardize_numeric_group_labels(stereoGroup);
    stereoGroup = reordercats(stereoGroup, local_order_categories(categories(stereoGroup)));
else
    stereoGroup = categorical(string(rawGroup));
    stereoGroup = local_standardize_numeric_group_labels(stereoGroup);
    stereoGroup = reordercats(stereoGroup, local_order_categories(categories(stereoGroup)));
end
end

function stereoGroup = local_standardize_numeric_group_labels(stereoGroup)
groupText = string(stereoGroup);
validText = groupText(~ismissing(groupText) & groupText ~= "");
if ~isempty(validText) && all(ismember(validText, ["1", "2", "3"]))
    groupText(groupText == "1") = "StereoTypical";
    groupText(groupText == "2") = "StereoDeficient";
    groupText(groupText == "3") = "StereoBlind";
    stereoGroup = categorical(groupText, ...
        ["StereoTypical", "StereoDeficient", "StereoBlind"], ...
        ["StereoTypical", "StereoDeficient", "StereoBlind"]);
end
end

function orderedCategories = local_order_categories(categoriesIn)
categoriesIn = string(categoriesIn(:));
preferred = ["StereoTypical"; "Typical"; "StereoDeficient"; "Deficient"; ...
    "StereoBlind"; "Blind"];
orderedCategories = strings(0, 1);
for iPreferred = 1:numel(preferred)
    if any(categoriesIn == preferred(iPreferred))
        orderedCategories(end + 1, 1) = preferred(iPreferred); %#ok<AGROW>
    end
end
for iCategory = 1:numel(categoriesIn)
    if ~ismember(categoriesIn(iCategory), orderedCategories)
        orderedCategories(end + 1, 1) = categoriesIn(iCategory); %#ok<AGROW>
    end
end
orderedCategories = cellstr(orderedCategories);
end

function groupSummaryLines = local_group_summary_lines(tbl)
groupNames = string(categories(tbl.StereoGroup));
groupSummaryLines = cell(1, numel(groupNames) + 1);
groupSummaryLines{1} = 'StereoGroup counts:';
for iGroup = 1:numel(groupNames)
    rowMask = string(tbl.StereoGroup) == groupNames(iGroup);
    groupSummaryLines{iGroup + 1} = sprintf('  %s: %d rows, %d participants', ...
        groupNames(iGroup), sum(rowMask), numel(unique(tbl.ID(rowMask))));
end
end

function sourceCsv = local_source_file_label(tbl, tblName)
sourceCsv = char(string(tblName));
try
    if isstruct(tbl.Properties.UserData) && isfield(tbl.Properties.UserData, 'SourceFile')
        sourceCsv = char(string(tbl.Properties.UserData.SourceFile));
    end
catch
end
if ~endsWith(string(sourceCsv), ".csv", "IgnoreCase", true)
    sourceCsv = sprintf('%s.csv (inferred from tblName; function input is a table)', sourceCsv);
end
end
