% Combine and fit data across both experiments
close all; clear all;

% add path
% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
QuadExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
cd(QuadExpDir)

QuadFile='AllQuadDataLong916.csv'
% QuadFile='AllQuadDataLongStereoblind926.csv';
% 
% QuadFile='AllStereoQuadDataLong930.csv';
all_quad_data=readtable(QuadFile);
QuadBasename = [erase(QuadFile,'.csv')] ;
% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task

ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  


MoonExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments';
cd(MoonExpDir)
MoonFile='FullMoonDataLong090225.csv'
all_moon_data=readtable(MoonFile);
MoonBasename = [erase(MoonFile,'.csv')] ;

ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon'
if ~exist('ResultsDir','dir')
  mkdir(ResultsDir)
end

saveLME=1; % 1 save files; 0 don't save 
%% 
colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'}
% transform moon distances from km to meters
moon_subset_data=table(all_moon_data.ID, all_moon_data.Real_Visual_Angle,1000*all_moon_data.Distance,all_moon_data.Elevation,...
                       all_moon_data.Task, all_moon_data.Reported_Visual_Angle, all_moon_data.Ratio_Visual_Angle, all_moon_data.Disparity_VA,...
                      'VariableNames',colNames);

% transform quad distances from cm to meters
quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,all_quad_data.Disparity_VA_1,...
                       'VariableNames',colNames);
combined_data=[moon_subset_data;quad_subset_data];
combined_basename=['combined_' MoonBasename '_' QuadBasename '.csv'];
combinedfileName=fullfile(ResultsDir,combined_basename);

writetable(combined_data,combinedfileName);


%% combined data
uniqueID=unique(combined_data.ID);
nsubjects=length(uniqueID);
cmap=jet(nsubjects);

% sort subjects by PM in Perceptual task
task='Perceptual';
task_p=find(strcmp(combined_data.Task,task));
all_data_perceptual=combined_data(task_p,:);

task='Adjusted';
task_a=find(strcmp(combined_data.Task,task));
all_data_adjusted=combined_data(task_a,:);


for i=1:nsubjects
    idx=find(all_data_perceptual.ID==uniqueID(i));
    meanPM(i)=mean(all_data_perceptual.Ratio_Visual_Angle(idx));
end

% sort subjects by PM
[sorted_PM, sorted_idx] = sort(meanPM);

for c=1:length(uniqueID)
        cindex=find(uniqueID==all_data_perceptual.ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
end

%
task='Perceptual';
Quad_PM_by_taskNelevation(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap,sorted_idx);

%

task='Adjusted';
Quad_PM_by_taskNelevation(all_data_adjusted,[combined_basename '_' task],ResultsDir,saveLME,cmap,sorted_idx);

%% just moon data

uniqueIDmoon=unique(moon_subset_data.ID);
nsubjects_moon=length(uniqueIDmoon);
cmap_moon=jet(nsubjects_moon);

% sort subjects by PM in Perceptual task
task='Perceptual';
task_p=find(strcmp(moon_subset_data.Task,task));
moon_data_perceptual=moon_subset_data(task_p,:);

task='Adjusted';
task_a=find(strcmp(moon_subset_data.Task,task));
moon_data_adjusted=moon_subset_data(task_a,:);


for i=1:nsubjects_moon
    idx=find(moon_data_perceptual.ID==uniqueIDmoon(i));
    meanPMmoon(i)=mean(moon_data_perceptual.Ratio_Visual_Angle(idx));
end

% sort subjects by PM
[sorted_PM_moon, sorted_idx_moon] = sort(meanPMmoon);

for c=1:length(uniqueIDmoon)
        cindex=find(uniqueIDmoon==moon_data_perceptual.ID(c));
        sorted_cindex_moon=find(sorted_idx_moon==cindex);
        subjectcolor_moon(c,:)=cmap_moon(sorted_cindex_moon,:);
end
%
task='Perceptual';
Quad_PM_by_taskNelevation(moon_data_perceptual,[MoonBasename  '_' task],ResultsDir,saveLME,cmap_moon,sorted_idx_moon);

task='Adjusted';
Quad_PM_by_taskNelevation(moon_data_adjusted,[MoonBasename  '_' task],ResultsDir,saveLME,cmap_moon,sorted_idx_moon);

%% Just quad data

uniqueIDquad=unique(quad_subset_data.ID);
nsubjects_quad=length(uniqueIDquad);
cmap_quad=jet(nsubjects_quad);

% sort subjects by PM in Perceptual task
task='Perceptual';
task_p=find(strcmp(quad_subset_data.Task,task));
quad_data_perceptual=quad_subset_data(task_p,:);

task='Adjusted';
task_a=find(strcmp(quad_subset_data.Task,task));
quad_data_adjusted=quad_subset_data(task_a,:);


for i=1:nsubjects_quad
    idx=find(quad_data_perceptual.ID==uniqueIDquad(i));
    meanPMquad(i)=mean(quad_data_perceptual.Ratio_Visual_Angle(idx));
end

% sort subjects by PM
[sorted_PM_quad, sorted_idx_quad] = sort(meanPMquad);

for c=1:length(uniqueIDquad)
        cindex=find(uniqueIDquad==quad_data_perceptual.ID(c));
        sorted_cindex_quad=find(sorted_idx_quad==cindex);
        subjectcolor_quad(c,:)=cmap_quad(sorted_cindex_quad,:);
end
%
task='Perceptual';
Quad_PM_by_taskNelevation(quad_data_perceptual,[QuadBasename  '_' task],ResultsDir,saveLME,cmap_quad,sorted_idx_quad);

task='Adjusted';
Quad_PM_by_taskNelevation(quad_data_adjusted,[QuadBasename  '_' task],ResultsDir,saveLME,cmap_quad,sorted_idx_quad);