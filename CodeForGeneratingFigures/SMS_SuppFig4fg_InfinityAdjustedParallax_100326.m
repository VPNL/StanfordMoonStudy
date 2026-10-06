%% SMS_SuppFig4fg_InfinityAdjustedParallax_100326
set(groot, 'defaultFigureVisible', 'on');
close all; clear all;
SMS_setCodePath;

expDir = '/Users/kalanit/Projects/StanfordMoonStudy';
moonFile = ['/Users/kalanit/Projects/PerceptualMagnification/Paper/' ...
    'ExperimentalData/MoonExperiments/Parallax_FullMoon_090225.csv'];
quadFile = fullfile(expDir, 'Data', 'QuadStudy', ...
    'merged_disparity_0429_version3.csv');
ResultsDir = fullfile(expDir, 'Figures', 'SuppFig4fg1003');
if ~exist(ResultsDir, 'dir'), mkdir(ResultsDir); end
saveLME = true;

[models, combinedTable, figHandle, colorOrder] = ...
    Combined_InfinityAdjustedParallax_by_ElevationStudy( ...
    moonFile, quadFile, ResultsDir, saveLME);

save(fullfile(ResultsDir, ...
    'combined_InfinityAdjustedParallax_ElevationStudy_analysed.mat'), ...
    'models', 'combinedTable', 'colorOrder');
