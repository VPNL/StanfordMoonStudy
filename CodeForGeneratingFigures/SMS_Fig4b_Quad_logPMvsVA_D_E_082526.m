% SMS_Fig4c_Quad_logPMvsVA_D_E_082526

close all; clear all;
SMS_setCodePath;
% set dirs
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';

QuadFile='MatchingProcessedData0421.csv';
QuadBasename = [erase(QuadFile,'.csv')]

% set dirs & files
ResultsDir=fullfile(expDir, 'Figures','Fig4b');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end
visualizeDir = fullfile(ResultsDir,'VisualizePM');
if ~exist(visualizeDir,'dir')
        mkdir(visualizeDir)
end

ObserverFlag=1; % all distances and elevations relative to observer
degreeFlag=1;
saveLME=1; % 1 save files; 0 don't save

%%  read data and plot experiment parameter range

all_quad_data=readtable(fullfile(dataDir,QuadFile));
all_quad_data=all_quad_data(all_quad_data.ID~=26,:); % remove participant who did not follow instructions
if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance/100; % transform distances from cm to m
else
    all_quad_data.Elevation=all_quad_data.Ground_Elevation;
    all_quad_data.Distance=all_quad_data.Ground_Distance/100; % transform distances from cm to m
end
uniqueID=unique(all_quad_data.ID);
nsubjects=length(uniqueID);

%% extract only the Adjusted data

task='Adjusted';
task_i=find(strcmp(all_quad_data.Task,task));
all_data_adjusted=all_quad_data(task_i,:);



plot_VA_D_E_parameters(all_data_adjusted,['SupFig_' task '_' QuadBasename '_ExperimentalParams'],ResultsDir); % this is Supplemental Fig S2.

recomputeSort=0; % sort subject colors by perceptual magnification in perceptual task
if recomputeSort
    % generate sorted subject list by mean PM
     meanPM=zeros(1,nsubjects);
    for i=1:nsubjects
        idx=find(all_data_adjusted.ID==uniqueID(i));
        meanPM(i)=mean(all_data_adjusted.Ratio_Visual_Angle(idx));
    end
    [~, sorted_idx] = sort(meanPM);   
     savefile=fullfile(ResultsDir, [QuadBasename  '_sortedidx']);
     save(savefile ,sorted_idx);
else
    % load sorted index from perceptual task
    loadfile=fullfile(expDir, 'Figures','Fig2c', 'Perceptual_StanfordQuadStudyDataProcessed0420_sortedidx');
    load(loadfile);
end

cmap=brighten(colormap(plasma(nsubjects*1.1)),0);

%% run lme model relating log PM to log each of the factors: VA, D, E
elevationTransform=2; % 1+abs(elevation);
[lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
                lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
                lme_logPM_by_logAngleNDistanceNElevation] = ...
                Quad_PM_by_task(all_data_adjusted, [task '_' QuadBasename], ResultsDir, saveLME, cmap, sorted_idx, elevationTransform);


lme_full = fit_PM_full_VA_D_E_model(all_data_adjusted, [task '_' QuadBasename '_fullmodel_fit'], ResultsDir, saveLME, cmap, sorted_idx, elevationTransform);
 


outCsvFile=fullfile(ResultsDir, [task '_' QuadBasename '_lme_summary.csv']);
Quad_export_LME_summary_csv(QuadBasename, task, ...
            lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
            lme_logPM_by_logAngleNDistanceNElevation, outCsvFile);

VAmax = 8;
distance_mm = 500;
FigName = [task '_' QuadBasename];
visualize_real_perceived_predicted(all_data_adjusted, lme_logPM_by_logAngleNDistanceNElevation, ...
    visualizeDir, FigName, VAmax, distance_mm, elevationTransform);

% compare model parameters across tasks
OutName = [ 'SupFig_PM_full_VA_D_E_modelbytask_' QuadBasename];
[lme, interactionStats, modelComparison] = fit_PM_full_VA_D_E_modelbytask( ...
    all_quad_data,  OutName, ResultsDir, 1,cmap, sorted_idx,  elevationTransform);

close all
