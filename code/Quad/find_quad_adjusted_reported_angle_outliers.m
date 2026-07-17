function [outlierIDs, summaryTbl, adjustedTbl] = find_quad_adjusted_reported_angle_outliers(csvFile, zThreshold)
% FIND_QUAD_ADJUSTED_REPORTED_ANGLE_OUTLIERS
% Identify subject outliers from the Adjusted-task Reported_Visual_Angle.
%
% [outlierIDs, summaryTbl, adjustedTbl] = find_quad_adjusted_reported_angle_outliers(csvFile, zThreshold)
%
% Inputs
%   csvFile    Path to a matching-data CSV file.
%   zThreshold Optional z-score threshold. Default is 3.
%
% Outputs
%   outlierIDs IDs whose subject mean Adjusted Reported_Visual_Angle is
%              farther than zThreshold standard deviations from the mean.
%   summaryTbl Per-subject summary table with means and z-scores.
%   adjustedTbl Adjusted-task subset used for the analysis.

if nargin < 2 || isempty(zThreshold)
    zThreshold = 3;
end

allTbl = readtable(csvFile);

requiredVars = {'ID', 'Task', 'Reported_Visual_Angle'};
missingVars = requiredVars(~ismember(requiredVars, allTbl.Properties.VariableNames));
if ~isempty(missingVars)
    error('Missing required variable(s): %s', strjoin(missingVars, ', '));
end

adjustedMask = strcmpi(string(allTbl.Task), "Adjusted");
adjustedTbl = allTbl(adjustedMask, :);
adjustedTbl = adjustedTbl(~isnan(adjustedTbl.Reported_Visual_Angle), :);

if isempty(adjustedTbl)
    outlierIDs = [];
    summaryTbl = table();
    warning('No non-NaN Adjusted-task rows found in %s.', csvFile);
    return;
end

[groupID, uniqueIDs] = findgroups(adjustedTbl.ID);
meanReported = splitapply(@mean, adjustedTbl.Reported_Visual_Angle, groupID);
nRows = splitapply(@numel, adjustedTbl.Reported_Visual_Angle, groupID);

grandMean = mean(meanReported, 'omitnan');
grandStd = std(meanReported, 0, 'omitnan');

if ~isfinite(grandStd) || grandStd == 0
    zScore = zeros(size(meanReported));
else
    zScore = (meanReported - grandMean) ./ grandStd;
end

isOutlier = abs(zScore) > zThreshold;

summaryTbl = table(uniqueIDs, meanReported, zScore, nRows, isOutlier, ...
    'VariableNames', {'ID', 'MeanReportedVisualAngle', 'ZScore', 'NRows', 'IsOutlier'});
summaryTbl = sortrows(summaryTbl, 'ZScore', 'descend');

outlierIDs = summaryTbl.ID(summaryTbl.IsOutlier);
end
