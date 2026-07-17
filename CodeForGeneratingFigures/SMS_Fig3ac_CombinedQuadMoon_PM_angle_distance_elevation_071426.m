% Combine and fit data across both experiments
% SMS_Fig3ac_CombinedQuadMoon_PM_angle_distance_elevation_071426
close all; clear all;
SMS_setCodePath;
% set dirs
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';

combinedDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/Combined/';
if ~exist('combinedDir','dir')
   mkdir(combinedDir)
end

ResultsDir=fullfile(expDir,'Figures','Fig3ac');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

visualizeDir = fullfile(ResultsDir,'VisualizeMoon');
if ~exist(visualizeDir,'dir')
    mkdir(visualizeDir)
end

ObserverFlag=1; %refer elevations and distances to observer line of sight otherwise use ground referred values
saveLME=1;      % 1 save files; 0 don't save
moonVisualizeVAmax=1;
moonVisualizeDistance_mm=500;
moonVisualizeSpecs = struct( ...
    'label', {'LowElevationBin','HighElevationBin'}, ...
    'date', {'8/7/25','10/17/24'}, ...
    'mode', {'lt','gt'}, ...
    'threshold', {4,39});

% full angle-distance-elevation models
% Elevation transform
% 1 = Elevation
% 2 = absElevation
% 3 = ElevationRAD
% 4 = absElevationRAD
% 5 = ElevationD90
% 6 = absElevationD90
task='Perceptual';
elevationTransform=2;

%%  generate combined and make all distances to meters
%  the moon data is in km and the quad data is in cm a

MoonExpDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';
MoonFile='Perceptual_FullMoonDataProcessed090225.csv';
all_moon_data=readtable(fullfile(MoonExpDir,MoonFile));
MoonBasename = [erase(MoonFile,'.csv')] ;

% moon study
colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'}
% transform moon distances from km to meters
all_moon_data.Distance=1000*all_moon_data.Distance;
moon_data_perceptual=table(all_moon_data.ID, all_moon_data.Real_Visual_Angle,all_moon_data.Distance,all_moon_data.Elevation,...
                       all_moon_data.Task, all_moon_data.Reported_Visual_Angle, all_moon_data.Ratio_Visual_Angle,...
                      'VariableNames',colNames);
hh=height(moon_data_perceptual);
for h=1:hh
    moon_data_perceptual.Study(h)={'MoonStudy'};
end


% Quad study
% set dirs

QuadExpDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';
QuadFile='Perceptual_StanfordQuadStudyDataProcessed0420.csv';
QuadBasename = [erase(QuadFile,'.csv')]

all_quad_data=readtable(fullfile(QuadExpDir,QuadFile));

if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance/100; % transform distances from cm to m
else
    all_quad_data.Elevation=all_quad_data.Ground_Elevation;
    all_quad_data.Distance=all_quad_data.Ground_Distance/100; % transform distances from cm to m
end


% remove subject 26 who is an outlier because did not follow the instructions
ii=find(all_quad_data.ID~=26);
all_quad_data=all_quad_data(ii,:);

quad_data_perceptual=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);
hh=height(quad_data_perceptual);
for h=1:hh
    quad_data_perceptual.Study(h)={'QuadStudy'};
end

%% organize combined data across moon and quad
combined_data=[moon_data_perceptual;quad_data_perceptual];
combined_basename=['combined_' MoonBasename '_' QuadBasename];
combinedfileName=fullfile(combinedDir,[combined_basename '.csv']);

writetable(combined_data,combinedfileName);
plot_VA_D_E_parameters(combined_data,combined_basename,ResultsDir);

% combined data
uniqueID=unique(combined_data.ID);
nsubjects=length(uniqueID);
cmap_combined=brighten(colormap(purpleVioletBlueTurquoiseColorMap(ceil(nsubjects*1.1))),0);

for i=1:nsubjects
    idx=find(combined_data.ID==uniqueID(i));
    meanPM(i)=mean(combined_data.Ratio_Visual_Angle(idx));
end

% sort subjects by PM
[sorted_PM, sorted_idx] = sort(meanPM);

for c=1:length(uniqueID)
        cindex=find(uniqueID==combined_data.ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap_combined(sorted_cindex,:);
end

taskData = struct('Perceptual', combined_data);
combinedLMEStore = struct();
%% model fittings
[sfx, runMode, modelTransform] = get_quad_transform_spec(elevationTransform);

% test all models: single, dual, and triple factor models; plot single
% factor fits
[lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
 lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
 lme_logPM_by_logAngleNDistanceNElevation] = ...
            Quad_PM_by_task(combined_data, combined_basename, ResultsDir, saveLME, cmap_combined, sorted_idx, elevationTransform);

% triple factor model plot fit by factor
lme_full = fit_PM_full_VA_D_E_model(combined_data, [combined_basename '_VA_D_E_model'], ResultsDir, saveLME, cmap_combined, sorted_idx, elevationTransform);

outCsvFile = fullfile(ResultsDir, [combined_basename '_lme_summary.csv']);
Quad_export_LME_summary_csv('combined_quad_moon', lower(task), ...
        lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
        lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
        lme_logPM_by_logAngleNDistanceNElevation, outCsvFile);

for specIdx = 1:numel(moonVisualizeSpecs)
        moonVizTbl = build_moon_visualization_tbl(all_moon_data, moonVisualizeSpecs(specIdx), task);
        if ~isempty(moonVizTbl)
            moonFigName = sprintf('%s_%s_moon_%s_%s', combined_basename, task, sfx, moonVisualizeSpecs(specIdx).label);
            visualize_real_perceived_predicted(moonVizTbl, lme_full, visualizeDir, ...
                moonFigName, moonVisualizeVAmax, moonVisualizeDistance_mm, modelTransform);
        end
end

combinedLMEStore.(task).(sfx) = lme_full;

saveFile=fullfile(ResultsDir, [combined_basename '.mat']);
save(saveFile, 'combinedLMEStore')


%% close all
close all