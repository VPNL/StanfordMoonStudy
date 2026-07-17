function moonVizTbl = build_moon_visualization_tbl(all_moon_data, spec, taskName)
% build_moon_visualization_tbl Build one representative moon row for visualization.
%
% Inputs
%   all_moon_data : Moon data table with Date, Task, Elevation, Distance,
%                   Real_Visual_Angle, and Ratio_Visual_Angle variables.
%   spec          : struct with fields date, mode, threshold, and label.
%                   mode must be 'lt' or 'gt'.
%   taskName      : task label to select, such as 'Perceptual' or 'Adjusted'.
%
% Output
%   moonVizTbl    : one-row table formatted for visualize_real_perceived_predicted.
%                   The first column, ID, stores the number of unique
%                   participant IDs contributing to the summarized row.
%                   Empty if no rows match the requested date/task/elevation rule.

moonVizTbl = table();

dateMask = match_moon_date(all_moon_data.Date, spec.date);
taskMask = strcmpi(strtrim(string(all_moon_data.Task)), strtrim(string(taskName)));
moonTbl = all_moon_data(dateMask & taskMask, :);

if strcmp(spec.mode, 'lt')
    elevMask = moonTbl.Elevation < spec.threshold;
elseif strcmp(spec.mode, 'gt')
    elevMask = moonTbl.Elevation > spec.threshold;
else
    error('Unsupported moon visualization mode %s.', spec.mode);
end

moonTbl = moonTbl(elevMask, :);

if isempty(moonTbl)
    warning('No moon rows found for date %s task %s and mode %s %.1f.', ...
        spec.date, taskName, spec.mode, spec.threshold);
    return
end

realVA = mean(moonTbl.Real_Visual_Angle, 'omitnan');
distanceM = 1000 * mean(moonTbl.Distance, 'omitnan');
ratioVA = mean(moonTbl.Ratio_Visual_Angle, 'omitnan');
reportedVA = realVA * ratioVA;
meanElevation = mean(moonTbl.Elevation, 'omitnan');
nID = numel(unique(moonTbl.ID));

measurementName = sprintf('Moon_%s_%s', regexprep(spec.date,'[^0-9]+','_'), spec.label);

moonVizTbl = table( ...
    nID, ...
    realVA, ...
    distanceM, ...
    meanElevation, ...
    string(taskName), ...
    reportedVA, ...
    ratioVA, ...
    string(measurementName), ...
    'VariableNames', {'N_ID','Real_Visual_Angle','Distance','Elevation','Task','Reported_Visual_Angle','Ratio_Visual_Angle','Measurement'});
end
