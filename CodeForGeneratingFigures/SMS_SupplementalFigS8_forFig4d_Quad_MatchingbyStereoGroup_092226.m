% SMS_SupplementalFigS8_forFig4d_Quad_MatchingbyStereoGroup_092226.m
% Analyze the Perceptual matching task for all participants and separately
% for StereoBlind, StereoDeficient, and StereoTypical groups.
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

codeDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/code_Paper2Figures/';
expDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';




%% Run configuration
quadFile = fullfile(expDir, 'merged_matching_0429.csv');

stereoTypicalThreshold = 85;
stereoBlindThreshold = 20;
transformId = 2;
colorMode = "stereoscore"; % "clinicalnotes" or "stereoscore"
groupComparisonColorMode = colorMode;
saveLME = true;

runConfigs = { ...
    struct('groupName', 'All', 'resultsSubdir', 'All', ...
    'basenameSuffix', ''), ...
    struct('groupName', 'StereoBlind', ...
    'resultsSubdir', sprintf('StereoBlind_%d', stereoBlindThreshold), ...
    'basenameSuffix', sprintf('_StereoBlind_%d', stereoBlindThreshold)), ...
    struct('groupName', 'StereoDeficient', ...
    'resultsSubdir', sprintf('StereoDeficient_%d_to_%d', ...
    stereoBlindThreshold, stereoTypicalThreshold), ...
    'basenameSuffix', sprintf('_StereoDeficient_%d_to_%d', ...
    stereoBlindThreshold, stereoTypicalThreshold)), ...
    struct('groupName', 'StereoTypical', ...
    'resultsSubdir', sprintf('StereoTypical_%d', stereoTypicalThreshold), ...
    'basenameSuffix', sprintf('_StereoTypical_%d', stereoTypicalThreshold))};

switch lower(colorMode)
    case "stereoscore"
        colorResultsFolder = 'MatchingColorbyStereoScore_0922';
    case "clinicalnotes"
        colorResultsFolder = 'MatchingColorbyClinicalNotes_0922';
    otherwise
        error('Paper2Matching:InvalidColorMode', ...
            'colorMode must be "stereoscore" or "clinicalnotes".');
end
resultsRoot = fullfile('/Users/kalanit/Projects/StanfordMoonStudy/Figures/', 'SupplementalFigS8_forFig4d', colorResultsFolder);


%% Load Perceptual-task data
allQuadDataBase = readtable(quadFile);
% get perceptual data
allQuadDataBase = allQuadDataBase( strcmpi(string(allQuadDataBase.Task), "Perceptual"), :);
[~, quadBasenameBase] = fileparts(quadFile);
stereoScoreVar = quadFindFirstTableVariable(allQuadDataBase, ...
    {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
stereoGroupResults = struct();

for runIdx = 1:numel(runConfigs)
    runConfig = runConfigs{runIdx};
    allQuadData = local_select_stereo_group(allQuadDataBase, stereoScoreVar, ...
        runConfig.groupName, stereoBlindThreshold, stereoTypicalThreshold);
    quadBasename = [quadBasenameBase runConfig.basenameSuffix];
    resultsDir = fullfile(resultsRoot, runConfig.resultsSubdir);
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end
    fprintf('Running %s (%d of %d), colored by %s: %d rows from %d participants.\n', ...
        runConfig.groupName, runIdx, numel(runConfigs), colorMode, ...
        height(allQuadData), numel(unique(allQuadData.ID)));

    allQuadData.Elevation = allQuadData.Observer_Elevation;
    allQuadData.Distance = allQuadData.Observer_Distance / 100;
    taskTable = allQuadData(:, {'ID', 'Measurement', 'Real_Visual_Angle', ...
        'Distance', 'Elevation', 'Task', 'Reported_Visual_Angle', ...
        'Ratio_Visual_Angle'});

    colorConfig = Quad_build_participant_color_config( ...
        allQuadData, resultsDir, quadBasename, colorMode, true);
    cmap = colorConfig.RankCmap;
    sortedIdx = colorConfig.SortedIdx;
    [transformSuffix, ~, modelTransform] = ...
        get_quad_transform_spec(transformId);
    tableName = sprintf('%s_Perceptual_%s', quadBasename, transformSuffix);

    Quad_PerceivedSize_by_task_table(allQuadData, quadBasename, ...
        'Perceptual', resultsDir, saveLME, colorConfig);
   
    [singleAngleLME, singleDistanceLME, singleElevationLME, ...
        singleAngleRSLME, singleDistanceRSLME, singleElevationRSLME] = ...
        Quad_PM_by_task_single(taskTable, tableName, resultsDir, ...
        saveLME, cmap, sortedIdx, modelTransform);
   

    singleFactorRI = struct('Angle', singleAngleLME, ...
        'Distance', singleDistanceLME, 'Elevation', singleElevationLME);
    singleRSLME = struct('Angle', singleAngleRSLME, ...
        'Distance', singleDistanceRSLME, 'Elevation', singleElevationRSLME);
    save(fullfile(resultsDir, [char(quadBasename) '.mat']), ...
        'allQuadData', 'colorConfig', 'singleFactorRI', 'singleRSLME', ...
        'transformId', 'colorMode');

    if string(runConfig.groupName) ~= "All"
        stereoGroupResults.(runConfig.groupName) = struct( ...
            'Data', allQuadData, 'SingleRSLME', singleRSLME);
    end
end

%% Compare RS intercepts and slopes across participants from three stereo groups
requiredGroups = ["StereoTypical", "StereoDeficient", "StereoBlind"];
if all(isfield(stereoGroupResults, cellstr(requiredGroups)))
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
    groupResultsDir = resultsRoot;
    if ~exist(groupResultsDir, 'dir')
        mkdir(groupResultsDir);
    end
    combinedGroupData = [stereoGroupResults.StereoTypical.Data; ...
        stereoGroupResults.StereoDeficient.Data; ...
        stereoGroupResults.StereoBlind.Data];
    groupColorConfig = Quad_build_participant_color_config( ...
        combinedGroupData, groupResultsDir, ...
        [quadBasenameBase '_across_stereo_groups'], ...
        groupComparisonColorMode, true);
    slopeAxisLimits = [-0.6 0.0; -0.2 0.6; -1.0 0.2];
    PM_compare_single_RS_intercepts_slopes_across_stereo_groups( ...
        stereoGroupResults, 'Perceptual', quadBasenameBase, ...
        groupResultsDir, true, slopeAxisLimits, groupColorConfig);
    save(fullfile(groupResultsDir, ...
        [quadBasenameBase '_across_stereo_groups.mat']), ...
        'stereoGroupResults', 'groupColorConfig', ...
        'groupComparisonColorMode', 'transformId', ...
        'stereoBlindThreshold', 'stereoTypicalThreshold');
end

quadFinalizeAnalysis();
%%
function groupTbl = local_select_stereo_group( ...
    tbl, scoreVar, groupName, blindThreshold, typicalThreshold)
score = tbl.(scoreVar);
switch string(groupName)
    case "All"
        keep = true(height(tbl), 1);
    case "StereoBlind"
        keep = score < blindThreshold;
    case "StereoDeficient"
        keep = score >= blindThreshold & score <= typicalThreshold;
    case "StereoTypical"
        keep = score > typicalThreshold;
    otherwise
        error('Paper2Matching:InvalidStereoGroup', ...
            'Unknown stereo group: %s', char(string(groupName)));
end
groupTbl = tbl(keep & isfinite(score), :);
end
