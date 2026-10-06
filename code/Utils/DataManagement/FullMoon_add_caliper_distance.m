function [ParallaxFile, parallaxTable] = FullMoon_add_caliper_distance( ...
    RawDataFile, disparityFile, ParallaxFile)
% FULLMOON_ADD_CALIPER_DISTANCE Add session-specific caliper distances.
%
% [ParallaxFile, parallaxTable] = FullMoon_add_caliper_distance( ...
%     RawDataFile, disparityFile, ParallaxFile)
%
% Lower disparity rows receive "Lower Elevation Disparity Arm Length (cm)"
% and Higher disparity rows receive the corresponding Higher column. Rows
% are matched by participant ID. The output otherwise preserves the
% disparity table and its row order.

arguments
    RawDataFile (1,1) string
    disparityFile (1,1) string
    ParallaxFile (1,1) string = ""
end

if ~isfile(RawDataFile)
    error('FullMoon_add_caliper_distance:MissingRawData', ...
        'Raw-data CSV does not exist: %s', RawDataFile);
end
if ~isfile(disparityFile)
    error('FullMoon_add_caliper_distance:MissingDisparityData', ...
        'Disparity CSV does not exist: %s', disparityFile);
end
if strlength(ParallaxFile) == 0
    [folder, name] = fileparts(disparityFile);
    ParallaxFile = fullfile(folder, name + "_with_caliper_distance.csv");
end

rawTable = readtable(RawDataFile, 'VariableNamingRule', 'preserve');
parallaxTable = readtable(disparityFile, 'VariableNamingRule', 'preserve');

rawIDName = 'ID Number';
if ~ismember(rawIDName, rawTable.Properties.VariableNames)
    error('FullMoon_add_caliper_distance:MissingRawVariables', ...
        'Raw-data CSV is missing: %s.', rawIDName);
end
lowerName = local_find_variable(rawTable, { ...
    'Lower Elevation Disparity Arm Length (cm)', ...
    'Round 1 Caliper Distance (cm)'}, 'lower-elevation caliper distance');
higherName = local_find_variable(rawTable, { ...
    'Higher Elevation Disparity Arm Length (cm)', ...
    'Round 2 Caliper Distance (cm)'}, 'higher-elevation caliper distance');
requiredDisparity = {'ID', 'Session'};
missingDisparity = requiredDisparity( ...
    ~ismember(requiredDisparity, parallaxTable.Properties.VariableNames));
if ~isempty(missingDisparity)
    error('FullMoon_add_caliper_distance:MissingDisparityVariables', ...
        'Disparity CSV is missing: %s.', strjoin(missingDisparity, ', '));
end

rawIDs = local_normalize_ids(rawTable.(rawIDName));
disparityIDs = local_normalize_ids(parallaxTable.ID);
sessions = lower(strtrim(string(parallaxTable.Session)));
hasTime = ismember('Time', rawTable.Properties.VariableNames) && ...
    ismember('Time', parallaxTable.Properties.VariableNames);
if hasTime
    rawTimes = string(rawTable.Time);
    disparityTimes = string(parallaxTable.Time);
end
caliperDistance = nan(height(parallaxTable), 1);

for iRow = 1:height(parallaxTable)
    rawRows = rawIDs == disparityIDs(iRow) & rawIDs ~= "" & ...
        ~ismissing(rawIDs);
    if ~any(rawRows)
        error('FullMoon_add_caliper_distance:UnmatchedID', ...
            'ID %s in disparity row %d was not found in the raw data.', ...
            disparityIDs(iRow), iRow);
    end
    if nnz(rawRows) > 1 && hasTime
        timeRows = rawRows & rawTimes == disparityTimes(iRow);
        if any(timeRows)
            rawRows = timeRows;
        end
    end
    switch sessions(iRow)
        case "lower"
            sourceValues = local_numeric(rawTable.(lowerName)(rawRows));
        case "higher"
            sourceValues = local_numeric(rawTable.(higherName)(rawRows));
        otherwise
            error('FullMoon_add_caliper_distance:UnknownSession', ...
                'Session "%s" in disparity row %d is not Lower or Higher.', ...
                string(parallaxTable.Session(iRow)), iRow);
    end
    sourceValues = unique(sourceValues(isfinite(sourceValues)));
    if isempty(sourceValues)
        error('FullMoon_add_caliper_distance:MissingCaliperDistance', ...
            'No caliper distance was found for ID %s, session %s.', ...
            disparityIDs(iRow), sessions(iRow));
    elseif numel(sourceValues) > 1
        error('FullMoon_add_caliper_distance:ConflictingCaliperDistance', ...
            ['Raw data contain conflicting caliper distances for ID %s, ' ...
             'session %s: %s.'], disparityIDs(iRow), sessions(iRow), ...
            strjoin(string(sourceValues), ', '));
    end
    caliperDistance(iRow) = sourceValues;
end

parallaxTable.Caliper_Distance = caliperDistance;
outputFolder = fileparts(ParallaxFile);
if strlength(outputFolder) > 0 && ~isfolder(outputFolder)
    mkdir(outputFolder);
end
writetable(parallaxTable, ParallaxFile);
fprintf('Wrote %d rows with Caliper_Distance to %s\n', ...
    height(parallaxTable), ParallaxFile);
end

function ids = local_normalize_ids(values)
if isnumeric(values)
    ids = string(values);
else
    ids = strtrim(string(values));
end
ids(ismissing(ids)) = "";
ids = regexprep(ids, '\.0+$', '');
end

function values = local_numeric(values)
if isnumeric(values)
    values = double(values);
else
    values = str2double(strtrim(string(values)));
end
end

function variableName = local_find_variable(tbl, candidates, description)
found = candidates(ismember(candidates, tbl.Properties.VariableNames));
if isempty(found)
    error('FullMoon_add_caliper_distance:MissingRawVariables', ...
        'Raw-data CSV has no recognized %s column. Expected one of: %s.', ...
        description, strjoin(candidates, ', '));
end
variableName = found{1};
end
