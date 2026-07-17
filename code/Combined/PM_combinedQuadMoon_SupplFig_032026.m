% Combine and fit data across both experiments
close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))
ObserverFlag=1;
ElevationTransform=1; % abs elevation
ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/SupplFig_QuadMoonPositiveOnly_032026'
if ~exist('ResultsDir','dir')
  mkdir(ResultsDir)
end

saveLME=1; % 1 save files; 0 don't save 
%%  generate combined and make all distances to meters
%  the moon data is in km and the quad data is in cm a

MoonExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments';
MoonFile='FullMoonDataLong090225.csv'
all_moon_data=readtable(fullfile(MoonExpDir,MoonFile));
MoonBasename = [erase(MoonFile,'.csv')] ;

% moon study
colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'}
% transform moon distances from km to meters
moon_subset_data=table(all_moon_data.ID, all_moon_data.Real_Visual_Angle,1000*all_moon_data.Distance,all_moon_data.Elevation,...
                       all_moon_data.Task, all_moon_data.Reported_Visual_Angle, all_moon_data.Ratio_Visual_Angle,...
                      'VariableNames',colNames);
hh=height(moon_subset_data);
for h=1:hh
    moon_subset_data.Study(h)={'MoonStudy'};
end


% quad study
% set dirs
QuadExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';


all_quad_data=readtable(fullfile(QuadExpDir,QuadFile));
QuadBasename = [erase(QuadFile,'.csv')] ;

if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance;
end


% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task
ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  


quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);
hh=height(quad_subset_data);
for h=1:hh
    quad_subset_data.Study(h)={'QuadStudy'};
end

combined_data=[moon_subset_data;quad_subset_data];
combined_basename=['combined_' MoonBasename '_' QuadBasename];
combinedfileName=fullfile(ResultsDir,[combined_basename '.csv']);

writetable(combined_data,combinedfileName);
plot_VA_D_E_parameters(combined_data,combined_basename,ResultsDir);


%% Separate by task quad data
uniqueIDquad=unique(quad_subset_data.ID);
nsubjects_quad=length(uniqueIDquad);
cmap_quad=brighten(colormap(plasma(nsubjects_quad)),0);

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

%% %% Separate by task moon data
uniqueIDmoon=unique(moon_subset_data.ID);
nsubjects_moon=length(uniqueIDmoon);
cmap_moon=brighten(colormap(plasma(nsubjects_moon)),0);


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
%% combined data
uniqueID=unique(combined_data.ID);
nsubjects=length(uniqueID);
cmap_combined=brighten(colormap(plasma(nsubjects*1.1)),0);


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
        subjectcolor(c,:)=cmap_combined(sorted_cindex,:);
end

%% Now let's calculate models
% combined data
task='Perceptual';

% sort subject colors by slopes of perceptual magnification
Perceptual_tblName=[combined_basename '_' task];

[lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation] = ...
    Quad_PM_by_task_elevationModelTest(all_data_perceptual, Perceptual_tblName, ResultsDir, saveLME, cmap_combined, sorted_idx)

% PM_by_Task_VA_Elevation(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);
% PM_by_Task_Distance_Elevation(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);
% PM_by_Task_VA_Distance(all_data_perceptual,[combined_basename  '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);
% 
% let's estimate all lmes including tripple factor lme
[Combined_Perceptual_lme_logPM_by_logAngle,Combined_Perceptual_lme_logPM_by_logDistance,Combined_Perceptual_lme_logPM_by_logElevation,...
    Combined_Perceptual_lme_logPM_by_logAngleNDistance, Combined_Perceptual_lme_logPM_by_logAngleNElevation, Combined_Perceptual_lme_logPM_by_logDistanceNElevation,...
    Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined, sorted_idx,ElevationTransform);

outCsvFile=fullfile(ResultsDir, [combined_basename '_' task '_lme_summary.csv'])
summaryTbl = Quad_export_LME_summary_csv( 'combined_quad_moon', 'perceptual',...
    Combined_Perceptual_lme_logPM_by_logAngle, Combined_Perceptual_lme_logPM_by_logDistance, Combined_Perceptual_lme_logPM_by_logElevation, ...
    Combined_Perceptual_lme_logPM_by_logAngleNDistance, Combined_Perceptual_lme_logPM_by_logAngleNElevation, Combined_Perceptual_lme_logPM_by_logDistanceNElevation, ...
    Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,outCsvFile)

[lme_test] = fit_PM_full_VA_D_E_model(all_data_perceptual,[combined_basename '_fullmodel_' task], ResultsDir, saveLME, cmap_combined, sorted_idx,ElevationTransform);



%%
task='Adjusted';
Adjusted_tblName=[combined_basename '_' task];
[lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation] = ...
    Quad_PM_by_task_elevationModelTest(all_data_adjusted, Adjusted_tblName, ResultsDir, saveLME, cmap_combined, sorted_idx)


% PM_by_Task_VA_Elevation(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);
% PM_by_Task_Distance_Elevation(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);
% PM_by_Task_VA_Distance(all_data_perceptual,[combined_basename  '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);

[Combined_Adjusted_lme_logPM_by_logAngle,Combined_Adjusted_lme_logPM_by_logDistance,Combined_Adjusted_lme_logPM_by_logElevation,...
    Combined_Adjusted_lme_logPM_by_logAngleNDistance, Combined_Adjusted_lme_logPM_by_logAngleNElevation, Combined_Adjusted_lme_logPM_by_logDistanceNElevation,...
    Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_adjusted,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined, sorted_idx,ElevationTransform);


outCsvFile=fullfile(ResultsDir, [combined_basename '_' task '_lme_summary.csv'])
summaryTbl = Quad_export_LME_summary_csv( 'combined_quad_moon', 'adjusted',...
    Combined_Adjusted_lme_logPM_by_logAngle, Combined_Adjusted_lme_logPM_by_logDistance, Combined_Adjusted_lme_logPM_by_logElevation, ...
    Combined_Adjusted_lme_logPM_by_logAngleNDistance, Combined_Adjusted_lme_logPM_by_logAngleNElevation, Combined_Adjusted_lme_logPM_by_logDistanceNElevation, ...
    Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,outCsvFile)


[lme_test] = fit_PM_full_VA_D_E_model(all_data_adjusted,[combined_basename '_fullmodel_' task], ResultsDir, saveLME, cmap_combined, sorted_idx,ElevationTransform);
 



%%

%% close all
close all
saveFile=fullfile(ResultsDir, [combined_basename '.mat'])
save(saveFile)