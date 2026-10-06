% SMS_Fig4f_Disparity_distance_elevation_092126
% Generate interocular-offset distance/elevation figures using one fixed
% elevation transform and one participant-color mode.

close all; clear all;
SMS_setCodePath;
expDir = '/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';


%% Run configuration
quadFileName = 'merged_disparity_0429_version3.csv';
quadFile = fullfile(expDir, quadFileName);
[~, quadBasename] = fileparts(quadFileName);
transformId = 2; % abs(Elevation);
distanceTransform=true; %use 1/D for disparity analysis
colorMode = "stereoscore"; % "stereoscore", "clinicalnotes", or "id"
colorMode = lower(strtrim(string(colorMode)));
saveLME = true;
recomputeColorIndex = true;
secondYAxisColor = 'k';

switch colorMode
    case "stereoscore"
          colorbarLabel = 'Normed stereo score';
    case "clinicalnotes"
           colorbarLabel = 'Clinical notes';
    case "id"
        colorbarLabel = 'Participant ID';
      otherwise
        error('Fig4f:InvalidColorMode', ...
            'colorMode must be "stereoscore", "clinicalnotes", or "id".');
end

resultsDir = fullfile('/Users/kalanit/Projects/StanfordMoonStudy/Figures/Fig4f');

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end


%% Load data
importOptions = detectImportOptions(quadFile, 'VariableNamingRule', 'modify');
if ismember('ClinicalNotes', importOptions.VariableNames)
    importOptions = setvartype(importOptions, 'ClinicalNotes', 'string');
end
allQuadData = readtable(quadFile, importOptions);


% Use observer-referenced distance and elevation for this analysis. The
% elevation transform is applied once below before model fitting.
allQuadData.Elevation = allQuadData.Observer_Elevation;
allQuadData.Distance = allQuadData.Observer_Distance; % Quad_prepare_perceived_disparity_table converts cm to m.

% Make StereoGroup only when stereo-score coloring is requested. This keeps
% ID and clinical-note modes usable for tables without stereo-score columns.
includeStereo = colorMode == "stereoscore";
if includeStereo
    stereoTypicalThreshold = 85;
    stereoBlindThreshold = 20;
    stereoScoreCandidates = {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'};
    stereoVarIdx = find(ismember(stereoScoreCandidates, allQuadData.Properties.VariableNames), 1, 'first');
    if isempty(stereoVarIdx)
        error('Paper2Matching:MissingStereoScore', ...
            'colorMode="stereoscore" requires one of these columns: %s. Use colorMode="id" for tables without stereo scores.', ...
            strjoin(stereoScoreCandidates, ', '));
    end
    stereoScoreVar = stereoScoreCandidates{stereoVarIdx};

    % make stereo groups 1: stereotypical; 2: stereodeficient; 3: stereoblind
    stereoScore = allQuadData.(stereoScoreVar);
    allQuadData.StereoGroup = nan(height(allQuadData), 1);
    ii = find(stereoScore > stereoTypicalThreshold);
    allQuadData.StereoGroup(ii)=ones(size(ii));
    jj = find(stereoScore <= stereoTypicalThreshold & stereoScore >= stereoBlindThreshold);
    allQuadData.StereoGroup(jj)=2*ones(size(jj));
    mm = find(stereoScore < stereoBlindThreshold);
    allQuadData.StereoGroup(mm)=3*ones(size(mm));
end
colorConfig = Quad_build_participant_color_config( ...
    allQuadData, resultsDir, quadBasename, colorMode, recomputeColorIndex, colorMode);
cmap = colorConfig.RankCmap;
sortedIdx = colorConfig.SortedIdx;
uniqueID = colorConfig.ID;

%% analysisFolder = ['PerceivedParallaxDistanceElevation_0811' quadBaseNameBase];

% Apply the model elevation transform once. For transformId=2, the log model
% sees log2(1 + abs(Observer_Elevation)).
[modelTbl, ~] = apply_quad_elevation_transform(allQuadData, transformId);

tableName = quadBasename;

%% Linear RS models for inverse distance (1/D) and elevation (E)
[lme_Parallax_by_InverseDistance_single, lme_Parallax_by_Elevation_single, ...
    lme_Parallax_by_InverseDistance_RS, lme_Parallax_by_Elevation_RS, ...
    lme_Parallax_by_InverseDistanceXStereoGroup, ...
    lme_Parallax_by_ElevationXStereoGroup] = ...
    Quad_Disparity_by_inverseDistanceElevation_single(...
    modelTbl, tableName, resultsDir, saveLME, cmap, ...
    sortedIdx, transformId, 0, uniqueID, ...
    colorbarLabel, secondYAxisColor, ...
    false, colorConfig, includeStereo, true);
% %%
% resultsDir = fullfile('/Users/kalanit/Projects/StanfordMoonStudy/Figures/Fig4f/Demeaned');
% if ~exist(resultsDir, 'dir')
%     mkdir(resultsDir);
% end
% [lme_Parallax_by_InverseDistance_single, lme_Parallax_by_Elevation_single, ...
%     lme_Parallax_by_InverseDistance_RS, lme_Parallax_by_Elevation_RS, ...
%     lme_Parallax_by_InverseDistanceXStereoGroup, ...
%     lme_Parallax_by_ElevationXStereoGroup] = ...
%     Quad_DemeanedParallax_by_inverseDistanceElevation_single(...
%     modelTbl, tableName, resultsDir, saveLME, cmap, ...
%     sortedIdx, transformId, 0, uniqueID, ...
%     colorbarLabel, secondYAxisColor, ...
%     false, colorConfig, includeStereo, true);


%%
geometryResultsDir = ...
    '/Users/kalanit/Projects/StanfordMoonStudy/Figures/SuppFig1003_Fig4f';
[lmeGeometryRI, lmeElevationRI, lmeGeometryRS, lmeElevationRS, ...
    lmeGeometryElevationRI, lmeGeometryElevationRS, ...
    lmeAdjustedParallaxElevationRI, lmeAdjustedParallaxElevationRS, ...
    lmeCaliperDistanceElevationRI, lmeCaliperDistanceDistanceRI, ...
    lmeInfinityAdjustedParallaxElevationRI, ...
    lmeInfinityAdjustedParallaxElevationRS] = ...
    Quad_Disparity_by_GeometryElevation_single(allQuadData, tableName, ...
    geometryResultsDir, true, cmap, sortedIdx, uniqueID, colorbarLabel, ...
    true, true, colorConfig);




%% write supplemental table that contains information about real_visual_angle, observer_distance, and observer information for each measurement of tablesubset
geometryCsv = fullfile(resultsDir, ...
    ['Supplemental_Table_' quadBasename '.csv']);
build_quad_ground_truth_disparity_table(quadFile, geometryCsv);


resultsFile = fullfile(resultsDir, ...
    [quadBasename '_interocular_offset_distance_elevation_results.mat']);
save(resultsFile, 'colorConfig', 'distanceTransform',...
     'transformId', 'colorMode');

close all;


%% Linear RI models for 1/Distance, elevation, their additive model, and interaction
[lme_Parallax_by_InverseDistance, lme_Parallax_by_Elevation, ...
    lme_Parallax_by_InverseDistanceNElevation, ...
    lme_Parallax_by_InverseDistancePlusElevation] = ...
    Quad_Disparity_by_inverseDistanceElevation( ...
    modelTbl, tableName, resultsDir, saveLME, cmap, ...
    sortedIdx, transformId, 1, uniqueID, ...
    secondYAxisColor, colorConfig);


