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
QuadFile='AllQuadDataLong916.csv'
all_quad_data=readtable(QuadFile);
QuadBasename = [erase(QuadFile,'.csv')] ;

saveLME=1; % 1 save files; 0 don't save 
ResultsDir=fullfile(expDir,'Paper_Fig3_010126');

if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end


%% prepare data

% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task

ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  

colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'}
% transform quad distances from cm to meters
quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,all_quad_data.Disparity_VA_1,...
                       'VariableNames',colNames);

%%
uniqueID=unique(quad_subset_data.ID);
nsubjects=length(uniqueID);
cmap=jet(nsubjects);

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

for c=1:length(uniqueID)
        cindex=find(uniqueID==all_data_perceptual.ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
end

%

%%
% calculate and plot the results of Experiment 1 Quad matching experiment

task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification
Perceptual_tblName=[QuadBasename '_' task];
Quad_PM_by_task(all_data_perceptual,Perceptual_tblName,ResultsDir,saveLME,cmap, sorted_idx)
orientation='vertical';
visualize_PM_VA_DS_EL(expDir,DataDir,QuadFile,task,saveLME,orientation,ResultsDir)


%% visualize perceptual magnification for example 0.5degree object at 150 m
% distance and 2.5degree elevation

VA=0.5;
D=150;
E=2.5;
% estimate perceieved visual angle using  model for perceptual matching 
perceivedVA=VA*0.42*VA^-0.08*D^0.37*(1+E)^0.12;
distance_mm=500;
saveFlag=1
saveFilename=fullfile(ResultsDir, [QuadBasename '_Perceptual_visualize_PM_0.5_150_2.5.png']);
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename)


%%
% calculate and plot the results of Experiment 2 Quad adjusted matching experiment

task='Adjusted';
Adjusted_tblName=[QuadBasename '_' task];
recomputeSort=1; % use the same participant color as perceptual matching task
Quad_PM_by_task(all_data_adjusted,Adjusted_tblName,ResultsDir,saveLME,cmap, sorted_idx)

% visualize perceptual magnification
orientation='vertical';
visualize_PM_VA_DS_EL(expDir,DataDir,QuadFile,task,saveLME,orientation,ResultsDir)

%% visualize perceptual magnification for example 0.5degree object at 150 m
% distance and 2.5degree elevation
VA=0.5;
D=150;
E=2.5; 
% estimated perceived VA using model for adjusted matching 
perceivedVA=VA*0.53*VA^-0.07*D^0.14*(1+E)^0.17;
distance_mm=500;
saveFlag=1;
saveFilename=fullfile(ResultsDir, [QuadBasename '_Adjusted_visualize_PM_0.5_150_2.5.png']);
[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename);
