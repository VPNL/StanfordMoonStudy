function deltaTbl = summarize_transform_deltas(detailTbl, saveCsvFile)
% summarize_transform_deltas Compute delta-from-best values within each evidence group.
%
% Input detailTbl is expected to contain:
%   Dataset, Task, Metric, TransformFamily, Value
%
% Output deltaTbl adds:
%   BestTransform, BestValue, DeltaFromBest, PercentAboveBest, RankWithinGroup

if ~isa(detailTbl, 'table') || isempty(detailTbl)
    error('detailTbl must be a non-empty table.');
end

requiredVars = {'Dataset','Task','Metric','TransformFamily','Value'};
missingVars = setdiff(requiredVars, detailTbl.Properties.VariableNames);
if ~isempty(missingVars)
    error('detailTbl is missing required variables: %s', strjoin(missingVars, ', '));
end

deltaTbl = detailTbl;
deltaTbl.Dataset = string(deltaTbl.Dataset);
deltaTbl.Task = string(deltaTbl.Task);
deltaTbl.Metric = string(deltaTbl.Metric);
deltaTbl.TransformFamily = string(deltaTbl.TransformFamily);

deltaTbl.BestTransform = strings(height(deltaTbl), 1);
deltaTbl.BestValue = nan(height(deltaTbl), 1);
deltaTbl.DeltaFromBest = nan(height(deltaTbl), 1);
deltaTbl.PercentAboveBest = nan(height(deltaTbl), 1);
deltaTbl.RankWithinGroup = nan(height(deltaTbl), 1);

groupKeys = unique(deltaTbl(:, {'Dataset','Task','Metric'}), 'rows', 'stable');
for g = 1:height(groupKeys)
    idx = deltaTbl.Dataset == groupKeys.Dataset(g) & ...
          deltaTbl.Task == groupKeys.Task(g) & ...
          deltaTbl.Metric == groupKeys.Metric(g);

    vals = deltaTbl.Value(idx);
    labels = deltaTbl.TransformFamily(idx);
    validIdx = find(~isnan(vals));
    if isempty(validIdx)
        continue;
    end

    validVals = vals(validIdx);
    validLabels = labels(validIdx);
    [bestVal, localBestIdx] = min(validVals);
    bestLabel = validLabels(localBestIdx);

    ranks = tiedrank(validVals);

    rowIdx = find(idx);
    deltaTbl.BestTransform(rowIdx(validIdx)) = bestLabel;
    deltaTbl.BestValue(rowIdx(validIdx)) = bestVal;
    deltaTbl.DeltaFromBest(rowIdx(validIdx)) = validVals - bestVal;
    if abs(bestVal) > eps
        deltaTbl.PercentAboveBest(rowIdx(validIdx)) = 100 * ((validVals - bestVal) ./ abs(bestVal));
    else
        deltaTbl.PercentAboveBest(rowIdx(validIdx)) = nan;
    end
    deltaTbl.RankWithinGroup(rowIdx(validIdx)) = ranks;
end

if nargin >= 2 && ~isempty(saveCsvFile)
    writetable(deltaTbl, saveCsvFile);
end
end
