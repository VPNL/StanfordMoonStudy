% TestBoring_Fig1_072126
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
datafile='BoringDataProcessed_simple.csv';
ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/PaperFigures/BoringData';
basename = erase(datafile,'.csv');

baseResultsDir = ResultsDir;
if ~exist(baseResultsDir,'dir')
    mkdir(baseResultsDir)
end
saveLME=1;
task='Binocular'
recomputeSort = 1
elevationModel = 'deg';


lme = SMS_FullMoon_PM_by_task_log(dataDir, datafile, ResultsDir, task, recomputeSort, saveLME);

task='Monocular'
recomputeSort = 1
elevationModel = 'deg';

lme = SMS_FullMoon_PM_by_task_log(dataDir, datafile, ResultsDir, task, recomputeSort, saveLME);



[summaryTbl, reportFile] = write_numeric_table_summary_report(dataFile, ResultsDir);

% Raw data for the moon
[summaryTbl, reportFile] = write_numeric_table_summary_report( fullfile(dataDir, datafile), ResultsDir);

close all;
