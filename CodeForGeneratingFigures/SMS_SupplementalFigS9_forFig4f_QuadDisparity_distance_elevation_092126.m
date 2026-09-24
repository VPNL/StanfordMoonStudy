% SMS_SupplementalFigS9_forFig4f_Disparity_distance_elevation_092126
% Generate interocular-offset distance/elevation figures using one fixed
% elevation transform and one participant-color mode.
close all; clear all;
SMS_setCodePath;
expDir = '/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';



%% Run configuration
quadFileName = 'merged_disparity_0429_version3.csv';
quadFile = fullfile(expDir, quadFileName);
[~, quadBasename] = fileparts(quadFileName);
transformId = 2; % abs(Elevation); this script intentionally runs no transform loop.
colorMode = "stereoscore"; % "stereoscore", "clinicalnotes", or "id"
colorMode = lower(strtrim(string(colorMode)));
saveLME = true;
recomputeColorIndex = true;
removeOutlierParticipants = false;
removeZScoreOutliers = false;
zScoreThreshold = 3;
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

resultsDir = fullfile('/Users/kalanit/Projects/StanfordMoonStudy/Figures/SupplementalFigS9_Fig4f');

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

    % Supplemental Figure S9 analyzes stereotypical participants only.
    stereotypicalRows = allQuadData.StereoGroup == 1;
    allQuadData = allQuadData(stereotypicalRows, :);
    if isempty(allQuadData)
        error('SupplementalFigS9:NoStereoTypicalParticipants', ...
            'No participants have a stereo score above %g.', stereoTypicalThreshold);
    end
    fprintf('Supplemental Figure S9: retaining %d rows from %d stereotypical participants.\n', ...
        height(allQuadData), numel(unique(string(allQuadData.ID))));
end
colorConfig = Quad_build_participant_color_config( ...
    allQuadData, resultsDir, quadBasename, colorMode, recomputeColorIndex, colorMode);
cmap = colorConfig.RankCmap;
sortedIdx = colorConfig.SortedIdx;
uniqueID = colorConfig.ID;

%% analysisFolder = ['PerceivedDisparityDistanceElevation_0811' quadBaseNameBase];

[~, transformInfo] = apply_quad_elevation_transform(allQuadData(1, :), transformId);
transformSuffix = char(transformInfo.sfx);
transformResultsDir = fullfile(resultsDir, transformSuffix);
if ~exist(transformResultsDir, 'dir')
    mkdir(transformResultsDir);
end

% Apply the model elevation transform once. For transformId=2, the log model
% sees log2(1 + abs(Observer_Elevation)).
[modelTbl, ~] = apply_quad_elevation_transform(allQuadData, transformId);

tableName = [quadBasename '_StereoTypical'];

% [distanceRI, elevationRI, distanceElevationRI,linearDistanceElevationRI] = ...
% Quad_PerceivedOffset_by_DistanceElevation( ...
%     modelTbl, tableName, transformResultsDir, saveLME, cmap, ...
%     sortedIdx, transformId, 1, uniqueID, ...
%     removeOutlierParticipants, secondYAxisColor, colorConfig);

[lme_logDisparity_by_logDistance, lme_logDisparity_by_logElevation, ...
    lme_logDisparity_by_logDistance_RS, lme_logDisparity_by_logElevation_RS, ...
    lme_Disparity_by_Distance, lme_Disparity_by_Elevation, ...
    lme_Disparity_by_Distance_RS, lme_Disparity_by_Elevation_RS, ...
    lme_logDisparity_by_logDistanceXStereoGroup, ...
    lme_logDisparity_by_logElevationXStereoGroup, ...
    lme_Disparity_by_DistanceXStereoGroup, ...
    lme_Disparity_by_ElevationXStereoGroup] = ...
    Quad_PerceivedOffset_by_DistanceElevation_single( ...
    modelTbl, tableName, transformResultsDir, saveLME, cmap, ...
    sortedIdx, transformId, 0, uniqueID, ...
    removeOutlierParticipants, colorbarLabel, secondYAxisColor, ...
    false, colorConfig, includeStereo);




%% write supplemental table that contains information about real_visual_angle, observer_distance, and observer information for each measurement of tablesubset
geometryCsv = fullfile(transformResultsDir, ...
    ['Supplemental_Table_' quadBasename '.csv']);
build_quad_ground_truth_disparity_table(quadFile, geometryCsv);


resultsFile = fullfile(resultsDir, ...
    [quadBasename '_interocular_offset_distance_elevation_results.mat']);
save(resultsFile, 'colorConfig', ...
    'removeOutlierParticipants', 'removeZScoreOutliers', ...
    'zScoreThreshold', 'transformId', 'colorMode');

close all; 
