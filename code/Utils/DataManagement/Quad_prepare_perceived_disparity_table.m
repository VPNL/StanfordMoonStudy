function tbl = Quad_prepare_perceived_disparity_table(inTbl, modelTransform, removeOutlierParticipants)
% QUAD_PREPARE_PERCEIVED_DISPARITY_TABLE
% Prepare the disparity table for LME fitting.

if nargin < 2 || isempty(modelTransform)
    modelTransform = 2;
end
if nargin < 3 || isempty(removeOutlierParticipants)
    removeOutlierParticipants = false;
end

tbl = inTbl;

required = {'ID','Real_Visual_Angle','Distance','Elevation'};
missing = required(~ismember(required, tbl.Properties.VariableNames));
if ~isempty(missing)
    error('Quad_prepare_perceived_disparity_table:MissingVars', ...
        'Missing required variable(s): %s', strjoin(missing, ', '));
end

tbl.MeanDisparity = local_compute_mean_disparity(tbl);
tbl.Distance = double(tbl.Distance) ./ 100;
tbl.Real_Visual_Angle = double(tbl.Real_Visual_Angle);
tbl.Elevation = double(tbl.Elevation);

if removeOutlierParticipants
    tbl = tbl(tbl.ID ~= 26, :);
    fprintf('removed outlier pariticipant ID=%d\n',26)
end

keep = isfinite(tbl.MeanDisparity) & tbl.MeanDisparity > 0 & ...
       isfinite(tbl.Real_Visual_Angle) & tbl.Real_Visual_Angle > 0 & ...
       isfinite(tbl.Distance) & tbl.Distance > 0 & ...
       isfinite(tbl.Elevation);

tbl = tbl(keep,:);

tbl.log2mean_disparity = log2(tbl.MeanDisparity);
tbl.log2real_visual_angle = log2(tbl.Real_Visual_Angle);
tbl.log2distance = log2(tbl.Distance);

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
else
    error('Quad_prepare_perceived_disparity_table:MissingDisparity', ...
        'Need Disparity1/Disparity2 or Disparity in the input table.');
end
end
