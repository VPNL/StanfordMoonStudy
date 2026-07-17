function [outTbl, summaryTbl, fitInfo] = PM_lme_latentDmoon(trainTbl, testTbl, fitName, opts)
% PM_lme_latentDmoon Fit the 3-factor PM LME while estimating latent Dmoon.
%
% [outTbl, summaryTbl, fitInfo] = PM_lme_latentDmoon(trainTbl, testTbl, fitName, opts)
%
% Fits the model:
%   log2(PM) ~ log2(VA) + log2(D) + log2(1+|E|) + (1|ID)
%
% For quad rows, D is the observed Distance. For moon rows, D is a fitted
% latent distance. By default one distance is fitted per moon Date, and each
% fitted moon distance is constrained to Dmoon > 10*max(quad Distance).
% For each candidate set of Dmoon values, this function fits the same LME
% model and minimizes the negative training log likelihood.
%
% Inputs
%   trainTbl : training table with ID, Study, Real_Visual_Angle, Distance,
%              Elevation, and Ratio_Visual_Angle.
%   testTbl  : test table with the same predictor columns.
%   fitName  : optional label for reporting.
%   opts     : optional struct with fields:
%              MoonStudyLabel, QuadStudyLabel, DistanceMode,
%              DistanceGroupVariable, MinimumDistanceFactor, StartDmoon,
%              MaxIter, MaxFunEvals, TolX, TolFun, Display.
%
% Outputs
%   outTbl     : testTbl plus predicted_PM_latentDmoon_logPM_by_logAngleNDistanceNElevation.
%   summaryTbl : one-row summary of the fitted coefficients, Dmoon, and fit statistics.
%   fitInfo    : struct containing the fitted LME and optimizer details.

if nargin < 3 || isempty(fitName)
    fitName = "latentDmoon";
end
if nargin < 4 || isempty(opts)
    opts = struct();
end

local_validate_input_table(trainTbl, 'trainTbl');
local_validate_input_table(testTbl, 'testTbl');

moonLabel = local_get_opt(opts, 'MoonStudyLabel', "MoonStudy");
quadLabel = local_get_opt(opts, 'QuadStudyLabel', "QuadStudy");
studyName = local_get_opt(opts, 'Study', "combined_training");
taskName = local_get_opt(opts, 'Task', local_infer_task(trainTbl));
displayOpt = local_get_opt(opts, 'Display', 'off');
maxIter = local_get_opt(opts, 'MaxIter', 40);
maxFunEvals = local_get_opt(opts, 'MaxFunEvals', 80);
tolX = local_get_opt(opts, 'TolX', 1e-3);
tolFun = local_get_opt(opts, 'TolFun', 1e-3);
distanceMode = string(local_get_opt(opts, 'DistanceMode', 'byDate'));
distanceGroupVariable = string(local_get_opt(opts, 'DistanceGroupVariable', 'Date'));
minimumDistanceFactor = double(local_get_opt(opts, 'MinimumDistanceFactor', 10));

moonTrain = local_study_mask(trainTbl, moonLabel);
quadTrain = local_study_mask(trainTbl, quadLabel);
if ~any(moonTrain)
    error('trainTbl has no moon rows. Expected Study containing "%s".', moonLabel);
end
if ~any(quadTrain)
    error('trainTbl has no quad rows. Expected Study containing "%s".', quadLabel);
end

maxQuadDistance = max(trainTbl.Distance(quadTrain), [], 'omitnan');
if ~isfinite(maxQuadDistance) || maxQuadDistance <= 0
    error('Could not determine a positive max quad Distance from trainTbl.');
end
minimumDmoon = minimumDistanceFactor * maxQuadDistance;

[moonGroupTrain, moonGroupLevels] = local_moon_group_values(trainTbl, moonTrain, distanceMode, distanceGroupVariable);
startDmoon = local_get_start_dmoon(trainTbl, moonTrain, moonGroupTrain, moonGroupLevels, minimumDmoon, opts);
startTheta = log2(startDmoon - minimumDmoon);

optimOpts = optimset( ...
    'Display', char(displayOpt), ...
    'MaxIter', maxIter, ...
    'MaxFunEvals', maxFunEvals, ...
    'TolX', tolX, ...
    'TolFun', tolFun);

objective = @(theta) local_objective(theta, trainTbl, moonTrain, distanceMode, distanceGroupVariable, moonGroupLevels, minimumDmoon);
[thetaHat, objectiveValue, exitFlag, optimOutput] = fminsearch(objective, startTheta, optimOpts);

DmoonHat = local_theta_to_dmoon(thetaHat, minimumDmoon);
fallbackDmoon = median(DmoonHat, 'omitnan');
[lme, trainPrepared] = local_fit_lme_with_dmoon(trainTbl, moonTrain, distanceMode, distanceGroupVariable, moonGroupLevels, DmoonHat, fallbackDmoon);

outTbl = testTbl;
moonTest = local_study_mask(testTbl, moonLabel);
[testPrepared, assignedTestDmoon, assignedTestGroup] = local_prepare_table_for_lme(testTbl, moonTest, distanceMode, distanceGroupVariable, moonGroupLevels, DmoonHat, fallbackDmoon);
predLog2PM = local_fixed_effect_prediction(lme, testPrepared);
predictionCol = 'predicted_PM_latentDmoon_logPM_by_logAngleNDistanceNElevation';
outTbl.(predictionCol) = 2.^predLog2PM;
outTbl.latentDmoon_m = nan(height(outTbl), 1);
outTbl.latentDmoon_m(moonTest) = assignedTestDmoon(moonTest);
outTbl.latentDmoon_log2_m = nan(height(outTbl), 1);
outTbl.latentDmoon_log2_m(moonTest) = log2(assignedTestDmoon(moonTest));
outTbl.latentDmoon_group = assignedTestGroup;

dmoonGroupTbl = local_dmoon_group_table(moonGroupLevels, DmoonHat, startDmoon, minimumDmoon);

summaryTbl = local_summary_table(lme, fitName, studyName, taskName, dmoonGroupTbl, maxQuadDistance, minimumDmoon, ...
    startDmoon, objectiveValue, exitFlag, optimOutput, predictionCol, distanceMode, distanceGroupVariable, minimumDistanceFactor);

fitInfo = struct();
fitInfo.fitName = string(fitName);
fitInfo.lme = lme;
fitInfo.Dmoon = DmoonHat;
fitInfo.DmoonByGroup = dmoonGroupTbl;
fitInfo.StartDmoon = startDmoon;
fitInfo.MaxQuadDistance = maxQuadDistance;
fitInfo.MinimumDmoon = minimumDmoon;
fitInfo.DistanceMode = distanceMode;
fitInfo.DistanceGroupVariable = distanceGroupVariable;
fitInfo.ObjectiveValue = objectiveValue;
fitInfo.ExitFlag = exitFlag;
fitInfo.OptimOutput = optimOutput;
fitInfo.PredictionColumnName = predictionCol;
fitInfo.TrainPrepared = trainPrepared;

fprintf('Latent Dmoon fit %s: median Dmoon = %.6g m, max quad D = %.6g m, objective = %.6g\n', ...
    char(string(fitName)), median(DmoonHat, 'omitnan'), maxQuadDistance, objectiveValue);
fprintf('  Dmoon mode: %s by %s; N groups = %d; min Dmoon bound = %.6g m\n', ...
    char(distanceMode), char(distanceGroupVariable), numel(DmoonHat), minimumDmoon);

end

function local_validate_input_table(tbl, tblName)
if ~isa(tbl, 'table')
    error('%s must be a table.', tblName);
end
required = {'ID','Study','Real_Visual_Angle','Distance','Elevation','Ratio_Visual_Angle'};
missing = setdiff(required, tbl.Properties.VariableNames);
if ~isempty(missing)
    error('%s is missing required variable(s): %s', tblName, strjoin(missing, ', '));
end
end

function value = local_get_opt(opts, fieldName, defaultValue)
if isstruct(opts) && isfield(opts, fieldName) && ~isempty(opts.(fieldName))
    value = opts.(fieldName);
else
    value = defaultValue;
end
end

function mask = local_study_mask(tbl, studyLabel)
studyText = lower(strtrim(string(tbl.Study)));
mask = contains(studyText, lower(string(studyLabel)));
end

function taskName = local_infer_task(tbl)
if ismember('Task', tbl.Properties.VariableNames)
    taskValues = string(tbl.Task);
    taskValues = taskValues(~ismissing(taskValues) & strlength(strtrim(taskValues)) > 0);
    if ~isempty(taskValues)
        taskName = taskValues(1);
        return;
    end
end
taskName = "";
end

function [moonGroupTrain, moonGroupLevels] = local_moon_group_values(tbl, moonMask, distanceMode, distanceGroupVariable)
allGroups = local_group_values_for_rows(tbl, distanceMode, distanceGroupVariable);
moonGroupTrain = allGroups(moonMask);
if any(ismissing(moonGroupTrain) | strlength(strtrim(moonGroupTrain)) == 0)
    error('Moon rows have missing %s values, so Dmoon cannot be estimated by group.', char(distanceGroupVariable));
end

moonGroupLevels = unique(moonGroupTrain, 'stable');
if isempty(moonGroupLevels)
    error('No moon distance groups were found.');
end
end

function groupValues = local_group_values_for_rows(tbl, distanceMode, distanceGroupVariable)
distanceMode = lower(string(distanceMode));
nRows = height(tbl);

switch distanceMode
    case {"constant","single","one"}
        groupValues = repmat("Moon", nRows, 1);
    case {"bydate","bygroup"}
        groupVar = char(distanceGroupVariable);
        if ~ismember(groupVar, tbl.Properties.VariableNames)
            error('DistanceMode "%s" requires table variable "%s".', char(distanceMode), groupVar);
        end
        groupValues = string(tbl.(groupVar));
        groupValues = strtrim(groupValues);
    otherwise
        error('Unknown DistanceMode: %s. Use "byDate", "byGroup", or "constant".', char(distanceMode));
end
end

function startDmoon = local_get_start_dmoon(trainTbl, moonTrain, moonGroupTrain, moonGroupLevels, minimumDmoon, opts)
nGroups = numel(moonGroupLevels);
if isstruct(opts) && isfield(opts, 'StartDmoon') && ~isempty(opts.StartDmoon)
    startOpt = double(opts.StartDmoon);
    if isscalar(startOpt)
        startDmoon = repmat(startOpt, nGroups, 1);
    elseif numel(startOpt) == nGroups
        startDmoon = startOpt(:);
    else
        error('opts.StartDmoon must be scalar or match the number of moon distance groups (%d).', nGroups);
    end
else
    startDmoon = nan(nGroups, 1);
    moonDistances = trainTbl.Distance(moonTrain);
    validMoonDistances = moonDistances(isfinite(moonDistances) & moonDistances > minimumDmoon);
    if isempty(validMoonDistances)
        fallbackStart = minimumDmoon * 10;
    else
        fallbackStart = median(validMoonDistances, 'omitnan');
    end

    for iGroup = 1:nGroups
        thisDistance = moonDistances(moonGroupTrain == moonGroupLevels(iGroup));
        thisDistance = thisDistance(isfinite(thisDistance) & thisDistance > minimumDmoon);
        if isempty(thisDistance)
            startDmoon(iGroup) = fallbackStart;
        else
            startDmoon(iGroup) = median(thisDistance, 'omitnan');
        end
    end
end

minOffset = max(1, abs(minimumDmoon) * 1e-3);
badStart = ~isfinite(startDmoon) | startDmoon <= minimumDmoon;
startDmoon(badStart) = minimumDmoon + minOffset;
end

function objectiveValue = local_objective(theta, trainTbl, moonTrain, distanceMode, distanceGroupVariable, moonGroupLevels, minimumDmoon)
Dmoon = local_theta_to_dmoon(theta, minimumDmoon);
if any(~isfinite(Dmoon)) || any(Dmoon <= minimumDmoon)
    objectiveValue = Inf;
    return;
end

try
    fallbackDmoon = median(Dmoon, 'omitnan');
    lme = local_fit_lme_with_dmoon(trainTbl, moonTrain, distanceMode, distanceGroupVariable, moonGroupLevels, Dmoon, fallbackDmoon);
    objectiveValue = -local_log_likelihood(lme);
    if ~isfinite(objectiveValue)
        objectiveValue = Inf;
    end
catch
    objectiveValue = Inf;
end
end

function Dmoon = local_theta_to_dmoon(theta, minimumDmoon)
theta = double(theta(:));
Dmoon = minimumDmoon + 2.^theta;
end

function [lme, tbl] = local_fit_lme_with_dmoon(tblIn, moonMask, distanceMode, distanceGroupVariable, moonGroupLevels, DmoonByGroup, fallbackDmoon)
tbl = local_prepare_table_for_lme(tblIn, moonMask, distanceMode, distanceGroupVariable, moonGroupLevels, DmoonByGroup, fallbackDmoon);
lme = fitlme(tbl, ...
    'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + log2elevation + (1|ID)');
end

function [tbl, assignedDmoon, assignedGroup] = local_prepare_table_for_lme(tblIn, moonMask, distanceMode, distanceGroupVariable, moonGroupLevels, DmoonByGroup, fallbackDmoon)
tbl = tblIn;
assignedDmoon = nan(height(tbl), 1);
assignedGroup = strings(height(tbl), 1);

if any(moonMask)
    allGroups = local_group_values_for_rows(tbl, distanceMode, distanceGroupVariable);
    moonGroups = allGroups(moonMask);
    assignedGroup(moonMask) = moonGroups;

    moonDmoon = nan(sum(moonMask), 1);
    for iGroup = 1:numel(moonGroupLevels)
        moonDmoon(moonGroups == moonGroupLevels(iGroup)) = DmoonByGroup(iGroup);
    end
    moonDmoon(~isfinite(moonDmoon)) = fallbackDmoon;
    assignedDmoon(moonMask) = moonDmoon;
    tbl.Distance(moonMask) = moonDmoon;
end

if any(tbl.Real_Visual_Angle <= 0 | tbl.Distance <= 0 | tbl.Elevation + 1 <= 0 | tbl.Ratio_Visual_Angle <= 0)
    error('Nonpositive values found in VA, Distance, Elevation+1, or PM; log2 is undefined.');
end

tbl.log2real_visual_angle = log2(tbl.Real_Visual_Angle);
tbl.log2ratio_visual_angle = log2(tbl.Ratio_Visual_Angle);
tbl.log2distance = log2(tbl.Distance);
tbl.log2elevation = log2(tbl.Elevation + 1);
end

function dmoonGroupTbl = local_dmoon_group_table(moonGroupLevels, DmoonHat, startDmoon, minimumDmoon)
dmoonGroupTbl = table();
dmoonGroupTbl.DmoonGroup = string(moonGroupLevels(:));
dmoonGroupTbl.Dmoon_m = double(DmoonHat(:));
dmoonGroupTbl.StartDmoon_m = double(startDmoon(:));
dmoonGroupTbl.DmoonLowerBound_m = repmat(double(minimumDmoon), numel(DmoonHat), 1);
dmoonGroupTbl.Dmoon_km = dmoonGroupTbl.Dmoon_m ./ 1000;
dmoonGroupTbl.Dmoon_log2_m = log2(dmoonGroupTbl.Dmoon_m);
end

function logLikelihood = local_log_likelihood(lme)
try
    logLikelihood = double(lme.LogLikelihood);
catch
    try
        logLikelihood = double(lme.ModelCriterion.LogLikelihood);
    catch
        logLikelihood = NaN;
    end
end
end

function predLog2PM = local_fixed_effect_prediction(lme, tbl)
coefNames = lower(string(lme.CoefficientNames));
coefEst = double(lme.Coefficients.Estimate);

b0 = local_coef_value(coefNames, coefEst, ["(intercept)","intercept"]);
bVA = local_coef_value(coefNames, coefEst, "log2real_visual_angle");
bD = local_coef_value(coefNames, coefEst, "log2distance");
bE = local_coef_value(coefNames, coefEst, "log2elevation");

predLog2PM = b0 + ...
    bVA .* tbl.log2real_visual_angle + ...
    bD .* tbl.log2distance + ...
    bE .* tbl.log2elevation;
end

function value = local_coef_value(coefNames, coefEst, targetNames)
targetNames = lower(string(targetNames));
idx = [];
for iTarget = 1:numel(targetNames)
    idx = find(coefNames == targetNames(iTarget), 1, 'first');
    if ~isempty(idx)
        break;
    end
end
if isempty(idx)
    value = 0;
else
    value = coefEst(idx);
end
end

function summaryTbl = local_summary_table(lme, fitName, studyName, taskName, dmoonGroupTbl, maxQuadDistance, minimumDmoon, ...
    startDmoon, objectiveValue, exitFlag, optimOutput, predictionCol, distanceMode, distanceGroupVariable, minimumDistanceFactor)
summaryTbl = table();
summaryTbl.Study = string(studyName);
summaryTbl.Task = string(taskName);
summaryTbl.modelName = "latentDmoon_logPM_by_logAngleNDistanceNElevation";
summaryTbl.FitName = string(fitName);
summaryTbl.FormulaStr = string(char(lme.Formula));
summaryTbl.DistanceMode = string(distanceMode);
summaryTbl.DistanceGroupVariable = string(distanceGroupVariable);

[summaryTbl.Intercept, summaryTbl.IciL, summaryTbl.IciU, summaryTbl.Ip] = ...
    local_get_coef_stats(lme, ["(Intercept)","intercept"], true);
[summaryTbl.VAe, summaryTbl.VAciL, summaryTbl.VAciU, summaryTbl.VAp] = ...
    local_get_coef_stats(lme, "log2real_visual_angle", false);
[summaryTbl.De, summaryTbl.DciL, summaryTbl.DciU, summaryTbl.Dp] = ...
    local_get_coef_stats(lme, "log2distance", false);
[summaryTbl.Ee, summaryTbl.EciL, summaryTbl.EciU, summaryTbl.Ep] = ...
    local_get_coef_stats(lme, "log2elevation", false);

summaryTbl.AIC = local_model_criterion(lme, 'AIC');
summaryTbl.BIC = local_model_criterion(lme, 'BIC');
summaryTbl.LogLikelihood = local_log_likelihood(lme);

dmoonValues = dmoonGroupTbl.Dmoon_m;
summaryTbl.Dmoon_m = mean(dmoonValues, 'omitnan');
summaryTbl.DmoonMean_m = mean(dmoonValues, 'omitnan');
summaryTbl.DmoonMedian_m = median(dmoonValues, 'omitnan');
summaryTbl.DmoonMin_m = min(dmoonValues, [], 'omitnan');
summaryTbl.DmoonMax_m = max(dmoonValues, [], 'omitnan');
summaryTbl.DmoonSD_m = std(dmoonValues, 'omitnan');
summaryTbl.DmoonNGroups = height(dmoonGroupTbl);
summaryTbl.Dmoon_log2_m = log2(summaryTbl.DmoonMean_m);
summaryTbl.MaxQuadDistance_m = maxQuadDistance;
summaryTbl.DmoonLowerBound_m = minimumDmoon;
summaryTbl.MinimumDistanceFactor = minimumDistanceFactor;
summaryTbl.StartDmoon_m = mean(startDmoon, 'omitnan');
summaryTbl.StartDmoonMedian_m = median(startDmoon, 'omitnan');
summaryTbl.NegLogLikelihoodObjective = objectiveValue;
summaryTbl.OptimizerExitFlag = exitFlag;
summaryTbl.OptimizerIterations = local_struct_field(optimOutput, 'iterations', NaN);
summaryTbl.OptimizerFuncCount = local_struct_field(optimOutput, 'funcCount', NaN);
summaryTbl.PredictionColumn = string(predictionCol);
end

function value = local_struct_field(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function [est, ciL, ciU, p] = local_get_coef_stats(lme, targetNames, isIntercept)
est = NaN;
ciL = NaN;
ciU = NaN;
p = NaN;

coefNames = lower(string(lme.CoefficientNames));
targets = lower(string(targetNames));
idx = [];
for iTarget = 1:numel(targets)
    idx = find(coefNames == targets(iTarget), 1, 'first');
    if ~isempty(idx)
        break;
    end
end
if isempty(idx) && isIntercept
    idx = find(contains(coefNames, "intercept"), 1, 'first');
end
if isempty(idx)
    return;
end

ct = lme.Coefficients;
est = double(ct.Estimate(idx));
try
    ciL = double(ct.Lower(idx));
catch
end
try
    ciU = double(ct.Upper(idx));
catch
end
try
    p = double(ct.pValue(idx));
catch
end
end

function value = local_model_criterion(lme, fieldName)
try
    value = double(lme.ModelCriterion.(fieldName));
catch
    value = NaN;
end
end
