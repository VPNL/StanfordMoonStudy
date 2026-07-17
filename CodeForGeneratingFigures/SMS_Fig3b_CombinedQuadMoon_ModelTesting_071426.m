% SMS_Fig3b_CombinedQuadMoon_ModelTesting_070326
close all;  clear all;
SMS_setCodePath;
set(groot, 'defaultFigureVisible', 'on');

%% Paths & parameters

% set dirs
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
combinedDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/Combined/';

ResultsDir=fullfile(expDir,'Figures','Fig3b');
if ~exist(ResultsDir,'dir')
   mkdir(ResultsDir)
end

saveLME= 1;
elevationTransform = 2 ;% 2 = absElevation
ObserverFlag=1;
nIterations  = 100;
QuadFraction = 0.8;
runLatentDmoonModel = 1;
latentDmoonOptions = struct( ...
    'DistanceMode', 'byDate', ...
    'DistanceGroupVariable', 'Date', ...
    'MinimumDistanceFactor', 10, ...
    'MaxIter', 25, ...
    'MaxFunEvals', 80, ...
    'Display', 'off');
latentMoonDResultsDir = fullfile(ResultsDir, 'latentMoonD');
if runLatentDmoonModel && ~exist(latentMoonDResultsDir, 'dir')
   mkdir(latentMoonDResultsDir)
end

%% load the data

MoonExpDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';
MoonFile='Perceptual_FullMoonDataProcessed090225.csv';

all_moon_data=readtable(fullfile(MoonExpDir,MoonFile));
MoonBasename = [erase(MoonFile,'.csv')] ;

% moon study
colNames=   {'ID','Date','Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'}
% transform moon distances from km to meters
all_moon_data.Distance=1000*all_moon_data.Distance;
meanMoonDistance=mean(all_moon_data.Distance);

moon_data_perceptual=table(all_moon_data.ID, string(all_moon_data.Date), all_moon_data.Real_Visual_Angle,all_moon_data.Distance,all_moon_data.Elevation,...
                       all_moon_data.Task, all_moon_data.Reported_Visual_Angle, all_moon_data.Ratio_Visual_Angle,...
                      'VariableNames',colNames);
hh=height(moon_data_perceptual);
for h=1:hh
    moon_data_perceptual.Study(h)={'MoonStudy'};
end


% quad study
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

% Tasks: must match the labels returned/used by splitTablebyTask
task = 'Perceptual';

paramsToPlot = {'Real_Visual_Angle','Distance','Elevation'};
minNID = 25; % minimal number of IDs 
allErrorSummaryTbl = table();
ThreeFactorLMEStore = struct();

[all_quad_data, transformInfo] = apply_quad_elevation_transform(all_quad_data, elevationTransform);
[all_quad_data, quadSingletonTbl] = Quad_remove_singleton_conditions(all_quad_data, paramsToPlot);
sfx = char(transformInfo.sfx);
if ~isempty(quadSingletonTbl)
    singletonFile = fullfile(ResultsDir, sprintf('%s_removed_singleton_conditions_%s.csv', QuadBasename, sfx));
    writetable(quadSingletonTbl, singletonFile);
end

quad_data_perceptual=table(all_quad_data.ID,string(all_quad_data.Date),all_quad_data.Real_Visual_Angle,all_quad_data.Distance, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);
hh=height(quad_data_perceptual);
for h=1:hh
    quad_data_perceptual.Study(h)={'QuadStudy'};
end

quad_subset_data = quad_data_perceptual;
[moon_subset_data, ~] = apply_quad_elevation_transform(moon_data_perceptual, elevationTransform);
combinedBasename=['combined_' MoonBasename '_' QuadBasename];


%%
fprintf('Transform %d (%s)\n', elevationTransform, sfx);
fprintf('Quad elevation range: %.2f to %.2f\n', min(quad_data_perceptual.Elevation), max(quad_subset_data.Elevation));
fprintf('Moon elevation range: %.2f to %.2f\n', min(moon_subset_data.Elevation), max(moon_subset_data.Elevation));

% Storage struct (one field per task)
R = struct();
R.all_testing_Tbl   = [];
R.all_training_Tbl  = [];
R.all_summarylmeTbl = [];
R.threeFactorLMEs   = cell(nIterations,1);
R.latentDmoonLMEs = cell(nIterations,1);
R.latentDmoonSummaryTbl = table();
R.latentDmoonGroupTbl = table();


%% Balance moon training fraction to reduce over-representation in dense conditions
VAs = unique(quad_subset_data.Real_Visual_Angle);
subjPerVA = nan(numel(VAs),1);
for d = 1:numel(VAs)
    jj = quad_subset_data.Real_Visual_Angle == VAs(d);
    subjPerVA(d) = numel(unique(quad_subset_data.ID(jj)));
end
meansubjVA = round(mean(subjPerVA));

Elevations = unique(quad_subset_data.Elevation);
subjPerE = nan(numel(Elevations),1);
for d = 1:numel(Elevations)
    jj = quad_subset_data.Elevation == Elevations(d);
    subjPerE(d) = numel(unique(quad_subset_data.ID(jj)));
end
meansubjE = round(mean(subjPerE));

Distances = unique(quad_subset_data.Distance);
subjPerDistance = nan(numel(Distances),1);
for d = 1:numel(Distances)
    jj = quad_subset_data.Distance == Distances(d);
    subjPerDistance(d) = numel(unique(quad_subset_data.ID(jj)));
end
meansubjDistance = round(mean(subjPerDistance));

meansubPerCond = max([meansubjVA meansubjE meansubjDistance]);
nIDmoon = numel(unique(moon_subset_data.ID));
moontrainingFraction = meansubPerCond / nIDmoon;
moontrainingFraction = max(0, min(1, moontrainingFraction));

%% Model fitting and testing across random subsets of the data separately per tasks
for itr = 1:nIterations
    [quad_training, quad_testing] = splitTablebyRandomIDs(quad_subset_data, QuadFraction);
    [moon_training, moon_testing] = splitTablebyRandomIDs(moon_subset_data, moontrainingFraction);

    combined_training_data = [quad_training; moon_training];
    combined_testing_data  = [quad_testing;  moon_testing];

    trainTbl =  combined_training_data;
    testTbl  = combined_testing_data;



    [lme_logAngle,lme_logDistance,lme_logElevation,...
     lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation,...
     lme_logAngleNDistanceNElevation] = PM_lmes(trainTbl, sprintf('combined_training_%s_I%d', sfx, itr));

    R.threeFactorLMEs{itr} = lme_logAngleNDistanceNElevation;

    summaryTbl = Quad_export_LME_summary_csv('combined_training', task, ...
                 lme_logAngle,lme_logDistance,lme_logElevation,...
                 lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation,...
                 lme_logAngleNDistanceNElevation);

    summaryTbl.Iteration = repmat(double(itr), height(summaryTbl), 1);
    summaryTbl.TransformID = repmat(double(elevationTransform), height(summaryTbl), 1);
    summaryTbl.TransformLabel = repmat(string(transformInfo.sfx), height(summaryTbl), 1);
    R.all_summarylmeTbl = [R.all_summarylmeTbl; summaryTbl];

    outTbl = estimate_PM_fromlmeTbl(testTbl, summaryTbl);

    if runLatentDmoonModel
        latentFitName = sprintf('combined_training_latentDmoon_%s_I%d', sfx, itr);
        [latentOutTbl, latentSummaryTbl, latentFitInfo] = ...
            PM_lme_latentDmoon(trainTbl, testTbl, latentFitName, latentDmoonOptions);

        latentSummaryTbl.Iteration = repmat(double(itr), height(latentSummaryTbl), 1);
        latentSummaryTbl.TransformID = repmat(double(elevationTransform), height(latentSummaryTbl), 1);
        latentSummaryTbl.TransformLabel = repmat(string(transformInfo.sfx), height(latentSummaryTbl), 1);
        R.latentDmoonSummaryTbl = [R.latentDmoonSummaryTbl; latentSummaryTbl];
        R.latentDmoonLMEs{itr} = latentFitInfo.lme;

        latentGroupTbl = latentFitInfo.DmoonByGroup;
        latentGroupTbl.Iteration = repmat(double(itr), height(latentGroupTbl), 1);
        latentGroupTbl.TransformID = repmat(double(elevationTransform), height(latentGroupTbl), 1);
        latentGroupTbl.TransformLabel = repmat(string(transformInfo.sfx), height(latentGroupTbl), 1);
        R.latentDmoonGroupTbl = [R.latentDmoonGroupTbl; latentGroupTbl];

        latentPredCol = latentFitInfo.PredictionColumnName;
        outTbl.(latentPredCol) = latentOutTbl.(latentPredCol);
        outTbl.latentDmoon_m = latentOutTbl.latentDmoon_m;
        outTbl.latentDmoon_log2_m = latentOutTbl.latentDmoon_log2_m;
        outTbl.latentDmoon_group = latentOutTbl.latentDmoon_group;
    end

    outTbl.Iteration = repmat(double(itr), height(outTbl), 1);
    outTbl.TransformID = repmat(double(elevationTransform), height(outTbl), 1);
    outTbl.TransformLabel = repmat(string(transformInfo.sfx), height(outTbl), 1);
    R.all_testing_Tbl = [R.all_testing_Tbl; outTbl];

    trainTbl.Iteration = repmat(double(itr), height(trainTbl), 1);
    trainTbl.TransformID = repmat(double(elevationTransform), height(trainTbl), 1);
    trainTbl.TransformLabel = repmat(string(transformInfo.sfx), height(trainTbl), 1);
    R.all_training_Tbl = [R.all_training_Tbl; trainTbl];

end

%% Save results and generate figures

training_Tblname = sprintf('%s_training_%diterations_lme_summary_combined_training_%s_%s', ...
    task, nIterations, combinedBasename, sfx);
writetable(R.all_training_Tbl, fullfile(ResultsDir, [training_Tblname '.csv']));

testing_Tblname = sprintf('%s_testing_%diterations_lme_summary_combined_training_%s_%s', ...
    task, nIterations, combinedBasename, sfx);
writetable(R.all_testing_Tbl, fullfile(ResultsDir, [testing_Tblname '.csv']));

Tblname = sprintf('%s_%diterations_lme_summary_combined_training_%s_%s', ...
    task, nIterations, combinedBasename, sfx);

outFigName = fullfile(ResultsDir, [Tblname '.png']);
coefVars = {'Intercept','VAe' 'De','Ee'};
plotCoefVars = {'Intercept', 'VAe', 'De','Ee'};
[outTbl, fh] = PM_plot_meanLMEcoeffs(R.all_summarylmeTbl, Tblname, outFigName);
writetable(outTbl, fullfile(ResultsDir, ['mean_' Tblname '.csv']));

coefVars = {'Intercept','VAe' 'De','Ee'};
plotCoefVars = {'VAe', 'De','Ee'};
outFigNameNoI = fullfile(ResultsDir, [Tblname '_noIntercepts.png']);
[~, fh] = PM_plot_meanLMEcoeffs(R.all_summarylmeTbl, Tblname, outFigNameNoI, coefVars, plotCoefVars);


transformErrorTbl = summarize_model_prediction_error( ...
    R.all_testing_Tbl, ...
    'predicted_PM_logPM_by_logAngleNDistanceNElevation', ...
    task, elevationTransform, string(transformInfo.sfx));
transformErrorTbl.Model = repmat("LME_3factor", height(transformErrorTbl), 1);
transformErrorTbl = movevars(transformErrorTbl, 'Model', 'After', 'TransformLabel');
writetable(transformErrorTbl, fullfile(ResultsDir, sprintf('%s_%diterations_prediction_error_%s.csv', lower(task), nIterations, sfx)));
allErrorSummaryTbl = [allErrorSummaryTbl; transformErrorTbl];

threeFactorFigName = sprintf('%s_%dminNID_3factor', task, minNID);
threeFactorPlotFile = fullfile(ResultsDir, sprintf('%s_%diterations_3factor_%s.png', ...
    task, nIterations, combinedBasename));
[~, fh_threeFactorByParam] = plot_MeanPredictedvsReportedPM_byParams_1model( ...
    R.all_testing_Tbl, ...
    'predicted_PM_logPM_by_logAngleNDistanceNElevation', ...
    paramsToPlot, minNID, threeFactorPlotFile, threeFactorFigName, 'sd', 'Combined');
fprintf('3-factor by-parameter plot: %s\n', threeFactorPlotFile);



% supplemental figure comparing 1, 2 , 3 factor mdoels
figName  = sprintf('%s_%dminNID', task, minNID);
for p = 1:numel(paramsToPlot)
    Param = paramsToPlot{p};
    saveFilename = fullfile(ResultsDir, sprintf('%s_%diterations_%s_combined_%s.png', ...
        figName, nIterations, Param, combinedBasename));
    [SummaryItrParam, ~, ~, ~, fh, fh_violin, ~, ~, fh_pctbar] = ...
        plot_MeanPredictedvsReportedPMbyParamwithMpERR_3models(R.all_testing_Tbl, Param, minNID, saveFilename, figName, 'sd','Combined');
    checkbinning(SummaryItrParam,Param,minNID)
end

if runLatentDmoonModel
    latentDmoonSummaryCsv = fullfile(latentMoonDResultsDir, sprintf('%s_%diterations_latentDmoon_lme_summary_combined_training_%s_%s.csv', ...
        task, nIterations, combinedBasename, sfx));
    writetable(R.latentDmoonSummaryTbl, latentDmoonSummaryCsv);
    if ~isempty(R.latentDmoonGroupTbl)
        latentDmoonGroupCsv = fullfile(latentMoonDResultsDir, sprintf('%s_%diterations_latentDmoon_byGroup_combined_training_%s_%s.csv', ...
            task, nIterations, combinedBasename, sfx));
        writetable(R.latentDmoonGroupTbl, latentDmoonGroupCsv);
    end

    latentErrorTbl = summarize_model_prediction_error( ...
        R.all_testing_Tbl, ...
        'predicted_PM_latentDmoon_logPM_by_logAngleNDistanceNElevation', ...
        task, elevationTransform, string(transformInfo.sfx));
    latentErrorTbl.Model = repmat("latentDmoon_LME_3factor", height(latentErrorTbl), 1);
    latentErrorTbl = movevars(latentErrorTbl, 'Model', 'After', 'TransformLabel');
    writetable(latentErrorTbl, fullfile(latentMoonDResultsDir, sprintf('%s_%diterations_latentDmoon_prediction_error_%s.csv', lower(task), nIterations, sfx)));
    allErrorSummaryTbl = [allErrorSummaryTbl; latentErrorTbl];

    latentFigName = sprintf('%s_%dminNID_latentDmoon_%s', task, minNID, sfx);
    latentPlotFile = fullfile(latentMoonDResultsDir, sprintf('%s_%diterations_latentDmoon_byParams_%s_%s.png', ...
        task, nIterations, combinedBasename, sfx));
    [~, fh_latent] = plot_MeanPredictedvsReportedPM_byParams_1model( ...
        R.all_testing_Tbl, ...
        'predicted_PM_latentDmoon_logPM_by_logAngleNDistanceNElevation', ...
        paramsToPlot, minNID, latentPlotFile, latentFigName, 'sd', 'Combined');
    fprintf('Latent Dmoon by-parameter plot: %s\n', latentPlotFile);
    if ~isempty(fh_latent); close(fh_latent); end

    latentReportOpts = struct();
    latentReportOpts.GeneratedBy = 'SMS_Fig3b_CombinedQuadMoon_ModelTesting_070326';
    latentReportOpts.SourceCSV = sprintf('Moon: %s; Quad: %s', fullfile(MoonExpDir, MoonFile), fullfile(QuadExpDir, QuadFile));
    latentReportOpts.FigureLabel = latentFigName;
    latentReportOpts.Notes = sprintf('Mean moon distance from source data = %.6g m; Dmoon was fitted by Date with Dmoon > %.1f * max quad distance.', meanMoonDistance, latentDmoonOptions.MinimumDistanceFactor);
    latentReportOpts.GroupTbl = R.latentDmoonGroupTbl;
    latentReportFile = fullfile(latentMoonDResultsDir, sprintf('%s_%diterations_latentDmoon_model_report_%s.txt', lower(task), nIterations, sfx));
    write_latentDmoon_model_report(R.latentDmoonSummaryTbl, latentReportFile, latentReportOpts);
end





saveFilename = fullfile(ResultsDir, sprintf('%diterations_combined_%s_%s.mat', ...
             nIterations, combinedBasename, sfx));

allErrorSummaryCsv = fullfile(ResultsDir, sprintf('%diterations_prediction_error_by_transform_combined_%s.csv', nIterations, combinedBasename));
writetable(allErrorSummaryTbl, allErrorSummaryCsv);


saveFilename = fullfile(ResultsDir, sprintf('%diterations_threeFactorLMEs_allTransforms_combined_%s.mat', nIterations, combinedBasename));
save(saveFilename);

close all;
