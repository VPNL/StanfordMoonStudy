% SMS_Fig2c_Quad_logPMvsVA_D_E

close all; clear all;
SMS_setCodePath;
% set dirs
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';
QuadFile='Perceptual_StanfordQuadStudyDataProcessed0420.csv';
QuadBasename = [erase(QuadFile,'.csv')]

% set dirs & files
ResultsDir=fullfile(expDir, 'Figures','Fig2c');
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

task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification

all_quad_data=readtable(fullfile(dataDir,QuadFile));

all_quad_data=all_quad_data(all_quad_data.ID~=26,:); % remove participant who did not follow instructions

if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance/100; % transform distances from cm to m
else
    all_quad_data.Elevation=all_quad_data.Ground_Elevation;
    all_quad_data.Distance=all_quad_data.Ground_Distance/100; % transform distances from cm to m
end


plot_VA_D_E_parameters(all_quad_data,['SupFig_' QuadBasename '_ExperimentalParams'],ResultsDir); % this is Supplemental Fig S2.

% generate sorted subject list by mean PM
uniqueID=unique(all_quad_data.ID);
nsubjects=length(uniqueID);
all_data_perceptual=all_quad_data;
meanPM=zeros(1,nsubjects);
for i=1:nsubjects
    idx=find(all_data_perceptual.ID==uniqueID(i));
    meanPM(i)=mean(all_data_perceptual.Ratio_Visual_Angle(idx));
end
[~, sorted_idx] = sort(meanPM);
cmap=brighten(colormap(plasma(nsubjects*1.1)),0);

elevationTransform=2;

%% run lme model relating log PM to log each of the factors: VA, D, E

[lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
                lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
                lme_logPM_by_logAngleNDistanceNElevation] = ...
                Quad_PM_by_task(all_data_perceptual, QuadBasename, ResultsDir, saveLME, cmap, sorted_idx, elevationTransform);

% to compare RI and RS single parameter models and plot with different object types
% with different markers can run additional code below
% [lme_logPM_by_logAngle_RI, lme_logPM_by_logDistance_RI, lme_logPM_by_logElevation_RI, ...
%     lme_logPM_by_logAngle_RS, lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS] = ...
%     Quad_PM_by_task_single(all_data_perceptual, QuadBasename, ResultsDir, saveLME, cmap, sorted_idx, elevationTransform, 1);


outCsvFile=fullfile(ResultsDir, [QuadBasename '_lme_summary.csv']);
Quad_export_LME_summary_csv(QuadBasename, task, ...
            lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
            lme_logPM_by_logAngleNDistanceNElevation, outCsvFile);

VAmax = 8;
distance_mm = 500;
FigName = QuadBasename;
visualize_real_perceived_predicted(all_data_perceptual, lme_logPM_by_logAngleNDistanceNElevation, ...
    visualizeDir, FigName, VAmax, distance_mm, elevationTransform);
close all
