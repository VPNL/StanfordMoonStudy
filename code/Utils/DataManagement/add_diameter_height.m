function [outTbl, missingTbl, outFile] = add_diameter_height(matchingCsv, outFile, groundTruthCsv)
% add_diameter_height
%
% Add object diameter/height information to each row of a Quad matching-data
% CSV. The new table column is named "size" and is in meters, matching the
% "Diameter/height [m]" column in Ground Truth Information.csv.
%
% Inputs
%   matchingCsv    Full path to a matching-data CSV with a Measurement column.
%   outFile        Optional output CSV path. If omitted or empty, no file is
%                  written and the augmented table is returned only.
%   groundTruthCsv Optional ground-truth CSV path. If omitted, this defaults to
%                  fullfile(matchDir, 'Ground Truth Information.csv'), where
%                  matchDir is the folder containing matchingCsv.
%
% Outputs
%   outTbl         Matching table with an added/replaced "Size" column.
%   missingTbl     Measurement groups that were not found in ground truth.
%   outFile        Output CSV path that was written, or "" if none was written.
%
% Example
%   matchingCsv = '/path/to/StanfordQuadProcessedData0630.csv';
%   outFile = '/path/to/StanfordQuadProcessedData0630_with_Size.csv';
%   [tbl, missingTbl] = add_diameter_height(matchingCsv, outFile);

if nargin < 1 || isempty(matchingCsv)
    error('matchingCsv is required.');
end

if nargin < 2 || isempty(outFile)
    outFile = "";
else
    outFile = string(outFile);
end

[matchDir, ~, ~] = fileparts(matchingCsv);
if nargin < 3 || isempty(groundTruthCsv)
    groundTruthCsv = fullfile(matchDir, 'Ground Truth Information.csv');
end

if ~exist(matchingCsv, 'file')
    error('Could not find matching CSV: %s', matchingCsv);
end
if ~exist(groundTruthCsv, 'file')
    error('Could not find ground truth file: %s', groundTruthCsv);
end

matchTbl = readtable(matchingCsv, 'TextType', 'string', 'VariableNamingRule', 'preserve');
if ~ismember('Measurement', matchTbl.Properties.VariableNames)
    error('Matching table is missing required variable "Measurement".');
end

gtTbl = readtable(groundTruthCsv, 'TextType', 'string', 'VariableNamingRule', 'preserve');
if width(gtTbl) < 3
    error('Ground truth table must contain at least three columns: object, variable name, and diameter/height.');
end

measurementBase = local_extract_measurement_base(matchTbl.Measurement);
measurementKey = local_normalize_measurement_key(measurementBase);
versionResolved = local_resolve_version(matchTbl, measurementKey);

gtLookup = local_ground_truth_size_lookup(gtTbl);
matchKeys = local_join_version_measurement_key(versionResolved, measurementKey);
gtKeys = local_join_version_measurement_key(gtLookup.VersionResolved, gtLookup.MeasurementKey);

[foundKey, gtIdx] = ismember(matchKeys, gtKeys);
sizeValues = nan(height(matchTbl), 1);
sizeValues(foundKey) = gtLookup.Size(gtIdx(foundKey));

outTbl = matchTbl;
outTbl.Size = sizeValues;

missingTbl = local_missing_ground_truth_entries(matchTbl, versionResolved, measurementKey, ~foundKey);

if strlength(outFile) > 0
    outDir = fileparts(outFile);
    if strlength(outDir) > 0 && ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    writetable(outTbl, outFile);
else
    outFile = "";
end
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

function versionResolved = local_resolve_version(matchTbl, measurementKey)
versionResolved = nan(numel(measurementKey), 1);
if ismember('Version', matchTbl.Properties.VariableNames)
    versionRaw = local_parse_version_values(matchTbl.Version);
    valid = ~isnan(versionRaw);
    versionResolved(valid) = versionRaw(valid);
end

missingVersion = isnan(versionResolved);
if any(missingVersion)
    versionResolved(missingVersion) = local_infer_version_from_key(measurementKey(missingVersion));
end
end

function versionValues = local_parse_version_values(values)
if isnumeric(values)
    versionValues = double(values(:));
    return
end

values = string(values(:));
versionValues = nan(numel(values), 1);
for iValue = 1:numel(values)
    token = regexp(values(iValue), '\d+', 'match', 'once');
    if ~isempty(token)
        versionValues(iValue) = str2double(token);
    end
end
end

function gtLookup = local_ground_truth_size_lookup(gtTbl)
gtObjectCol = string(gtTbl{:,1});
gtVarCol = string(gtTbl{:,2});
gtSizeCol = string(gtTbl{:,3});

validGT = strlength(strtrim(gtObjectCol)) > 0 & strlength(strtrim(gtVarCol)) > 0;
gtLookup = table( ...
    strtrim(gtObjectCol(validGT)), ...
    local_normalize_measurement_key(strtrim(gtVarCol(validGT))), ...
    str2double(gtSizeCol(validGT)), ...
    'VariableNames', {'Object','MeasurementKey','Size'});

gtLookup = local_apply_ground_truth_aliases(gtLookup);
gtLookup = gtLookup(ismember(gtLookup.MeasurementKey, local_allowed_measurement_keys()), :);
gtLookup.VersionResolved = local_infer_version_from_key(gtLookup.MeasurementKey);

gtKeys = local_join_version_measurement_key(gtLookup.VersionResolved, gtLookup.MeasurementKey);
[uniqueKeys, uniqueIdx] = unique(gtKeys, 'stable'); %#ok<ASGLU>
gtLookup = gtLookup(uniqueIdx, :);
end

function gtLookup = local_apply_ground_truth_aliases(gtLookup)
objectStr = lower(strtrim(string(gtLookup.Object)));

isStick9a = contains(objectStr, "lamp post 9a");
gtLookup.MeasurementKey(isStick9a) = "STICK9A";

aliasRows = gtLookup([], :);

idxSpike = find(gtLookup.MeasurementKey == "SPIKEBALL");
if ~isempty(idxSpike)
    blueRows = gtLookup(idxSpike, :);
    blueRows.MeasurementKey(:) = "BLUEBALL";
    blueRows.Object(:) = "Blue ball";
    aliasRows = [aliasRows; blueRows];
end

idxStick5b = find(gtLookup.MeasurementKey == "STICK5B");
if ~isempty(idxStick5b)
    stick10Rows = gtLookup(idxStick5b, :);
    stick10Rows.MeasurementKey(:) = "STICK10";
    stick10Rows.Object(:) = "Lamp post 10";
    aliasRows = [aliasRows; stick10Rows];
end

gtLookup = [gtLookup; aliasRows];
end

function allowedMeasurementKeys = local_allowed_measurement_keys()
allowedMeasurementKeys = [ ...
    "LAMP1","LAMP2","LAMP3","LAMP4","LAMP5","LAMP6","LAMP7", ...
    "LAMP1A","LAMP2A","LAMP3A","LAMP4A", ...
    "STICK1","STICK2","STICK3","STICK4","STICK1A","STICK2A","STICK3A","STICK4A", ...
    "STICK5B","STICK7","STICK8","STICK9","STICK9A","STICK10", "BLUEBALL", ...
    "MOON1","MOON2","MOON3","MOON4","SPIKEBALL"];
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

function keys = local_join_version_measurement_key(versionValues, measurementKeys)
keys = string(versionValues(:)) + "|" + upper(strtrim(string(measurementKeys(:))));
end

function missingTbl = local_missing_ground_truth_entries(matchTbl, versionResolved, measurementKey, missingMask)
missingTbl = table();
if ~any(missingMask)
    return
end

missingRows = matchTbl(missingMask, :);
missingRows.VersionResolved = versionResolved(missingMask);
missingRows.MeasurementKey = measurementKey(missingMask);

[groupIdx, keyTbl] = findgroups(missingRows(:, {'VersionResolved','MeasurementKey'}));
measurementEntries = splitapply(@local_join_unique_values, missingRows.Measurement, groupIdx);
nEntries = splitapply(@numel, missingRows.Measurement, groupIdx);

if ismember('ID', missingRows.Properties.VariableNames)
    ids = splitapply(@local_join_unique_values, missingRows.ID, groupIdx);
    nParticipants = splitapply(@local_count_unique_ids, missingRows.ID, groupIdx);
else
    ids = strings(height(keyTbl), 1);
    nParticipants = nan(height(keyTbl), 1);
end

missingTbl = [keyTbl table(ids, measurementEntries, nEntries, nParticipants, ...
    'VariableNames', {'IDs','MeasurementEntries','N_Entries','N_Participants'})];
missingTbl = sortrows(missingTbl, {'VersionResolved','MeasurementKey'});

warning('Found %d matching-data measurement group(s) absent from Ground Truth Information.csv.', height(missingTbl));
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
