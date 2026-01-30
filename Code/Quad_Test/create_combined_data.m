% Combine and fit data across both experiments
close all; clear all;

% add path
% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';

% now make a subtable that just includes the data from experiments 2 and 3 that has the balls the lamps and the stick at the same distances but different elevations
QuadFile2='SQSData106_Table2_072524_to_110824.csv';
QuadFile3='SQSData106_Table3_053025_to_073125.csv';


all_quad_data2=readtable(fullfile(expDir,'Data',QuadFile2));
all_quad_data3=readtable(fullfile(expDir,'Data',QuadFile3));

KeepEntries={'Lamp5', 'Lamp6', 'Stick10' 'Ball'}
newtablename='SQSData106_Table3_justBallLamp56Stick10.csv'
newtable=Quad_keep_entries(expDir, QuadFile3, newtablename, KeepEntries);
combined_basename='SQSData106_Elevation_Distance_Balanced';
combined_data=[all_quad_data2; newtable];
writetable(combined_data,fullfile(expDir,'Data',[combined_basename '.csv']));

% verify measurements of combined_data
unique(combined_data.Measurement)
sort(unique(combined_data.Distance))/100
sort(unique(combined_data.Real_Visual_Angle))