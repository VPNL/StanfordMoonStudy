% Quad_PM_Fig2
close all; clear all;


%codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
dataDir=fullfile(expDir,'Data')
Quadfile='AllQuadDataLong916.csv'
QuadBasename = [erase(Quadfile,'.csv')]
ResultsDir=fullfile(expDir,'Paper_Fig2_111225');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

saveLME=1; % 1 save files; 0 don't save 

%%
% calculate and plot the results of Quad perceptual matching experiment

task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification
lme_by_angle_perceptual=Quad_PerceivedSize_by_task(dataDir,Quadfile,task, ResultsDir, recomputeSort, saveLME)

% visualize PM
realVA=0.5;
mean_slope_perceptual=lme_by_angle_perceptual.Coefficients.Estimate;
perceivedVA=mean_slope_perceptual*realVA;
distance_mm=500;
saveFlag=1
saveFilename=fullfile(ResultsDir,[ QuadBasename '_Perceptual_visualize_PM.png']);
[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveFlag,saveFilename)
%%
% calculate and plot the results of  Quad adjusted matching experiment

task='Adjusted';
recomputeSort=0; % use the same participant color as perceptual matching task
lme_by_angle_adjusted=Quad_PerceivedSize_by_task(dataDir,Quadfile,task, ResultsDir, recomputeSort, saveLME)
mean_slope_adjusted=lme_by_angle_adjusted.Coefficients.Estimate;


%%
% test if there are significant differences across tasks and if there 
% are consistent individual subject differences in PM across tasks
lme_by_angleNtask=Quad_TaskCompariso(ndataDir,Quadfile,ResultsDir,saveLME);