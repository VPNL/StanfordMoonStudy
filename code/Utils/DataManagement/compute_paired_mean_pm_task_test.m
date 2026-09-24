function PMsummary = compute_paired_mean_pm_task_test(tbl)
%COMPUTE_PAIRED_MEAN_PM_TASK_TEST Compare participant mean PM across tasks.
%
% PMsummary = compute_paired_mean_pm_task_test(tbl) computes each
% participant's mean Ratio_Visual_Angle separately for Perceptual and
% Adjusted tasks and performs a paired t-test across participants.
% Participants without finite means in both tasks are excluded.

requiredVars = {'ID', 'Task', 'Ratio_Visual_Angle'};
missingVars = setdiff(requiredVars, tbl.Properties.VariableNames);
if ~isempty(missingVars)
    error('PairedMeanPMTaskTest:MissingVariables', ...
        'tbl is missing required variable(s): %s', strjoin(missingVars, ', '));
end

PMsummary = struct('Available', false, 'NPairs', 0, ...
    'MeanPerceptual', NaN, 'SDPerceptual', NaN, ...
    'MeanAdjusted', NaN, 'SDAdjusted', NaN, ...
    'TStat', NaN, 'DF', NaN, 'PValue', NaN, ...
    'ReportLine', '');

taskValues = string(tbl.Task);
if ~any(strcmpi(taskValues, 'Perceptual')) || ...
        ~any(strcmpi(taskValues, 'Adjusted'))
    PMsummary.ReportLine = ['Mean PM paired task test: not run ' ...
        '(input table must contain both Perceptual and Adjusted tasks).'];
    return;
end

participantIDs = unique(string(tbl.ID), 'stable');
perceptual = nan(numel(participantIDs), 1);
adjusted = nan(numel(participantIDs), 1);
rowIDs = string(tbl.ID);
for participantIdx = 1:numel(participantIDs)
    participantRows = rowIDs == participantIDs(participantIdx);
    perceptualRows = participantRows & strcmpi(taskValues, 'Perceptual');
    adjustedRows = participantRows & strcmpi(taskValues, 'Adjusted');
    perceptual(participantIdx) = mean( ...
        tbl.Ratio_Visual_Angle(perceptualRows), 'omitnan');
    adjusted(participantIdx) = mean( ...
        tbl.Ratio_Visual_Angle(adjustedRows), 'omitnan');
end

validPairs = isfinite(perceptual) & isfinite(adjusted);
perceptual = perceptual(validPairs);
adjusted = adjusted(validPairs);
PMsummary.NPairs = numel(perceptual);
if PMsummary.NPairs < 2
    PMsummary.ReportLine = sprintf([ ...
        'Mean PM paired task test: not run ' ...
        '(only %d participant had finite means in both tasks).'], ...
        PMsummary.NPairs);
    return;
end

[~, PMsummary.PValue, ~, stats] = ttest(perceptual, adjusted);
PMsummary.Available = true;
PMsummary.MeanPerceptual = mean(perceptual);
PMsummary.SDPerceptual = std(perceptual);
PMsummary.MeanAdjusted = mean(adjusted);
PMsummary.SDAdjusted = std(adjusted);
PMsummary.TStat = stats.tstat;
PMsummary.DF = stats.df;
PMsummary.ReportLine = sprintf( ...
    ['Mean PM paired task test: Perceptual %.2f +/- %.2f, ' ...
    'Adjusted %.2f +/- %.2f, t(%d) = %.2f, p = %.2e'], ...
    PMsummary.MeanPerceptual, PMsummary.SDPerceptual, ...
    PMsummary.MeanAdjusted, PMsummary.SDAdjusted, ...
    PMsummary.DF, PMsummary.TStat, PMsummary.PValue);
end
