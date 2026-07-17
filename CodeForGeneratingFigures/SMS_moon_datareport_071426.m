% SMS_moon_datarepot_071426.m

close all; clear all;
SMS_setCodePath;

dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';
ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';

dataFile =fullfile(dataDir,'Perceptual_FullMoonDataProcessed090225.csv');
[summaryTbl, reportFile] = write_numeric_table_summary_report(dataFile, ResultsDir);

% Raw data for the moon
dataFile = fullfile(dataDir,'Perceptual_FullMoonDataRaw090225.csv');% 
[summaryTbl, reportFile] = write_numeric_table_summary_report(dataFile, ResultsDir);
