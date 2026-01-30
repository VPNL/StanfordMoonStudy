% Quad_PM_Fig2cd_angle_distance_elevation.

close all; clear all;

% add path
% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
QuadFile='SQSProcessedData0122.csv'
all_data=readtable(fullfile(expDir,'Data',QuadFile));
QuadBasename = [erase(QuadFile,'.csv')] ;


%% adjust distances and elevations to consider observer elevation 
new_data.xDistance=new_data.Distance;
new_data.oHeight=new_data.Distance.*tan(pi*new_data.Elevation/180);
new_data.pHeight=118*ones(height(new_data),1); % mean participant elevation in matching task
new_data.Distance=sqrt((new_data.oHeight-new_data.pHeight).^2+new_data.xDistance.^2);
out_datafile=fullfile(expDir,'Data',[QuadBasename '_participant_referred_D.csv']);
writetable(new_data,out_datafile);
%

new_data.Elevation=180*atan((new_data.oHeight-new_data.pHeight)./new_data.xDistance)/pi;
out_datafile=fullfile(expDir,'Data',[QuadBasename '_participant_referred_DE.csv']);
writetable(new_data,out_datafile);

%
new_data.Elevation=abs(new_data.Elevation);
out_datafile=fullfile(expDir,'Data',[QuadBasename '_participant_referred_DabsE.csv']);
writetable(new_data,out_datafile);

%% run analysis

QuadFile='SQSProcessedData0122_participant_referred_DE.csv'
%QuadFile='SQSProcessedData0122_participant_referred_DabsE.csv'
QuadBasename = [erase(QuadFile,'.csv')] ;


all_quad_data=readtable(fullfile(expDir,'Data',QuadFile));
% remove outlier subject who did not follow instrux
ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  


saveLME=1; % 1 save files; 0 don't save 
saveFlag=1;

ResultsDir=fullfile(expDir,'Paper_Fig2cd', QuadBasename);
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
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

% linear fit
[Perceptual_lme_PM_by_Angle,Perceptual_lme_PM_by_Distance,Perceptual_lme_PM_by_Elevation,...
    Perceptual_lme_PM_by_AngleNDistance, Perceptual_lme_PM_by_AngleNElevation, Perceptual_lme_PM_by_DistanceNElevation,...
    Perceptual_lme_PM_by_AngleNDistanceNElevation]=Quad_PM_by_task_linear(all_data_perceptual,Perceptual_tblName,ResultsDir,saveLME,cmap, sorted_idx);

ii=find(all_data_perceptual.Elevation<0);

if ~isempty(ii)
    all_data_perceptual.nElevation=NaN(height(all_data_perceptual), 1);
    all_data_perceptual.nElevation(ii)=all_data_perceptual.Elevation(ii);
    all_data_perceptual.Elevation(ii)=NaN;

    % if we have negative elevations we need to add another model parameter
    % for negative elevations

    [Perceptual_lme_logPM_by_logAngle,Perceptual_lme_logPM_by_logDistance,Perceptual_lme_logPM_by_logElevation,...
    Perceptual_lme_logPM_by_logAngleNDistance, Perceptual_lme_logPM_by_logAngleNElevation, Perceptual_lme_logPM_by_logDistanceNElevation,...
    Perceptual_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task_wNE(all_data_perceptual,Perceptual_tblName,ResultsDir,saveLME,cmap, sorted_idx);
else
    [Perceptual_lme_logPM_by_logAngle,Perceptual_lme_logPM_by_logDistance,Perceptual_lme_logPM_by_logElevation,...
    Perceptual_lme_logPM_by_logAngleNDistance, Perceptual_lme_logPM_by_logAngleNElevation, Perceptual_lme_logPM_by_logDistanceNElevation,...
    Perceptual_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_perceptual,Perceptual_tblName,ResultsDir,saveLME,cmap, sorted_idx);
end

[lme_test] = fit_PM_lme_wMax(all_data_perceptual,[Perceptual_tblName '_fullmodel_fit' task], ResultsDir, saveLME, cmap, sorted_idx);




%%
% calculate and plot the results of Experiment 2 Quad adjusted matching experiment

task='Adjusted';
% sort subject colors by slopes of Adjusted magnification
Adjusted_tblName=[QuadBasename '_' task];


[Adjusted_lme_PM_by_Angle,Adjusted_lme_PM_by_Distance,Adjusted_lme_PM_by_Elevation,...
    Adjusted_lme_PM_by_AngleNDistance, Adjusted_lme_PM_by_AngleNElevation, Adjusted_lme_PM_by_DistanceNElevation,...
    Adjusted_lme_PM_by_AngleNDistanceNElevation]=Quad_PM_by_task_linear(all_data_adjusted,Adjusted_tblName,ResultsDir,saveLME,cmap, sorted_idx);

[Adjusted_lme_logPM_by_logAngle,Adjusted_lme_logPM_by_logDistance,Adjusted_lme_logPM_by_logElevation,...
    Adjusted_lme_logPM_by_logAngleNDistance, Adjusted_lme_logPM_by_logAngleNElevation, Adjusted_lme_logPM_by_logDistanceNElevation,...
    Adjusted_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_adjusted,Adjusted_tblName,ResultsDir,saveLME,cmap, sorted_idx);

[lme_test] = fit_PM_lme_wMax(all_data_adjusted,[Adjusted_tblName '_fullmodel_fit' task], ResultsDir, saveLME, cmap, sorted_idx);



saveresultsFile=fullfile(ResultsDir, [QuadBasename '.mat']);
save(saveresultsFile);