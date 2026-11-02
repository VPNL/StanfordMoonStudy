% SMS_Fig4d_Quad_MatchingbyStereoGroup_VA_D_E_092126.m
% Generate the Paper 2 matching figures with one elevation transform and
% one participant-color mode selected in the configuration block below.

clx
SMS_setCodePath;

expDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';

addpath(genpath(codeDir));

%% Set output directory
transformId = 2; % abs(Elevation); this script intentionally runs no transform loop.
colorMode = "stereoscore" ; %  "clinicalnotes" or "stereoscore";

stereoTypicalThreshold = 85;
stereoBlindThreshold=20;
saveLME=1;
switch lower(colorMode)
    case "stereoscore"
        colorResultsFolder = 'MatchingColorbyStereoScore';
    case "clinicalnotes"
        colorResultsFolder = 'MatchingColorbyClinicalNotes';
    otherwise
        error('Paper2Matching:InvalidColorMode', ...
            'colorMode must be "stereoscore" or "clinicalnotes".');
end

resultsDir = fullfile('/Users/kalanit/Projects/StanfordMoonStudy/Figures/', 'Fig4d', colorResultsFolder);

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

%% Load data

csvFile='QuadProcessedMatchingandStereoData.csv';
quadFile = fullfile(expDir,csvFile);

allQuadData = readtable(quadFile);
[~, quadBasename] = fileparts(quadFile);
stereoScoreVar = quadFindFirstTableVariable(allQuadData, ...
    {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
stereoGroupResults = struct();

% Use observer-referenced distance and elevation;
allQuadData.Elevation = allQuadData.Observer_Elevation;
allQuadData.Distance = allQuadData.Observer_Distance/100; % transform distance from cm to m

% make stereo groups 1: stereotypical; 2: stereodeficient; 3: stereoblind
ii=find(allQuadData.NormedScore>stereoTypicalThreshold);
allQuadData.StereoGroup(ii)=ones(size(ii));
jj=find(allQuadData.NormedScore<=stereoTypicalThreshold & allQuadData.NormedScore>stereoBlindThreshold);
allQuadData.StereoGroup(jj)=2*ones(size(jj));
mm=find(allQuadData.NormedScore<stereoBlindThreshold);
allQuadData.StereoGroup(mm)=3*ones(size(mm));

colorConfig = Quad_build_participant_color_config( ...
    allQuadData, resultsDir, quadBasename, colorMode, true);
cmap = colorConfig.RankCmap;
sortedIdx = colorConfig.SortedIdx;


%%
task='Perceptual'
taskData = allQuadData(strcmp(allQuadData.Task, task),:);

[transformSuffix, ~, modelTransform] = get_quad_transform_spec(transformId); % determines elevation tranform


%taskTable = taskData.(task);
tableName = sprintf('%s_%s_%s', quadBasename, task, transformSuffix);

% [singleAngleLME, singleDistanceLME, singleElevationLME, ...
%     singleAngleRSLME, singleDistanceRSLME, singleElevationRSLME] = ...
%     Quad_PM_by_task_single(taskData, tableName, resultsDir, ...
%     saveLME, cmap, sortedIdx, modelTransform);

[taskNstereoGroupAngleLME, taskNstereoGroupDistanceLME, taskNstereoGroupElevationLME, ...
taskNstereoGroupAngleRSLME, taskNstereoGroupDistanceRSLME, taskNstereoGroupElevationRSLME, stereoComparisons] = ...
Quad_PM_by_taskNstereoGroup_single(taskData, tableName, resultsDir, ...
saveLME, cmap, sortedIdx, modelTransform, true, false, colorConfig);

%%
[fullStereoLME, fullStereoInteractionStats, fullStereoComparison] = ...
fit_PM_full_VA_D_E_modelbyStereoGroup(taskData, ...
[tableName '_full_VA_D_E'], resultsDir, saveLME, ...
cmap, sortedIdx, modelTransform, colorConfig);
