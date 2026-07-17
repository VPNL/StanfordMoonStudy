function summaryTbl = summarize_model_prediction_error(testTbl, predictedCol, taskName, transformId, transformLabel)
% summarize_model_prediction_error Summarize row-wise prediction error per iteration.
%
% Inputs
%   testTbl        : table with Iteration, Ratio_Visual_Angle, and predictedCol
%   predictedCol   : predicted PM column name
%   taskName       : string label for the task
%   transformId    : numeric transform id
%   transformLabel : string label shown on plots
%
% Output
%   summaryTbl : one row per iteration with mean error metrics

if ~isa(testTbl, 'table')
    error('testTbl must be a table.');
end

requiredVars = {'Iteration', 'Ratio_Visual_Angle'};
for i = 1:numel(requiredVars)
    if ~ismember(requiredVars{i}, testTbl.Properties.VariableNames)
        error('Missing required variable: %s', requiredVars{i});
    end
end
if ~ismember(predictedCol, testTbl.Properties.VariableNames)
    error('Missing predicted column: %s', predictedCol);
end

actualPM = testTbl.Ratio_Visual_Angle;
predPM = testTbl.(predictedCol);
absErr = abs(predPM - actualPM);
sqErr = (predPM - actualPM).^2;
pctDen = abs(actualPM);
pctDen(pctDen == 0) = NaN;
absPctErr = 100 * absErr ./ pctDen;

[G, iterationLevels] = findgroups(testTbl.Iteration);

meanAbsErr = splitapply(@(x) mean(x, 'omitnan'), absErr, G);
meanSqErr = splitapply(@(x) mean(x, 'omitnan'), sqErr, G);
meanPctErr = splitapply(@(x) mean(x, 'omitnan'), absPctErr, G);
nObs = splitapply(@(x) sum(isfinite(x)), absPctErr, G);

summaryTbl = table(iterationLevels, meanAbsErr, meanSqErr, meanPctErr, nObs, ...
    'VariableNames', {'Iteration','MeanAbsError','MeanSqError','MeanPctError','NObs'});

summaryTbl.Task = repmat(string(taskName), height(summaryTbl), 1);
summaryTbl.TransformID = repmat(double(transformId), height(summaryTbl), 1);
summaryTbl.TransformLabel = repmat(string(transformLabel), height(summaryTbl), 1);
summaryTbl = movevars(summaryTbl, {'Task','TransformID','TransformLabel'}, 'Before', 'Iteration');
end
