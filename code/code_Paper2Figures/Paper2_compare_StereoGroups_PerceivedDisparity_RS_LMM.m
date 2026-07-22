% Paper2_compare_StereoGroups_PerceivedDisparity_RS_LMM
% Compare StereoTypical and StereoDeficient participants for the distance
% and elevation coefficients in the perceived-disparity analysis.

clear;
close all force;
clc;

scriptDir = fileparts(mfilename('fullpath'));
codeDir = fileparts(scriptDir);
addpath(genpath(codeDir));

%% Configuration shared with Paper2_Quad_PerceivedDisparity_distance_elevation_072126
quadFileName = 'merged_disparity_0429.csv';
quadFile = fullfile(codeDir, '..', 'QuadExperiments', 'Data', quadFileName);
stereoThreshold = 85;
transformId = 2; % abs(Elevation)
participantColorMode = "clinicalnotes"; % "clinicalnotes" or "stereoscore"
versionLabels = ["Version3", "Version3Lamp5", "Version3Lamp7"];
removeOutlierParticipants = false;

importOptions = detectImportOptions(quadFile, 'VariableNamingRule', 'modify');
importOptions = setvartype(importOptions, 'ClinicalNotes', 'string');
allQuadData = readtable(quadFile, importOptions);
if ~ismember('Elevation', allQuadData.Properties.VariableNames)
    allQuadData.Elevation = allQuadData.Observer_Elevation;
end
if ~ismember('Distance', allQuadData.Properties.VariableNames)
    allQuadData.Distance = allQuadData.Observer_Distance;
end

[~, quadBasename] = fileparts(quadFileName);
colorLabel = Quad_color_mode_folder_label(participantColorMode);
resultsRoot = fullfile(codeDir, '..', 'Paper2Figures', ...
    ['PerceivedDisparityStereoGroupRSLMMColorBy' colorLabel], ...
    'absElevation');
analysisSpecs = quadBuildDisparityAnalysisSpecs(allQuadData, versionLabels);

for versionIdx = 1:numel(analysisSpecs)
    versionLabel = analysisSpecs(versionIdx).Label;
    versionData = analysisSpecs(versionIdx).Table;
    [versionData, ~] = apply_quad_elevation_transform(versionData, transformId);
    versionData = Quad_prepare_perceived_disparity_table( ...
        versionData, transformId, removeOutlierParticipants);
    versionResultsDir = fullfile(resultsRoot, char(versionLabel));

    [participantTbl, statisticsTbl, baseModels, groupModels] = ...
        Quad_compare_disparity_stereo_groups_RS_LMM(versionData, ...
        versionLabel, quadBasename, versionResultsDir, stereoThreshold, ...
        participantColorMode, true);

    save(fullfile(versionResultsDir, sprintf( ...
        '%s_%s_stereo_group_disparity_RS_LMM_results.mat', ...
        quadBasename, versionLabel)), 'participantTbl', 'statisticsTbl', ...
        'baseModels', 'groupModels', 'stereoThreshold', 'transformId', ...
        'participantColorMode', 'versionLabel');
end
quadFinalizeAnalysis();
