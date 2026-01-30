close all; clear all;

% add path
% add code path
%codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
cd(expDir)
csvfile='AllQuadDataLong916.csv'

saveLME=1; % 1 save files; 0 don't save 

ResultsDir='AllQuadDataLong916'


% ResultsDir='DataLong082525'
% if ~exist('ResultsDir','dir')
%    mkdir(ResultsDir)
% end


%%
% calculate and plot the results of Experiment 1 Quad matching experiment

task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification

Quad_PM_by_task(expDir,csvfile,ResultsDir,task, recomputeSort, saveLME)
%%
% calculate and plot the results of Experiment 2 Quad adjusted matching experiment
cd(expDir)

task='Adjusted';
recomputeSort=0; % use the same participant color as perceptual matching task
Quad_PM_by_task(expDir,csvfile,ResultsDir,task, recomputeSort, saveLME)


%% Fig 2


% test if there are significant differences across tasks and if there 
% are consistent individual subject differences in PM across tasks
%Quad_TaskComparison(dataDir,csvfile,ResultsDir,saveLME);

% visualize PM
realVA=0.5;
perceivedVA=1.76*realVA;
distance_mm=500;
saveFlag=1
saveFilename=fullfile('.',ResultsDir, ['Perceptual_visualize_PM.png']);
%[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveFlag,saveFilename)

realVA=0.5;
perceivedVA=1.08*realVA;
distance_mm=500;
saveFlag=1
saveFilename=fullfile('.',ResultsDir, ['Adjusted_visualize_PM.png']);
%[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveFlag,saveFilename)
