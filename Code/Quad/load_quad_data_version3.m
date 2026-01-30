% data loading and setting up some basic information
clx % clear workspace

% set dirs
%expDir='/Users/kalanit/Projects/PerceptualMagnification/ExperimentalData/QuadExperiments/';
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
cd(expDir)
csvfile='SQSData106_Table3_053025_to_073125.csv'
datafile=fullfile(expDir,'Data',csvfile);

basename = erase(csvfile,'.csv'); % for saving
saveLME=1;
ResultsDir='Results'
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
   cd Results
end
% make directory in results based on datafile
if ~exist('basename','dir')
    mkdir(basename)
end
cd(expDir)

%%
all_data=readtable(datafile);
nameVars=all_data.Properties.VariableNames;
disp(nameVars)
nVars=length(all_data.Properties.VariableNames);
allTasks =unique(all_data.Task);disp(allTasks)
nTasks=length(allTasks);
uniqueID=unique(all_data.ID);
uniqueObject=unique(all_data.Measurement);
nObjects=length(uniqueObject);

% %% remove subject 26 & 86 who are outliers
% ii=find(all_data.ID~=26);
% all_data=all_data(ii,:);
% 
% ii=find(all_data.ID~=86);
% all_data=all_data(ii,:);
% 
% uniqueID=unique(all_data.ID);
 nsubjects=length(uniqueID);

%% remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
all_data=all_data(NotNaN,:);


%% find max angle and maxRatio for graphs
maxRealAngle=max(all_data.Real_Visual_Angle);
maxAngle=max(all_data.Reported_Visual_Angle);

task_1=find(strcmp(all_data.Task,allTasks(1)));
task_2=find(strcmp(all_data.Task,allTasks(2)));
maxRatio=max(all_data.Ratio_Visual_Angle);
% transform distances from cm to m 
all_data.Distance=all_data.Distance/100;
maxDistance=max(all_data.Distance);
minDistance=min(all_data.Distance);
% check that NA in QuadDataLong.csv has been replaced with empty cell
minDisparity=min([all_data.Disparity_VA_1; all_data.Disparity_VA_2]);
maxDisparity=max([all_data.Disparity_VA_1; all_data.Disparity_VA_2]);


%% set colormap
cmapflag=2;
if cmapflag==1
    tmp_cmap_cool=cool(round(nsubjects/4)+1);
    tmp_cmap_hot=autumn(round(nsubjects/4)+1);
    tmp_cmap_copper=copper(round(nsubjects/4)+1);
    tmp_cmap_jet=jet(round(nsubjects/4)+1);

    for i=1:nsubjects
        if (mod(i,4)==0)
            cmap(i,:)=tmp_cmap_cool(i/4,:);
        elseif (mod(i,4)==1)
            cmap(i,:)=tmp_cmap_hot(ceil(i/4),:);
        elseif (mod(i,4)==2)
            cmap(i,:)=tmp_cmap_copper(ceil(i/4),:);
        else
            cmap(i,:)=tmp_cmap_jet(ceil(i/4),:);
        end
    end
else
    % alt cmap
    cmap=jet(nsubjects);
end
markerScale=36;
