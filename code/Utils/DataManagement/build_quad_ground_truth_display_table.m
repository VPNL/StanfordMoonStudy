function [summaryTbl, displayTbl] = build_quad_ground_truth_display_table(matchingCsv, outFile, ObserverFlag, includeGroundDistanceColumn) %#ok<INUSD>
% build_quad_ground_truth_display_table
%
% Build a quad ground-truth summary table like the supplementary-table
% layout, using:
%   1) the matching-data CSV for elevation values
%   2) the standard quad ground-truth CSV for object names, sizes,
%      distances, and angles
%
% Example
%   [summaryTbl, displayTbl] = build_quad_ground_truth_display_table( ...
%       '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/MatchingData0318_topStick.csv', ...
%       '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/QuadGroundTruthDisplayTable.xlsx', ...
%       1);

if nargin < 1 || isempty(matchingCsv)
    error('matchingCsv is required.');
end
if nargin < 2
    outFile = '';
end
if nargin < 3 || isempty(ObserverFlag)
    ObserverFlag = 0;
end
matchTbl = readtable(matchingCsv, 'TextType', 'string');
[matchDir,~,~] = fileparts(matchingCsv);
groundTruthCsv = fullfile(matchDir, 'Ground Truth Information.csv');
if ~exist(groundTruthCsv, 'file')
    error('Could not find ground truth file: %s', groundTruthCsv);
end
gtTbl = readtable(groundTruthCsv, 'TextType', 'string', 'VariableNamingRule', 'preserve');

if ObserverFlag
    distanceVar = 'Observer_Distance';
    elevationVar='Observer_Elevation';
    distanceLabel = 'Observer_Distance_m';
    elevationLabel = 'Observer_Elevation_degrees';
else
    distanceVar = 'Ground_Distance';
    elevationVar= 'Ground_Elevation';
    distanceLabel = 'Matched_Ground_Distance_m';
    elevationLabel = 'Ground_Elevation_degrees';
end

requiredMatchVars = {'ID','Measurement','Version',distanceVar,elevationVar};
for iVar = 1:numel(requiredMatchVars)
    if ~ismember(requiredMatchVars{iVar}, matchTbl.Properties.VariableNames)
        error('Matching table is missing required variable "%s".', requiredMatchVars{iVar});
    end
end

matchTbl.MeasurementBase = local_extract_measurement_base(matchTbl.Measurement);
matchTbl.MeasurementKey = local_normalize_measurement_key(matchTbl.MeasurementBase);
matchTbl.VersionResolved = local_resolve_version(matchTbl);

allowedMeasurementKeys = [ ...
    "LAMP1","LAMP2","LAMP3","LAMP4","LAMP5","LAMP6","LAMP7", ...
    "LAMP1A","LAMP2A","LAMP3A","LAMP4A", ...
    "STICK1","STICK2","STICK3","STICK4","STICK1A","STICK2A","STICK3A","STICK4A", ...
    "STICK5B","STICK7","STICK8","STICK9","STICK9A","STICK10", "BLUEBALL", ...
    "MOON1","MOON2","MOON3","MOON4","SPIKEBALL"];
local_check_missing_measurements(matchTbl.MeasurementKey, allowedMeasurementKeys);

elevSummary = groupsummary(matchTbl, {'VersionResolved','MeasurementKey'}, 'mean', elevationVar);
elevSummary = renamevars(elevSummary, ['mean_' elevationVar], 'Elevation_degrees');

distSummary = groupsummary(matchTbl, {'VersionResolved','MeasurementKey'}, 'mean', distanceVar);
distSummary = renamevars(distSummary, ['mean_' distanceVar], 'Distance_source');

elevSummary = outerjoin(elevSummary, distSummary(:, {'VersionResolved','MeasurementKey','Distance_source'}), ...
    'Keys', {'VersionResolved','MeasurementKey'}, 'MergeKeys', true);

participantSummary = local_participant_count_summary(matchTbl);
elevSummary = outerjoin(elevSummary, participantSummary, ...
    'Keys', {'VersionResolved','MeasurementKey'}, 'MergeKeys', true);
elevSummary = removevars(elevSummary, 'GroupCount');

gtObjectCol = gtTbl{:,1};
gtVarCol = gtTbl{:,2};
gtSizeCol = gtTbl{:,3};
gtDistanceCol = gtTbl{:,4};
gtAngleCol = gtTbl{:,5};

gtObjectCol = string(gtObjectCol(:));
gtVarCol = string(gtVarCol(:));
gtSizeCol = string(gtSizeCol(:));
gtDistanceCol = string(gtDistanceCol(:));
gtAngleCol = string(gtAngleCol(:));

validGT = strlength(strtrim(gtObjectCol)) > 0 & strlength(strtrim(gtVarCol)) > 0;
gtParsed = table( ...
    strtrim(gtObjectCol(validGT)), ...
    local_normalize_measurement_key(strtrim(gtVarCol(validGT))), ...
    str2double(gtSizeCol(validGT)), ...
    str2double(gtDistanceCol(validGT)), ...
    str2double(gtAngleCol(validGT)), ...
    'VariableNames', {'Object','MeasurementKey','Diameter_Height_m','Distance_m','Visual_angle_degrees'});
gtParsed = local_apply_ground_truth_aliases(gtParsed);
isQuadObject = ismember(gtParsed.MeasurementKey, allowedMeasurementKeys);
gtParsed = gtParsed(isQuadObject, :);
isMoonBall = startsWith(gtParsed.MeasurementKey, "MOON");
for iRow = find(isMoonBall').'
    suffix = erase(gtParsed.MeasurementKey(iRow), "MOON");
    gtParsed.Object(iRow) = "Inflatable moon ball " + suffix;
end
gtParsed.VersionResolved = local_infer_version_from_key(gtParsed.MeasurementKey);
gtParsed.SortIndex = local_sort_index(gtParsed.VersionResolved, gtParsed.MeasurementKey);
missingGroundTruthTbl = local_missing_ground_truth_entries(matchTbl, gtParsed);

summaryTbl = outerjoin(gtParsed, elevSummary, ...
    'Keys', {'VersionResolved','MeasurementKey'}, 'MergeKeys', true, 'Type', 'full');
summaryKeys = local_join_version_measurement_key(summaryTbl.VersionResolved, summaryTbl.MeasurementKey);
gtKeys = local_join_version_measurement_key(gtParsed.VersionResolved, gtParsed.MeasurementKey);
hasGroundTruthData = ismember(summaryKeys, gtKeys);
missingObject = ismissing(summaryTbl.Object) | strlength(strtrim(string(summaryTbl.Object))) == 0;
summaryTbl.Object(missingObject) = local_default_object_name(summaryTbl.MeasurementKey(missingObject));
[summaryTbl, sortIdx] = sortrows(summaryTbl, {'VersionResolved','SortIndex'});
hasGroundTruthData = hasGroundTruthData(sortIdx);
hasSubjectData = ~isnan(summaryTbl.Elevation_degrees);
missingSubjectKeys = unique(summaryTbl.MeasurementKey(~hasSubjectData & hasGroundTruthData));
missingSubjectKeys = missingSubjectKeys(strlength(missingSubjectKeys) > 0);
if ~isempty(missingSubjectKeys)
    warning('Dropping measurement(s) with no subject data in matching table: %s', ...
        strjoin(cellstr(missingSubjectKeys), ', '));
end
summaryTbl = summaryTbl(hasSubjectData & hasGroundTruthData, :);
summaryTblWithSort = summaryTbl;
summaryTbl = removevars(summaryTbl, {'SortIndex'});
summaryTbl = renamevars(summaryTbl, 'Distance_m', 'Ground_Distance_m');
distanceFromMatching = summaryTbl.Distance_source / 100;
summaryTbl.Selected_Distance_m = summaryTbl.Ground_Distance_m;
distanceAvailable = ~isnan(distanceFromMatching);
summaryTbl.Selected_Distance_m(distanceAvailable) = distanceFromMatching(distanceAvailable);
summaryTbl = removevars(summaryTbl, 'Distance_source');
summaryTbl = renamevars(summaryTbl, 'VersionResolved', 'Version');

displayRows = {};
versionOrder = [1 2 3];
asteriskKeys = ["STICK1A","STICK2A","STICK3A","STICK4A"];
for iVersion = 1:numel(versionOrder)
    thisVersion = versionOrder(iVersion);
    thisTbl = summaryTbl(summaryTbl.Version == thisVersion, :);
    thisTbl = thisTbl(~ismember(thisTbl.MeasurementKey, asteriskKeys), :);
    if isempty(thisTbl)
        continue;
    end

    displayRows(end+1,:) = local_make_display_row(sprintf('Version %d', thisVersion), '', '', '', '', '', ''); %#ok<AGROW>
    for iRow = 1:height(thisTbl)
        displayRows(end+1,:) = local_make_display_row( ...
            '', ...
            char(thisTbl.Object(iRow)), ...
            sprintf('%.4f', thisTbl.Diameter_Height_m(iRow)), ...
            sprintf('%.4f', thisTbl.Visual_angle_degrees(iRow)), ...
            sprintf('%.2f', thisTbl.Selected_Distance_m(iRow)), ...
            sprintf('%.4f', thisTbl.Elevation_degrees(iRow)), ...
            sprintf('%d', thisTbl.N_Participants(iRow))); %#ok<AGROW>
    end
    if iVersion < numel(versionOrder)
        displayRows(end+1,:) = local_make_display_row('', '', '', '', '', '', ''); %#ok<AGROW>
    end
end

asteriskTbl = summaryTblWithSort(ismember(summaryTblWithSort.MeasurementKey, asteriskKeys), :);
if ~isempty(asteriskTbl)
    asteriskTbl = sortrows(asteriskTbl, {'VersionResolved','SortIndex'});
    asteriskTbl = removevars(asteriskTbl, {'SortIndex'});
    asteriskTbl = renamevars(asteriskTbl, 'Distance_m', 'Ground_Distance_m');
    asteriskDistanceFromMatching = asteriskTbl.Distance_source / 100;
    asteriskTbl.Selected_Distance_m = asteriskTbl.Ground_Distance_m;
    asteriskAvailable = ~isnan(asteriskDistanceFromMatching);
    asteriskTbl.Selected_Distance_m(asteriskAvailable) = asteriskDistanceFromMatching(asteriskAvailable);
    displayRows(end+1,:) = local_make_display_row('* one participant was run on lamp bulbs 1a-4a and lamp posts 1a-4a', '', '', '', '', '', '');
    for iRow = 1:height(asteriskTbl)
        displayRows(end+1,:) = local_make_display_row( ...
            '', ...
            char(asteriskTbl.Object(iRow)), ...
            sprintf('%.4f', asteriskTbl.Diameter_Height_m(iRow)), ...
            sprintf('%.4f', asteriskTbl.Visual_angle_degrees(iRow)), ...
            sprintf('%.2f', asteriskTbl.Selected_Distance_m(iRow)), ...
            sprintf('%.4f', asteriskTbl.Elevation_degrees(iRow)), ...
            sprintf('%d', asteriskTbl.N_Participants(iRow))); %#ok<AGROW>
    end
end

if ~isempty(missingGroundTruthTbl)
    displayRows(end+1,:) = local_make_display_row('', '', '', '', '', '', '');
    displayRows(end+1,:) = local_make_display_row('Entries missing from Ground Truth Information.csv', '', '', '', '', '', '');
    for iRow = 1:height(missingGroundTruthTbl)
        displayRows(end+1,:) = local_make_display_row( ...
            sprintf('Version %g', missingGroundTruthTbl.VersionResolved(iRow)), ...
            sprintf('MeasurementKey: %s', char(missingGroundTruthTbl.MeasurementKey(iRow))), ...
            sprintf('IDs: %s', char(missingGroundTruthTbl.IDs(iRow))), ...
            sprintf('Entries: %s', char(missingGroundTruthTbl.MeasurementEntries(iRow))), ...
            sprintf('N entries: %d', missingGroundTruthTbl.N_Entries(iRow)), ...
            '', ...
            sprintf('%d', missingGroundTruthTbl.N_Participants(iRow))); %#ok<AGROW>
    end
end

headerNames = local_header_names(distanceLabel, elevationLabel);
displayTbl = cell2table(displayRows, 'VariableNames', headerNames);

if ~isempty(outFile)
    [outDir,~,ext] = fileparts(outFile);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    headerRow = headerNames;
    exportCell = [headerRow; displayRows];
    switch lower(ext)
        case '.csv'
            local_write_delimited_cell(exportCell, outFile);
        otherwise
            try
                xlswrite(outFile, exportCell);
            catch
                fallbackCsv = fullfile(outDir, [erase(string(outFile), ext) '.csv']);
                local_write_delimited_cell(exportCell, char(fallbackCsv));
                warning('Spreadsheet export failed. Wrote CSV instead: %s', fallbackCsv);
            end
    end
end

end

function row = local_make_display_row(versionTxt, objectTxt, diameterTxt, visualAngleTxt, selectedDistanceTxt, elevationTxt, nParticipantsTxt)
row = {versionTxt, objectTxt, diameterTxt, visualAngleTxt, selectedDistanceTxt, elevationTxt, nParticipantsTxt};
end

function names = local_header_names(distanceLabel, elevationLabel)
names = {'Version','Object','Diameter_Height_m','Visual_angle_degrees',distanceLabel,elevationLabel,'N_Participants'};
end

function local_write_delimited_cell(cellData, outFile)
fid = fopen(outFile, 'w');
if fid == -1
    error('Could not open file for writing: %s', outFile);
end
cleanupObj = onCleanup(@() fclose(fid));
for iRow = 1:size(cellData,1)
    row = cellData(iRow,:);
    rowText = cellfun(@local_cell_to_csv_text, row, 'UniformOutput', false);
    fprintf(fid, '%s\n', strjoin(rowText, ','));
end
end

function txt = local_cell_to_csv_text(value)
if isempty(value)
    txt = '';
    return
end
if isstring(value)
    if numel(value) == 0 || strlength(value) == 0
        txt = '';
        return
    end
    txt = char(value);
elseif ischar(value)
    txt = value;
elseif isnumeric(value)
    txt = num2str(value);
else
    txt = char(string(value));
end
txt = strrep(txt, '"', '""');
if contains(txt, ',') || contains(txt, '"') || contains(txt, newline)
    txt = ['"' txt '"'];
end
end

function participantSummary = local_participant_count_summary(matchTbl)
[groupIdx, keyTbl] = findgroups(matchTbl(:, {'VersionResolved','MeasurementKey'}));
nParticipants = splitapply(@local_count_unique_ids, matchTbl.ID, groupIdx);
participantSummary = [keyTbl table(nParticipants, 'VariableNames', {'N_Participants'})];
end

function n = local_count_unique_ids(ids)
if isnumeric(ids)
    ids = ids(~isnan(ids));
elseif iscategorical(ids)
    ids = ids(~isundefined(ids));
end

ids = strtrim(string(ids(:)));
ids = ids(~ismissing(ids) & strlength(ids) > 0 & lower(ids) ~= "nan");
n = numel(unique(ids));
end

function measurementBase = local_extract_measurement_base(measurementNames)
measurementBase = string(measurementNames);
for i = 1:numel(measurementBase)
    parts = split(measurementBase(i), "_");
    measurementBase(i) = strtrim(parts(1));
end
end

function key = local_normalize_measurement_key(values)
key = upper(strtrim(string(values)));
key = replace(key, "MOONBALL", "MOON");
end

function gtParsed = local_apply_ground_truth_aliases(gtParsed)
objectStr = lower(strtrim(string(gtParsed.Object)));

isStick9a = contains(objectStr, "lamp post 9a");
gtParsed.MeasurementKey(isStick9a) = "STICK9A";

aliasRows = gtParsed([], :);

idxSpike = find(gtParsed.MeasurementKey == "SPIKEBALL");
if ~isempty(idxSpike)
    blueRows = gtParsed(idxSpike, :);
    blueRows.MeasurementKey(:) = "BLUEBALL";
    blueRows.Object(:) = "Blue ball";
    aliasRows = [aliasRows; blueRows];
end

idxStick5b = find(gtParsed.MeasurementKey == "STICK5B");
if ~isempty(idxStick5b)
    stick10Rows = gtParsed(idxStick5b, :);
    stick10Rows.MeasurementKey(:) = "STICK10";
    stick10Rows.Object(:) = "Lamp post 10";
    aliasRows = [aliasRows; stick10Rows];
end

gtParsed = [gtParsed; aliasRows];
end

function objectName = local_default_object_name(measurementKey)
measurementKey = upper(string(measurementKey));
objectName = strings(size(measurementKey));
for i = 1:numel(measurementKey)
    key = measurementKey(i);
    if startsWith(key, "LAMP")
        suffix = erase(key, "LAMP");
        objectName(i) = "Lamp bulb " + lower(suffix);
    elseif startsWith(key, "STICK")
        suffix = erase(key, "STICK");
        objectName(i) = "Lamp post " + lower(suffix);
    elseif startsWith(key, "MOON")
        suffix = erase(key, "MOON");
        objectName(i) = "Inflatable moon ball " + suffix;
    elseif key == "BLUEBALL"
        objectName(i) = "Blue ball";
    elseif key == "SPIKEBALL"
        objectName(i) = "Inflatable spike ball";
    else
        objectName(i) = key;
    end
end
end

function local_check_missing_measurements(measurementKeys, allowedMeasurementKeys)
measurementKeys = unique(upper(strtrim(string(measurementKeys))));
measurementKeys = measurementKeys(strlength(measurementKeys) > 0);
missingKeys = setdiff(measurementKeys, allowedMeasurementKeys);
if ~isempty(missingKeys)
    warning('Measurement(s) in matching table missing from isQuadObject allow-list: %s', ...
        strjoin(cellstr(missingKeys), ', '));
end
end

function missingTbl = local_missing_ground_truth_entries(matchTbl, gtParsed)
missingTbl = table();
if isempty(matchTbl) || isempty(gtParsed)
    return
end

gtKeys = local_join_version_measurement_key(gtParsed.VersionResolved, gtParsed.MeasurementKey);
matchKeys = local_join_version_measurement_key(matchTbl.VersionResolved, matchTbl.MeasurementKey);
missingMask = ~ismember(matchKeys, gtKeys);
if ~any(missingMask)
    return
end

missingRows = matchTbl(missingMask, :);
[groupIdx, keyTbl] = findgroups(missingRows(:, {'VersionResolved','MeasurementKey'}));
ids = splitapply(@local_join_unique_values, missingRows.ID, groupIdx);
measurementEntries = splitapply(@local_join_unique_values, missingRows.Measurement, groupIdx);
nEntries = splitapply(@numel, missingRows.Measurement, groupIdx);
nParticipants = splitapply(@local_count_unique_ids, missingRows.ID, groupIdx);

missingTbl = [keyTbl table(ids, measurementEntries, nEntries, nParticipants, ...
    'VariableNames', {'IDs','MeasurementEntries','N_Entries','N_Participants'})];
missingTbl = sortrows(missingTbl, {'VersionResolved','MeasurementKey'});

warning('Found %d matching-data measurement group(s) absent from Ground Truth Information.csv.', height(missingTbl));
end

function keys = local_join_version_measurement_key(versionValues, measurementKeys)
keys = string(versionValues(:)) + "|" + upper(strtrim(string(measurementKeys(:))));
end

function joined = local_join_unique_values(values)
values = strtrim(string(values(:)));
values = values(~ismissing(values) & strlength(values) > 0 & lower(values) ~= "nan");
values = unique(values, 'stable');
if isempty(values)
    joined = "";
else
    joined = strjoin(values, '; ');
end
end

function versionResolved = local_resolve_version(matchTbl)
versionResolved = nan(height(matchTbl),1);
if ismember('Version', matchTbl.Properties.VariableNames)
    versionRaw = str2double(string(matchTbl.Version));
    valid = ~isnan(versionRaw);
    versionResolved(valid) = versionRaw(valid);
end

for i = 1:height(matchTbl)
    if isnan(versionResolved(i))
        versionResolved(i) = local_infer_version_from_key(matchTbl.MeasurementKey(i));
    end
end
end

function version = local_infer_version_from_key(measurementKey)
measurementKey = upper(string(measurementKey));
version = nan(size(measurementKey));

isVersion1 = ismember(measurementKey, ["LAMP1","LAMP2","LAMP3","LAMP4","STICK1","STICK2","STICK3","STICK4"]);
isVersion2 = ismember(measurementKey, ["LAMP1A","LAMP2A","LAMP3A","LAMP4A","MOON1","MOON2","MOON3","MOON4","STICK1A","STICK2A","STICK3A","STICK4A"]);
isVersion3 = ismember(measurementKey, ["BLUEBALL","SPIKEBALL","LAMP5","LAMP6","LAMP7","STICK5B","STICK7","STICK8","STICK9","STICK9A","STICK10"]);

version(isVersion1) = 1;
version(isVersion2) = 2;
version(isVersion3) = 3;

if any(isnan(version))
    badKeys = unique(measurementKey(isnan(version)));
    error('Could not infer version for measurement key(s): %s', strjoin(cellstr(badKeys), ', '));
end
end

function idx = local_sort_index(versionVec, keyVec)
idx = nan(numel(versionVec),1);
for i = 1:numel(versionVec)
    idx(i) = local_single_sort_index(versionVec(i), keyVec(i));
end
end

function idx = local_single_sort_index(versionVal, measurementKey)
measurementKey = upper(string(measurementKey));
switch versionVal
    case 1
        order = ["LAMP1","LAMP2","LAMP3","LAMP4","STICK1","STICK2","STICK3","STICK4"];
    case 2
        order = ["LAMP1A","LAMP2A","LAMP3A","LAMP4A", ...
                 "STICK1A","STICK2A","STICK3A","STICK4A", ...
                 "MOON1","MOON2","MOON3","MOON4"];
    case 3
        order = ["BLUEBALL","SPIKEBALL","LAMP5","LAMP6","LAMP7","STICK5B","STICK7","STICK8","STICK9","STICK9A","STICK10"];
    otherwise
        error('Unsupported version %d.', versionVal);
end

matchIdx = find(order == measurementKey, 1, 'first');
if isempty(matchIdx)
    error('No sort index found for "%s" in version %d.', measurementKey, versionVal);
end
idx = matchIdx;
end
