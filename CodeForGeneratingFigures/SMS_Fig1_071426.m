% SMS_Fig1_071426
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';
datafile='Perceptual_FullMoonDataProcessed090225.csv';
ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Figures/Fig1';

basename = erase(datafile,'.csv');
saveLME=1;
baseResultsDir = ResultsDir;
task='Perceptual'
recomputeSort = 1
elevationModel = 'deg';

if ~exist(baseResultsDir,'dir')
    mkdir(baseResultsDir)
end

lme = SMS_FullMoon_PM_by_task_log(dataDir, datafile, ResultsDir, task, recomputeSort, saveLME); 


close all; 