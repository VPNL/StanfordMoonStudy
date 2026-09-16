% SMS_SupplementalTable4_090496
% Generate Quad interocular-offset table

close all; clear all;
% set paths

SMS_setCodePath;
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/OcularOffset/';

quadFileName ='StanfordQuad_merged_disparity_0429_version3.csv'
quadFile = fullfile(dataDir, quadFileName);
[~, quadBasename] = fileparts(quadFileName);

ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Figures/SupplementalTables/';
if ~exist(ResultsDir,'dir')
   mkdir(ResultsDir)
end

% write supplemental table that contains information about real_visual_angle, observer_distance, and observer information for each measurement of tablesubset
TableFile = fullfile(ResultsDir, ...
    ['Supplemental_Table3_' quadBasename '.csv']);
build_quad_ground_truth_disparity_table(quadFile, TableFile);



