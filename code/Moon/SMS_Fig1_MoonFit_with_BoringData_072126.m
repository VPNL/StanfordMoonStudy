% SMS_Fig1_MoonFit_with_BoringData_072126
% Load the reusable Moon task LMEs saved by PM_FullMoon_Fig1_072126 and
% create two Boring-data overlays without refitting the Moon models:
%   1. Perceptual Moon task + Boring Binocular data
%   2. Adjusted Moon task + Boring tasks containing "Monocular"

set(groot, 'defaultFigureVisible', 'on');
close all force;
clear;
clc;

scriptDir = fileparts(mfilename('fullpath'));
codeDir = fileparts(scriptDir);
addpath(genpath(codeDir));

moonResultsDir = fullfile(codeDir, '..', 'PaperFigures', ...
    'Fig1_Moon_072125');
lmeDataFile = fullfile(moonResultsDir, ...
    'PM_FullMoon_Fig1_072126_lme_data.mat');
boringFile = fullfile(codeDir, '..', 'MoonExperiments', ...
    'BoringDataProcessed.csv');
resultsDir = fullfile(codeDir, '..', 'PaperFigures', 'BoringData');

if ~exist(lmeDataFile, 'file')
    error('BoringOverlay:MissingMoonLMEData', ...
        ['Run PM_FullMoon_Fig1_072126 first. Expected reusable LME data at ' ...
        '%s.'], lmeDataFile);
end
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

loadedMoonData = load(lmeDataFile, 'moonLMEData');
moonLMEData = loadedMoonData.moonLMEData;

boringDataBase = readtable(boringFile);
validBoringRows = isfinite(double(boringDataBase.Ratio_Visual_Angle)) & ...
    double(boringDataBase.Ratio_Visual_Angle) > 0 & ...
    isfinite(double(boringDataBase.Elevation)) & ...
    double(boringDataBase.Elevation) >= 0;
boringDataBase = boringDataBase(validBoringRows, :);
boringDataBase.logRatio = log2(double(boringDataBase.Ratio_Visual_Angle));
boringDataBase.logElevation = log2(double(boringDataBase.Elevation) + 1);

%% Perceptual Moon LME with Boring Binocular observations
binocularRows = strcmpi(strtrim(string(boringDataBase.Task)), "Binocular");
boringBinocular = boringDataBase(binocularRows, :);
perceptualOutputStem = fullfile(resultsDir, ...
    'SMS_Fig1_MoonPerceptualLME_with_Boring_Binocular');
[perceptualFigure, sortedMoonIDs] = plot_moon_lme_with_boring_overlay( ...
    moonLMEData.Perceptual, boringBinocular, 'Perceptual', 'Binocular', ...
    perceptualOutputStem, []);
close(perceptualFigure);

%% Adjusted Moon LME with every Boring task containing "Monocular"
monocularRows = contains(string(boringDataBase.Task), "Monocular", ...
    'IgnoreCase', true);
boringMonocular = boringDataBase(monocularRows, :);
adjustedOutputStem = fullfile(resultsDir, ...
    'SMS_Fig1_MoonAdjustedLME_with_Boring_Monocular');
adjustedFigure = plot_moon_lme_with_boring_overlay( ...
    moonLMEData.Adjusted, boringMonocular, 'Adjusted', ...
    'Monocular', adjustedOutputStem, sortedMoonIDs);
close(adjustedFigure);

fprintf(['Saved Perceptual overlay: %d Binocular observations from %d ' ...
    'Boring participants.\n'], height(boringBinocular), ...
    numel(unique(boringBinocular.ID)));
fprintf(['Saved Adjusted overlay: %d observations whose task contains ' ...
    'Monocular from %d Boring participants.\n'], height(boringMonocular), ...
    numel(unique(boringMonocular.ID)));
fprintf('Perceptual output: %s.png\n', perceptualOutputStem);
fprintf('Adjusted output: %s.png\n', adjustedOutputStem);
