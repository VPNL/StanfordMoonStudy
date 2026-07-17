function [tblOut, info] = apply_quad_elevation_transform(tblIn, transformId)
% apply_quad_elevation_transform Apply one of the standard quad elevation transforms.
%
% Inputs
%   tblIn       : input table containing an Elevation variable
%   transformId : integer transform code
%                 1 = Elevation
%                 2 = absElevation
%                 3 = ElevationRAD
%                 4 = absElevationRAD
%                 5 = ElevationD90
%                 6 = absElevationD90
%
% Outputs
%   tblOut : copy of tblIn with transformed Elevation
%   info   : struct with metadata fields
%            .transformId
%            .sfx
%            .displayName

if ~isa(tblIn, 'table')
    error('tblIn must be a table.');
end
if ~ismember('Elevation', tblIn.Properties.VariableNames)
    error('tblIn must contain an Elevation variable.');
end

tblOut = tblIn;
info = struct('transformId', transformId, 'sfx', "", 'displayName', "");

switch transformId
    case 1
        info.sfx = "Elevation";
        info.displayName = "Elevation";
    case 2
        tblOut.Elevation = abs(tblOut.Elevation);
        info.sfx = "absElevation";
        info.displayName = "|Elevation|";
    case 3
        tblOut.Elevation = pi * tblOut.Elevation / 180;
        info.sfx = "ElevationRAD";
        info.displayName = "Elevation (rad)";
    case 4
        tblOut.Elevation = pi * abs(tblOut.Elevation) / 180;
        info.sfx = "absElevationRAD";
        info.displayName = "|Elevation| (rad)";
    case 5
        tblOut.Elevation = tblOut.Elevation / 90;
        info.sfx = "ElevationD90";
        info.displayName = "Elevation/90";
    case 6
        tblOut.Elevation = abs(tblOut.Elevation / 90);
        info.sfx = "absElevationD90";
        info.displayName = "|Elevation|/90";
    otherwise
        error('Unsupported transformId %d. Expected 1..6.', transformId);
end
end
