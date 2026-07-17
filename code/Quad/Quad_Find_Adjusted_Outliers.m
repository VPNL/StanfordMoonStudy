% FIND outliers in the quad by adjusted task
close all; clear all;
%codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
dataDir=fullfile(expDir,'Data')

Quadfile='MatchingData0318_topStick.csv';
ObserverFlag=1;
QuadBasename = [erase(Quadfile,'.csv')]

ResultsDir=fullfile(expDir,'Paper_Fig2ab_032426');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

zThreshold = 3;

[outlierIDsAngle, summaryTbl, adjustedTbl] = find_quad_adjusted_reported_angle_outliers(fullfile(dataDir, Quadfile), zThreshold);
[outlierIDsRatio, summaryTbl, adjustedTbl] = find_quad_ratio_visual_angle_outliers(fullfile(dataDir, Quadfile), zThreshold);
