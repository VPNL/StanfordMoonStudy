% PM_Combined_ModelTesting_thoughtExperiment_refactored.m
%
% Refactor goals:
%   1) Loop over Hypothetical_moonD values.
%   2) For each moonD value, overwrite moon_subset_data.Distance with that constant.
%   3) Run the same workflow as before (splits, LMEs, predictions), looping over tasks.
%   4) Preserve the constraint that, for each iteration, the SAME train/test subject IDs
%      are used for both Perceptual and Adjusted tasks.
%   5) Store predictions per task, and compute per-task error summaries per model,
%      iteration, and Hypothetical_moonD.
%   6) Plot error across iterations for each Hypothetical_moonD and summarize which
%      Hypothetical_moonD yields the lowest average error per model.

close all; clearvars;

%% Paths and parameters
codeDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir));

ResultsDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/test';
if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir);
end

nIterations  = 2;
QuadFraction = 0.8;
saveLME      = 1; 

% Tasks must match the labels returned/used by splitTablebyTask
Tasks = {'Perceptual','Adjusted'};

% Thought experiment: hypothetical Moon distance values in meters
Hypothetical_moonD = [100*1000; 1000*1000];

%% Build combined dataset (moon + quad) and ensure all distances are in meters
MoonExpDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments';
MoonFile   = 'FullMoonDataLong090225.csv';
all_moon_data = readtable(fullfile(MoonExpDir, MoonFile));

MoonBasename = erase(MoonFile,'.csv');

colNames = {'ID','Real_Visual_Angle','Distance','Elevation', ...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'};

% Moon distances: km -> meters
moon_subset_base = table(all_moon_data.ID, ...
    all_moon_data.Real_Visual_Angle, ...
    1000*all_moon_data.Distance, ...
    all_moon_data.Elevation, ...
    all_moon_data.Task, ...
    all_moon_data.Reported_Visual_Angle, ...
    all_moon_data.Ratio_Visual_Angle, ...
    all_moon_data.Disparity_VA, ...
    'VariableNames', colNames);

moon_subset_base.Study = repmat({'MoonStudy'}, height(moon_subset_base), 1);

% Quad study
QuadExpDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
QuadFile   = 'QuadStudy0115.csv';
all_quad_data = readtable(fullfile(QuadExpDir, QuadFile));
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
    all_quad_data.Disparity_VA_1, ...
    'VariableNames', colNames);

quad_subset_data.Study = repmat({'QuadStudy'}, height(quad_subset_data), 1);

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

nIDmoon = numel(unique(moon_subset_base.ID));
moontrainingFraction = meansubPerCond / nIDmoon;
moontrainingFraction = max(0, min(1, moontrainingFraction)); % safety clamp

%% Storage across Hypothetical_moonD and tasks
% R.(moonDKey).(task).all_training_Tbl / all_testing_Tbl / all_summarylmeTbl
R = struct();

% Long-format error summary table across all conditions
% Columns: Task, Iteration, Hypothetical_moonD, Model, MSE, MAPE, N
ErrSummary = table();

paramsToPlot = {'Real_Visual_Angle','Distance','Elevation'};

%% Main loop: Hypothetical_moonD -> iterations -> tasks
for h = 1:numel(Hypothetical_moonD)

    moonD = Hypothetical_moonD(h);
    moonDKey = local_mkMoonDKey(moonD);

    % Initialize per-moonD storage
    if ~isfield(R, moonDKey)
        for t = 1:numel(Tasks)
            taskName = Tasks{t};
            R.(moonDKey).(taskName).all_testing_Tbl   = table();
            R.(moonDKey).(taskName).all_training_Tbl  = table();
            R.(moonDKey).(taskName).all_summarylmeTbl = table();
        end
    end

    % Build moon subset for this condition by overwriting distance
    moon_subset_data = moon_subset_base;
    moon_subset_data.Distance(:) = moonD;

    combinedBasename = sprintf('%s_%s_%s', MoonBasename, QuadBasename, moonDKey);

    for itr = 1:nIterations

        % Split by IDs ONCE per study and iteration
        [quad_training, quad_testing] = splitTablebyRandomIDs(quad_subset_data, QuadFraction);
        [moon_training, moon_testing] = splitTablebyRandomIDs(moon_subset_data, moontrainingFraction);

        combined_training_data = [quad_training; moon_training];
        combined_testing_data  = [quad_testing;  moon_testing];

        % if itr == 1
        %     plot_VA_D_E_parameters(combined_training_data, sprintf('combined_training_%s_I%d', moonDKey, itr), ResultsDir);
        %     plot_VA_D_E_parameters(combined_testing_data,  sprintf('combined_testing_%s_I%d',  moonDKey, itr), ResultsDir);
        % end

        % Split training and testing by task
        [trainP, trainA] = splitTablebyTask(combined_training_data);
        [testP,  testA ] = splitTablebyTask(combined_testing_data);

        % Enforce same IDs across tasks within train and test sets
        trainCommonIDs = intersect(unique(trainP.ID), unique(trainA.ID));
        testCommonIDs  = intersect(unique(testP.ID),  unique(testA.ID));

        trainP = trainP(ismember(trainP.ID, trainCommonIDs), :);
        trainA = trainA(ismember(trainA.ID, trainCommonIDs), :);
        testP  = testP( ismember(testP.ID,  testCommonIDs),  :);
        testA  = testA( ismember(testA.ID,  testCommonIDs),  :);

        % Map tables by task for clean looping
        trainByTask = struct('Perceptual', trainP, 'Adjusted', trainA);
        testByTask  = struct('Perceptual', testP,  'Adjusted', testA);

        for t = 1:numel(Tasks)

            taskName = Tasks{t};
            trainTbl = trainByTask.(taskName);
            testTbl  = testByTask.(taskName);

            % Fit the 7 LMEs on training data
            [lme_logAngle,lme_logDistance,lme_logElevation, ...
             lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation, ...
             lme_logAngleNDistanceNElevation] = PM_lmes(trainTbl, sprintf('combined_training_%s_I%d', moonDKey, itr));

            % Summarize coefficients
            summaryTbl = Quad_export_LME_summary_csv('combined_training', taskName, ...
                         lme_logAngle,lme_logDistance,lme_logElevation, ...
                         lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation, ...
                         lme_logAngleNDistanceNElevation);

            summaryTbl.Iteration = repmat(double(itr), height(summaryTbl), 1);
            summaryTbl.Hypothetical_moonD = repmat(double(moonD), height(summaryTbl), 1);

            R.(moonDKey).(taskName).all_summarylmeTbl = [R.(moonDKey).(taskName).all_summarylmeTbl; summaryTbl];

            % Estimate predictions on TESTING data
            outTbl = estimate_PM_fromlmeTbl(testTbl, summaryTbl);
            outTbl.Iteration = repmat(double(itr), height(outTbl), 1);
            outTbl.Hypothetical_moonD = repmat(double(moonD), height(outTbl), 1);

            R.(moonDKey).(taskName).all_testing_Tbl = [R.(moonDKey).(taskName).all_testing_Tbl; outTbl];

            % Store TRAINING data for provenance
            trainTbl.Iteration = repmat(double(itr), height(trainTbl), 1);
            trainTbl.Hypothetical_moonD = repmat(double(moonD), height(trainTbl), 1);
            R.(moonDKey).(taskName).all_training_Tbl = [R.(moonDKey).(taskName).all_training_Tbl; trainTbl];

            % Compute task-specific error summary per model for this iteration/moonD
            ErrSummary = [ErrSummary; local_summarizeErrors(outTbl, taskName, itr, moonD)];
        end
    end

    %% Save per-moonD results and generate standard plots (per task)
    for t = 1:numel(Tasks)
        taskName = Tasks{t};

        % training table
        training_Tblname = sprintf('%s_training_%diterations_%s', taskName, nIterations, combinedBasename);
        writetable(R.(moonDKey).(taskName).all_training_Tbl, fullfile(ResultsDir, [training_Tblname '.csv']));

        % testing table
        testing_Tblname = sprintf('%s_testing_%diterations_%s', taskName, nIterations, combinedBasename);
        writetable(R.(moonDKey).(taskName).all_testing_Tbl, fullfile(ResultsDir, [testing_Tblname '.csv']));

        % Mean predicted vs reported by parameter (unbinned)
        for p = 1:numel(paramsToPlot)
            Param = paramsToPlot{p};
            saveFilename = fullfile(ResultsDir, sprintf('%s_%diterations_%s_%s.png', taskName, nIterations, Param, combinedBasename));
            plot_MeanPredictedvsReportedPMbyParamwithMpERR(R.(moonDKey).(taskName).all_testing_Tbl, Param, saveFilename, taskName, 'sd');
        end

        % Plot coefficients and export mean table
        Tblname = sprintf('%s_%diterations_lme_summary_%s', taskName, nIterations, combinedBasename);
        outFigName = fullfile(ResultsDir, [Tblname '.png']);
        [outTblMean, ~] = PM_plot_meanLMEcoeffsI(R.(moonDKey).(taskName).all_summarylmeTbl, Tblname, outFigName);
        writetable(outTblMean, fullfile(ResultsDir, ['mean_' Tblname '.csv']));

        % Plot coefficients without intercepts
        outFigNameNoI = fullfile(ResultsDir, [Tblname '_noIntercepts.png']);
        PM_plot_meanLMEcoeffs(R.(moonDKey).(taskName).all_summarylmeTbl, Tblname, outFigNameNoI);
    end

    % Both tasks coefficient comparison for this moonD
    saveFilename = fullfile(ResultsDir, sprintf('bothtasks_lme_coeffs_%diterations_%s.png', nIterations, combinedBasename));
    PM_plot_meanLMEcoeffsI_bothtasks(R.(moonDKey).Perceptual.all_summarylmeTbl, R.(moonDKey).Adjusted.all_summarylmeTbl, saveFilename);

    % Binned plots (minNID)
    minNID = 20;
    for t = 1:numel(Tasks)
        taskName = Tasks{t};
        figName  = sprintf('%s_%dminNID', taskName, minNID);
        for p = 1:numel(paramsToPlot)
            Param = paramsToPlot{p};
            saveFilename = fullfile(ResultsDir, sprintf('%s_%diterations_%s_%s.png', figName, nIterations, Param, combinedBasename));
            plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(R.(moonDKey).(taskName).all_testing_Tbl, Param, minNID, saveFilename, figName, 'sd');
        end
    end

end

%% Save global error summaries
ErrSummaryFile = fullfile(ResultsDir, sprintf('ErrorSummary_byTaskIterMoonD_%diterations.csv', nIterations));
writetable(ErrSummary, ErrSummaryFile);

% Aggregate across iterations to identify best Hypothetical_moonD per model and task
Agg = groupsummary(ErrSummary, {'Task','Model','Hypothetical_moonD','Metric'}, 'mean', 'Value');
Agg.Properties.VariableNames{'mean_Value'} = 'MeanValue';

Best = table();
for metricName = unique(Agg.Metric)'
    metricMask = Agg.Metric == metricName;
    sub = Agg(metricMask, :);
    [G, taskNames, modelNames] = findgroups(sub.Task, sub.Model);
    bestIdx = splitapply(@(x) find(x == min(x), 1, 'first'), sub.MeanValue, G);
    tmp = sub(bestIdx, {'Task','Model','Hypothetical_moonD','Metric','MeanValue'});
    Best = [Best; tmp];
end
BestFile = fullfile(ResultsDir, sprintf('BestHypotheticalMoonD_byTaskModel_%diterations.csv', nIterations));
writetable(Best, BestFile);

%% Plots: error across iterations for each Hypothetical_moonD (per task and model)
local_plotErrorAcrossIterations(ErrSummary, Hypothetical_moonD, ResultsDir, nIterations);

close all;

%% Local helper functions (script-local)
function key = local_mkMoonDKey(moonD)
% Create a safe struct field name for a Hypothetical_moonD value.
key = sprintf('moonD_%g', moonD);
key = regexprep(key, '[^a-zA-Z0-9_]', '_');
end

function ES = local_summarizeErrors(outTbl, taskName, itr, moonD)
% Summarize errors per predicted column. Returns a table with:
%   Task, Iteration, Hypothetical_moonD, Model, Metric, Value, N

ES = table();

if ~istable(outTbl) || height(outTbl) == 0
    return;
end

if ~ismember('Ratio_Visual_Angle', outTbl.Properties.VariableNames)
    warning('local_summarizeErrors:MissingObserved', 'Observed column Ratio_Visual_Angle not found.');
    return;
end

y = outTbl.Ratio_Visual_Angle;

predVars = outTbl.Properties.VariableNames(contains(outTbl.Properties.VariableNames, 'predicted', 'IgnoreCase', true));
if isempty(predVars)
    return;
end

for i = 1:numel(predVars)
    v = predVars{i};
    yhat = outTbl.(v);

    % Align NaNs
    ok = ~(isnan(y) | isnan(yhat));
    if ~any(ok)
        continue;
    end

    err = yhat(ok) - y(ok);
    mse = mean(err.^2, 'omitnan');
    mape = mean(100 * abs(err) ./ max(eps, abs(y(ok))), 'omitnan');

    modelName = string(v);

    % MSE row
    ES = [ES; table(string(taskName), double(itr), double(moonD), modelName, "MSE", mse, sum(ok), ...
        'VariableNames', {'Task','Iteration','Hypothetical_moonD','Model','Metric','Value','N'})];

    % MAPE row
    ES = [ES; table(string(taskName), double(itr), double(moonD), modelName, "MAPE", mape, sum(ok), ...
        'VariableNames', {'Task','Iteration','Hypothetical_moonD','Model','Metric','Value','N'})];
end
end

function local_plotErrorAcrossIterations(ErrSummary, Hypothetical_moonD, ResultsDir, nIterations)
% Create diagnostic plots of error across iterations for each Hypothetical_moonD.

if isempty(ErrSummary) || ~istable(ErrSummary)
    return;
end

tasks = unique(ErrSummary.Task);
metrics = unique(ErrSummary.Metric);
models = unique(ErrSummary.Model);

for ti = 1:numel(tasks)
    taskName = tasks(ti);

    for mi = 1:numel(metrics)
        metricName = metrics(mi);

        % One figure per task x metric with panels for models
        fh = figure('Color','w');
        tl = tiledlayout(fh, 'flow', 'TileSpacing','compact', 'Padding','compact'); %#ok<NASGU>

        for mdl = 1:numel(models)
            modelName = models(mdl);
            ax = nexttile;
            hold(ax, 'on');

            for h = 1:numel(Hypothetical_moonD)
                moonD = Hypothetical_moonD(h);
                mask = ErrSummary.Task==taskName & ErrSummary.Metric==metricName & ErrSummary.Model==modelName & ErrSummary.Hypothetical_moonD==moonD;
                if ~any(mask)
                    continue;
                end
                [itrVals, ord] = sort(ErrSummary.Iteration(mask));
                vals = ErrSummary.Value(mask);
                vals = vals(ord);
                plot(ax, itrVals, vals, '-o', 'DisplayName', sprintf('moonD=%g', moonD));
            end

            title(ax, modelName, 'Interpreter','none');
            xlabel(ax, 'Iteration');
            ylabel(ax, metricName);
            xlim(ax, [1 nIterations]);
        end

        lg = legend('Location','bestoutside');
        lg.Interpreter = 'none';

        outName = fullfile(ResultsDir, sprintf('ErrorAcrossIterations_%s_%s_%diterations.png', taskName, metricName, nIterations));
        saveas(fh, outName);
    end
end

% Also create a compact summary: mean error across iterations vs Hypothetical_moonD, per model and task
Agg = groupsummary(ErrSummary, {'Task','Model','Hypothetical_moonD','Metric'}, 'mean', 'Value');
Agg.Properties.VariableNames{'mean_Value'} = 'MeanValue';

for ti = 1:numel(tasks)
    taskName = tasks(ti);

    for mi = 1:numel(metrics)
        metricName = metrics(mi);

        sub = Agg(Agg.Task==taskName & Agg.Metric==metricName, :);
        if isempty(sub)
            continue;
        end

        fh = figure('Color','w');
        tl = tiledlayout(fh, 'flow', 'TileSpacing','compact', 'Padding','compact'); %#ok<NASGU>

        for mdl = 1:numel(models)
            modelName = models(mdl);
            ax = nexttile;
            hold(ax,'on');

            s2 = sub(sub.Model==modelName, :);
            if isempty(s2)
                continue;
            end
            [moonVals, ord] = sort(s2.Hypothetical_moonD);
            y = s2.MeanValue(ord);
            plot(ax, moonVals, y, '-o');
            title(ax, modelName, 'Interpreter','none');
            xlabel(ax, 'Hypothetical moonD (m)');
            ylabel(ax, sprintf('Mean %s', metricName));
        end

        outName = fullfile(ResultsDir, sprintf('ErrorVsHypotheticalMoonD_%s_%s_%diterations.png', taskName, metricName, nIterations));
        saveas(fh, outName);
    end
end

end
