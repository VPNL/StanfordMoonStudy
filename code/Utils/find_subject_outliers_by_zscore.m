function [outlierIDs, statsTbl] = find_subject_outliers_by_zscore(tbl, valueVarName, idVarName, zThreshold)
% FIND_SUBJECT_OUTLIERS_BY_ZSCORE
% Identify subject-level outliers using a z-score rule on subject means.

if nargin < 2 || isempty(valueVarName)
    valueVarName = 'MeanDisparity';
end
if nargin < 3 || isempty(idVarName)
    idVarName = 'ID';
end
if nargin < 4 || isempty(zThreshold)
    zThreshold = 3;
end

if ~istable(tbl)
    error('find_subject_outliers_by_zscore:InvalidInput', 'tbl must be a table.');
end
if ~ismember(valueVarName, tbl.Properties.VariableNames)
    error('find_subject_outliers_by_zscore:MissingValueVar', ...
        'Missing value variable "%s".', valueVarName);
end
if ~ismember(idVarName, tbl.Properties.VariableNames)
    error('find_subject_outliers_by_zscore:MissingIDVar', ...
        'Missing ID variable "%s".', idVarName);
end

idVals = tbl.(idVarName);
if iscategorical(idVals)
    uniqueIDs = categories(removecats(idVals));
    idStrings = string(idVals);
else
    uniqueIDs = unique(idVals, 'stable');
    idStrings = string(idVals);
    uniqueIDs = string(uniqueIDs);
end

subjectMean = nan(numel(uniqueIDs), 1);
subjectN = zeros(numel(uniqueIDs), 1);
for i = 1:numel(uniqueIDs)
    idx = idStrings == string(uniqueIDs(i));
    vals = double(tbl.(valueVarName)(idx));
    vals = vals(isfinite(vals));
    subjectN(i) = numel(vals);
    if ~isempty(vals)
        subjectMean(i) = mean(vals, 'omitnan');
    end
end

groupMean = mean(subjectMean, 'omitnan');
groupStd = std(subjectMean, 0, 'omitnan');
if ~isfinite(groupStd) || groupStd == 0
    zScore = zeros(size(subjectMean));
else
    zScore = (subjectMean - groupMean) ./ groupStd;
end

isOutlier = abs(zScore) > zThreshold;
outlierIDs = uniqueIDs(isOutlier);

statsTbl = table(uniqueIDs(:), subjectMean, zScore, subjectN, isOutlier, ...
    'VariableNames', {'ID','SubjectMean','ZScore','NRows','IsOutlier'});
end
