% SMS_Fig4b_092126
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';
datafile='FullMoonDataLong090225.csv';
ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Figures/Fig4b';
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

basename = erase(datafile,'.csv');

saveLME=1;
elevationModel = 'deg';
%% Test each task and generate the same coloring by participant across tasks
task='Perceptual'; recomputeSort=1;
lmePerceptual = SMS_FullMoon_PM_by_task_log(dataDir, datafile, ResultsDir, task, recomputeSort, saveLME); 

task='Adjusted'; recomputeSort =0;
lme = SMS_FullMoon_PM_by_task_log(dataDir, datafile, ResultsDir, task, recomputeSort, saveLME); 
%% compare between tasks
SMS_FullMoon_TaskComparison(dataDir, datafile, ResultsDir, saveLME)

close all; 