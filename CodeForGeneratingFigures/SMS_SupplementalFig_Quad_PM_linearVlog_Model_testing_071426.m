% SMS_SupplemnentalFig_Quad_PM_linearVlog_Model_testing_070126.m

close all; clear all;

% add code path
SMS_setCodePath;

%setdirs
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/'
QuadFile='Perceptual_StanfordQuadStudyDataProcessed0420.csv';
ObserverFlag=1;
QuadBasename = [erase(QuadFile,'.csv')]

all_quad_data=readtable(fullfile(dataDir,QuadFile));
saveLME=1; % 1 save files; 0 don't save
saveFlag=1;

ResultsDir=fullfile(expDir,'Figures','Supplemental_Fig_Quad_LinearVsLog_ModelTesting');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end


%% run analysis

% remove outlier subject who did not follow instrux
ii=find(all_quad_data.ID~=26);
all_quad_data=all_quad_data(ii,:);
uniqueID=unique(all_quad_data.ID);
nsubjects=length(uniqueID);

if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance;
else
    all_quad_data.Elevation=all_quad_data.Ground_Elevation;
    all_quad_data.Distance=all_quad_data.Ground_Distance;
end

colNames=   {'ID','Measurement', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'};

all_data_perceptual=table(all_quad_data.ID, all_quad_data.Measurement, all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);

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

%%  VA Model testing

[lme_PM_by_VA, lme_logPM_by_logVA, leaderboardTbl] = ...
    Quad_PM_by_task_VAModelTest(all_data_perceptual, QuadBasename, ResultsDir, saveLME, cmap, sorted_idx);



%%  Distance Model testing
[lme_PM_by_VA, lme_logPM_by_logVA, leaderboardTbl] = ...
    Quad_PM_by_task_DistanceModelTest(all_data_perceptual, QuadBasename, ResultsDir, saveLME, cmap, sorted_idx);

%% Elevation Model testing

[lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation] = ...
    Quad_PM_by_task_simple_elevationModelTest(all_data_perceptual, QuadBasename, ResultsDir, saveLME, cmap, sorted_idx);


%% save

saveresultsFile=fullfile(ResultsDir, [QuadBasename '.mat']);
save(saveresultsFile);
clx
