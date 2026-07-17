function [sfx, runMode, modelTransform, degreeFlag, info] = get_quad_transform_spec(transformId)
% GET_QUAD_TRANSFORM_SPEC Return the shared quad elevation-transform spec.
%
% Shared transform coding across the quad PM/disparity codebase:
%   1 = Elevation
%   2 = absElevation
%   3 = ElevationRAD
%   4 = absElevationRAD
%   5 = ElevationD90
%   6 = absElevationD90

if ~isscalar(transformId) || ~isnumeric(transformId)
    error('transformId must be a numeric scalar.');
end

transformId = double(transformId);
degreeFlag = 1;

switch transformId
    case 1
        sfx = 'Elevation';
        runMode = 'standard';
        modelTransform = 1;
        displayName = 'Elevation';
    case 2
        sfx = 'absElevation';
        runMode = 'standard';
        modelTransform = 2;
        displayName = '|Elevation|';
    case 3
        sfx = 'ElevationRAD';
        runMode = 'rad';
        modelTransform = 3;
        degreeFlag = 0;
        displayName = 'Elevation (rad)';
    case 4
        sfx = 'absElevationRAD';
        runMode = 'rad';
        modelTransform = 4;
        degreeFlag = 0;
        displayName = '|Elevation| (rad)';
    case 5
        sfx = 'ElevationD90';
        runMode = 'standard';
        modelTransform = 5;
        displayName = 'Elevation/90';
    case 6
        sfx = 'absElevationD90';
        runMode = 'standard';
        modelTransform = 6;
        displayName = '|Elevation|/90';
    otherwise
        error('Unsupported quad transform %d. Expected 1..6.', transformId);
end

info = struct( ...
    'transformId', transformId, ...
    'sfx', sfx, ...
    'runMode', runMode, ...
    'modelTransform', modelTransform, ...
    'degreeFlag', degreeFlag, ...
    'displayName', displayName);
end
