function combinedTbl = Combined_build_moon_quad_interocular_offset_table(quadCsv, moonCsv, moonTask, useQuadObserverGeometry)
% Combined_build_moon_quad_interocular_offset_table
%
% Build a single Moon + Quad interocular-offset table from the disparity
% source CSV files.
%
% Inputs
%   quadCsv                 : Quad disparity CSV path.
%   moonCsv                 : Moon disparity CSV path.
%   moonTask                : Moon task to keep, usually 'Perceptual'.
%   useQuadObserverGeometry : true uses Observer_Distance/Observer_Elevation;
%                             false uses Ground_Distance/Ground_Elevation.
%
% Output
%   combinedTbl             : Combined table with Distance and Width
%                             standardized to meters. Original-value columns
%                             keep the source units.

if nargin < 3 || isempty(moonTask)
    moonTask = 'Perceptual';
end
if nargin < 4 || isempty(useQuadObserverGeometry)
    useQuadObserverGeometry = true;
end

quadOpts = detectImportOptions(quadCsv, 'VariableNamingRule', 'modify');
quadTbl = readtable(quadCsv, quadOpts);

moonOpts = detectImportOptions(moonCsv, 'VariableNamingRule', 'modify');
moonTbl = readtable(moonCsv, moonOpts);

quadOut = local_quad_offset_table(quadTbl, quadCsv, useQuadObserverGeometry);
moonOut = local_moon_offset_table(moonTbl, moonCsv, moonTask);

combinedTbl = [quadOut; moonOut];
keep = isfinite(combinedTbl.InterocularOffset) & ...
    combinedTbl.InterocularOffset > 0 & ...
    isfinite(combinedTbl.Elevation);
combinedTbl = combinedTbl(keep, :);
combinedTbl.AbsElevation = abs(combinedTbl.Elevation);
combinedTbl.logInterocularOffset = log2(combinedTbl.InterocularOffset);
combinedTbl.logAbsElevation = log2(1 + combinedTbl.AbsElevation);
end

function quadOut = local_quad_offset_table(quadTbl, quadCsv, useQuadObserverGeometry)
nRows = height(quadTbl);
quadOut = local_empty_output_table(nRows);

[quadDistanceCm, distanceSource] = local_quad_geometry_var(quadTbl, ...
    useQuadObserverGeometry, 'Observer_Distance', 'Ground_Distance', 'Distance', nRows);
[quadElevation, elevationSource] = local_quad_geometry_var(quadTbl, ...
    useQuadObserverGeometry, 'Observer_Elevation', 'Ground_Elevation', 'Elevation', nRows);

quadOut.Experiment(:) = "Quad";
quadOut.ID = string(quadTbl.ID);
quadOut.SourceID = string(quadTbl.ID);
quadOut.Measurement = local_string_var(quadTbl, 'Measurement', nRows, "Quad");
quadOut.Task(:) = "";
quadOut.InterocularOffset = local_quad_mean_offset(quadTbl);
quadOut.Disparity = quadOut.InterocularOffset;
quadOut.Elevation = quadElevation;
quadOut.Real_Visual_Angle = local_numeric_var(quadTbl, 'Real_Visual_Angle', nan(nRows, 1));
quadOut.Distance = quadDistanceCm ./ 100; % Quad distances are stored in cm; output uses meters.
quadOut.DistanceUnits(:) = "m";
quadOut.DistanceOriginal = quadDistanceCm;
quadOut.DistanceOriginalUnits(:) = "cm";
quadOut.DistanceSource(:) = string(distanceSource);
quadOut.Width = local_numeric_var(quadTbl, 'Width', nan(nRows, 1)) ./ 100;
quadOut.WidthUnits(:) = "m";
quadOut.WidthOriginal = local_numeric_var(quadTbl, 'Width', nan(nRows, 1));
quadOut.WidthOriginalUnits(:) = "cm";
quadOut.WidthSource(:) = "Width";
quadOut.ElevationSource(:) = string(elevationSource);
quadOut.QuadGeometry(:) = local_quad_geometry_label(useQuadObserverGeometry);
quadOut.SourceCSV(:) = string(quadCsv);
end

function moonOut = local_moon_offset_table(moonTbl, moonCsv, moonTask)
taskRows = strcmpi(string(moonTbl.Task), string(moonTask));
moonTbl = moonTbl(taskRows, :);
nRows = height(moonTbl);
moonOut = local_empty_output_table(nRows);

moonOut.Experiment(:) = "Moon";
moonOut.ID = string(moonTbl.ID);
moonOut.SourceID = string(moonTbl.ID);
moonOut.Measurement = "FullMoon_" + local_string_var(moonTbl, 'Session', nRows, "Session");
moonOut.Task = string(moonTbl.Task);
moonOut.InterocularOffset = double(moonTbl.Disparity_VA) - double(moonTbl.Real_Visual_Angle);
moonOut.Disparity = moonOut.InterocularOffset;
moonOut.Elevation = double(moonTbl.Elevation);
moonOut.Real_Visual_Angle = double(moonTbl.Real_Visual_Angle);
moonDistanceKm = double(moonTbl.Distance);
moonOut.Distance = moonDistanceKm .* 1000; % Moon distances are stored in km; output uses meters.
moonOut.DistanceUnits(:) = "m";
moonOut.DistanceOriginal = moonDistanceKm;
moonOut.DistanceOriginalUnits(:) = "km";
moonOut.DistanceSource(:) = "Distance";
moonOut.Width(:) = 3476 * 1000; % Moon diameter is 3476 km; output uses meters.
moonOut.WidthUnits(:) = "m";
moonOut.WidthOriginal(:) = 3476;
moonOut.WidthOriginalUnits(:) = "km";
moonOut.WidthSource(:) = "Moon diameter";
moonOut.ElevationSource(:) = "Elevation";
moonOut.QuadGeometry(:) = "";
moonOut.SourceCSV(:) = string(moonCsv);
end

function outTbl = local_empty_output_table(nRows)
outTbl = table( ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    nan(nRows, 1), ...
    nan(nRows, 1), ...
    nan(nRows, 1), ...
    nan(nRows, 1), ...
    nan(nRows, 1), ...
    strings(nRows, 1), ...
    nan(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    nan(nRows, 1), ...
    strings(nRows, 1), ...
    nan(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    strings(nRows, 1), ...
    'VariableNames', {'Experiment','ID','SourceID','Measurement','Task', ...
    'InterocularOffset','Disparity','Elevation','Real_Visual_Angle', ...
    'Distance','DistanceUnits','DistanceOriginal','DistanceOriginalUnits', ...
    'DistanceSource','Width','WidthUnits','WidthOriginal','WidthOriginalUnits', ...
    'WidthSource','ElevationSource','QuadGeometry','SourceCSV'});
end

function meanOffset = local_quad_mean_offset(quadTbl)
if all(ismember({'Disparity1','Disparity2'}, quadTbl.Properties.VariableNames))
    meanOffset = mean([double(quadTbl.Disparity1) double(quadTbl.Disparity2)], 2, 'omitnan');
elseif ismember('Disparity', quadTbl.Properties.VariableNames)
    meanOffset = double(quadTbl.Disparity);
else
    error('CombinedBuildMoonQuadOffset:MissingQuadOffset', ...
        'Quad table needs Disparity1/Disparity2 or Disparity.');
end
end

function [values, sourceName] = local_quad_geometry_var(tbl, useObserverGeometry, ...
    observerVar, groundVar, fallbackVar, nRows)
if useObserverGeometry
    candidateVars = {observerVar, fallbackVar, groundVar};
else
    candidateVars = {groundVar, fallbackVar, observerVar};
end

sourceName = "";
values = nan(nRows, 1);
for iVar = 1:numel(candidateVars)
    varName = candidateVars{iVar};
    if ismember(varName, tbl.Properties.VariableNames)
        values = double(tbl.(varName));
        sourceName = string(varName);
        return;
    end
end
end

function label = local_quad_geometry_label(useObserverGeometry)
if useObserverGeometry
    label = "observer";
else
    label = "ground";
end
end

function values = local_numeric_var(tbl, varName, defaultValues)
if ismember(varName, tbl.Properties.VariableNames)
    values = double(tbl.(varName));
else
    values = defaultValues;
end
end

function values = local_string_var(tbl, varName, nRows, defaultValue)
if ismember(varName, tbl.Properties.VariableNames)
    values = string(tbl.(varName));
else
    values = repmat(string(defaultValue), nRows, 1);
end
end
