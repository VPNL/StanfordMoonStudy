% Organize data by task for the Quad Study

close all; clear all;
SMS_setCodePath;

dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';
ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';

% Processed data for Quad study
dataFile='Perceptual_StanfordQuadStudyDataProcessed0420.csv'
[summaryTbl, reportFile] = write_numeric_table_summary_report(fullfile(dataDir,dataFile), ResultsDir);


% Raw data for Quad study
dataFileRaw = 'Perceptual_StanfordQuadStudyDataRaw0420.csv';
[summaryTbl, reportFile] = write_numeric_table_summary_report(fullfile(dataDir,dataFileRaw), ResultsDir);
