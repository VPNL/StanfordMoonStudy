close all; clear all;

% add path
% add code path
%codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
%expDir='/Users/kalanit/Projects/PerceptualMagnification/Data/QuadExperiments/';
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
cd(expDir)
datafile='AllQuadDataLong825.csv'
dataDir=fullfile(expDir,'Data');
basename = [erase( datafile,'.csv')] ;

ResultsDir='DataLong082525'
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

saveLME=1; % 1 save files; 0 don't save 
outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';


%% 
%%
task='Perceptual';
% generate tables for subjects that have stick & lamp or stick & ball for
% Perceptual task
[perceptual_stickNlamp_data,perceptual_ballNlamp_data,perceptual_ballNlamp_data_v2] = Quad_filterbyObject(dataDir,datafile,ResultsDir,task);
colormap=[.4 .4 1; % ball
         1 .5 0] % lamp
tbl=perceptual_ballNlamp_data_v2;
tblName='Perceptual_AllQuadDataLong825_ballNlamp_v2';
outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';
Quad_PM_by_taskNobject(tbl,tblName,ResultsDir,saveLME,colormap);

tbl=perceptual_ballNlamp_data;
tblName='Perceptual_AllQuadDataLong825_ballNlamp';
outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';
Quad_PM_by_taskNobject(tbl,tblName,ResultsDir,saveLME,colormap);

colormap=[1 .5 0; % lamp
         .5 .5 .5]; % stick
        
tbl=perceptual_stickNlamp_data;
tblName='Perceptual_AllQuadDataLong825_stickNlamp';
outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';
Quad_PM_by_taskNobject(tbl,tblName,ResultsDir,saveLME,colormap);

%%
% generate tables for subjects that have stick & lamp or stick & ball for
% Adjusted task
task='Adjusted';
[adjusted_stickNlamp_data,adjusted_ballNlamp_data,adjusted_ballNlamp_data_v2] = Quad_filterbyObject(dataDir,datafile,ResultsDir,task);

colormap=[.4 .4 1; % ball
         1 .5 0] % lamp
tbl=adjusted_ballNlamp_data_v2;
tblName='Adjusted_AllQuadDataLong825_ballNlamp_v2';
outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';
Quad_PM_by_taskNobject(tbl,tblName,ResultsDir,saveLME,colormap);

tbl=adjusted_ballNlamp_data;
tblName='Adjusted_AllQuadDataLong825_ballNlamp';
outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';
Quad_PM_by_taskNobject(tbl,tblName,ResultsDir,saveLME,colormap);

colormap=[1 .5 0; % lamp
         .5 .5 .5]; % stick
        
tbl=adjusted_stickNlamp_data;
tblName='Adjusted_AllQuadDataLong825_stickNlamp';
outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';
Quad_PM_by_taskNobject(tbl,tblName,ResultsDir,saveLME,colormap);

