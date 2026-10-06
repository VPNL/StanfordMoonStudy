
%% SMS_Fig4g_FullMoon_Parallax_092626
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

expDir='/Users/kalanit/Projects/StanfordMoonStudy';
dataDir=['/Users/kalanit/Projects/PerceptualMagnification/Paper/' ...
    'ExperimentalData/MoonExperiments/'];

%datafile='Disparity_BothElevations_FullMoonDataLong090225.csv';
datafile='Parallax_FullMoon_090225.csv';

dataPath = fullfile(dataDir, datafile);
if ~isfile(dataPath) && isfile([dataPath '.csv'])
    dataPath = [dataPath '.csv'];
end
[~, basename, ~] = fileparts(dataPath);

ResultsDir=fullfile(expDir, 'Figures', 'Fig4g1003' );
if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end


saveLME=1; % save stats

%% Perceived parallax by elevation and PM by perceived parallax across tasks
task='Perceptual';

[models, lme_PM_by_parallax_and_task, tablewithParallax, ...
    sorteduniqueIDD, figHandles] = ...
    FullMoon_Parallax(dataDir, datafile, task, ResultsDir, saveLME);

%% Caliper distance and infinity-adjusted parallax
InfinityResultsDir = fullfile(ResultsDir, ...
    'InfinityAdjustedParallax1003');
if ~exist(InfinityResultsDir, 'dir')
    mkdir(InfinityResultsDir)
end
[infinityModels, ~, tablewithInfinityAdjustedParallax, ...
    infinitySorteduniqueIDD, infinityFigHandles] = ...
    FullMoon_InfinityAdjusted_Parallax(dataDir, datafile, task, ...
    InfinityResultsDir, saveLME, sorteduniqueIDD);


uniqueDate=unique(tablewithParallax.Date);
disp('dates'); disp(uniqueDate)
IDD=tablewithParallax.ID;
uniqueIDD=unique(IDD);
nsubjectsD=length(uniqueIDD);
fprintf('%d subjects for full moon parallax data\n ',nsubjectsD);


%% 
close all



savefile=fullfile(ResultsDir, [basename '_' task '_analysed']);
save(savefile)
