% SMS_Fig2b_Quad_PerceivedVAVsPhysicalVA_071426
close all; clear all;
SMS_setCodePath;

% Processed data for Quad study

% set dirs
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';
QuadFile='Perceptual_StanfordQuadStudyDataProcessed0420.csv';
QuadBasename = [erase(QuadFile,'.csv')]

ResultsDir=fullfile(expDir,'Figures','Fig2b');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

ObserverFlag=1;
saveLME=1; % 1 save files; 0 don't save

%%  plot perceived size vs physical size for Quad perceptual matching experiment

task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification
lme_by_angle_perceptual=Quad_PerceivedSize_by_task(dataDir,QuadFile,task, ObserverFlag, ResultsDir, recomputeSort, saveLME)

%%
close all
