% SMS_supplemental_FigS4_forFig2c_QuadlogPMvsS_VA_D_E_091726.m

close all; clear all;

SMS_setCodePath;
% set dirs & files
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';


ResultsDir=fullfile(expDir, 'Figures','SupFig4_forFig2c_logPMvs_logS_D_VA');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

Quadfile='Perceptual_StanfordQuadStudyDataProcessed0420.csv';
QuadBasename = [erase(Quadfile,'.csv')]

ObserverFlag=1; % all distances and elevations relative to observer
degreeFlag=1;
saveLME=1; % 1 save files; 0 don't save

%%  read data and plot experiment parameter range

task='Perceptual';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification

% use ground truth table to get the Size data for each object; these sizes are in meters
all_quad_data = add_diameter_height(fullfile(dataDir,Quadfile), fullfile(dataDir,[QuadBasename '_wSize.csv' ])); 

all_quad_data=all_quad_data(all_quad_data.ID~=26,:); % remove participant who did not follow instructions

if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance/100; % transform distances from cm to m
    all_quad_data.Width=all_quad_data.Width/100; % transform distances from cm to m
else
    all_quad_data.Elevation=all_quad_data.Ground_Elevation;
    all_quad_data.Distance=all_quad_data.Ground_Distance/100; % transform distances from cm to m
    all_quad_data.Width=all_quad_data.Width/100;
end


plot_S_D_VA_parameters(all_quad_data,['SupFig_' QuadBasename '_ExperimentalParams'],ResultsDir); % this is Supplemental Fig S2.
%%
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

%% run lme model relating log PM to log each of the factors: VA, D, S

[lme_logPM_by_logSize,lme_logPM_by_logDistance,lme_logPM_by_logVA,...
    lme_logPM_by_logSizeNDistance, lme_logPM_by_logSizeNVA,lme_logPM_by_logVANDistance,...
    lme_logPM_by_logSizeNDistanceNVA]=Quad_PM_by_task_S_VA_D(all_data_perceptual,QuadBasename,ResultsDir,saveLME,colormap, sorted_idx)


close all
