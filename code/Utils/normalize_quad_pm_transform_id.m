function transformId = normalize_quad_pm_transform_id(transformId, mode)
% NORMALIZE_QUAD_PM_TRANSFORM_ID Normalize legacy PM transform codes to shared IDs.

if nargin < 2 || isempty(mode)
    mode = 'standard';
end

mode = lower(string(mode));

switch mode
    case "standard"
        switch transformId
            case {1, 2, 5, 6}
            case 3
                transformId = 5;
            case 4
                transformId = 6;
            otherwise
                error('Unsupported standard PM transformId %d. Use 1,2,5,6.', transformId);
        end

    case "rad"
        switch transformId
            case 1
                transformId = 3;
            case 2
                transformId = 4;
            case {3, 4}
            otherwise
                error('Unsupported rad PM transformId %d. Use 3 or 4.', transformId);
        end

    otherwise
        error('Unsupported mode "%s".', mode);
end
end
