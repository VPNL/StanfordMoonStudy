function cmap = earthColormap3(nLevels, varargin)
% earthColormapExtended  Earth-like colormap extended into lavender & purples
%
%   cmap = earthColormapExtended(nLevels)
%   cmap = earthColormapExtended(nLevels, 'CLim', [cmin cmax])
%   cmap = earthColormapExtended(nLevels, 'CLim', [cmin cmax], 'Axes', ax)
%   cmap = earthColormapExtended(..., 'Apply', tf)
%
% This variant extends earthColormapDistinct by adding, after the blues,
% a progression: light blue -> lavender -> purple -> deep purple.
%
% Notes:
% - Designed for MATLAB's default 'tex' interpreter usage in figures.
% - Uses 'pchip' interpolation to avoid harsh banding and preserve contrast.

    if nargin < 1 || isempty(nLevels)
        nLevels = 256;
    end
    validateattributes(nLevels, {'numeric'}, {'scalar','integer','>=',2}, mfilename, 'nLevels');

    % Parse options
    p = inputParser;
    p.FunctionName = mfilename;

    addParameter(p, 'CLim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && numel(x)==2 && isfinite(x(1)) && isfinite(x(2))));
    addParameter(p, 'Axes', [], @(x) isempty(x) || isgraphics(x,'axes'));
    addParameter(p, 'Apply', true, @(x) islogical(x) && isscalar(x));

    parse(p, varargin{:});
    clim    = p.Results.CLim;
    ax      = p.Results.Axes;
    doApply = p.Results.Apply;

    if isempty(ax)
        ax = gca;
    end

    % Control points (RGB in [0,1])
    % brown -> green -> teal -> deep blue -> light blue -> lavender -> purple -> deep purple
    ctrl = [
        0.18 0.09 0.06  % dark brown
        0.40 0.20 0.10  % earthy brown
        0.1 0.40 0.1  % vivid green
        .05  .45 .3   % dark teal
        0.00 0.5 0.5  % teal 
        0 0.3 0.7     % blue with a greenish tint   
        0.25 .35  0.925 % blue
    ];

    % % Non-uniform spacing:
    % % - preserve contrast at green->blue
    % % - give extra room to lavender/purple tail
    % % xCtrl = [0.00 0.28 0.48 0.56 0.66 0.76 0.86 0.93 1.00];
    % x     = linspace(0, 1, nLevels);
    xCtrl = linspace(0, 1, size(ctrl,1));
    x     = linspace(0, 1, nLevels);


    cmap = zeros(nLevels, 3);
    for c = 1:3
        cmap(:,c) = interp1(xCtrl, ctrl(:,c), x, 'pchip');
    end
    cmap = max(0, min(1, cmap));

    % Optionally apply to axes
    if doApply
        colormap(ax, cmap);
        if ~isempty(clim)
            if clim(2) <= clim(1)
                error('earthColormapExtended:InvalidCLim', '''CLim'' must satisfy cmax > cmin.');
            end
            set(ax, 'CLim', clim);
        end
    end
end
