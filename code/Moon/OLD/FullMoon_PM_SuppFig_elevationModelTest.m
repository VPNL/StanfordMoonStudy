close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))
% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
datafile='FullMoonDataLong090225.csv'; % all data
basename = erase( datafile,'.csv') ; % for saving
all_data=readtable(fullfile(dataDir,datafile));

OutDir='SupplementalFig_032226_ElevationmodelTesting';
ResultsDir=fullfile(dataDir,OutDir, basename);
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

saveLME=1; % 1 save files; 0 don't save 
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);

% sort subjects by PM in Perceptual task
task='Perceptual';
task_p=find(strcmp(all_data.Task,task));
all_data_perceptual=all_data(task_p,:);

task='Adjusted';
task_a=find(strcmp(all_data.Task,task));
all_data_adjusted=all_data(task_a,:);

for i=1:nsubjects
    idx=find(all_data_perceptual.ID==uniqueID(i));
    meanPM(i)=mean(all_data_perceptual.Ratio_Visual_Angle(idx));
end

% sort subjects by PM
[sorted_PM, sorted_idx] = sort(meanPM);
cmap=colormap(jet(nsubjects));
for c=1:length(uniqueID)
        cindex=find(uniqueID==all_data_perceptual.ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
end

task='Perceptual';
% sort subject colors by slopes of perceptual magnification
Perceptual_tblName=[basename '_' task];
[lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation,lme_logPM_by_logElevationRAD,lme_logPM_by_logabsElevationRAD] = ...
    Quad_PM_by_task_elevationModelTest(all_data_perceptual, Perceptual_tblName, ResultsDir, saveLME, cmap, sorted_idx)

task='Adjusted';
% sort subject colors by slopes of perceptual magnification
Adjusted_tblName=[basename '_' task];
[lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation,lme_logPM_by_logElevationRAD,lme_logPM_by_logabsElevationRAD] = ...
    Quad_PM_by_task_elevationModelTest(all_data_adjusted, Adjusted_tblName, ResultsDir, saveLME, cmap, sorted_idx)


%% calculate and plot the results of Experiment 1 Full Moon matching experiment
task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification
results_perceptual = FullMoon_PM_compare3modelsv3(dataDir,datafile,OutDir,task,recomputeSort,saveLME)

% calculate and plot the results of Experiment 2 Full Moon adjusted matching experiment
task='Adjusted';
recomputeSort=0; % use the same participant color as perceptual matching task
results_adjusted = FullMoon_PM_compare3modelsv3(dataDir,datafile,OutDir,task,recomputeSort,saveLME)
% test if there are significant differences across tasks and if there 
% are consistent individual subject differences in PM across tasks

% clx