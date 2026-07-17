% test if elevation is a lso a factors
close all; clear all;

% add path
% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/DataLong082525/';
cd(expDir)

datafile='AllQuadDataLong825withElevation.csv'

all_data=readtable(datafile);

basename = [erase( datafile,'.csv')] ;

ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/DataLong082525/DataLong082525withElevation'

saveLME=1; % 1 save files; 0 don't save 
%%


%outDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Results/AllQuadDataLong825/';
% load sorted subject index by magnification & set colormap


% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task

ii=find(all_data.ID~=26); 
all_data=all_data(ii,:);  
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);

% remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
all_data=all_data(NotNaN,:);

loadfile=fullfile( ResultsDir, 'AllQuadDataLong825withElevation_sorted_idx.mat');
load(loadfile ,'sorted_idx');
cmap=jet(nsubjects);


%%
task='Perceptual';
task_i=find(strcmp(all_data.Task,task));
all_data_by_task=all_data(task_i,:);
Quad_PM_by_taskNelevation(all_data_by_task,[basename '_' task],ResultsDir,saveLME,cmap,sorted_idx);

%%

task='Adjusted';
task_i=find(strcmp(all_data.Task,task));
all_data_by_task=all_data(task_i,:);
Quad_PM_by_taskNelevation(all_data_by_task,[basename '_' task],ResultsDir,saveLME,cmap,sorted_idx);


%% junk
%expDir='/Users/kalanit/Projects/PerceptualMagnification/Data/QuadExperiments/';
%expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'

% dataDir='DataLong082525'
% cd(fullfile(expDir,dataDir))

% dataDir=fullfile(expDir,'Data');
% ResultsDir=fullfile(expDir,'Results','DataLong082525withElevation')
% if ~exist('ResultsDir','dir')
%    mkdir(ResultsDir)
% end

%ResultsDir='DataLong082525withElevation'