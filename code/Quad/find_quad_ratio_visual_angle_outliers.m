function [outlierIDs, summaryTbl, analysisTbl] = find_quad_ratio_visual_angle_outliers(csvFile, taskName, zThreshold)
% FIND_QUAD_RATIO_VISUAL_ANGLE_OUTLIERS
% Identify subject outliers from Ratio_Visual_Angle in a quad matching-data CSV.
%
% [outlierIDs, summaryTbl, analysisTbl] = find_quad_ratio_visual_angle_outliers(csvFile, taskName, zThreshold)
%
% Inputs
%   csvFile    Path to a matching-data CSV file.
%   taskName   Optional task filter, e.g. 'Adjusted' or 'Perceptual'.
%              Default is '' meaning use all tasks.
%   zThreshold Optional z-score threshold. Default is 3.
%
% Outputs
%   outlierIDs IDs whose subject mean Ratio_Visual_Angle is farther than
%              zThreshold standard deviations from the mean.
%   summaryTbl Per-subject summary table with means and z-scores.
%   analysisTbl Table subset used for the analysis.

if nargin < 2 || isempty(taskName)
    taskName = '';
end

if nargin < 3 || isempty(zThreshold)
    zThreshold = 3;
end

allTbl = readtable(csvFile);

requiredVars = {'ID', 'Ratio_Visual_Angle'};
missingVars = requiredVars(~ismember(requiredVars, allTbl.Properties.VariableNames));
if ~isempty(missingVars)
    error('Missing required variable(s): %s', strjoin(missingVars, ', '));
end

analysisTbl = allTbl;

if ~isempty(taskName)
    if ~ismember('Task', analysisTbl.Properties.VariableNames)
        error('Task variable is not present in %s.', csvFile);
    end
    taskMask = strcmpi(string(analysisTbl.Task), string(taskName));
    analysisTbl = analysisTbl(taskMask, :);
end

analysisTbl = analysisTbl(~isnan(analysisTbl.Ratio_Visual_Angle), :);

if isempty(analysisTbl)
    outlierIDs = [];
    summaryTbl = table();
    if isempty(taskName)
        warning('No non-NaN Ratio_Visual_Angle rows found in %s.', csvFile);
    else
        warning('No non-NaN Ratio_Visual_Angle rows found in %s for task %s.', csvFile, taskName);
    end
    return;
end

[groupID, uniqueIDs] = findgroups(analysisTbl.ID);
meanRatio = splitapply(@mean, analysisTbl.Ratio_Visual_Angle, groupID);
nRows = splitapply(@numel, analysisTbl.Ratio_Visual_Angle, groupID);

grandMean = mean(meanRatio, 'omitnan');
grandStd = std(meanRatio, 0, 'omitnan');

if ~isfinite(grandStd) || grandStd == 0
    zScore = zeros(size(meanRatio));
else
    zScore = (meanRatio - grandMean) ./ grandStd;
end

isOutlier = abs(zScore) > zThreshold;

summaryTbl = table(uniqueIDs, meanRatio, zScore, nRows, isOutlier, ...
    'VariableNames', {'ID', 'MeanRatioVisualAngle', 'ZScore', 'NRows', 'IsOutlier'});
summaryTbl = sortrows(summaryTbl, 'ZScore', 'descend');

outlierIDs = summaryTbl.ID(summaryTbl.IsOutlier);
end
