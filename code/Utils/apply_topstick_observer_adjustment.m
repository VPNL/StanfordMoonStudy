function [all_data, out_datafile] = apply_topstick_observer_adjustment(csvFile, dataDir, topstick, elevationVarName)
% APPLY_TOPSTICK_OBSERVER_ADJUSTMENT
% Shift stick elevations from stick center to stick top
% and save a new CSV with the '_topStick' suffix.
%
% Inputs
%   csvFile      : input quad CSV filename or full path
%   dataDir      : directory containing the quad CSV and destination output
%   topstick     : logical flag; when false, the original CSV is read and
%                  returned without modification
%   elevationVarName : name of the elevation column to modify
%                      default = 'Elevation'
%
% Outputs
%   all_data     : updated table (read from the output CSV when topstick=1)
%   out_datafile : path to the output CSV

if nargin < 3 || isempty(topstick)
    topstick = true;
end
if nargin < 4 || isempty(elevationVarName)
    elevationVarName = 'Elevation';
end
elevationVarName = char(string(elevationVarName));

if nargin < 2 || isempty(dataDir)
    error('apply_topstick_observer_adjustment:MissingDataDir', ...
        'You must provide dataDir.');
end

if nargin < 1 || isempty(csvFile)
    error('apply_topstick_observer_adjustment:MissingCsvFile', ...
        'You must provide csvFile.');
end

if exist(csvFile, 'file') == 2
    in_datafile = csvFile;
    [~, QuadBasename, ext] = fileparts(csvFile);
    if isempty(ext)
        ext = '.csv';
    end
else
    in_datafile = fullfile(dataDir, csvFile);
    [~, QuadBasename, ext] = fileparts(csvFile);
    if isempty(ext)
        ext = '.csv';
    end
end

if exist(in_datafile, 'file') ~= 2
    error('apply_topstick_observer_adjustment:MissingInputFile', ...
        'Could not find input CSV: %s', in_datafile);
end

all_data = readtable(in_datafile);
out_datafile = in_datafile;

if ~topstick
    return
end

requiredVars = {'Measurement', elevationVarName, 'Real_Visual_Angle'};
missingVars = requiredVars(~ismember(requiredVars, all_data.Properties.VariableNames));
if ~isempty(missingVars)
    error('apply_topstick_observer_adjustment:MissingVars', ...
        'Missing required variable(s): %s', strjoin(missingVars, ', '));
end

stick = contains(string(all_data.Measurement), 'Stick', 'IgnoreCase', true);

% Shift from stick center to the top of the stick in visual-angle units.
all_data.(elevationVarName)(stick) = ...
    all_data.(elevationVarName)(stick) + 0.5 * all_data.Real_Visual_Angle(stick);

out_datafile = fullfile(dataDir, [QuadBasename '_topStick' ext]);
writetable(all_data, out_datafile);

all_data = readtable(out_datafile);
