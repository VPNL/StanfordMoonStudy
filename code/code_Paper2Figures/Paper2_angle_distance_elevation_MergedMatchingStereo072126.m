% Paper2_angle_distance_elevation_MergedMatchingStereo072126
% Generate the Paper 2 matching figures with one elevation transform and
% one participant-color mode selected in the configuration block below.

clear;
close all force;
clc;

scriptDir = fileparts(mfilename('fullpath'));
codeDir = fileparts(scriptDir);
addpath(genpath(codeDir));

%% Run configuration
quadFile = fullfile(codeDir, '..', 'QuadExperiments', 'Data', ...
    'merged_matching_0429_x7001.csv');
stereoThreshold = 85;
transformId = 2; % abs(Elevation); this script intentionally runs no transform loop.
colorMode = "clinicalnotes"; % "stereoscore" or "clinicalnotes"
groupComparisonColorMode = colorMode; % "clinicalnotes", "stereoscore", or "id"
saveLME = true;

% runConfigs = { ...
%     struct( ...
%         'resultsSubdir', sprintf('StereoDeficient%d', stereoThreshold), ...
%         'basenameSuffix', sprintf('_justStereoDeficient_%d', stereoThreshold), ...
%         'justStereoDeficient', true, ...
%         'justStereoTypical', false) ...
%     };

runConfigs = { ...
    struct('resultsSubdir', 'All', 'basenameSuffix', '', ...
        'justStereoDeficient', false, 'justStereoTypical', false), ...
    struct('resultsSubdir', sprintf('StereoDeficient%d', stereoThreshold), ...
        'basenameSuffix', sprintf('_justStereoDeficient_%d', stereoThreshold), ...
        'justStereoDeficient', true, 'justStereoTypical', false), ...
    struct('resultsSubdir', sprintf('StereoTypical%d', stereoThreshold), ...
        'basenameSuffix', sprintf('_justStereoTypical_%d', stereoThreshold), ...
        'justStereoDeficient', false, 'justStereoTypical', true) ...
    };

switch lower(colorMode)
    case "stereoscore"
        colorResultsFolder = 'MatchingColorbyStereoScore';
    case "clinicalnotes"
        colorResultsFolder = 'MatchingColorbyClinicalNotes';
    otherwise
        error('Paper2Matching:InvalidColorMode', ...
            'colorMode must be "stereoscore" or "clinicalnotes".');
end
resultsRoot = fullfile(codeDir, '..', 'Paper2Figures', colorResultsFolder);

%% Load data
allQuadDataBase = readtable(quadFile);
[~, quadBasenameBase] = fileparts(quadFile);
stereoScoreVar = quadFindFirstTableVariable(allQuadDataBase, ...
    {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
stereoGroupResults = struct();

for runIdx = 1:numel(runConfigs)
    runConfig = runConfigs{runIdx};
    allQuadData = allQuadDataBase;
    quadBasename = [quadBasenameBase runConfig.basenameSuffix];

    if runConfig.justStereoDeficient
        allQuadData = allQuadData(allQuadData.(stereoScoreVar) < stereoThreshold, :);
    elseif runConfig.justStereoTypical
        allQuadData = allQuadData(allQuadData.(stereoScoreVar) >= stereoThreshold, :);
    end

    baseResultsDir = fullfile(resultsRoot, runConfig.resultsSubdir);
    if ~exist(baseResultsDir, 'dir')
        mkdir(baseResultsDir);
    end

    fprintf('Running %s (%d of %d), colored by %s: %d rows from %d participants.\n', ...
        runConfig.resultsSubdir, runIdx, numel(runConfigs), colorMode, ...
        height(allQuadData), numel(unique(allQuadData.ID)));

    % Use observer-referenced distance and elevation for this analysis.
    allQuadData.Elevation = allQuadData.Observer_Elevation;
    allQuadData.Distance = allQuadData.Observer_Distance;

    columnNames = {'ID', 'Measurement', 'Real_Visual_Angle', 'Distance', ...
        'Elevation', 'Task', 'Reported_Visual_Angle', 'Ratio_Visual_Angle'};
    quadSubsetData = table( ...
        allQuadData.ID, allQuadData.Measurement, allQuadData.Real_Visual_Angle, ...
        allQuadData.Distance / 100, allQuadData.Elevation, allQuadData.Task, ...
        allQuadData.Reported_Visual_Angle, allQuadData.Ratio_Visual_Angle, ...
        'VariableNames', columnNames);

    [pairedTbl, lmeRI, lmeRS, cmpTbl] = ...
        PerceptualVsAdjusted_ReportedVisualAngle( ...
        allQuadData, quadBasename, baseResultsDir, colorMode);

    colorConfig = Quad_build_participant_color_config( ...
        allQuadData, baseResultsDir, quadBasename, colorMode, true);
    cmap = colorConfig.RankCmap;
    sortedIdx = colorConfig.SortedIdx;

    taskOrder = {'Perceptual', 'Adjusted'};
    taskData = struct( ...
        'Perceptual', quadSubsetData(strcmp(quadSubsetData.Task, 'Perceptual'), :), ...
        'Adjusted', quadSubsetData(strcmp(quadSubsetData.Task, 'Adjusted'), :));

    [transformSuffix, ~, modelTransform] = get_quad_transform_spec(transformId);
    resultsDir = fullfile(baseResultsDir, transformSuffix);
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end

    threeFactorLME = struct('Perceptual', [], 'Adjusted', []);
    singleRSLME = struct( ...
        'Perceptual', struct('Angle', [], 'Distance', [], 'Elevation', []), ...
        'Adjusted', struct('Angle', [], 'Distance', [], 'Elevation', []));
    singleFactorRI = struct('Perceptual', [], 'Adjusted', []);
    fullModelLME = struct('Perceptual', [], 'Adjusted', []);

    for taskIdx = 1:numel(taskOrder)
        task = taskOrder{taskIdx};
        taskTable = taskData.(task);
        tableName = sprintf('%s_%s_%s', quadBasename, task, transformSuffix);

        [singleAngleLME, singleDistanceLME, singleElevationLME, ...
            singleAngleRSLME, singleDistanceRSLME, singleElevationRSLME] = ...
            Quad_PM_by_task_single(taskTable, tableName, resultsDir, ...
            saveLME, cmap, sortedIdx, modelTransform);
        quadCloseFigures();

        [angleLME, distanceLME, elevationLME, angleDistanceLME, ...
            angleElevationLME, distanceElevationLME, threeFactorModel] = ...
            Quad_PM_by_task(taskTable, tableName, resultsDir, saveLME, ...
            cmap, sortedIdx, modelTransform);
        quadCloseFigures();

        fullModel = fit_PM_full_VA_D_E_model(taskTable, ...
            [tableName '_fullmodel_fit'], resultsDir, saveLME, ...
            cmap, sortedIdx, modelTransform);

        summaryFile = fullfile(resultsDir, [tableName '_lme_summary.csv']);
        Quad_export_LME_summary_csv(quadBasename, task, ...
            angleLME, distanceLME, elevationLME, angleDistanceLME, ...
            angleElevationLME, distanceElevationLME, threeFactorModel, summaryFile);

        taskRows = strcmp(allQuadData.Task, task);
        Quad_PM_intercepts_by_stereoscore(allQuadData(taskRows, :), ...
            threeFactorModel, tableName, resultsDir, colorConfig);

        threeFactorLME.(task) = threeFactorModel;
        singleRSLME.(task).Angle = singleAngleRSLME;
        singleRSLME.(task).Distance = singleDistanceRSLME;
        singleRSLME.(task).Elevation = singleElevationRSLME;

        singleFactorRI.(task) = struct( ...
            'Angle', singleAngleLME, ...
            'Distance', singleDistanceLME, ...
            'Elevation', singleElevationLME);
        fullModelLME.(task) = fullModel;
    end

    %% Compare model parameters across tasks
    if ~isempty(threeFactorLME.Perceptual) && ~isempty(threeFactorLME.Adjusted)
        Quad_PM_intercept_StereoNotes(allQuadData, threeFactorLME.Perceptual, ...
            threeFactorLME.Adjusted, quadBasename, resultsDir, true, [0 3.5], colorConfig);
        Quad_PM_intercept_StereoNotes(allQuadData, threeFactorLME.Perceptual, ...
            threeFactorLME.Adjusted, [quadBasename '_v2'], resultsDir, true, [0 2], colorConfig);
    end

    if ~isempty(singleRSLME.Perceptual.Angle) && ~isempty(singleRSLME.Adjusted.Angle)
        slopeAxisLimits = [ ...
            -0.6 0.0; ... % visual angle
            -0.2 0.6; ... % distance
            -1.0 0.2];    % elevation
        PM_compare_single_RS_across_tasks(allQuadData, ...
            singleRSLME.Perceptual.Angle, singleRSLME.Perceptual.Distance, ...
            singleRSLME.Perceptual.Elevation, singleRSLME.Adjusted.Angle, ...
            singleRSLME.Adjusted.Distance, singleRSLME.Adjusted.Elevation, ...
            quadBasename, resultsDir, true, slopeAxisLimits, colorConfig);
    end

    allResultsFile = fullfile(resultsRoot, [char(quadBasename) '.mat']);
    save(allResultsFile, 'pairedTbl', 'lmeRI', 'lmeRS', 'cmpTbl', ...
        'colorConfig', 'threeFactorLME', 'singleRSLME', 'singleFactorRI', ...
        'fullModelLME', 'transformId', 'colorMode');

    groupResult = struct('Data', allQuadData, ...
        'ThreeFactorLME', threeFactorLME, 'SingleRSLME', singleRSLME);
    if runConfig.justStereoDeficient
        stereoGroupResults.StereoDeficient = groupResult;
    elseif runConfig.justStereoTypical
        stereoGroupResults.StereoTypical = groupResult;
    end
    quadCloseFigures();
end

%% Compare independent StereoTypical and StereoDeficient groups within each task
if isfield(stereoGroupResults, 'StereoTypical') && ...
        isfield(stereoGroupResults, 'StereoDeficient')
    switch lower(string(groupComparisonColorMode))
        case {"clinicalnotes", "clinical"}
            groupColorFolder = 'MatchingAcrossStereoGroupsColorByClinicalNotes';
        case {"stereoscore", "stereo", "normed", "normedstereoscore"}
            groupColorFolder = 'MatchingAcrossStereoGroupsColorByStereoScore';
        case {"id", "participant", "participantid"}
            groupColorFolder = 'MatchingAcrossStereoGroupsColorByID';
        otherwise
            error('Paper2Matching:InvalidGroupComparisonColorMode', ...
                ['groupComparisonColorMode must be "clinicalnotes", ' ...
                '"stereoscore", or "id".']);
    end

    [transformSuffix, ~, ~] = get_quad_transform_spec(transformId);
    groupResultsDir = fullfile(codeDir, '..', 'Paper2Figures', ...
        groupColorFolder, transformSuffix);
    if ~exist(groupResultsDir, 'dir')
        mkdir(groupResultsDir);
    end

    typicalResult = stereoGroupResults.StereoTypical;
    deficientResult = stereoGroupResults.StereoDeficient;
    combinedGroupData = [typicalResult.Data; deficientResult.Data];
    groupColorConfig = Quad_build_participant_color_config( ...
        combinedGroupData, groupResultsDir, ...
        [quadBasenameBase '_across_stereo_groups'], ...
        groupComparisonColorMode, true);
    groupSlopeAxisLimits = [ ...
        -0.6 0.0; ... % visual angle
        -0.2 0.6; ... % distance
        -1.0 0.2];    % elevation

    for taskIdx = 1:numel(taskOrder)
        task = taskOrder{taskIdx};
        Quad_PM_compare_intercepts_across_stereo_groups( ...
            typicalResult.Data, typicalResult.ThreeFactorLME.(task), ...
            deficientResult.Data, deficientResult.ThreeFactorLME.(task), ...
            task, quadBasenameBase, groupResultsDir, true, groupColorConfig);
        PM_compare_single_RS_across_stereo_groups( ...
            typicalResult.Data, typicalResult.SingleRSLME.(task), ...
            deficientResult.Data, deficientResult.SingleRSLME.(task), ...
            task, quadBasenameBase, groupResultsDir, true, ...
            groupSlopeAxisLimits, groupColorConfig);
    end
    save(fullfile(groupResultsDir, ...
        [quadBasenameBase '_across_stereo_groups.mat']), ...
        'stereoGroupResults', 'groupColorConfig', ...
        'groupComparisonColorMode', 'transformId');
end

quadFinalizeAnalysis();
