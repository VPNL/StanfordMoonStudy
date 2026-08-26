% SMS_Fig1_071426
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';
datafile='FullMoonDataLong090225.csv';
ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Figures/Fig4a';

basename = erase(datafile,'.csv');
saveLME=1;
baseResultsDir = ResultsDir;
task='Adjusted'
recomputeSort =0;
elevationModel = 'deg';

if ~exist(baseResultsDir,'dir')
    mkdir(baseResultsDir)
end

lme = SMS_FullMoon_PM_by_task_log(dataDir, datafile, ResultsDir, task, recomputeSort, saveLME); 

FullMoon_TaskComparison(dataDir, datafile, ResultsDir, saveLME)

close all; 