close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))
% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
datafile='FullMoonDataLong090225.csv'; % all data
ResultsDir='PaperFig1_102825'
basename = [erase( datafile,'s.csv')] ; % for saving
saveLME=1; % 1 save files; 0 don't save 
%%
% calculate and plot the results of Experiment 1 Full Moon matching experiment
task='Perceptual';
recomputeSort=0; % sort subject colors by slopes of perceptual magnification

lme_by_logRatio_by_Elevation_Perceptual=FullMoon_PM_by_task_log(dataDir,datafile,ResultsDir,task, recomputeSort, saveLME)
%%
% calculate and plot the results of Experiment 2 Full Moon adjusted matching experiment
task='Adjusted';
recomputeSort=0; % use the same participant color as perceptual matching task
lme_by_logRatio_by_Elevation_Adjusted=FullMoon_PM_by_task_log(dataDir,datafile,ResultsDir,task, recomputeSort, saveLME)

% test if there are significant differences across tasks and if there 
% are consistent individual subject differences in PM across tasks
FullMoon_TaskComparison(dataDir,datafile,ResultsDir,saveLME)

%% violin plot of perceived size by moon date
FullMoon_ReportedVisualAngle_Violin(dataDir,datafile,ResultsDir)
%%  test if there is a relation between the intercepts estimates (PM at horizon) across tasks
%   best model is log2(perceptual magnification) ~ log2(elevation) 
%   with fixed slopes and random intercepts per participant

FullMoon_PM_InterceptsAcrossTasks(dataDir,basename, ResultsDir,lme_by_logRatio_by_Elevation_Perceptual,lme_by_logRatio_by_Elevation_Adjusted)
