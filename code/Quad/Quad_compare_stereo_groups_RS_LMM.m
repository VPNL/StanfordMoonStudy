function [participantTbl, statisticsTbl, baseModels, groupModels] = ...
    Quad_compare_stereo_groups_RS_LMM(quadFile, taskName, quadBasename, ...
    resultsDir, stereoThreshold, transformId, participantColorMode, saveFigure)
%QUAD_COMPARE_STEREO_GROUPS_RS_LMM Formal stereo-group RS-LMM comparison.
%
% For each physical predictor, this function fits:
%   Base:  log2(PM) ~ centered predictor + (1 + centered predictor | ID)
%   Group: log2(PM) ~ centered predictor * StereoGroup +
%                    (1 + centered predictor | ID)
%
% The group main effect tests the intercept difference at the mean value of
% the predictor. The interaction tests the group slope difference. The
% likelihood-ratio comparison tests whether adding both group terms improves
% the model. Typical is the reference group.

if nargin < 5 || isempty(stereoThreshold)
    stereoThreshold = 85;
end
if nargin < 6 || isempty(transformId)
    transformId = 2;
end
if nargin < 7 || isempty(participantColorMode)
    participantColorMode = "clinicalnotes";
end
if nargin < 8 || isempty(saveFigure)
    saveFigure = true;
end
if transformId ~= 2
    error('QuadStereoGroupRSLMM:UnsupportedTransform', ...
        'This analysis currently requires transformId=2 (absolute elevation).');
end
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

importOptions = detectImportOptions(quadFile, 'VariableNamingRule', 'modify');
if ismember('ClinicalNotes', importOptions.VariableNames)
    importOptions = setvartype(importOptions, 'ClinicalNotes', 'string');
end
tbl = readtable(quadFile, importOptions);
scoreVar = quadFindFirstTableVariable(tbl, ...
    {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
tbl = tbl(strcmpi(string(tbl.Task), string(taskName)), :);
tbl = tbl(isfinite(double(tbl.(scoreVar))), :);

tbl.Distance = double(tbl.Observer_Distance) ./ 100;
tbl.Elevation = abs(double(tbl.Observer_Elevation));
tbl.log2ratio_visual_angle = log2(double(tbl.Ratio_Visual_Angle));
tbl.log2real_visual_angle = log2(double(tbl.Real_Visual_Angle));
tbl.log2distance = log2(tbl.Distance);
tbl.log2elevation = log2(1 + tbl.Elevation);
keepRows = isfinite(tbl.log2ratio_visual_angle) & ...
    isfinite(tbl.log2real_visual_angle) & isfinite(tbl.log2distance) & ...
    isfinite(tbl.log2elevation);
tbl = tbl(keepRows, :);

if ~iscategorical(tbl.ID)
    tbl.ID = categorical(tbl.ID);
end
groupOrder = ["Typical", "Deficient"];
groupText = repmat(groupOrder(1), height(tbl), 1);
groupText(double(tbl.(scoreVar)) < stereoThreshold) = groupOrder(2);
tbl.StereoGroup = categorical(groupText, groupOrder, groupOrder);

predictorNames = ["log2real_visual_angle", "log2distance", "log2elevation"];
centeredNames = predictorNames;
factorNames = ["Angle", "Distance", "Elevation"];
predictorCenters = nan(numel(predictorNames), 1);
for factorIdx = 1:numel(predictorNames)
    predictorCenters(factorIdx) = mean(tbl.(predictorNames(factorIdx)), 'omitnan');
    tbl.(centeredNames(factorIdx)) = tbl.(predictorNames(factorIdx)) - ...
        predictorCenters(factorIdx);
end

colorConfig = Quad_build_participant_color_config(tbl, resultsDir, ...
    sprintf('%s_%s_RS_LMM', quadBasename, taskName), ...
    participantColorMode, true);
[~, clinicalCategory, clinicalIDs] = ...
    Quad_compute_clinical_notes_color_idx(tbl, resultsDir, ...
    sprintf('%s_%s_RS_LMM', quadBasename, taskName), true);

baseModels = struct();
groupModels = struct();
participantParts = cell(numel(factorNames), 1);
statisticsParts = cell(numel(factorNames), 1);
comparisonStore = cell(numel(factorNames), 1);

for factorIdx = 1:numel(factorNames)
    factorName = factorNames(factorIdx);
    predictor = centeredNames(factorIdx);
    baseFormula = sprintf(['log2ratio_visual_angle ~ %s + ' ...
        '(1 + %s|ID)'], predictor, predictor);
    groupFormula = sprintf(['log2ratio_visual_angle ~ %s*StereoGroup + ' ...
        '(1 + %s|ID)'], predictor, predictor);
    baseModel = fitlme(tbl, baseFormula, 'FitMethod', 'ML');
    groupModel = fitlme(tbl, groupFormula, 'FitMethod', 'ML');
    modelComparison = compare(baseModel, groupModel);
    baseModels.(factorName) = baseModel;
    groupModels.(factorName) = groupModel;
    comparisonStore{factorIdx} = modelComparison;

    coefNames = string(groupModel.Coefficients.Name);
    groupCoefName = "StereoGroup_Deficient";
    interactionMask = contains(coefNames, predictor) & ...
        contains(coefNames, groupCoefName);
    groupIdx = find(coefNames == groupCoefName, 1, 'first');
    interactionIdx = find(interactionMask, 1, 'first');
    predictorIdx = find(coefNames == predictor, 1, 'first');
    interceptIdx = find(coefNames == "(Intercept)", 1, 'first');
    if isempty(groupIdx) || isempty(interactionIdx)
        error('QuadStereoGroupRSLMM:MissingGroupCoefficient', ...
            'Could not identify the stereo-group coefficients for %s.', factorName);
    end

    participantIDs = string(categories(removecats(tbl.ID)));
    subjectIntercept = Quad_extract_subject_model_coefficient( ...
        groupModel, '(Intercept)', participantIDs);
    subjectSlope = Quad_extract_subject_model_coefficient( ...
        groupModel, predictor, participantIDs);
    participantGroup = strings(numel(participantIDs), 1);
    participantScore = nan(numel(participantIDs), 1);
    participantCategory = strings(numel(participantIDs), 1);
    for participantIdx = 1:numel(participantIDs)
        participantRows = string(tbl.ID) == participantIDs(participantIdx);
        participantGroup(participantIdx) = string(tbl.StereoGroup( ...
            find(participantRows, 1, 'first')));
        participantScore(participantIdx) = mean( ...
            double(tbl.(scoreVar)(participantRows)), 'omitnan');
        clinicalIdx = find(string(clinicalIDs) == participantIDs(participantIdx), 1);
        participantCategory(participantIdx) = clinicalCategory(clinicalIdx);
    end
    deficientParticipants = participantGroup == groupOrder(2);
    subjectIntercept(deficientParticipants) = ...
        subjectIntercept(deficientParticipants) + ...
        groupModel.Coefficients.Estimate(groupIdx);
    subjectSlope(deficientParticipants) = subjectSlope(deficientParticipants) + ...
        groupModel.Coefficients.Estimate(interactionIdx);

    participantParts{factorIdx} = table( ...
        repmat(string(taskName), numel(participantIDs), 1), ...
        repmat(factorName, numel(participantIDs), 1), participantIDs, ...
        categorical(participantGroup, groupOrder, groupOrder), ...
        participantScore, participantCategory, subjectIntercept, ...
        2 .^ subjectIntercept, subjectSlope, ...
        'VariableNames', {'Task', 'Factor', 'ID', 'StereoGroup', ...
        'NormedStereoScore', 'ClinicalCategory', ...
        'SubjectLog2InterceptAtMean', 'SubjectPowerLawInterceptAtMean', ...
        'SubjectSlope'});

    statisticsParts{factorIdx} = table(string(taskName), factorName, ...
        sum(participantGroup == groupOrder(1)), ...
        sum(participantGroup == groupOrder(2)), predictorCenters(factorIdx), ...
        groupModel.Coefficients.Estimate(interceptIdx), ...
        groupModel.Coefficients.Estimate(groupIdx), ...
        groupModel.Coefficients.pValue(groupIdx), ...
        groupModel.Coefficients.Estimate(predictorIdx), ...
        groupModel.Coefficients.Estimate(interactionIdx), ...
        groupModel.Coefficients.pValue(interactionIdx), ...
        modelComparison.pValue(2), baseModel.ModelCriterion.AIC, ...
        groupModel.ModelCriterion.AIC, ...
        'VariableNames', {'Task', 'Factor', 'NTypical', 'NDeficient', ...
        'PredictorCenter', 'TypicalInterceptAtMean', ...
        'DeficientMinusTypicalIntercept', 'InterceptGroupPValue', ...
        'TypicalSlope', 'DeficientMinusTypicalSlope', ...
        'SlopeInteractionPValue', 'JointGroupAndInteractionLRPValue', ...
        'BaseAIC', 'GroupAIC'});
end

participantTbl = vertcat(participantParts{:});
statisticsTbl = vertcat(statisticsParts{:});
fileStem = sprintf('%s_%s_stereo_group_RS_LMM', quadBasename, taskName);
writetable(participantTbl, fullfile(resultsDir, [fileStem '_participants.csv']));
writetable(statisticsTbl, fullfile(resultsDir, [fileStem '_statistics.csv']));

reportFile = fullfile(resultsDir, [fileStem '_models.txt']);
fileID = fopen(reportFile, 'w');
if fileID == -1
    error('QuadStereoGroupRSLMM:ReportOpenFailed', ...
        'Could not open report file %s.', reportFile);
end
cleanupObject = onCleanup(@() fclose(fileID));
fprintf(fileID, 'Stereo-group random-slope LMM analysis: %s task\n', taskName);
fprintf(fileID, 'StereoDeficient threshold: score < %g\n', stereoThreshold);
fprintf(fileID, 'Typical is the reference group; predictors are mean-centered.\n\n');
for factorIdx = 1:numel(factorNames)
    factorName = factorNames(factorIdx);
    fprintf(fileID, '===== %s =====\n', factorName);
    Quad_write_compact_lme_report(fileID, 'Base model', ...
        baseModels.(factorName));
    Quad_write_compact_lme_report(fileID, 'Stereo-group model', ...
        groupModels.(factorName));
    Quad_write_compact_model_comparison(fileID, ...
        ['Joint likelihood-ratio test: group intercept difference + ' ...
        'group-by-predictor slope difference'], comparisonStore{factorIdx});
end

if ~saveFigure
    return;
end

figH = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.02 0.05 0.96 0.86], 'Name', fileStem, 'Visible', 'off');
tiled = tiledlayout(figH, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
axesList = gobjects(6, 1);
for factorIdx = 1:numel(factorNames)
    factorTbl = participantParts{factorIdx};
    x = Quad_group_plot_x_positions(factorTbl.StereoGroup, groupOrder);

    axIntercept = nexttile(tiled, factorIdx);
    axesList(factorIdx) = axIntercept;
    hold(axIntercept, 'on');
    Quad_plot_group_participant_points(axIntercept, x, ...
        factorTbl.SubjectPowerLawInterceptAtMean, factorTbl.ID, colorConfig);
    Quad_plot_group_means(axIntercept, factorTbl.StereoGroup, ...
        factorTbl.SubjectPowerLawInterceptAtMean, groupOrder);
    set(axIntercept, 'XLim', [0.5 2.5], 'XTick', 1:2, ...
        'XTickLabel', {'Typical', 'Deficient'}, ...
        'FontName', 'Avenir', 'FontSize', 13);
    ylabel(axIntercept, 'Power-law intercept at mean predictor', 'FontSize', 14);
    title(axIntercept, sprintf('%s intercept\nGroup intercept difference p=%s', ...
        factorNames(factorIdx), ...
        Quad_format_pvalue(statisticsTbl.InterceptGroupPValue(factorIdx))), ...
        'FontSize', 13, 'FontWeight', 'normal');
    box(axIntercept, 'off');

    axSlope = nexttile(tiled, factorIdx + 3);
    axesList(factorIdx + 3) = axSlope;
    hold(axSlope, 'on');
    Quad_plot_group_participant_points(axSlope, x, factorTbl.SubjectSlope, ...
        factorTbl.ID, colorConfig);
    Quad_plot_group_means(axSlope, factorTbl.StereoGroup, ...
        factorTbl.SubjectSlope, groupOrder);
    yline(axSlope, 0, 'k-', 'LineWidth', 1);
    set(axSlope, 'XLim', [0.5 2.5], 'XTick', 1:2, ...
        'XTickLabel', {'Typical', 'Deficient'}, ...
        'FontName', 'Avenir', 'FontSize', 13);
    ylabel(axSlope, 'Subject slope', 'FontSize', 14);
    title(axSlope, sprintf(['%s slope\nGroup slope difference p=%s\n' ...
        'Joint intercept+slope LRT p=%s'], factorNames(factorIdx), ...
        Quad_format_pvalue(statisticsTbl.SlopeInteractionPValue(factorIdx)), ...
        Quad_format_pvalue(statisticsTbl.JointGroupAndInteractionLRPValue(factorIdx))), ...
        'FontSize', 13, 'FontWeight', 'normal');
    box(axSlope, 'off');
end
title(tiled, sprintf('%s: StereoTypical versus StereoDeficient RS LMM', taskName), ...
    'FontName', 'Avenir', 'FontSize', 18, 'FontWeight', 'normal');
Quad_finish_group_color_key(axesList, colorConfig);
exportgraphics(figH, fullfile(resultsDir, [fileStem '.png']), 'Resolution', 600);
close(figH);
end
