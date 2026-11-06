% SMS_Fig4b_110526
% Generate only the log-log RI/RS analyses used for Figure 4b.
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

dataDir = fullfile(paths.Data, 'MoonStudy');
datafile = 'FullMoonDataLong090225.csv';
ResultsDir = fullfile(paths.Figures, 'Fig4b');
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir)
end

sortSourceDir = fullfile(paths.Figures, 'Fig1');
sortSourceBasename = 'Perceptual_FullMoonDataProcessed090225';
saveLME = true;

% Figure 1 already reports the Perceptual task. Figure 4b reports the
% Adjusted task using the same participant color ordering.
task = 'Adjusted';
SMS_FullMoon_PM_by_task_log_Fig4b(dataDir, datafile, ResultsDir, ...
    task, sortSourceDir, sortSourceBasename, saveLME);

% Test whether PM and elevation effects differ across matching tasks.
SMS_FullMoon_TaskComparison(dataDir, datafile, ResultsDir, saveLME)

close all;
