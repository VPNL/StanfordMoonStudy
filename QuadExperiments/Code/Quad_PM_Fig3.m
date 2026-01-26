close all; clear all;

% add path
% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Data/QuadExperiments/';
cd(expDir)

%ResultsDir='Phase2DataLong7-21-25'
%ResultsDir='PaperFig3'
%ResultsDir='DataLongKeithan072125'
ResultsDir='DataLong081225';
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

% csvfile='DataLongKeithan071025.csv'; % July 2025 with v3 of the experiment
% csvfile='DataLongKeithanWithPhase2_071825.csv'
%csvfile='Phase2DataLong7-21-25.csv'
% csvfile='DataLongKeithan072125.csv'
csvfile='AllQuadData813.csv';
dataDir=fullfile(expDir,'Data')
saveLME=1; % 1 save files; 0 don't save 


%%
% calculate and plot the results of Experiment 1 Quad matching experiment
task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification

Quad_PM_by_task(dataDir,csvfile,ResultsDir,task, recomputeSort, saveLME)
%%
% calculate and plot the results of Experiment 2 Quad adjusted matching experiment
task='Adjusted';
recomputeSort=0; % use the same participant color as perceptual matching task
Quad_PM_by_task(dataDir,csvfile,ResultsDir,task, recomputeSort, saveLME)


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
[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveFlag,saveFilename)

realVA=0.5;
perceivedVA=1.08*realVA;
distance_mm=500;
saveFlag=1
saveFilename=fullfile('.',ResultsDir, ['Adjusted_visualize_PM.png']);
[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveFlag,saveFilename)
