function tbl = Quad_prepare_perceived_disparity_table(inTbl, modelTransform)
% QUAD_PREPARE_PERCEIVED_DISPARITY_TABLE
% Prepare the disparity table for LME fitting.

if nargin < 2 || isempty(modelTransform)
    modelTransform = 2;
end


tbl = inTbl;

required = {'ID','Real_Visual_Angle','Distance','Elevation'};
missing = required(~ismember(required, tbl.Properties.VariableNames));
if ~isempty(missing)
    error('Quad_prepare_perceived_disparity_table:MissingVars', ...
        'Missing required variable(s): %s', strjoin(missing, ', '));
end

tbl.MeanDisparity = local_compute_mean_disparity(tbl);
if ~ismember('h_va', tbl.Properties.VariableNames)
    tbl.h_va = compute_h_va_from_table_geometry(tbl);
end
tbl.Distance = local_distance_to_meters(tbl);
tbl.Real_Visual_Angle = double(tbl.Real_Visual_Angle);
tbl.Elevation = double(tbl.Elevation);
tbl.h_va = double(tbl.h_va);


keep = isfinite(tbl.MeanDisparity) & tbl.MeanDisparity > 0 & ...
       isfinite(tbl.Real_Visual_Angle) & tbl.Real_Visual_Angle > 0 & ...
       isfinite(tbl.Distance) & tbl.Distance > 0 & ...
       isfinite(tbl.Elevation) & ...
       isfinite(tbl.h_va) & tbl.h_va > 0;

tbl = tbl(keep,:);

tbl.log2mean_disparity = log2(tbl.MeanDisparity);
tbl.log2real_visual_angle = log2(tbl.Real_Visual_Angle);
tbl.log2distance = log2(tbl.Distance);
tbl.log2h_va = log2(tbl.h_va);
switch modelTransform
    case 2
        tbl.ElevationDisplay = tbl.Elevation;
        tbl.ElevationModel = tbl.Elevation + 1;
        tbl.ElevationLabel = repmat("absElevation", height(tbl), 1);
    case 5
        keep = (1 + tbl.Elevation) > 0;
        tbl = tbl(keep,:);
        tbl.ElevationDisplay = 90 * tbl.Elevation;
        tbl.ElevationModel = 1 + tbl.Elevation;
        tbl.ElevationLabel = repmat("ElevationD90", height(tbl), 1);
    case 6
        keep = (1 + tbl.Elevation) > 0;
        tbl = tbl(keep,:);
        tbl.ElevationDisplay = 90 * tbl.Elevation;
        tbl.ElevationModel = 1 + tbl.Elevation;
        tbl.ElevationLabel = repmat("absElevationD90", height(tbl), 1);
    otherwise
        error('Quad_prepare_perceived_disparity_table:InvalidTransform', ...
            'Unsupported modelTransform %d.', modelTransform);
end

tbl.log2elevation = log2(tbl.ElevationModel);

if ~iscategorical(tbl.ID)
    tbl.ID = categorical(tbl.ID);
end
end

function meanDisparity = local_compute_mean_disparity(tbl)
if all(ismember({'Disparity1','Disparity2'}, tbl.Properties.VariableNames))
    meanDisparity = mean([double(tbl.Disparity1) double(tbl.Disparity2)], 2, 'omitnan');
elseif ismember('Disparity', tbl.Properties.VariableNames)
    meanDisparity = double(tbl.Disparity);
elseif ismember('InterocularOffset', tbl.Properties.VariableNames)
    meanDisparity = double(tbl.InterocularOffset);
elseif ismember('logInterocularOffset', tbl.Properties.VariableNames)
    meanDisparity = 2 .^ double(tbl.logInterocularOffset);
else
    error('Quad_prepare_perceived_disparity_table:MissingDisparity', ...
        'Need Disparity1/Disparity2, Disparity, InterocularOffset, or logInterocularOffset in the input table.');
end
end

function distanceM = local_distance_to_meters(tbl)
distanceValues = double(tbl.Distance);
if ~ismember('DistanceUnits', tbl.Properties.VariableNames)
    distanceM = distanceValues ./ 100; % Raw Quad distance tables store distance in cm.
    return;
end

units = lower(strtrim(string(tbl.DistanceUnits)));
units(ismissing(units)) = "";
distanceM = nan(size(distanceValues));

meterRows = units == "" | units == "m" | units == "meter" | units == "meters";
centimeterRows = units == "cm" | units == "centimeter" | units == "centimeters";
kilometerRows = units == "km" | units == "kilometer" | units == "kilometers";

distanceM(meterRows) = distanceValues(meterRows);
distanceM(centimeterRows) = distanceValues(centimeterRows) ./ 100;
distanceM(kilometerRows) = distanceValues(kilometerRows) .* 1000;

unknownRows = ~(meterRows | centimeterRows | kilometerRows);
if any(unknownRows)
    unknownUnits = unique(units(unknownRows));
    error('Quad_prepare_perceived_disparity_table:UnknownDistanceUnits', ...
        'Unsupported DistanceUnits value(s): %s', strjoin(cellstr(unknownUnits), ', '));
end
end
