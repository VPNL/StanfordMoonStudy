function tableSubset = quadFilterDisparityOutliers(tableSubset, transformId, ...
    removeOutlierParticipants, removeZScoreOutliers, zScoreThreshold, ...
    resultsDir, outputBaseName)
%QUADFILTERDISPARITYOUTLIERS Optionally remove and report disparity outliers.

if ~removeZScoreOutliers
    return;
end

preparedTable = Quad_prepare_perceived_disparity_table( ...
    tableSubset, transformId, removeOutlierParticipants);
[outlierIDs, outlierStats] = find_subject_outliers_by_zscore( ...
    preparedTable, 'MeanDisparity', 'ID', zScoreThreshold);

if isempty(outlierIDs)
    fprintf('No z-score outlier IDs for %s at threshold %.2f.\n', ...
        outputBaseName, zScoreThreshold);
else
    fprintf('Removing z-score outlier IDs for %s: %s\n', ...
        outputBaseName, strjoin(cellstr(outlierIDs), ', '));
    keepRows = ~ismember(string(tableSubset.ID), string(outlierIDs));
    tableSubset = tableSubset(keepRows, :);
end

writetable(outlierStats, fullfile(resultsDir, ...
    [outputBaseName '_outlier_zscores.csv']));

reportFile = fullfile(resultsDir, [outputBaseName '_outlier_IDs.txt']);
fileID = fopen(reportFile, 'w');
if fileID < 0
    warning('QuadDisparity:OutlierReportNotWritten', ...
        'Could not open outlier report for writing: %s', reportFile);
    return;
end
cleanupObj = onCleanup(@() fclose(fileID));

if isempty(outlierIDs)
    fprintf(fileID, 'No outlier IDs removed.\n');
else
    fprintf(fileID, 'Removed outlier IDs (|z| > %.2f):\n', zScoreThreshold);
    for outlierIdx = 1:numel(outlierIDs)
        fprintf(fileID, '%s\n', outlierIDs(outlierIdx));
    end
end
end
