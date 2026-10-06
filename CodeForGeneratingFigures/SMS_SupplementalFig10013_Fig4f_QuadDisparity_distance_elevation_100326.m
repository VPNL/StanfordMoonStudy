%% SMS_SupplementalFig10013_Fig4f_QuadDisparity_distance_elevation_100326
% Validate perceived parallax against the geometric prediction.

close all; clear all;
SMS_setCodePath;
expDir = '/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';

%% Run configuration
quadFileName = 'merged_disparity_0429_version3.csv';
quadFile = fullfile(expDir, quadFileName);
[~, quadBasename] = fileparts(quadFileName);
colorMode = "stereoscore"; % "stereoscore", "clinicalnotes", or "id"
colorMode = lower(strtrim(string(colorMode)));
saveLME = true;
recomputeColorIndex = true;

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

resultsDir = fullfile('/Users/kalanit/Projects/StanfordMoonStudy/Figures', ...
    'SuppFig1003_Fig4f');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

%% Load data
importOptions = detectImportOptions(quadFile, ...
    'VariableNamingRule', 'modify');
if ismember('ClinicalNotes', importOptions.VariableNames)
    importOptions = setvartype(importOptions, 'ClinicalNotes', 'string');
end
allQuadData = readtable(quadFile, importOptions);

% Use observer-referenced geometry. Distances remain in the source cm units
% required by the geometric-parallax equation.
allQuadData.Elevation = allQuadData.Observer_Elevation;
allQuadData.Distance = allQuadData.Observer_Distance;

% StereoGroup is retained for compatibility with the shared color utility;
% Quad_Parallax_by_Geometry does not fit any StereoGroup model.
if colorMode == "stereoscore"
    stereoTypicalThreshold = 85;
    stereoBlindThreshold = 20;
    scoreCandidates = {'NormedStereoScore', 'NormedScore', ...
        'NormScore', 'StereoScore'};
    scoreIndex = find(ismember(scoreCandidates, ...
        allQuadData.Properties.VariableNames), 1, 'first');
    if isempty(scoreIndex)
        error('Fig4f:MissingStereoScore', ...
            'Stereo-score coloring requires one of: %s.', ...
            strjoin(scoreCandidates, ', '));
    end
    stereoScore = allQuadData.(scoreCandidates{scoreIndex});
    allQuadData.StereoGroup = nan(height(allQuadData), 1);
    allQuadData.StereoGroup(stereoScore > stereoTypicalThreshold) = 1;
    allQuadData.StereoGroup(stereoScore <= stereoTypicalThreshold & ...
        stereoScore >= stereoBlindThreshold) = 2;
    allQuadData.StereoGroup(stereoScore < stereoBlindThreshold) = 3;
end

colorConfig = Quad_build_participant_color_config(allQuadData, ...
    resultsDir, quadBasename, colorMode, recomputeColorIndex, colorMode);
cmap = colorConfig.RankCmap;
sortedIdx = colorConfig.SortedIdx;
uniqueID = colorConfig.ID;

%% Estimate fixation distance from perceived parallax
[lmeDistanceRI, lmeDistanceRS, ...
    lmeElevationRI, lmeElevationRS] = ...
    Quad_DistancefromPerceivedParallax( ...
    allQuadData, quadBasename, resultsDir, saveLME, cmap, ...
    sortedIdx, uniqueID, colorbarLabel, colorConfig);

%% Estimate fixation distance from row-mean parallax and caliper distance
[lmeMeanDistanceRI, lmeMeanDistanceRS, ...
    lmeMeanElevationRI, lmeMeanElevationRS] = ...
    Quad_DistancefromMeanPerceivedParallax( ...
    allQuadData, quadBasename, resultsDir, saveLME, cmap, ...
    sortedIdx, uniqueID, colorbarLabel, colorConfig);

%% Validate perceived parallax against geometric parallax
[lmePvG_RI, lmePvG_RS] = Quad_Parallax_by_Geometry( ...
    allQuadData, quadBasename, resultsDir, saveLME, cmap, ...
    sortedIdx, uniqueID, colorbarLabel, colorConfig);

save(fullfile(resultsDir, ...
    [quadBasename '_parallax_by_geometry_models.mat']), ...
    'lmeDistanceRI', 'lmeDistanceRS', ...
    'lmeElevationRI', 'lmeElevationRS', ...
    'lmeMeanDistanceRI', 'lmeMeanDistanceRS', ...
    'lmeMeanElevationRI', 'lmeMeanElevationRS', ...
    'lmePvG_RI', 'lmePvG_RS', ...
    'colorConfig', 'colorMode');
close all;
