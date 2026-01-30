lme_by_angleNtask=Quad_TaskComparison(dataDir,Quadfile,ResultsDir,saveLME);
% 
% 
%  lme_by_angleNtask=Quad_PercievedSize_by_task(dataDir,datafile,task, ResultsDir,recomputeSort, saveLME)
% This function visualizes and calculates the relationship between the reported visual angle 
% and the ground truth (real) visual angle
% for the Stanford Quad Experiments
% 
% dataDir       Directory where the data resides
% datafile      csv file with subjects data
% ResultsDir    Directory where the data is output resides,task, recomputeSort, saveLME)
% KGS
% Nov 2025

% Quad_PM_by_task(dataDir,datafile,ResultsDir,task, recomputeSort, saveLME)
% defaults
% if ~exist('dataDir')
%     dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
% end
% cd(dataDir)
% 
% if ~exist('datafile')
%    datafile='DataLongKeithan071025.csv'; % all data
% 
% end
% basename = [erase( datafile,'.csv')] ; % for saving
% 
% if ~exist('ResultsDir')
%   ResultsDir='PaperFigures'; % all data
% end
% 
% if ~exist('saveLME')
%         saveLME=1;
% end
% 
% if ~exist('task')
%        task='Perceptual'
%        recomputeSort=1;
% end

%set defaults
% data loading and setting up some basic information
if ~exist('dataDir')
    dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
end
cd(dataDir)

if ~exist('datafile')
   datafile='AllQuadDataLong916.csv'; % all data
end
basename = [erase( datafile,'.csv')] ; % for saving

if ~exist('task')
       task='Perceptual'
       recomputeSort=1;
end
if ~exist('ResultsDir')
    ResultsDir=fullfile(dataDir,'Results',basename);
end
if ~exist('recomputeSort')
    recomputeSort=0;
end

if ~exist('saveLME')
        saveLME=1;
end

%%


all_data=readtable(datafile);
nameVars=all_data.Properties.VariableNames;
nVars=length(all_data.Properties.VariableNames);
allTasks =unique(all_data.Task);disp(allTasks)
nTasks=length(allTasks);
uniqueID=unique(all_data.ID);
uniqueObject=unique(all_data.Measurement);
nObjects=length(uniqueObject);

% %% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task

 ii=find(all_data.ID~=26); 
 all_data=all_data(ii,:);  
 uniqueID=unique(all_data.ID);
 nsubjects=length(uniqueID);

%% remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
all_data=all_data(NotNaN,:);

%% task comparison test if slope of relation between reported and real visual angle varies accprs tasks while accounting for individual differences
lme_by_angleNtask = fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task -1  + (Real_Visual_Angle*Task- 1|ID)')

if saveLME % save stats table
     savelmefile=fullfile(ResultsDir, [basename '_reported_vs_real_angle_task_comparison.txt']);
     diary(savelmefile)
     lme_by_angleNtask
     diary off
end
