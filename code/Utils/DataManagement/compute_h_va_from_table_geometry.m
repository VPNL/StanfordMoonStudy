function hVa = compute_h_va_from_table_geometry(tbl)
% compute_h_va_from_table_geometry Compute horizontal visual angle from table geometry.
%
% If Width is available, the function uses Width with Observer_Distance
% when that column exists, otherwise with Distance. When WidthUnits and
% DistanceUnits are present, values are converted to meters before calling
% visualangle. If Width is unavailable, h_va or Real_Visual_Angle is used
% as a fallback.

vars = tbl.Properties.VariableNames;
hasWidth = ismember('Width', vars);
if hasWidth
    width = double(tbl.Width);
    if ismember('Observer_Distance', vars)
        distance = double(tbl.Observer_Distance);
    elseif ismember('Distance', vars)
        width = local_to_meters(width, local_units(tbl, 'WidthUnits'));
        distance = local_to_meters(double(tbl.Distance), local_units(tbl, 'DistanceUnits'));
    else
        error('compute_h_va_from_table_geometry:MissingDistance', ...
            'Width is present, but neither Observer_Distance nor Distance is available.');
    end
    hVa = visualangle(width, distance);
elseif ismember('h_va', vars)
    hVa = double(tbl.h_va);
elseif ismember('Real_Visual_Angle', vars)
    hVa = double(tbl.Real_Visual_Angle);
else
    error('compute_h_va_from_table_geometry:MissingAngle', ...
        'Need Width + distance, h_va, or Real_Visual_Angle to compute h_va.');
end
end

function units = local_units(tbl, unitVar)
if ismember(unitVar, tbl.Properties.VariableNames)
    units = lower(strtrim(string(tbl.(unitVar))));
    units(ismissing(units)) = "";
else
    units = strings(height(tbl), 1);
end
end

function valuesM = local_to_meters(values, units)
valuesM = values;
meterRows = units == "" | units == "m" | units == "meter" | units == "meters";
centimeterRows = units == "cm" | units == "centimeter" | units == "centimeters";
kilometerRows = units == "km" | units == "kilometer" | units == "kilometers";

valuesM(meterRows) = values(meterRows);
valuesM(centimeterRows) = values(centimeterRows) ./ 100;
valuesM(kilometerRows) = values(kilometerRows) .* 1000;

unknownRows = ~(meterRows | centimeterRows | kilometerRows);
if any(unknownRows)
    unknownUnits = unique(units(unknownRows));
    error('compute_h_va_from_table_geometry:UnknownUnits', ...
        'Unsupported unit value(s): %s', strjoin(cellstr(unknownUnits), ', '));
end
end
