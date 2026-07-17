function taskTbl = prepare_fullmoon_pm_table(dataDir, datafile, task)
% prepare_fullmoon_pm_table Load and standardize full-moon PM data for one task.

if nargin < 1 || isempty(dataDir)
    dataDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
end
if nargin < 2 || isempty(datafile)
    datafile = 'FullMoonDataLong.csv';
end
if nargin < 3 || isempty(task)
    task = 'Perceptual';
end

dataTbl = readtable(fullfile(dataDir, datafile));
dataTbl = dataTbl(~isnan(dataTbl.Reported_Visual_Angle), :);
dataTbl = dataTbl(strcmp(dataTbl.Task, task), :);

requiredVars = {'ID','Real_Visual_Angle','Distance','Elevation','Reported_Visual_Angle','Ratio_Visual_Angle'};
for i = 1:numel(requiredVars)
    if ~ismember(requiredVars{i}, dataTbl.Properties.VariableNames)
        error('Missing required variable %s in %s.', requiredVars{i}, datafile);
    end
end

taskTbl = dataTbl(:, requiredVars);
taskTbl.Task = repmat({task}, height(taskTbl), 1);
taskTbl = movevars(taskTbl, 'Task', 'After', 'Elevation');
end
