close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))
% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
datafile='FullMoonDataLong090225.csv'; % all data
ResultsDir='PaperFig1_100225'
basename = [erase( datafile,'s.csv')] ; % for saving
readfile=fullfile(dataDir,datafile);

% Load the data
T = readtable(readfile);
%%
