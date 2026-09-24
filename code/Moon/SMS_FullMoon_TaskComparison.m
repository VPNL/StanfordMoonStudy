function SMS_FullMoon_TaskComparison(dataDir,datafile,ResultsDir,saveLME)
% SMS_FullMoon_TaskComparison
% (dataDir,datafile,ResultsDir)
% test if there is significant differences across tasks and individual
% subject variability in PM across tasks
% load data
cd(dataDir)
basename = [erase( datafile,'.csv')] ; % for saving
all_data=readtable(datafile);
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

% Make Perceptual the explicit reference task for all task coefficients.
all_data.Task = categorical(string(all_data.Task));
taskCategories = string(categories(all_data.Task));
requiredTasks = ["Perceptual", "Adjusted"];
if ~all(ismember(requiredTasks, taskCategories))
    error('FullMoon_TaskComparison:MissingTask', ...
        'Task must contain both Perceptual and Adjusted observations.');
end
% reorder tasks so Perceptual is a reference task
otherTasks = taskCategories(taskCategories ~= "Perceptual");
all_data.Task = reordercats(all_data.Task, cellstr(["Perceptual"; otherTasks]));


% test if there is a significant difference across tasks in log-log model coefficients 
all_data.logRatio=log2(all_data.Ratio_Visual_Angle);
all_data.logElevation=log2(all_data.Elevation+1);

lme_PM_by_Elevation_and_task = fitlme(all_data,'logRatio~logElevation*Task  + (1|ID)')
if saveLME % save stats table
     %% Paired test of each observer's mean PM across tasks
     uniqueID = unique(all_data.ID);
     perceptual = nan(numel(uniqueID), 1);
     adjusted = nan(numel(uniqueID), 1);
     for i = 1:numel(uniqueID)
         idRows = all_data.ID == uniqueID(i);
         idData = all_data(idRows, :);
         perceptualRows = strcmpi(string(idData.Task), 'Perceptual');
         adjustedRows = strcmpi(string(idData.Task), 'Adjusted');
         perceptual(i) = mean(idData.Ratio_Visual_Angle(perceptualRows), 'omitnan');
         adjusted(i) = mean(idData.Ratio_Visual_Angle(adjustedRows), 'omitnan');
     end
     validPairs = isfinite(perceptual) & isfinite(adjusted);
     perceptual = perceptual(validPairs);
     adjusted = adjusted(validPairs);
     [~, p, ~, stats] = ttest(perceptual, adjusted);
     meanPMTestLine = sprintf( ...
         ['Mean PM paired task test: Perceptual %.2f +/- %.2f, ' ...
         'Adjusted %.2f +/- %.2f, t(%d) = %.2f, p = %.2e'], ...
         mean(perceptual), std(perceptual), mean(adjusted), std(adjusted), ...
         stats.df, stats.tstat, p);
     fprintf('%s\n', meanPMTestLine);

     summaryLines = {
         'Model tests whether elevation effects differ across Perceptual and Adjusted tasks.'
         'Reference task: Perceptual'
         'Task coefficient: Adjusted relative to Perceptual'
         sprintf('Rows: %d', height(all_data))
         sprintf('Subjects: %d', numel(unique(all_data.ID)))
         sprintf('Paired observers in mean PM test: %d', numel(perceptual))
         meanPMTestLine
         };

     pmReportFile = fullfile(ResultsDir, ...
         [basename '_lme_moon_PM_by_task.txt']);
     write_moon_lme_report(pmReportFile, ...
         'Moon perceptual magnification by elevation and task', ...
         summaryLines, ...
         {lme_PM_by_Elevation_and_task}, ...
         {'Perceptual magnification model'}, ...
         {}, {});
end



