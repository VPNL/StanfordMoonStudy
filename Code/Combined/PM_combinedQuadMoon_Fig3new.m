% Combine and fit data across both experiments
close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/SupplFig_QuadMoon_012226'
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
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'}
% transform moon distances from km to meters
moon_subset_data=table(all_moon_data.ID, all_moon_data.Real_Visual_Angle,1000*all_moon_data.Distance,all_moon_data.Elevation,...
                       all_moon_data.Task, all_moon_data.Reported_Visual_Angle, all_moon_data.Ratio_Visual_Angle, all_moon_data.Disparity_VA,...
                      'VariableNames',colNames);
hh=height(moon_subset_data);
for h=1:hh
    moon_subset_data.Study(h)={'MoonStudy'};
end


% quad study
% set dirs
QuadExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
%QuadFile='AllQuadDataLong916.csv'
QuadFile='FinalQuadProcessedData109.csv'

all_quad_data=readtable(fullfile(QuadExpDir,QuadFile));
QuadBasename = [erase(QuadFile,'.csv')] ;

% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task
ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  


quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,all_quad_data.Disparity_VA_1,...
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
cmap_quad=jet(nsubjects_quad);

% sort subjects by PM in Perceptual task
task='Perceptual';
task_p=find(strcmp(quad_subset_data.Task,task));
quad_data_perceptual=quad_subset_data(task_p,:);

task='Adjusted';
task_a=find(strcmp(quad_subset_data.Task,task));
quad_data_adjusted=quad_subset_data(task_a,:);

% quad_distances=unique(quad_data_perceptual.Distance);
% for dd=1:numel(quad_distances)
%     jj=find(quad_data_perceptual.Distance==quad_distances(dd));
%     subjPerDistance(dd)=numel(unique(quad_data_perceptual.ID(jj)));
% end
% fprintf(1,'Quad Study: min subjects per distance %0d; mean subjects per distance %.0f\n', min(subjPerDistance),mean(subjPerDistance));

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
%% combined data
uniqueID=unique(combined_data.ID);
nsubjects=length(uniqueID);
cmap_combined=jet(nsubjects);

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

%% Now let's calculated models
% combined data
task='Perceptual';
PM_by_Task_VA_Elevation(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);
PM_by_Task_Distance_Elevation(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);
PM_by_Task_VA_Distance(all_data_perceptual,[combined_basename  '_' task],ResultsDir,saveLME,cmap_combined,sorted_idx);

% let's estimate all lmes including tripple factor lme
[Combined_Perceptual_lme_logPM_by_logAngle,Combined_Perceptual_lme_logPM_by_logDistance,Combined_Perceptual_lme_logPM_by_logElevation,...
    Combined_Perceptual_lme_logPM_by_logAngleNDistance, Combined_Perceptual_lme_logPM_by_logAngleNElevation, Combined_Perceptual_lme_logPM_by_logDistanceNElevation,...
    Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_perceptual,[combined_basename '_' task],ResultsDir,saveLME,cmap_combined, sorted_idx);

outCsvFile=fullfile(ResultsDir, [combined_basename '_' task '_lme_summary.csv'])
summaryTbl = Quad_export_LME_summary_csv( 'combined_quad_moon', 'perceptual',...
    Combined_Perceptual_lme_logPM_by_logAngle, Combined_Perceptual_lme_logPM_by_logDistance, Combined_Perceptual_lme_logPM_by_logElevation, ...
    Combined_Perceptual_lme_logPM_by_logAngleNDistance, Combined_Perceptual_lme_logPM_by_logAngleNElevation, Combined_Perceptual_lme_logPM_by_logDistanceNElevation, ...
    Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,outCsvFile)

[lme_test] = fit_PM_lme(all_data_perceptual,[combined_basename '_fullmodel_' task], ResultsDir, saveLME, cmap_combined, sorted_idx);


% get model coefficients & confidence intervals and pvalues

%%
% range to visualize PM
OutFile=[combined_basename '_' task]; 

% moon distance on log scale
moonDistance=384000*1000; % moon distance in m
VArange=[.1 10]; Erange=[1 40]; Drange=[10 moonDistance];
logscale=1; OutFile=[combined_basename '_' task '_log'];
visualize_PM_VA_DS_EL(ResultsDir,OutFile,task,statstable.Intercept(1),statstable.VAe(1),statstable.De(1),statstable.Ee(1),VArange,Drange,Erange,logscale);

% quad distance on linear scale
quadDistance=200;
VArange=[.1 10]; Erange=[1 40]; Drange=[10 quadDistance];
visualize_PM_VA_DS_EL(ResultsDir,[OutFile '_quadRange'],task,statstable.Intercept(1),statstable.VAe(1),statstable.De(1),statstable.Ee(1),VArange,Drange,Erange);

%
saveFlag=1;


% %% visualize perceptual magnification for moonball 1	60.60	0.3491
D=60.60;
ii=find(quad_data_perceptual.Distance==D);
VA=mean(quad_data_perceptual.Real_Visual_Angle(ii)); %=1.3777
E=mean(quad_data_perceptual.Elevation(ii)); %13.2955
meanperceivedVA=mean(quad_data_perceptual.Reported_Visual_Angle(ii));

PM=evaluatePMbyVisualAngleDistanceElevation(Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
estimated_perceivedVA=VA*PM;
distance_mm=500;

saveFilename=fullfile(ResultsDir, sprintf('%s_EstimatedPerceptual_visualize_%.1f_%.1f_%.1f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,estimated_perceivedVA,distance_mm,saveFlag,saveFilename);

% now compare to participants' data
%
meanperceived_PM=mean(quad_data_perceptual.Ratio_Visual_Angle(ii));
saveFilename=fullfile(ResultsDir, sprintf('%s_ParticipantPerceptual_visualize_%.1f_%.1f_%.1f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,meanperceivedVA,distance_mm,saveFlag,saveFilename);


% at a higher elevation
D=16.9;
ii=find(quad_data_perceptual.Distance==D);
VA=mean(quad_data_perceptual.Real_Visual_Angle(ii)); %=1.3777
E=mean(quad_data_perceptual.Elevation(ii)); %13.2955
meanperceivedVA=mean(quad_data_perceptual.Reported_Visual_Angle(ii));
PM=evaluatePMbyVisualAngleDistanceElevation(Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
estimated_perceivedVA=VA*PM;
distance_mm=500;

saveFilename=fullfile(ResultsDir, sprintf('%s_EstimatedPerceptual_visualize_%.1f_%.1f_%.1f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,estimated_perceivedVA,distance_mm,saveFlag,saveFilename);

saveFilename=fullfile(ResultsDir, sprintf('%s_PerceivedPerceptual_visualize_%.1f_%.1f_%.1f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,meanperceivedVA,distance_mm,saveFlag,saveFilename);


%% estimate moon PM close to horizon
ii=find(moon_data_perceptual.Elevation<5);
E=mean(moon_data_perceptual.Elevation(ii));
VA=mean(moon_data_perceptual.Real_Visual_Angle(ii));
D=mean(moon_data_perceptual.Distance(ii))
meanperceivedmoonVA=mean(moon_data_perceptual.Reported_Visual_Angle(ii));

PM=evaluatePMbyVisualAngleDistanceElevation(Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
estimatedperceivedmoonVA=VA*PM;

saveFilename=fullfile(ResultsDir, sprintf('%s_EstimatedPerceptual_visualize_moon_%.2f_%.1f_%.0f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,estimatedperceivedmoonVA,distance_mm,saveFlag,saveFilename);
saveFilename=fullfile(ResultsDir, sprintf('%s_PerceptivedPerceptual_visualize_moon_%.2f_%.1f_%.0f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,meanperceivedmoonVA,distance_mm,saveFlag,saveFilename);

% estimate moon PM at around 40 degrees
ii=find(moon_data_perceptual.Elevation>=36);
E=mean(moon_data_perceptual.Elevation(ii));
VA=mean(moon_data_perceptual.Real_Visual_Angle(ii));
D=mean(moon_data_perceptual.Distance(ii))
meanperceivedmoonVA=mean(moon_data_perceptual.Reported_Visual_Angle(ii));

PM=evaluatePMbyVisualAngleDistanceElevation(Combined_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
estimatedperceivedmoonVA=VA*PM;

saveFilename=fullfile(ResultsDir, sprintf('%s_EstimatedPerceptual_visualize_moon_%.2f_%.1f_%.0f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,estimatedperceivedmoonVA,distance_mm,saveFlag,saveFilename);

saveFilename=fullfile(ResultsDir, sprintf('%s_ParticipantPerceptual_visualize_moon_%.2f_%.1f_%.0f.png',combined_basename,VA,E,D));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,meanperceivedmoonVA,distance_mm,saveFlag,saveFilename);


%%
task='Adjusted';
PM_by_Task_VA_Elevation(all_data_adjusted,[combined_basename '_' task],ResultsDir,saveLME,cmap,sorted_idx);
PM_by_Task_Distance_Elevation(all_data_adjusted,[combined_basename '_' task],ResultsDir,saveLME,cmap,sorted_idx);
[Combined_Adjusted_lme_logPM_by_logAngle,Combined_Adjusted_lme_logPM_by_logDistance,Combined_Adjusted_lme_logPM_by_logElevation,...
    Combined_Adjusted_lme_logPM_by_logAngleNDistance, Combined_Adjusted_lme_logPM_by_logAngleNElevation, Combined_Adjusted_lme_logPM_by_logDistanceNElevation,...
    Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(all_data_adjusted,[combined_basename '_' task],ResultsDir,saveLME,cmap, sorted_idx);



outCsvFile=fullfile(ResultsDir, [OutFile '_' task '_lme_summary.csv'])
summaryTbl = Quad_export_LME_summary_csvCombined_Adjusted_lme_logPM_by_logAngle, Combined_Adjusted_lme_logPM_by_logDistance, Combined_Adjusted_lme_logPM_by_logElevation, ...
    Combined_Adjusted_lme_logPM_by_logAngleNDistance, Combined_Adjusted_lme_logPM_by_logAngleNElevation, Combined_Adjusted_lme_logPM_by_logDistanceNElevation, ...
    Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation, outCsvFile)
[lme_test] = fit_PM_lme(all_data_adjusted,[combined_basename '_test_' task], ResultsDir, saveLME, cmap, sorted_idx)


% get model coefficients
Intercept=Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(1);
VAe=Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(2);
De=Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(3);
Ee=Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(4);

visualize_PM_VA_DS_EL(ResultsDir,OutFile,task,Intercept,VAe,De,Ee,VArange,Drange,Erange); 
% now on logscale
logscale=1; OutFile=[combined_basename '_log'];
visualize_PM_VA_DS_EL(ResultsDir,OutFile,task,Intercept,VAe,De,Ee,VArange,Drange,Erange,logscale);

VArange=[.1 10]; Erange=[1 40]; Drange=[10 200];
visualize_PM_VA_DS_EL(ResultsDir,[OutFile '_quadRange'],task,Intercept,VAe,De,Ee,VArange,Drange,Erange);

%%
% %% visualize perceptual magnification for example 0.5degree object at 150 m
% distance and 2.5degree elevation
VA=0.5;
D=150;
E=2.5; 
PM=evaluatePMbyVisualAngleDistanceElevation(Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
perceivedVA=VA*PM;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Adjusted_visualize_PM%.2f_%.1f_%0.f_%.1f.png',combined_basename,PM,VA,D,E));

[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

% estimate moon PM
VA=0.5;
D=384000*1000;
E=2.5; 
PM=evaluatePMbyVisualAngleDistanceElevation(Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
perceivedVA=VA*PM;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Adjusted_visualize_PM%.2f_%.1f_sky_%.1f.png',combined_basename,PM,VA,E));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

E=40; 
PM=evaluatePMbyVisualAngleDistanceElevation(Combined_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
perceivedVA=VA*PM;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Adjusted_visualize_PM%.2f_%.1f_sky_%.1f.png',combined_basename,PM,VA,E));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);



%%

OutFile=QuadBasename;
task='Perceptual';
PM_by_Task_VA_Elevation(quad_data_perceptual,[QuadBasename  '_' task],ResultsDir,saveLME,cmap_quad,sorted_idx_quad);
PM_by_Task_Distance_Elevation(quad_data_perceptual,[QuadBasename  '_' task],ResultsDir,saveLME,cmap_quad,sorted_idx_quad);
[Quad_Perceptual_lme_logPM_by_logAngle,Quad_Perceptual_lme_logPM_by_logDistance,Quad_Perceptual_lme_logPM_by_logElevation,...
    Quad_Perceptual_lme_logPM_by_logAngleNDistance, Quad_Perceptual_lme_logPM_by_logAngleNElevation, Quad_Perceptual_lme_logPM_by_logDistanceNElevation,...
    Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(quad_data_perceptual,[QuadBasename '_' task],ResultsDir,saveLME,cmap, sorted_idx);

outCsvFile=fullfile(ResultsDir, [OutFile '_' task '_lme_summary.csv'])
summaryTbl = Quad_export_LME_summary_csv(Quad_Perceptual_lme_logPM_by_logAngle, Quad_Perceptual_lme_logPM_by_logDistance, Quad_Perceptual_lme_logPM_by_logElevation, ...
    Quad_Perceptual_lme_logPM_by_logAngleNDistance, Quad_Perceptual_lme_logPM_by_logAngleNElevation, Quad_Perceptual_lme_logPM_by_logDistanceNElevation, ...
    Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,outCsvFile)

[lme_test] = fit_PM_lme(quad_data_perceptual,[QuadBasename '_test_' task], ResultsDir, saveLME, cmap, sorted_idx)

% get model coefficients
Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation.CoefficientNames
Intercept=Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(1);
VAe=Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(2);
De=Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(3);
Ee=Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(4);
% range to visalize PM
VArange=[.1 10]; Erange=[1 40]; Drange=[10 200];
visualize_PM_VA_DS_EL(ResultsDir,OutFile,task,Intercept,VAe,De,Ee,VArange,Drange,Erange); 
logscale=1; % now on logscale
visualize_PM_VA_DS_EL(ResultsDir,[OutFile '_log'],task,Intercept,VAe,De,Ee,VArange,Drange,Erange,logscale); 


%%

% %% visualize perceptual magnification for example 0.5degree object at 150 m
% distance and 2.5degree elevation
VA=0.5;
D=150;
E=2.5; 
% estimated perceived VA using model for adjusted matching 
PM=evaluatePMbyVisualAngleDistanceElevation(Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)

perceivedVA=VA*PM;
distance_mm=500;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Perceptual_visualize_PM%.2f_%.1f_%0.f_%.1f.png',QuadBasename,PM,VA,D,E));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

% estimate moon PM
VA=0.5;
D=100*1000;
E=2.5; 
PM=evaluatePMbyVisualAngleDistanceElevation(Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
perceivedVA=VA*PM;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Perceptual_visualize_PM%.2f_%.1f_sky_%.1f.png',QuadBasename,PM,VA,E));

[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

E=40; 
PM=evaluatePMbyVisualAngleDistanceElevation(Quad_Perceptual_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
perceivedVA=VA*PM;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Perceptual_visualize_PM%.2f_%.1f_sky_%.1f.png',QuadBasename,PM,VA,E));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

%%

OutFile=QuadBasename;
task='Adjusted';
PM_by_Task_VA_Elevation(quad_data_adjusted,[QuadBasename  '_' task],ResultsDir,saveLME,cmap_quad,sorted_idx_quad);
PM_by_Task_Distance_Elevation(quad_data_adjusted,[QuadBasename  '_' task],ResultsDir,saveLME,cmap_quad,sorted_idx_quad);
[Quad_Adjusted_lme_logPM_by_logAngle,Quad_Adjusted_lme_logPM_by_logDistance,Quad_Adjusted_lme_logPM_by_logElevation,...
    Quad_Adjusted_lme_logPM_by_logAngleNDistance, Quad_Adjusted_lme_logPM_by_logAngleNElevation, Quad_Adjusted_lme_logPM_by_logDistanceNElevation,...
    Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(quad_data_adjusted,[QuadBasename  '_' task],ResultsDir,saveLME,cmap, sorted_idx);

outCsvFile=fullfile(ResultsDir, [OutFile '_' task '_lme_summary.csv'])
summaryTbl = Quad_export_LME_summary_csv(Quad_Adjusted_lme_logPM_by_logAngle, Quad_Adjusted_lme_logPM_by_logDistance, Quad_Adjusted_lme_logPM_by_logElevation, ...
    Quad_Adjusted_lme_logPM_by_logAngleNDistance, Quad_Adjusted_lme_logPM_by_logAngleNElevation, Quad_Adjusted_lme_logPM_by_logDistanceNElevation, ...
    Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,outCsvFile)

[lme_test] = fit_PM_lme(quad_data_adjusted,[OutFile '_test_' task], ResultsDir, saveLME, cmap, sorted_idx)


Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.CoefficientNames
Intercept=Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(1);
VAe=Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(2);
De=Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(3);
Ee=Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(4);
visualize_PM_VA_DS_EL(ResultsDir,OutFile,task,Intercept,VAe,De,Ee,VArange,Drange,Erange); 
logscale=1; % now on logscale
visualize_PM_VA_DS_EL(ResultsDir,[OutFile '_log'],task,Intercept,VAe,De,Ee,VArange,Drange,Erange,logscale); 


%% 
%%

% %% visualize perceptual magnification for example 0.5degree object at 150 m
% distance and 2.5degree elevation
VA=0.5;
D=150;
E=2.5; 
% estimated perceived VA using model for adjusted matching 
PM=evaluatePMbyVisualAngleDistanceElevation(Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)

perceivedVA=VA*PM;
distance_mm=500;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Adjusted_visualize_PM%.2f_%.1f_%0.f_%.1f.png',QuadBasename,PM,VA,D,E));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

% estimate moon PM
VA=0.5;
D=100*1000;
E=2.5; 
PM=evaluatePMbyVisualAngleDistanceElevation(Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
perceivedVA=VA*PM;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Adjusted_visualize_PM%.2f_%.1f_sky_%.1f.png',QuadBasename,PM,VA,E));

[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

E=40; 
PM=evaluatePMbyVisualAngleDistanceElevation(Quad_Adjusted_lme_logPM_by_logAngleNDistanceNElevation,VA,D,E)
perceivedVA=VA*PM;
saveFlag=1;
saveFilename=fullfile(ResultsDir, sprintf('%s_Adjusted_visualize_PM%.2f_%.1f_sky_%.1f.png',QuadBasename,PM,VA,E));
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);

%% close all
close all