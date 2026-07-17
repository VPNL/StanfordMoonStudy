close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))
% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
datafile='FullMoonDataLong090225.csv'; % all data
ResultsDir='LogAnalysis_090225'
basename = [erase( datafile,'s.csv')] ; % for saving
saveLME=1; % 1 save files; 0 don't save 
%%
% calculate and plot the results of Experiment 1 Full Moon matching experiment
task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification

FullMoon_PM_by_task_log(dataDir,datafile,ResultsDir,task, recomputeSort, saveLME)

% calculate and plot the results of Experiment 2 Full Moon adjusted matching experiment
task='Adjusted';
recomputeSort=0; % use the same participant color as perceptual matching task
FullMoon_PM_by_task_log(dataDir,datafile,ResultsDir,task, recomputeSort, saveLME)

% test if there are significant differences across tasks and if there 
% are consistent individual subject differences in PM across tasks
FullMoon_TaskComparison(dataDir,datafile,ResultsDir,saveLME)

