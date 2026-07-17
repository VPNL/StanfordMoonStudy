close all; clear all;
set(groot,'defaultFigureVisible','off');

codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir))

expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data';
QuadFileName='QuadProcessedDisparityData032626_11pm_6001cleaned.csv';
QuadBaseName=erase(QuadFileName,'.csv');
DataDir=fullfile(expDir,'Data');

ResultsDir=fullfile(expDir,['PerceivedDisparityDistanceElevation_' QuadBaseName '_allTransforms']);

all_quad_data = readtable(fullfile(DataDir, QuadFileName));
v3idx=find(all_quad_data.Version==3);
version3=all_quad_data(v3idx,:); % only interested in version3 data
writetable(version3, fullfile(dataDir,[QuadBaseName 'V3.csv']));
