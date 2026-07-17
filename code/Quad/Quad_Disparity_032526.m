% Quad_Disparity_Fig4
close all; clear all;

%codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data'
addpath(genpath(codeDir))

% set dirs
cd(dataDir)
Quadfile='QuadProcessedDisparityData032626_9pm.csv';
QuadBasename = [erase(Quadfile,'.csv')];
topstick=1;
elevationVarName='Observer_Elevation';
distanceVarName='Observer_Distance';
% generate the topstick referred observer data
[quad_disparity_data, out_datafile] = apply_topstick_observer_adjustment(Quadfile, dataDir, topstick, elevationVarName);


%[quad_disparity_data, out_datafile, resultsTxtFile, figureFiles] = run_quad_disparity_lme_analysis(Quadfile, dataDir, topstick, elevationVarName, distanceVarName)


