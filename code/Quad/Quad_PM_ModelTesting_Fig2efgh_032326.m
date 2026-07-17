% Combine and fit data across both experiments
close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir))


saveLME=1; % 1 save files; 0 don't save

% quad study
QuadExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
%QuadFile='MatchingData0318.csv';
QuadFile='MatchingData0318_topStick.csv';

QuadBasename = erase(QuadFile,'.csv');
all_quad_data=readtable(fullfile(QuadExpDir,QuadFile));

nIterations=100;
QuadFraction=.8;
ObserverFlag=1;

if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance;
end
fprintf('before transform elevation: min  %.2f, max %.2f\n', min(all_quad_data.Elevation), max(all_quad_data.Elevation));

ElevationTransform=6;
 
if ElevationTransform==1
    sfx='Elevation';
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Paper_Fig2efgh_Modeltesting_0323226_Elevation';
elseif    ElevationTransform==2
    all_quad_data.Elevation=abs(all_quad_data.Elevation);
    sfx='absElevation';
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Paper_Fig2efgh_Modeltesting_0323226_absElevation';
elseif ElevationTransform==3
    sfx='ElevationRAD';
    all_quad_data.Elevation=pi*(all_quad_data.Elevation)/180;% transform to radians
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Paper_Fig2efgh_Modeltesting_032326_ElevationRAD';
elseif ElevationTransform==4
    sfx='absElevationRAD';
    all_quad_data.Elevation=pi*(abs(all_quad_data.Elevation))/180;% transform to absolute radians
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Paper_Fig2efgh_Modeltesting_032326_absElevationRAD';
elseif ElevationTransform==5
    sfx='ElevationD90';
    all_quad_data.Elevation=all_quad_data.Elevation/90;% normalize elevation to be -90:90
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Paper_Fig2efgh_Modeltesting_032326_ElevationD90';
elseif ElevationTransform==6
    sfx='absElevationD90';
    all_quad_data.Elevation=abs(all_quad_data.Elevation/90);% normalize elevation to be -90:90
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Paper_Fig2efgh_Modeltesting_032326_absElevationD90';

end
fprintf('after transform elevation:  min  %.2f, max %.2f\n', min(all_quad_data.Elevation), max(all_quad_data.Elevation));



% NOTE: fix directory existence check (use variable, not literal string)
if ~exist('ResultsDir','dir')
  mkdir(ResultsDir)
end


%%
% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task
all_quad_data = all_quad_data(all_quad_data.ID~=26,:);

colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'};

quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,...
                       'VariableNames',colNames);

quad_subset_data.Study = repmat({'QuadStudy'}, height(quad_subset_data), 1);

%% Model fitting/testing across random subsets of the data

% Task configuration
tasks   = {'Perceptual','Adjusted'};         % Tasks in Quad_export_LME_summary_csv
plotTitles = {'Perceptual','Adjusted'};      % labels used in figures
nTasks = numel(tasks);

% Storage per task
S = struct();
for t=1:nTasks
    task = tasks{t};
    S.(task).all_testing_Tbl    = [];
    S.(task).all_training_Tbl   = [];
    S.(task).all_summarylmeTbl  = [];
end

for itr=1:nIterations
    [quad_training_data, quad_testing_data, keepIDs] = splitTablebyRandomIDs(quad_subset_data, QuadFraction);

    quad_training_name=sprintf('quad_training_I%d',itr);
    quad_testing_name=sprintf('quad_testing_I%d',itr);

    % plot testing and training range of parameters for an example iteration
    % if itr==1
    %       plot_VA_D_E_parameters(quad_training_data,quad_training_name,ResultsDir);
    %       plot_VA_D_E_parameters(quad_testing_data,quad_testing_name,ResultsDir);
    % end

    % split table by task (assumes function returns [perceptual, adjusted])
    [trainP, trainA] = splitTablebyTask(quad_training_data);
    [testP,  testA ] = splitTablebyTask(quad_testing_data);

    trainByTask = {trainP, trainA};
    testByTask  = {testP,  testA};

    % loop over tasks with identical logic
    for t=1:nTasks
        task = tasks{t};
        trainTbl = trainByTask{t};
        testTbl  = testByTask{t};

        % estimate all LMEs
        [lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
         lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
         lme_logPM_by_logAngleNDistanceNElevation] = PM_lmes(trainTbl, quad_training_name);

        % export LME summary
        summaryTbl = Quad_export_LME_summary_csv('quad_training', task, ...
            lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
            lme_logPM_by_logAngleNDistanceNElevation);

        summaryTbl.Iteration = repmat(double(itr), height(summaryTbl), 1);
        S.(task).all_summarylmeTbl = [S.(task).all_summarylmeTbl; summaryTbl];

        % predict PM in testing set
        outTbl = estimate_PM_fromlmeTbl(testTbl, summaryTbl);
        outTbl.Iteration = repmat(double(itr), height(outTbl), 1);
        S.(task).all_testing_Tbl = [S.(task).all_testing_Tbl; outTbl];

        % store training data for this iteration
        trainTbl.Iteration = repmat(double(itr), height(trainTbl), 1);
        S.(task).all_training_Tbl = [S.(task).all_training_Tbl; trainTbl];
    end
end

%% Save results and figures
paramsToPlot = {'Real_Visual_Angle','Distance','Elevation'};

for t=1:nTasks
    task = tasks{t};
    figName = plotTitles{t};
    if strcmp(task,'Perceptual')
        training_Tblname = sprintf('perceptual_training_%diterations_lme_summary_%s', nIterations, QuadBasename);
        testing_Tblname  = sprintf('perceptual_testing_%diterations_lme_summary_%s',  nIterations, QuadBasename);
        coeff_Tblname    = sprintf('Perceptual_%diterations_lme_summary_%s',          nIterations, QuadBasename);
        noInterceptFig   = [coeff_Tblname '_noIntercepts.png'];
    else % Adjusted
        training_Tblname = sprintf('adjusted_training_%d_iterations_lme_summary_%s',  nIterations, QuadBasename);
        testing_Tblname  = sprintf('adjusted_testing_%d_iterations_lme_summary_%s',   nIterations, QuadBasename);
        coeff_Tblname    = sprintf('adjusted_%diterations_lme_summary_%s',            nIterations, QuadBasename);
        noInterceptFig   = [coeff_Tblname 'noIntercepts.png']; % (no underscore, matches original)
    end

    % write training/testing tables to keep record
    writetable(S.(task).all_training_Tbl, fullfile(ResultsDir,[training_Tblname '.csv']));
    writetable(S.(task).all_testing_Tbl,  fullfile(ResultsDir,[testing_Tblname  '.csv']));

  
    % plot mean LME coefficients 
    outFigName = fullfile(ResultsDir, [coeff_Tblname '.png']);
    coefVars = {'Intercept','VAe' 'De','Ee'};
    plotCoefVars = {'Intercept', 'VAe', 'De','Ee'};
    [meanCoeffTbl, fh] = PM_plot_meanLMEcoeffs(S.(task).all_summarylmeTbl, coeff_Tblname, outFigName,coefVars, plotCoefVars );
    writetable(meanCoeffTbl, fullfile(ResultsDir, ['mean_' coeff_Tblname '.csv']));

    % just exponents no intercepts
    outFigName = fullfile(ResultsDir, noInterceptFig);
    plotCoefVars = {'VAe', 'De','Ee'};
    [meanCoeffTbl, fh] = PM_plot_meanLMEcoeffs(S.(task).all_summarylmeTbl, coeff_Tblname, outFigName, coefVars, plotCoefVars);
end

%% Plot poth tasks coefficients across the LMEs
saveFilename = fullfile(ResultsDir, sprintf('both_tasks_%diterations_lme_coeffs_%s_%s.png', nIterations, QuadBasename, sfx));
[statsTblP, statsTblA, fh] = PM_plot_meanLMEcoeffsI_bothtasks(S.Perceptual.all_summarylmeTbl, S.Adjusted.all_summarylmeTbl, saveFilename);

%% Evaluated on binned parameter values 
%  evaluate predicted vs perceived on binned values to ensure a minimum of
%  minID participants per bin to get reasonable estimate of mean perceived
%  magnification per paramter level

minNID = 25;

for t=1:nTasks % loop on tasks
    task = tasks{t};
    if strcmp(task,'Perceptual')
        figName = sprintf('Perceptual_%dminNID', minNID);
        suffixTemplate = '%s_%diterations_%s_%s_%s';
    else % adjusted
        figName = sprintf('Adjusted_%dminNID', minNID);
        suffixTemplate = '%s_%diterations_%s_combined_%s_%s';
    end

    for p=1:numel(paramsToPlot) % loop on parameters to plot
        Param = paramsToPlot{p};
        saveBase = sprintf(suffixTemplate, figName, nIterations, Param, QuadBasename,sfx);
        saveFilename = fullfile(ResultsDir, [saveBase '.png']);
        % 
        % [SummaryItrParambinned, SummaryParambinned, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = ...
        %     plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(S.(task).all_testing_Tbl, Param, minNID, saveFilename, figName, 'sd','Quad');
         [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, ...
          fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNIDbinned(S.(task).all_testing_Tbl, Param, minNID, saveFilename, figName, 'sd','Quad');
          checkbinning(SummaryItrParam,Param,minNID)
    end
end
%%
close all
% save results
saveFilename = fullfile(ResultsDir, sprintf('%diterations_lme_coeffs_%s_%s.mat', nIterations, QuadBasename, sfx));
save(saveFilename);