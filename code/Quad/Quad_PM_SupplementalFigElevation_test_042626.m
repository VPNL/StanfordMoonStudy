% Quad_PM_SupplementFigElevation_test_042626
close all; clear all;

% add path
% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
%QuadFile='SQSProcessedData0122.csv';
ObserverFlag=1;

QuadFile='MatchingProcessedData0421.csv';
all_data=readtable(fullfile(expDir,'Data',QuadFile));
QuadBasename = [erase(QuadFile,'.csv')] ;

saveLME=1; % 1 save files; 0 don't save 
saveFlag=1;

ResultsDir=fullfile(expDir,'Paper_SupplementalFigElevationTesting_0426', QuadBasename);
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

%% adjust distances and elevations to consider observer elevation if ObserverFlag or Ground Elevation otherwise
 
all_quad_data=all_data;
if ObserverFlag
    all_quad_data.Elevation=all_data.Observer_Elevation;
    all_quad_data.Distance=all_data.Observer_Distance;
else
    all_quad_data.Elevation=all_data.Ground_Elevation;
    all_quad_data.Distance=all_data.Ground_Distance;
end

%% run analysis

% remove outlier subject who did not follow instrux
ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  

ii=find(all_quad_data.ID~=86);  % outlier subject in the adjusted task ID 86: mean 5.09 over 4 rows
all_quad_data=all_quad_data(ii,:);  

mm=find(all_quad_data.Elevation<0);
uniqueNE=sort(unique(all_quad_data.Elevation(mm)));
numNE=numel(uniqueNE)
if ~isempty(uniqueNE)
    for i=1:numNE
      mm=find(all_quad_data.Elevation==uniqueNE(i));
      all_quad_data(mm(1),:)
    end
end



colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'};

% transform quad distances from cm to meters
quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100,...
    all_quad_data.Elevation, all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);

uniqueID=unique(quad_subset_data.ID);
nsubjects=length(uniqueID);

% sort subjects by PM in Perceptual task
task='Perceptual';
task_p=find(strcmp(quad_subset_data.Task,task));
all_data_perceptual=quad_subset_data(task_p,:);

task='Adjusted';
task_a=find(strcmp(quad_subset_data.Task,task));
all_data_adjusted=quad_subset_data(task_a,:);

for i=1:nsubjects
    idx=find(all_data_perceptual.ID==uniqueID(i));
    meanPM(i)=mean(all_data_perceptual.Ratio_Visual_Angle(idx));
end

% sort subjects by PM
[sorted_PM, sorted_idx] = sort(meanPM);
cmap=brighten(colormap(plasma(nsubjects*1.1)),0);
for c=1:length(uniqueID)
        cindex=find(uniqueID==all_data_perceptual.ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
end

%%
% calculate and plot the results of Experiment 1 Quad matching experiment

task='Perceptual';
% sort subject colors by slopes of perceptual magnification
Perceptual_tblName=[QuadBasename '_' task];

[lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation] = ...
    Quad_PM_by_task_elevationModelTest(all_data_perceptual, Perceptual_tblName, ResultsDir, saveLME, cmap, sorted_idx)




%%
% calculate and plot the results of Experiment 2 Quad adjusted matching experiment

task='Adjusted';
% sort subject colors by slopes of Adjusted magnification
Adjusted_tblName=[QuadBasename '_' task];
[lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation] = ...
    Quad_PM_by_task_elevationModelTest(all_data_adjusted, Adjusted_tblName, ResultsDir, saveLME, cmap, sorted_idx)



saveresultsFile=fullfile(ResultsDir, [QuadBasename '.mat']);
save(saveresultsFile);
%%  clear space
 %clx