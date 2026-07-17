% SMS_Fig2de_Quadmodel_predictivity_071426.m
close all; clear all;
SMS_setCodePath;
% set dirs
expDir='/Users/kalanit/Projects/StanfordMoonStudy/';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';
QuadFile='Perceptual_StanfordQuadStudyDataProcessed0420.csv';
QuadBasename = [erase(QuadFile,'.csv')]

% set dirs & files


ResultsDir=fullfile(expDir, 'Figures','Fig2de');
if ~exist(ResultsDir,'dir')
   mkdir(ResultsDir)
end

SupResultsDir=fullfile(ResultsDir,'SupplementalFig')
if ~exist(SupResultsDir,'dir')
   mkdir(SupResultsDir)
end

ObserverFlag=1; % all distances and elevations relative to observer
degreeFlag=1;

saveLME=1; % 1 save files; 0 don't save
nIterations=100;
QuadFraction=.8;
ObserverFlag=1;
ElevationTransform=2; % abs(Elevation), used by PM_lmes as log2(Elevation + 1)
sfx = 'logAbsE';
recomputeSort=1; % sort subject colors by slopes of perceptual magnification
paramsToPlot = {'Real_Visual_Angle','Distance','Elevation'};
minNID = 25;
task='Perceptual';

%%  read data

all_quad_data=readtable(fullfile(dataDir,QuadFile));
all_quad_data=all_quad_data(all_quad_data.ID~=26,:); % remove participant who did not follow instructions

if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance/100; % transform distances from cm to m;
else
    all_quad_data.Elevation=all_quad_data.Ground_Elevation;
    all_quad_data.Distance=all_quad_data.Ground_Distance/100;
end

[all_data_perceptual, transformInfo] = apply_quad_elevation_transform(all_quad_data, ElevationTransform); % Apply the elevation transform
[all_data_perceptual, quadSingletonTbl] = Quad_remove_singleton_conditions(all_data_perceptual, paramsToPlot);
if ~isempty(quadSingletonTbl)
    singletonFile = fullfile(ResultsDir, sprintf('%s_removed_singleton_conditions_%s.csv', QuadBasename, sfx));
    writetable(quadSingletonTbl, singletonFile);
end

% generate sorted subject list by mean PM
uniqueID=unique(all_data_perceptual.ID);
nsubjects=length(uniqueID);
meanPM=zeros(1,nsubjects);
for i=1:nsubjects
    idx=find(all_data_perceptual.ID==uniqueID(i));
    meanPM(i)=mean(all_data_perceptual.Ratio_Visual_Angle(idx));
end
[~, sorted_idx] = sort(meanPM);
cmap=brighten(colormap(plasma(nsubjects*1.1)),0);

modelTransform=ElevationTransform; % this relates to the elevation model we will use which is log2(abs(Elevation) + 1)

allErrorSummaryTbl = table();
ThreeFactorLMEStore = struct();

S = struct();
S.(task).all_testing_Tbl = [];
S.(task).all_training_Tbl = [];
S.(task).all_summarylmeTbl = [];
S.(task).threeFactorLMEs = cell(nIterations, 1);

%% test model abililyt to predict PM in left out participants
 for itr=1:nIterations
        quad_training_name=sprintf('quad_training_I%d_%s', itr, char(transformInfo.sfx));
        [quad_training_data, quad_testing_data] = splitTablebyRandomIDs(all_data_perceptual, QuadFraction);
        trainTbl = quad_training_data;
        testTbl  = quad_testing_data;

        [lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
         lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
         lme_logPM_by_logAngleNDistanceNElevation] = PM_lmes(trainTbl, quad_training_name);

        S.(task).threeFactorLMEs{itr} = lme_logPM_by_logAngleNDistanceNElevation;

        summaryTbl = Quad_export_LME_summary_csv('quad_training', task, ...
            lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
            lme_logPM_by_logAngleNDistanceNElevation);

        summaryTbl.Iteration = repmat(double(itr), height(summaryTbl), 1);
        summaryTbl.TransformID = repmat(double(ElevationTransform), height(summaryTbl), 1);
        summaryTbl.TransformLabel = repmat(string(transformInfo.sfx), height(summaryTbl), 1);
        S.(task).all_summarylmeTbl = [S.(task).all_summarylmeTbl; summaryTbl];

        outTbl = estimate_PM_fromlmeTbl(testTbl, summaryTbl);
        outTbl.Iteration = repmat(double(itr), height(outTbl), 1);
        outTbl.TransformID = repmat(double(ElevationTransform), height(outTbl), 1);
        outTbl.TransformLabel = repmat(string(transformInfo.sfx), height(outTbl), 1);
        S.(task).all_testing_Tbl = [S.(task).all_testing_Tbl; outTbl];

        trainTbl.Iteration = repmat(double(itr), height(trainTbl), 1);
        trainTbl.TransformID = repmat(double(ElevationTransform), height(trainTbl), 1);
        trainTbl.TransformLabel = repmat(string(transformInfo.sfx), height(trainTbl), 1);
        S.(task).all_training_Tbl = [S.(task).all_training_Tbl; trainTbl];

    end

%% Save transform-specific results and figures

figName = 'Perceptual';
training_Tblname = sprintf('perceptual_training_%diterations_lme_summary_%s_%s', nIterations, QuadBasename, sfx);
testing_Tblname  = sprintf('perceptual_testing_%diterations_lme_summary_%s_%s',  nIterations, QuadBasename, sfx);
coeff_Tblname    = sprintf('Perceptual_%diterations_lme_summary_%s_%s',          nIterations, QuadBasename, sfx);
noInterceptFig   = [coeff_Tblname '_noIntercepts.png'];

writetable(S.(task).all_training_Tbl, fullfile(ResultsDir,[training_Tblname '.csv']));
writetable(S.(task).all_testing_Tbl,  fullfile(ResultsDir,[testing_Tblname  '.csv']));

outFigName = fullfile(ResultsDir, [coeff_Tblname '.png']);
coefVars = {'Intercept','VAe' 'De','Ee'};
plotCoefVars = {'Intercept', 'VAe', 'De','Ee'}; % plots all estimated coefficients: intercept+ exponents across iterations
[meanCoeffTbl, fh] = PM_plot_meanLMEcoeffs(S.(task).all_summarylmeTbl, coeff_Tblname, outFigName,coefVars, plotCoefVars );
writetable(meanCoeffTbl, fullfile(ResultsDir, ['mean_' coeff_Tblname '.csv']));


outFigName = fullfile(ResultsDir, noInterceptFig); %  plots all estimated exponents across iterations
plotCoefVars = {'VAe', 'De','Ee'};
[~, fh] = PM_plot_meanLMEcoeffs(S.(task).all_summarylmeTbl, coeff_Tblname, outFigName, coefVars, plotCoefVars);
if ~isempty(fh); close(fh); end

transformErrorTbl = summarize_model_prediction_error( ...
    S.(task).all_testing_Tbl, ...
    'predicted_PM_logPM_by_logAngleNDistanceNElevation', ...
    task, ElevationTransform, string(transformInfo.sfx));
writetable(transformErrorTbl, fullfile(ResultsDir, sprintf('%s_%diterations_prediction_error_%s.csv', lower(task), nIterations, sfx)));


%%


figName = sprintf('Perceptual_%dminID_%diterations', minNID, nIterations);

% main figure
Param = 'Distance';
saveBase = sprintf('%s_%s_%s', figName, Param, QuadBasename);
mainFigFile = fullfile(ResultsDir, [saveBase '.png']);
[SummaryItrParam, ~, ~, ~, fh, fh_violin, ~, ~, fh_pctbar] = ...
    plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNIDbinned(S.(task).all_testing_Tbl, Param, minNID, mainFigFile, figName, 'sd','Quad');
checkbinning(SummaryItrParam,Param,minNID);


saveBase = sprintf('%s_VA_D_E_%s', figName, QuadBasename);
threeFactorFigFile = fullfile(ResultsDir, [saveBase '.png']);

Param = {'Real_Visual_Angle','Distance','Elevation'};
[~, fh_threeFactorByParam] = plot_MeanPredictedvsReportedPM_byParams_1model( ...
    S.(task).all_testing_Tbl, ...
    'predicted_PM_logPM_by_logAngleNDistanceNElevation', ...
    Param, minNID, threeFactorFigFile, figName, 'sd', 'Quad');


% supplemental figure

for p=1:numel(paramsToPlot)
    Param = paramsToPlot{p};
    saveBase = sprintf('%s_%s_%s', figName, Param, QuadBasename);
    save3MFilename = fullfile(SupResultsDir,[saveBase '3Models.png']);
    [SummaryItrParam, ~, ~, ~, fh, fh_violin, ~, ~, fh_pctbar] = ...
    plot_MeanPredictedvsReportedPMbyParamwithMpERR_3models( ...
        S.(task).all_testing_Tbl, Param, minNID, save3MFilename, [figName '3Models'], 'sd', 'Quad');
end
transformField = matlab.lang.makeValidName(sfx);
ThreeFactorLMEStore.(transformField).TransformID = ElevationTransform;
ThreeFactorLMEStore.(transformField).TransformLabel = string(transformInfo.sfx);
ThreeFactorLMEStore.(transformField).Perceptual = S.Perceptual.threeFactorLMEs;

modelStoreFile = fullfile(ResultsDir, sprintf('%diterations_lme_coeffs_%s_%s.mat', nIterations, QuadBasename, sfx));
save(modelStoreFile, 'S', 'transformInfo', 'ElevationTransform');

%%
 close all
