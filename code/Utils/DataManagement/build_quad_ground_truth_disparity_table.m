function [summaryTbl, displayTbl] = build_quad_ground_truth_disparity_table(matchingCsv, outFile)
% BUILD_QUAD_GROUND_TRUTH_DISPARITY_TABLE
%
% Build a Quad disparity display table from a disparity-style CSV such
% as merged_disparity_0429.csv, using only values present in the CSV.
%
% Required input columns in matchingCsv:
%   Version
%   Measurement
%   Real_Visual_Angle
%   Observer_Distance
%   Observer_Elevation
%
% Output columns:
%   Version
%   Object
%   Visual_Angle_degrees
%   Observer_Distance_m
%   Observer_Elevation_degrees

if nargin < 1 || isempty(matchingCsv)
    error('matchingCsv is required.');
end

if nargin < 2 || isempty(outFile)
    [matchDir, matchBase, ~] = fileparts(matchingCsv);
    outFile = fullfile(matchDir, ['QuadGroundTruthDisparityTable_' matchBase '.csv']);
end

matchTbl = readtable(matchingCsv, 'TextType', 'string');

requiredMatchVars = {'Version','Measurement','Real_Visual_Angle', ...
    'Observer_Distance','Observer_Elevation'};
for iVar = 1:numel(requiredMatchVars)
    if ~ismember(requiredMatchVars{iVar}, matchTbl.Properties.VariableNames)
        error('Matching table is missing required variable "%s".', requiredMatchVars{iVar});
    end
end

versionValues = str2double(string(matchTbl.Version));
validVersion = isfinite(versionValues);
if ~all(validVersion)
    warning('build_quad_ground_truth_disparity_table:InvalidVersionRows', ...
        'Ignoring %d row(s) with nonnumeric Version values in %s.', ...
        sum(~validVersion), matchingCsv);
    matchTbl = matchTbl(validVersion, :);
    versionValues = versionValues(validVersion);
end
if isempty(matchTbl)
    error('Version column must contain at least one numeric value.');
end
matchTbl.Version = versionValues;

matchTbl.MeasurementBase = local_extract_measurement_base(matchTbl.Measurement);
matchTbl.MeasurementKey = local_normalize_measurement_key(matchTbl.MeasurementBase);

summaryTbl = groupsummary(matchTbl, {'Version','MeasurementKey'}, 'mean', ...
    {'Real_Visual_Angle','Observer_Distance','Observer_Elevation'});
summaryTbl = removevars(summaryTbl, 'GroupCount');
summaryTbl = renamevars(summaryTbl, ...
    {'mean_Real_Visual_Angle','mean_Observer_Distance','mean_Observer_Elevation'}, ...
    {'Visual_Angle_degrees','Observer_Distance_source','Observer_Elevation_degrees'});
summaryTbl.Object = local_default_object_name(summaryTbl.MeasurementKey);

summaryTbl = sortrows(summaryTbl, {'Version','MeasurementKey'});

summaryTbl.Observer_Distance_m = summaryTbl.Observer_Distance_source ./ 100;

displayTbl = summaryTbl(:, {'Version','Object','Visual_Angle_degrees', ...
    'Observer_Distance_m','Observer_Elevation_degrees'});

[outDir,~,outExt] = fileparts(outFile);
if isempty(outExt)
    outFile = [outFile '.csv'];
end
if ~isempty(outDir) && ~exist(outDir, 'dir')
    mkdir(outDir);
end

writetable(displayTbl, outFile);
end

function measurementBase = local_extract_measurement_base(measurementNames)
measurementBase = string(measurementNames);
for i = 1:numel(measurementBase)
    thisName = strtrim(measurementBase(i));
    thisName = regexprep(thisName, '^(First|Second|Third|Fourth)_', '', 'ignorecase');
    thisName = regexprep(thisName, 'Disparity.*$', '', 'ignorecase');
    measurementBase(i) = strtrim(thisName);
end
end

function key = local_normalize_measurement_key(values)
key = upper(strtrim(string(values)));
key = replace(key, "MOONBALL", "MOON");
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
    elseif contains(key, "DISK")
        objectName(i) = extractBefore(key, "DISK") + " disk " + extractAfter(key, "DISK");
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
