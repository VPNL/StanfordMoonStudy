function data = FullMoon_Parallax_prepare_table(dataOrDir, datafile)
% FullMoon_Parallax_prepare_table Read/validate moon data and add parallax.

if istable(dataOrDir)
    data = dataOrDir;
elseif isfile(dataOrDir)
    data = readtable(dataOrDir);
else
    if nargin < 2 || isempty(datafile)
        error('Provide a table or data directory and filename.');
    end
    dataPath = fullfile(dataOrDir, datafile);
    if isfile(datafile)
        dataPath = datafile;
    elseif ~isfile(dataPath) && isfile([dataPath '.csv'])
        dataPath = [dataPath '.csv'];
    end
    if ~isfile(dataPath)
        error('Could not find input table: %s', dataPath);
    end
    data = readtable(dataPath);
end

required = {'ID','Task','Ratio_Visual_Angle','Elevation', ...
    'Disparity_VA','Real_Visual_Angle'};
missing = setdiff(required, data.Properties.VariableNames);
if ~isempty(missing)
    error('Input table is missing required variable(s): %s', strjoin(missing, ', '));
end

data.PerceivedParallax = data.Disparity_VA - data.Real_Visual_Angle;
keep = isfinite(data.Ratio_Visual_Angle) & data.Ratio_Visual_Angle > 0 & ...
    isfinite(data.Elevation) & isfinite(data.PerceivedParallax);
data = data(keep, :);
data.ID = categorical(data.ID);

taskText = string(data.Task);
data.Task = categorical(taskText);
if all(ismember(["Perceptual","Adjusted"], string(categories(data.Task))))
    data.Task = reordercats(data.Task, {'Perceptual','Adjusted'});
end
end
