% SMS_SupplementalStatsTable10c_forFig4d_Quad_Matching_JustStereoBlindVs092326.m
% Analyze the Perceptual matching task for all participants and separately
% for StereoBlind and StereoTypical groups.
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

expDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';




%% Run configuration
quadFile = fullfile(expDir, 'merged_matching_0429.csv');

stereoTypicalThreshold = 85;
stereoBlindThreshold = 20;
transformId = 2;
colorMode = "stereoscore"; % "clinicalnotes" or "stereoscore"
saveLME = true;

runConfigs = {struct('groupName', 'All', 'resultsSubdir', 'All', ...
    'basenameSuffix', '')};

switch lower(colorMode)
    case "stereoscore"
        colorResultsFolder = 'MatchingColorbyStereoScore_0923';
    case "clinicalnotes"
        colorResultsFolder = 'MatchingColorbyClinicalNotes_0923';
    otherwise
        error('Paper2Matching:InvalidColorMode', ...
            'colorMode must be "stereoscore" or "clinicalnotes".');
end
resultsRoot = fullfile('/Users/kalanit/Projects/StanfordMoonStudy/Figures/', 'SupplementalStatsTable10c_forFig4d', colorResultsFolder);


%% Load Perceptual-task data
allQuadDataBase = readtable(quadFile);
% get perceptual data
allQuadDataBase = allQuadDataBase( strcmpi(string(allQuadDataBase.Task), "Perceptual"), :);

% remove stereodeficient from table;
ii=find(allQuadDataBase.NormedScore>stereoTypicalThreshold); % stereotypical
mm=find(allQuadDataBase.NormedScore<stereoBlindThreshold);

allQuadDataBase=[allQuadDataBase(ii,:);allQuadDataBase(mm,:)]; 
stereoGroup = strings(height(allQuadDataBase), 1);
stereoGroup(allQuadDataBase.NormedScore > stereoTypicalThreshold) = "StereoTypical";
stereoGroup(allQuadDataBase.NormedScore < stereoBlindThreshold) = "StereoBlind";
allQuadDataBase.StereoGroup = categorical(stereoGroup, ...
    ["StereoTypical", "StereoBlind"], ["StereoTypical", "StereoBlind"]);

[~, quadBasenameBase] = fileparts(quadFile);
stereoScoreVar = quadFindFirstTableVariable(allQuadDataBase, ...
    {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
if ~exist(resultsRoot, 'dir')
    mkdir(resultsRoot);
end
compute_mean_pm_stereo_group_test(allQuadDataBase, ...
    fullfile(resultsRoot, [quadBasenameBase '_mean_PM_by_stereo_group.txt']), ...
    quadFile);
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

    % Fit direct StereoGroup-by-factor interactions on the pooled
    % StereoTypical and StereoBlind data. Write the full report without
    % generating redundant group-specific figures.
    Quad_PM_by_taskNstereoGroup_single( ...
        allQuadData, tableName, resultsDir, saveLME, cmap, sortedIdx, ...
        modelTransform, false, false, colorConfig);

    % Fit the full VA/D/E model with StereoGroup interactions and write its
    % report without generating a redundant full-model figure.
    fit_PM_full_VA_D_E_modelbyStereoGroup( ...
        allQuadData, [tableName '_full_VA_D_E'], resultsDir, saveLME, ...
        cmap, sortedIdx, modelTransform, colorConfig, false);
   

    singleFactorRI = struct('Angle', singleAngleLME, ...
        'Distance', singleDistanceLME, 'Elevation', singleElevationLME);
    singleRSLME = struct('Angle', singleAngleRSLME, ...
        'Distance', singleDistanceRSLME, 'Elevation', singleElevationRSLME);
    save(fullfile(resultsDir, [char(quadBasename) '.mat']), ...
        'allQuadData', 'colorConfig', 'singleFactorRI', 'singleRSLME', ...
        'transformId', 'colorMode');

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
