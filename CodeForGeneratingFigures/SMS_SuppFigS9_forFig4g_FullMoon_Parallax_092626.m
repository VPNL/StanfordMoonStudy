%% SMS_SuppFigS9_forFig4g_FullMoon_Parallax_092626
% Sensitivity analysis for Fig. 4g after applying Grubbs' test to each
% participant's mean adjusted-task perceptual magnification. Participants
% identified as outliers are removed from both tasks and all analyses.

set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

expDir = '/Users/kalanit/Projects/StanfordMoonStudy';
dataDir = fullfile(expDir, 'Data', 'MoonStudy');
datafile = 'Disparity_BothElevations_FullMoonDataLong090225.csv';
dataPath = fullfile(dataDir, datafile);
ResultsDir = fullfile(expDir, 'Figures', ...
    'SuppFig4g_FullMoon_Parallax_092626');
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir)
end

saveLME = true;
task = 'Perceptual';
outlierMethod = 'grubbs';

%% Identify adjusted-task participant-level PM outliers
allData = readtable(dataPath);
adjustedRows = strcmpi(string(allData.Task), 'Adjusted') & ...
    isfinite(allData.Ratio_Visual_Angle);
adjustedData = allData(adjustedRows, :);
adjustedParticipantMeans = groupsummary(adjustedData, 'ID', {'mean', 'max'}, ...
    'Ratio_Visual_Angle');
adjustedParticipantMeans.Properties.VariableNames{...
    strcmp(adjustedParticipantMeans.Properties.VariableNames, ...
    'mean_Ratio_Visual_Angle')} = 'MeanAdjustedPM';
adjustedParticipantMeans.Properties.VariableNames{...
    strcmp(adjustedParticipantMeans.Properties.VariableNames, ...
    'max_Ratio_Visual_Angle')} = 'MaxAdjustedPM';
adjustedParticipantMeans.Excluded = isoutlier( ...
    adjustedParticipantMeans.MeanAdjustedPM, outlierMethod);
excludedIDs = adjustedParticipantMeans.ID(adjustedParticipantMeans.Excluded);

fprintf(['Excluding %d participants identified by Grubbs'' test of ' ...
    'participant mean adjusted-task PM:\n'], numel(excludedIDs));
disp(adjustedParticipantMeans(adjustedParticipantMeans.Excluded, ...
    {'ID', 'MeanAdjustedPM', 'MaxAdjustedPM'}));

keepParticipant = ~ismember(string(allData.ID), string(excludedIDs));
filteredData = allData(keepParticipant, :);

%% Save the exclusion audit trail and filtered data
writetable(adjustedParticipantMeans, fullfile(ResultsDir, ...
    'adjusted_task_participant_mean_PM_outlier_check.csv'));
writetable(filteredData, fullfile(ResultsDir, ...
    'Disparity_BothElevations_FullMoonDataLong090225_without_adjusted_PM_outliers.csv'));

auditFile = fullfile(ResultsDir, ...
    'adjusted_task_PM_outlier_exclusions.txt');
fid = fopen(auditFile, 'w');
if fid < 0, error('Could not open exclusion report: %s', auditFile); end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'Supplemental Fig. 4g participant exclusion audit\n');
fprintf(fid, 'Source: %s\n', dataPath);
fprintf(fid, ['Criterion: MATLAB isoutlier applied to participant mean ' ...
    'adjusted-task PM using the Grubbs method (default alpha = 0.05)\n']);
fprintf(fid, 'Excluded participants: %d\n\n', numel(excludedIDs));
excludedTable = adjustedParticipantMeans(adjustedParticipantMeans.Excluded, ...
    {'ID', 'MeanAdjustedPM', 'MaxAdjustedPM'});
for iID = 1:height(excludedTable)
    fprintf(fid, ['ID %s: mean adjusted-task PM = %.6f, ' ...
        'maximum adjusted-task PM = %.6f\n'], ...
        char(string(excludedTable.ID(iID))), excludedTable.MeanAdjustedPM(iID), ...
        excludedTable.MaxAdjustedPM(iID));
end
fprintf(fid, '\nRows before exclusion: %d\n', height(allData));
fprintf(fid, 'Rows after exclusion: %d\n', height(filteredData));
fprintf(fid, 'Participants before exclusion: %d\n', ...
    numel(unique(string(allData.ID))));
fprintf(fid, 'Participants after exclusion: %d\n', ...
    numel(unique(string(filteredData.ID))));
clear cleanupObj

%% Repeat the complete Fig. 4g analysis on the filtered participant set
filteredSourceName = ...
    'FullMoon_without_adjusted_PM_outliers.csv';
[models, lme_PM_by_parallax_and_task, tablewithParallax, ...
    sorteduniqueIDD, figHandles] = ...
    FullMoon_Parallax(filteredData, filteredSourceName, task, ResultsDir, saveLME);

uniqueDate = unique(tablewithParallax.Date);
disp('dates'); disp(uniqueDate)
uniqueIDD = unique(tablewithParallax.ID);
fprintf('%d subjects retained for supplemental Full Moon parallax analysis\n', ...
    numel(uniqueIDD));

savefile = fullfile(ResultsDir, ...
    'FullMoon_without_adjusted_PM_outliers_Perceptual_analysed');
save(savefile)
