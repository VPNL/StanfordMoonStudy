% PM_FullMoon_Fig1_072126
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir))

dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments//';
datafile='FullMoonDataLong090225.csv';
ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/PaperFigures/Fig1_Moon_072125';

basename = erase(datafile,'.csv');
saveLME=1;
baseResultsDir = ResultsDir;
task='Perceptual';
recomputeSort = 1;
elevationModel = 'deg';

if ~exist(baseResultsDir,'dir')
    mkdir(baseResultsDir)
end

[lmeRI, lmeRS, taskData] = SMS_FullMoon_PM_by_task_log( ...
    dataDir, datafile, ResultsDir, task, recomputeSort, saveLME);
moonLMEData = struct();
moonLMEData.Perceptual = struct('RILME', lmeRI, 'RSLME', lmeRS, ...
    'Data', taskData);


task='Adjusted';
recomputeSort = 0;
elevationModel = 'deg';
[lmeRI, lmeRS, taskData] = SMS_FullMoon_PM_by_task_log( ...
    dataDir, datafile, ResultsDir, task, recomputeSort, saveLME);
moonLMEData.Adjusted = struct('RILME', lmeRI, 'RSLME', lmeRS, ...
    'Data', taskData);

lmeDataFile = fullfile(ResultsDir, ...
    'PM_FullMoon_Fig1_072126_lme_data.mat');
save(lmeDataFile, 'moonLMEData', 'dataDir', 'datafile', 'ResultsDir');
fprintf('Saved reusable Moon LME data: %s\n', lmeDataFile);


close all;
