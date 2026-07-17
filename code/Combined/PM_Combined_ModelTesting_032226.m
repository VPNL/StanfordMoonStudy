% PM_Combined_ModelTesting_032226.m

close all; clearvars;

%% Paths & parameters
codeDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir));


nIterations  = 100;
QuadFraction = 0.8;
saveLME      = 1; 

% Tasks: must match the labels returned/used by splitTablebyTask
Tasks    = {'Perceptual','Adjusted'};

% Storage struct (one field per task)
R = struct();
for t = 1:numel(Tasks)
    taskName = Tasks{t};
    R.(taskName).all_testing_Tbl   = [];
    R.(taskName).all_training_Tbl  = [];
    R.(taskName).all_summarylmeTbl = [];
end

%% Build combined dataset (moon + quad) and ensure all distances are in meters 
MoonExpDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments';
MoonFile   = 'FullMoonDataLong090225.csv';
all_moon_data = readtable(fullfile(MoonExpDir, MoonFile));

MoonBasename = erase(MoonFile,'.csv');
colNames = {'ID','Real_Visual_Angle','Distance','Elevation', ...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle'};

% Moon distances: km -> meters
moon_subset_data = table(all_moon_data.ID, ...
    all_moon_data.Real_Visual_Angle, ...
    1000*all_moon_data.Distance, ...
    all_moon_data.Elevation, ...
    all_moon_data.Task, ...
    all_moon_data.Reported_Visual_Angle, ...
    all_moon_data.Ratio_Visual_Angle, ...
    'VariableNames', colNames);

moon_subset_data.Study = repmat({'MoonStudy'}, height(moon_subset_data), 1);

% Quad study
QuadExpDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
ObserverFlag=1;
%QuadFile='MatchingData0318.csv';
QuadFile='MatchingData0318_topStick.csv';
all_quad_data = readtable(fullfile(QuadExpDir, QuadFile));
if ObserverFlag
    all_quad_data.Elevation=all_quad_data.Observer_Elevation;
    all_quad_data.Distance=all_quad_data.Observer_Distance;
end

QuadBasename = erase(QuadFile,'.csv');

% Remove subject 26 who is an outlier (did not follow instructions in the adjusted task)
all_quad_data = all_quad_data(all_quad_data.ID ~= 26, :);


% Quad distances: cm -> meters
quad_subset_data = table(all_quad_data.ID, ...
    all_quad_data.Real_Visual_Angle, ...
    all_quad_data.Distance/100, ...
    all_quad_data.Elevation, ...
    all_quad_data.Task, ...
    all_quad_data.Reported_Visual_Angle, ...
    all_quad_data.Ratio_Visual_Angle, ...
    'VariableNames', colNames);

quad_subset_data.Study = repmat({'QuadStudy'}, height(quad_subset_data), 1);
combinedBasename = sprintf('%s_%s', MoonBasename, QuadBasename);



% transform elevation to deal with negative numbers in quad
ElevationTransform=3;

if ElevationTransform==1
     ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/SupplFig_PositiveOnlyQuadMoon_ModelTesting_032226_Elevation';
elseif  ElevationTransform==2
    quad_subset_data.Elevation=abs(quad_subset_data.Elevation);
    moon_subset_data.Elevation=abs(moon_subset_data.Elevation);
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/SupplFig_QuadMoon_ModelTesting_032226_absElevation';
elseif ElevationTransform==3
    quad_subset_data.Elevation=pi*quad_subset_data.Elevation/180;
    moon_subset_data.Elevation=pi*moon_subset_data.Elevation/180;
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/SupplFig_QuadMoon_ModelTesting_032226_ElevationRAD';
elseif ElevationTransform==4
    quad_subset_data.Elevation=abs(pi*quad_subset_data.Elevation/180);
   moon_subset_data.Elevation=abs(pi*moon_subset_data.Elevation/180);
    ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/SupplFig_QuadMoon_ModelTesting_032226_absElevationRAD';
end

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir);
end


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
moontrainingFraction = max(0, min(1, moontrainingFraction)); % safety clamp

%% Model fitting and testing across random subsets of the data separately per tasks

for itr = 1:nIterations

    % Split by IDs ONCE per study and iteration
    [quad_training, quad_testing] = splitTablebyRandomIDs(quad_subset_data, QuadFraction);
    [moon_training, moon_testing] = splitTablebyRandomIDs(moon_subset_data, moontrainingFraction);

    combined_training_data = [quad_training; moon_training];
    combined_testing_data  = [quad_testing;  moon_testing];

    if itr == 1
        plot_VA_D_E_parameters(combined_training_data, sprintf('combined_training_I%d', itr), ResultsDir);
        plot_VA_D_E_parameters(combined_testing_data,  sprintf('combined_testing_I%d',  itr), ResultsDir);
    end

    % Split training and testing by task (once)
    [trainP, trainA] = splitTablebyTask(combined_training_data);
    [testP,  testA ] = splitTablebyTask(combined_testing_data);

    % Map tables by task for clean looping
    trainByTask = struct('Perceptual', trainP, 'Adjusted', trainA);
    testByTask  = struct('Perceptual', testP,  'Adjusted', testA);

    for t = 1:numel(Tasks)
       
        taskName = Tasks{t}; 
        trainTbl = trainByTask.(taskName);
        testTbl  = testByTask.(taskName);

        % Fit the 7 LMEs on training data
        %[lme1,lme2,lme3,lme4,lme5,lme6,lme7] = PM_lmes(trainTbl, sprintf('combined_training_I%d', itr));

        [lme_logAngle,lme_logDistance,lme_logElevation,...
        lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation,...
        lme_logAngleNDistanceNElevation]=PM_lmes(trainTbl, sprintf('combined_training_I%d', itr));

        
        % summaryTbl = Quad_export_LME_summary_csv('combined_training', taskName, ...
        %     lme1, lme2, lme3, lme4, lme5, lme6, lme7);

        % Summarize coefficients
        summaryTbl = Quad_export_LME_summary_csv('combined_training', taskName, ...
                     lme_logAngle,lme_logDistance,lme_logElevation,...
                     lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation,...
                     lme_logAngleNDistanceNElevation);

       
        summaryTbl.Iteration = repmat(double(itr), height(summaryTbl), 1);
        R.(taskName).all_summarylmeTbl = [R.(taskName).all_summarylmeTbl; summaryTbl];

        % Estimate predictions on TESTING data
        outTbl = estimate_PM_fromlmeTbl(testTbl, summaryTbl);
        outTbl.Iteration = repmat(double(itr), height(outTbl), 1);
        R.(taskName).all_testing_Tbl = [R.(taskName).all_testing_Tbl; outTbl];

        % Store TRAINING data for provenance
        trainTbl.Iteration = repmat(double(itr), height(trainTbl), 1);
        R.(taskName).all_training_Tbl= [R.(taskName).all_training_Tbl; trainTbl];
    end
end

%% Save results and generate figures (loop over tasks)
paramsToPlot = {'Real_Visual_Angle','Distance','Elevation'};

for t = 1:numel(Tasks)
    taskName = Tasks{t};

    % training table
    training_Tblname = sprintf('%s_training_%diterations_lme_summary_combined_training_%s', ...
        taskName, nIterations, combinedBasename);
    writetable(R.(taskName).all_training_Tbl, fullfile(ResultsDir, [training_Tblname '.csv']));

    % testing table
    testing_Tblname = sprintf('%s_testing_%diterations_lme_summary_combined_training_%s', ...
        taskName, nIterations, combinedBasename);
    writetable(R.(taskName).all_testing_Tbl, fullfile(ResultsDir, [testing_Tblname '.csv']));

   
    % Plot coefficients & export mean table
    Tblname = sprintf('%s_%diterations_lme_summary_combined_training_%s', ...
        taskName, nIterations, combinedBasename);

    outFigName = fullfile(ResultsDir, [Tblname '.png']);
    coefVars = {'Intercept','VAe' 'De','Ee'};
    plotCoefVars = {'Intercept', 'VAe', 'De','Ee'};
    [outTbl, ~] = PM_plot_meanLMEcoeffs(R.(taskName).all_summarylmeTbl, Tblname, outFigName);
    writetable(outTbl, fullfile(ResultsDir, ['mean_' Tblname '.csv']));
    % Plot coefficients without intercepts
    coefVars = {'Intercept','VAe' 'De','Ee'};
    plotCoefVars = {'VAe', 'De','Ee'};
    outFigNameNoI = fullfile(ResultsDir, [Tblname 'noIntercepts.png']);
    PM_plot_meanLMEcoeffs(R.(taskName).all_summarylmeTbl, Tblname, outFigNameNoI, coefVars, plotCoefVars);

   
end

%% Both tasks coefficient comparison
saveFilename = fullfile(ResultsDir, sprintf('bothtasks_lme_coeffs_%diterations_combined_%s.png', ...
    nIterations, combinedBasename));
PM_plot_meanLMEcoeffsI_bothtasks(R.Perceptual.all_summarylmeTbl, R.Adjusted.all_summarylmeTbl, saveFilename);

%% Binned plots (minNID)
minNID = 25;
for t = 1:numel(Tasks)
    taskName = Tasks{t};
    figName  = sprintf('%s_%dminNID', taskName, minNID);
    for p = 1:numel(paramsToPlot)
        Param = paramsToPlot{p};
        saveFilename = fullfile(ResultsDir, sprintf('%s_%diterations_%s_combined_%s.png', ...
            figName, nIterations, Param, combinedBasename));
        %plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(R.(taskName).all_testing_Tbl, Param, minNID, saveFilename, figName, 'sd');
    [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, ...
        fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNIDbinned(R.(taskName).all_testing_Tbl, Param, minNID, saveFilename, figName, 'sd','Combined');
      checkbinning(SummaryItrParam,Param,minNID)

    end
end
%%

saveFilename = fullfile(ResultsDir, sprintf('%diterations_combined_%s.mat', ...
             nIterations, combinedBasename));
save(saveFilename)
close all;