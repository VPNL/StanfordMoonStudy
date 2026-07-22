% Paper2_Quad_PerceivedDisparity_distance_elevation_072126
% Generate perceived-disparity distance/elevation figures using one fixed
% elevation transform and one participant-color mode.

clear;
close all force;
clc;

scriptDir = fileparts(mfilename('fullpath'));
codeDir = fileparts(scriptDir);
addpath(genpath(codeDir));

%% Run configuration
quadFileName = 'merged_disparity_0429.csv';
quadFile = fullfile(codeDir, '..', 'QuadExperiments', 'Data', quadFileName);
transformId = 2; % abs(Elevation); this script intentionally runs no transform loop.
colorMode = "clinicalnotes"; % "stereoscore" or "clinicalnotes"
saveLME = true;
recomputeColorIndex = true;
removeOutlierParticipants = false;
removeZScoreOutliers = false;
zScoreThreshold = 3;
secondYAxisColor = 'k';
stereoThreshold = 85;

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
        colorFolder = 'ColorByStereoScore';
        colorbarLabel = 'Normed stereo score';
    case "clinicalnotes"
        colorFolder = 'ColorByClinicalNotes';
        colorbarLabel = 'Clinical notes';
    otherwise
        error('Paper2Disparity:InvalidColorMode', ...
            'colorMode must be "stereoscore" or "clinicalnotes".');
end

%% Load data
importOptions = detectImportOptions(quadFile, 'VariableNamingRule', 'modify');
importOptions = setvartype(importOptions, 'ClinicalNotes', 'string');
allQuadDataBase = readtable(quadFile, importOptions);
[~, quadBaseNameBase] = fileparts(quadFileName);
stereoScoreVar = quadFindFirstTableVariable(allQuadDataBase, ...
    {'NormedStereoScore', 'NormedScore'});

resultsRoot = fullfile(codeDir, '..', 'Paper2Figures');
analysisFolder = ['PerceivedDisparityDistanceElevation_' quadBaseNameBase];
baseResultsDir = fullfile(resultsRoot, analysisFolder, colorFolder);
versionLabels = ["Version3", "Version3Lamp5", "Version3Lamp7"];

for runIdx = 1:numel(runConfigs)
    runConfig = runConfigs{runIdx};
    allQuadData = allQuadDataBase;
    quadBasename = [quadBaseNameBase runConfig.basenameSuffix];

    if runConfig.justStereoDeficient
        allQuadData = allQuadData(allQuadData.(stereoScoreVar) < stereoThreshold, :);
    elseif runConfig.justStereoTypical
        allQuadData = allQuadData(allQuadData.(stereoScoreVar) >= stereoThreshold, :);
    end

    resultsDir = fullfile(baseResultsDir, runConfig.resultsSubdir);
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end

    fprintf('Running %s (%d of %d), colored by %s: %d rows from %d participants.\n', ...
        runConfig.resultsSubdir, runIdx, numel(runConfigs), colorMode, ...
        height(allQuadData), numel(unique(allQuadData.ID)));

    if ~ismember('Elevation', allQuadData.Properties.VariableNames)
        elevationVar = quadFindFirstTableVariable(allQuadData, {'Observer_Elevation'});
        allQuadData.Elevation = allQuadData.(elevationVar);
    end
    if ~ismember('Distance', allQuadData.Properties.VariableNames)
        distanceVar = quadFindFirstTableVariable(allQuadData, {'Observer_Distance'});
        allQuadData.Distance = allQuadData.(distanceVar);
    end

    colorConfig = Quad_build_participant_color_config( ...
        allQuadData, resultsDir, quadBasename, colorMode, recomputeColorIndex);
    cmap = colorConfig.RankCmap;
    sortedColorIdx = colorConfig.SortedIdx;
    uniqueID = colorConfig.ID;

    [~, transformInfo] = apply_quad_elevation_transform(allQuadData(1, :), transformId);
    transformSuffix = char(transformInfo.sfx);
    transformResultsDir = fullfile(resultsDir, transformSuffix);
    if ~exist(transformResultsDir, 'dir')
        mkdir(transformResultsDir);
    end

    analysisSpecs = quadBuildDisparityAnalysisSpecs(allQuadData, versionLabels);
    modelStore = struct();
    summaryStore = struct();

    for versionIdx = 1:numel(analysisSpecs)
        versionLabel = analysisSpecs(versionIdx).Label;
        versionField = matlab.lang.makeValidName(char(versionLabel));
        tableSubset = analysisSpecs(versionIdx).Table;
        [tableSubset, ~] = apply_quad_elevation_transform(tableSubset, transformId);

        versionResultsDir = fullfile(transformResultsDir, char(versionLabel));
        if ~exist(versionResultsDir, 'dir')
            mkdir(versionResultsDir);
        end

        outlierBaseName = sprintf('%s_%s_%s', ...
            quadBasename, versionLabel, transformSuffix);
        tableSubset = quadFilterDisparityOutliers(tableSubset, transformId, ...
            removeOutlierParticipants, removeZScoreOutliers, zScoreThreshold, ...
            versionResultsDir, outlierBaseName);

        tableName = outlierBaseName;
        [distanceRI, elevationRI, distanceElevationRI] = ...
            Quad_PerceivedDisparity_by_DistanceElevation( ...
            tableSubset, tableName, versionResultsDir, saveLME, cmap, ...
            sortedColorIdx, transformId, 1, uniqueID, ...
            removeOutlierParticipants, secondYAxisColor, colorConfig);

        [distanceSingleRI, elevationSingleRI, distanceRS, elevationRS] = ...
            Quad_PerceivedDisparity_by_DistanceElevation_single( ...
            tableSubset, tableName, versionResultsDir, saveLME, cmap, ...
            sortedColorIdx, transformId, 1, uniqueID, ...
            removeOutlierParticipants, colorbarLabel, secondYAxisColor, ...
            false, colorConfig);

        summaryFile = fullfile(versionResultsDir, [tableName '_lme_summary.csv']);
        summaryStore.(versionField) = ...
            Quad_export_PercievedDisparity_LME_summary_csv(quadBasename, ...
            [], distanceRI, elevationRI, [], [], distanceElevationRI, [], summaryFile);
        modelStore.(versionField) = struct( ...
            'DistanceRI', distanceRI, ...
            'ElevationRI', elevationRI, ...
            'DistanceElevationRI', distanceElevationRI, ...
            'DistanceSingleRI', distanceSingleRI, ...
            'ElevationSingleRI', elevationSingleRI, ...
            'DistanceRS', distanceRS, ...
            'ElevationRS', elevationRS);

        quadCloseFigures();
    end

    resultsFile = fullfile(resultsDir, ...
        [quadBasename '_perceived_disparity_distance_elevation_results.mat']);
    save(resultsFile, 'summaryStore', 'modelStore', 'colorConfig', ...
        'removeOutlierParticipants', 'removeZScoreOutliers', ...
        'zScoreThreshold', 'transformId', 'colorMode');
end

quadFinalizeAnalysis();
