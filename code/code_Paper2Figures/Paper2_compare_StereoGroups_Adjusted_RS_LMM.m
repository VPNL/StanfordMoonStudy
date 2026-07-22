% Paper2_compare_StereoGroups_Adjusted_RS_LMM
% Compare StereoTypical and StereoDeficient participants in the Adjusted
% task using combined random-intercept/random-slope LMMs.

clear;
close all force;
clc;

scriptDir = fileparts(mfilename('fullpath'));
codeDir = fileparts(scriptDir);
addpath(genpath(codeDir));

%% Configuration
quadFile = fullfile(codeDir, '..', 'QuadExperiments', 'Data', ...
    'merged_matching_0429_x7001.csv');
stereoThreshold = 85;
transformId = 2; % abs(Elevation)
participantColorMode = "clinicalnotes"; % "clinicalnotes" or "stereoscore"

[~, quadBasename] = fileparts(quadFile);
colorLabel = Quad_color_mode_folder_label(participantColorMode);
resultsDir = fullfile(codeDir, '..', 'Paper2Figures', ...
    ['MatchingStereoGroupRSLMMColorBy' colorLabel], 'Adjusted', ...
    'absElevation');

[participantTbl, statisticsTbl, baseModels, groupModels] = ...
    Quad_compare_stereo_groups_RS_LMM(quadFile, "Adjusted", ...
    quadBasename, resultsDir, stereoThreshold, transformId, ...
    participantColorMode, true);

save(fullfile(resultsDir, ...
    [quadBasename '_Adjusted_stereo_group_RS_LMM_results.mat']), ...
    'participantTbl', 'statisticsTbl', 'baseModels', 'groupModels', ...
    'stereoThreshold', 'transformId', 'participantColorMode');
quadFinalizeAnalysis();
