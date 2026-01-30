% Quad_PM_Fig3_angle_distance_elevation.

close all; clear all;

% add path
% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
DataDir=fullfile(expDir,'Data');
cd(DataDir)

QuadFile='SQSProcessedData0122_corrected_Distance.csv'
% ResultsDir=fullfile(expDir,'Paper_Fig3_012526_oD');

QuadFile='SQSProcessedData0122.csv'
ResultsDir=fullfile(expDir,'Paper_Fig3_012526');
visualizeDir=fullfile(ResultsDir,'VisualizePM');

all_quad_data=readtable(QuadFile);
QuadBasename = [erase(QuadFile,'.csv')] ;

saveLME=1; % 1 save files; 0 don't save 
saveFlag=1;

if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end
if ~exist('visualizeDir','dir')
   mkdir(visualizeDir)
end


%% prepare data

% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task

ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  

% colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
%             'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'}
colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'}

% transform quad distances from cm to meters
quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);

plot_VA_D_E_parameters(quad_subset_data,[QuadBasename '_ExperimentalParams'],ResultsDir);

%%
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


%% get ranges for plotting
uniqueD=sort(unique(quad_subset_data.Distance)); minD=min(uniqueD); maxD=max(uniqueD)
uniqueVA=sort(unique(quad_subset_data.Real_Visual_Angle));minVA=min(uniqueVA);maxVA=max(uniqueVA);
uniqueE=sort(unique(quad_subset_data.Elevation));minE=min(uniqueE); maxE=max(uniqueE);

jj=find(strcmp(all_quad_data.Measurement,'Lamp1_Perceptual_VA'));
VA2visualize=unique(all_quad_data.Real_Visual_Angle(jj));
E2visualize=unique(all_quad_data.Elevation(jj));
D2visualize=unique(all_quad_data.Distance(jj))/100; % transform distances to cmm


%%
% calculate and plot the results of Experiment 1 Quad matching experiment

task='Perceptual';
% sort subject colors by slopes of perceptual magnification
Perceptual_tblName=[QuadBasename '_' task];


[Perceptual_lme_logPM_by_logAngle,Perceptual_lme_logPM_by_logDistance,Perceptual_lme_logPM_by_logElevation,...
    Perceptual_lme_logPM_by_logAngleNDistance, Perceptual_lme_logPM_by_logAngleNElevation, Perceptual_lme_logPM_by_logDistanceNElevation,...
    Perceptual_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_perceptual,Perceptual_tblName,ResultsDir,saveLME,cmap, sorted_idx);

outCsvFile=fullfile(ResultsDir, [Perceptual_tblName '_lme_summary.csv'])
Perceptual_summaryTbl = Quad_export_LME_summary_csv(QuadBasename, 'perceptual',...
    Perceptual_lme_logPM_by_logAngle, Perceptual_lme_logPM_by_logDistance, Perceptual_lme_logPM_by_logElevation, ...
    Perceptual_lme_logPM_by_logAngleNDistance, Perceptual_lme_logPM_by_logAngleNElevation, Perceptual_lme_logPM_by_logDistanceNElevation, ...
    Perceptual_lme_logPM_by_logAngleNDistanceNElevation,outCsvFile)

[lme_test] = fit_PM_lme_wMax(all_data_perceptual,[Perceptual_tblName '_fullmodel_fit' task], ResultsDir, saveLME, cmap, sorted_idx);


VAmax=8;
distance_mm=500;
FigName=Perceptual_tblName;
visualize_real_perceived_predicted(all_data_perceptual,Perceptual_lme_logPM_by_logAngleNDistanceNElevation,visualizeDir,FigName,VAmax, distance_mm)



%%
% calculate and plot the results of Experiment 2 Quad adjusted matching experiment

task='Adjusted';
% sort subject colors by slopes of Adjusted magnification
Adjusted_tblName=[QuadBasename '_' task];


[Adjusted_lme_logPM_by_logAngle,Adjusted_lme_logPM_by_logDistance,Adjusted_lme_logPM_by_logElevation,...
    Adjusted_lme_logPM_by_logAngleNDistance, Adjusted_lme_logPM_by_logAngleNElevation, Adjusted_lme_logPM_by_logDistanceNElevation,...
    Adjusted_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_adjusted,Adjusted_tblName,ResultsDir,saveLME,cmap, sorted_idx);

outCsvFile=fullfile(ResultsDir, [Adjusted_tblName '_lme_summary.csv'])
Adjusted_summaryTbl = Quad_export_LME_summary_csv(QuadBasename, 'Adjusted',...
    Adjusted_lme_logPM_by_logAngle, Adjusted_lme_logPM_by_logDistance, Adjusted_lme_logPM_by_logElevation, ...
    Adjusted_lme_logPM_by_logAngleNDistance, Adjusted_lme_logPM_by_logAngleNElevation, Adjusted_lme_logPM_by_logDistanceNElevation, ...
    Adjusted_lme_logPM_by_logAngleNDistanceNElevation,outCsvFile)

[lme_test] = fit_PM_lme_wMax(all_data_adjusted,[Adjusted_tblName '_fullmodel_fit' task], ResultsDir, saveLME, cmap, sorted_idx);

VAmax=8;
distance_mm=500;
FigName=Adjusted_tblName;
visualize_real_perceived_predicted(all_data_adjusted,Adjusted_lme_logPM_by_logAngleNDistanceNElevation,visualizeDir,FigName,VAmax, distance_mm)


