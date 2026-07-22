% Paper2_angle_distance_elevation_MergedMatchingStereo042926

clx;
set(groot,'defaultFigureVisible','on');

codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir))

expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
DataDir=fullfile(expDir,'Data');
cd(DataDir)

QuadFile='merged_matching_0429_x7001.csv';

QuadBasenameBase = erase(QuadFile,'.csv');
all_quad_data_base=readtable(QuadFile);
StereoThres=85;
stereoScoreVar = quadFindFirstTableVariable(all_quad_data_base, {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});

colorConfigs = { ...
    struct('metric', 'normed', ...
    'resultsRoot', '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/Paper2Figures/MatchingColorbyStereoScore/'), ...
    struct('metric', 'clinicalnotes', ...
    'resultsRoot', '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/Paper2Figures/MatchingColorbyClinicalNotes/') ...
    };

runConfigs = { ...
    struct('resultsSubdir', 'All', 'basenameSuffix', '', ...
    'justStereoDeficient', false, 'justStereoTypical', false), ...
    struct('resultsSubdir', ['StereoDeficient' num2str(StereoThres)], ...
    'basenameSuffix', ['_justStereoDeficient_' num2str(StereoThres)], ...
    'justStereoDeficient', true, 'justStereoTypical', false), ...
    struct('resultsSubdir', ['StereoTypical' num2str(StereoThres)], ...
    'basenameSuffix', ['_justStereoTypical_' num2str(StereoThres)], ...
    'justStereoDeficient', false, 'justStereoTypical', true) ...
    };


ObserverFlag=1;
degreeFlag=1;
saveLME=1;
participantColorFlag=1;

for colorConfigIdx = 1:numel(colorConfigs)
    colorCfg = colorConfigs{colorConfigIdx};
    sort_metric = colorCfg.metric;
    resultsRoot = colorCfg.resultsRoot;
    fprintf('Coloring participants by %s (%d of %d).\n', ...
        sort_metric, colorConfigIdx, numel(colorConfigs));

    for runIdx = 1:numel(runConfigs)
    cfg = runConfigs{runIdx};
    all_quad_data = all_quad_data_base;
    QuadBasename = [QuadBasenameBase cfg.basenameSuffix];
    justStereoDeficient = cfg.justStereoDeficient;
    justStereoTypical = cfg.justStereoTypical;
    ResultsDir=fullfile(resultsRoot, cfg.resultsSubdir);
    if ~exist(ResultsDir,'dir')
       mkdir(ResultsDir)
    end

    fprintf('Running %s (%d of %d): %s\n', cfg.resultsSubdir, runIdx, numel(runConfigs), QuadBasename);

    if justStereoDeficient
        jj=find(all_quad_data.(stereoScoreVar)<StereoThres);
        all_quad_data=all_quad_data(jj,:);
    elseif justStereoTypical
        jj=find(all_quad_data.(stereoScoreVar)>=StereoThres);
        all_quad_data=all_quad_data(jj,:);
    end

    fprintf('  Using %d rows from %d participants.\n', height(all_quad_data), numel(unique(all_quad_data.ID)));



%%
if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance;
else
    all_quad_data.Elevation=all_quad_data.Ground_Elevation;
    all_quad_data.Distance=all_quad_data.Ground_Distance;
end



colNames=   {'ID','Measurement', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'};

quad_subset_data=table(all_quad_data.ID, all_quad_data.Measurement, all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);

%plot_VA_D_E_parameters(quad_subset_data,[QuadBasename '_ExperimentalParams'],ResultsDir);

uniqueID=unique(quad_subset_data.ID);
nsubjects=length(uniqueID);

%%
[pairedTbl, lmeRI, lmeRS, cmpTbl] = PerceptualVsAdjusted_ReportedVisualAngle( ...
    all_quad_data, QuadBasename, ResultsDir, sort_metric);

all_data_perceptual=quad_subset_data(strcmp(quad_subset_data.Task,'Perceptual'),:);
all_data_adjusted=quad_subset_data(strcmp(quad_subset_data.Task,'Adjusted'),:);

if participantColorFlag
    recomputeColorIndex = 1;
    if strcmpi(sort_metric, 'clinicalnotes')
        [sorted_idx, clinical_category_by_id, uniqueID, cmap] = ...
            Quad_compute_clinical_notes_color_idx(all_quad_data, ResultsDir, QuadBasename, recomputeColorIndex);
    else
        [sorted_idx, mean_stereo_by_id, uniqueID, cmap] = ...
            Quad_compute_mean_stereo_color_idx(all_quad_data, ResultsDir, QuadBasename, recomputeColorIndex, sort_metric);
    end
else
    meanPM=zeros(1,nsubjects);
    for i=1:nsubjects
        idx=find(all_data_perceptual.ID==uniqueID(i));
        meanPM(i)=mean(all_data_perceptual.Ratio_Visual_Angle(idx));
    end
    [~, sorted_idx] = sort(meanPM);
    cmap=brighten(colormap(plasma(nsubjects*1.1)),0);
end

taskOrder = {'Perceptual','Adjusted'};
taskData = struct('Perceptual', all_data_perceptual, 'Adjusted', all_data_adjusted);
baseResultsDir = ResultsDir;
% Elevation transform
% 1 = Elevation
% 2 = absElevation
% 3 = ElevationRAD
% 4 = absElevationRAD
% 5 = ElevationD90
% 6 = absElevationD90
transformList = [2];
criteriaRows = {};
lmeStore = struct('Perceptual', struct(), 'Adjusted', struct());
threeFactorLME = struct('Perceptual', [], 'Adjusted', []);
singleRSLME = struct( ...
    'Perceptual', struct('Angle', [], 'Distance', [], 'Elevation', []), ...
    'Adjusted', struct('Angle', [], 'Distance', [], 'Elevation', []));

for transformId = transformList
    [sfx, runMode, modelTransform] = get_quad_transform_spec(transformId);
    ResultsDir = fullfile(baseResultsDir, sfx);
    if ~exist(ResultsDir,'dir')
        mkdir(ResultsDir)
    end
    visualizeDir = fullfile(ResultsDir,'VisualizePM');
    if ~exist(visualizeDir,'dir')
        mkdir(visualizeDir)
    end

    for t = 1:numel(taskOrder)
        task = taskOrder{t};
        tbl = taskData.(task);
        tblName = [QuadBasename '_' task '_' sfx];

        if strcmp(runMode, 'rad')
              [lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logAngle_RS, lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS] = ...
            Quad_PM_by_task_rad_single(tbl, tblName, ResultsDir, saveLME, cmap, sorted_idx, modelTransform)
            quadCloseFigures();

            [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
                lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
                lme_logPM_by_logAngleNDistanceNElevation] = ...
                Quad_PM_by_task_rad(tbl, tblName, ResultsDir, saveLME, cmap, sorted_idx, modelTransform, degreeFlag);
            quadCloseFigures();

            lme_full = fit_PM_full_VA_D_Erad_model(tbl, [tblName '_fullmodel_fit'], ResultsDir, saveLME, cmap, sorted_idx, modelTransform, degreeFlag);
            quadCloseFigures();
        else
              [lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
                lme_logPM_by_logAngle_RS, lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS] = ...
                 Quad_PM_by_task_single(tbl, tblName, ResultsDir, saveLME, cmap, sorted_idx, modelTransform)
            quadCloseFigures();

            [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
                lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
                lme_logPM_by_logAngleNDistanceNElevation] = ...
                Quad_PM_by_task(tbl, tblName, ResultsDir, saveLME, cmap, sorted_idx, modelTransform);
            quadCloseFigures();
                lme_full = fit_PM_full_VA_D_E_model(tbl, [tblName '_fullmodel_fit'], ResultsDir, saveLME, cmap, sorted_idx, modelTransform);
            quadCloseFigures();
        end

        outCsvFile=fullfile(ResultsDir, [tblName '_lme_summary.csv']);
        Quad_export_LME_summary_csv(QuadBasename, task, ...
            lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
            lme_logPM_by_logAngleNDistanceNElevation, outCsvFile);

        stereoTblTask = all_quad_data(strcmp(all_quad_data.Task, task), :);
        Quad_PM_intercepts_by_stereoscore(stereoTblTask, lme_logPM_by_logAngleNDistanceNElevation, ...
            tblName, ResultsDir);
        quadCloseFigures();
        threeFactorLME.(task) = lme_logPM_by_logAngleNDistanceNElevation;
        singleRSLME.(task).Angle = lme_logPM_by_logAngle_RS;
        singleRSLME.(task).Distance = lme_logPM_by_logDistance_RS;
        singleRSLME.(task).Elevation = lme_logPM_by_logElevation_RS;

        % VAmax = 8;
        % distance_mm = 500;
        % FigName = tblName;
        % % visualize_real_perceived_predicted(tbl, lme_logPM_by_logAngleNDistanceNElevation, ...
        % %     visualizeDir, FigName, VAmax, distance_mm, transformId);
        % quadCloseFigures();

        lmeStore.(task).(sfx) = lme_full;
        criteriaRows(end+1,:) = {string(task), string(sfx), lme_full.ModelCriterion.AIC, lme_full.ModelCriterion.BIC}; %#ok<AGROW>
        clear lme_logPM_by_logAngle lme_logPM_by_logDistance lme_logPM_by_logElevation
        clear lme_logPM_by_logAngle_RS lme_logPM_by_logDistance_RS lme_logPM_by_logElevation_RS
        clear lme_logPM_by_logAngleNDistance lme_logPM_by_logAngleNElevation lme_logPM_by_logDistanceNElevation
        clear lme_logPM_by_logAngleNDistanceNElevation lme_full outCsvFile VAmax distance_mm FigName
    end
end
availableTransforms = numel(transformList);
saveresultsFile=fullfile(baseResultsDir, [QuadBasename '_threefactor_transform_comparison.mat']);

if availableTransforms >= 2
    criteriaTbl = cell2table(criteriaRows, 'VariableNames', {'Task','TransformLabel','AIC','BIC'});
    writetable(criteriaTbl, fullfile(ResultsDir, [QuadBasename '_threefactor_model_criteria.csv']));

    fh = plot_lme_criterion_by_transform(criteriaTbl, 'AIC', fullfile(ResultsDir, [QuadBasename '_threefactor_AIC_by_transform.png']), ...
        sprintf('Quad 3-factor Model AIC (%s)', QuadBasename));
    if ~isempty(fh); close(fh); end
    quadCloseFigures();

    fh = plot_lme_criterion_by_transform(criteriaTbl, 'BIC', fullfile(ResultsDir, [QuadBasename '_threefactor_BIC_by_transform.png']), ...
        sprintf('Quad 3-factor Model BIC (%s)', QuadBasename));
    if ~isempty(fh); close(fh); end
    quadCloseFigures();


    compareTbl = compare_lmes_by_transform(lmeStore, taskOrder, ...
        availableTransforms, ...
        fullfile(ResultsDir, [QuadBasename '_threefactor_model_pairwise_comparisons.csv']));
      save(saveresultsFile, 'criteriaTbl', 'compareTbl', 'lmeStore');

end


%% compare model parameters acros tasks
% Quad_PM_intercept_StereoNotes
% compare the interscepts between the Perceptual and Adjusted models and
% write to csv organizing subjects by rank order:
%
if ~isempty(threeFactorLME.Perceptual) && ~isempty(threeFactorLME.Adjusted)
    setaxesLim = 1;
    val = [0 3.5];
    Quad_PM_intercept_StereoNotes(all_quad_data, threeFactorLME.Perceptual, ...
        threeFactorLME.Adjusted, QuadBasename, ResultsDir, setaxesLim, val);

    setaxesLim = 1;
    val = [0 2];
    Quad_PM_intercept_StereoNotes(all_quad_data, threeFactorLME.Perceptual, ...
        threeFactorLME.Adjusted, [QuadBasename '_v2'], ResultsDir, setaxesLim, val);
end

%  PM_compare_single_RS_across_tasks.m
if ~isempty(singleRSLME.Perceptual.Angle) && ~isempty(singleRSLME.Adjusted.Angle)
    setaxesLimRS = 1;
    valRS = [
        -0.6 0.0   % VA / Angle
        -0.2 0.6   % Distance
        -1.0 0.2   % Elevation
        ];
    PM_compare_single_RS_across_tasks(all_quad_data, ...
        singleRSLME.Perceptual.Angle, singleRSLME.Perceptual.Distance, singleRSLME.Perceptual.Elevation, ...
        singleRSLME.Adjusted.Angle, singleRSLME.Adjusted.Distance, singleRSLME.Adjusted.Elevation, ...
        QuadBasename, ResultsDir, setaxesLimRS, valRS);
end
allresultsfile=fullfile(resultsRoot, [QuadBasename '.mat']);
save(allresultsfile);
quadCloseFigures();
    end % run configurations
end % participant-color configurations

%%
quadFinalizeAnalysis();
