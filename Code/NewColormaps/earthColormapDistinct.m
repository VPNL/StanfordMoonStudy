function cmap = earthColormapDistinct(nLevels, varargin)
% earthColormapDistinct  Earth-like colormap with more distinct greens/blues
%
%   cmap = earthColormapDistinct(nLevels)
%   cmap = earthColormapDistinct(nLevels, 'CLim', [cmin cmax])
%   cmap = earthColormapDistinct(nLevels, 'CLim', [cmin cmax], 'Axes', ax)
%   cmap = earthColormapDistinct(..., 'Apply', tf)
%
% This variant increases chroma separation between the land (greens) and
% ocean (blues) portions by (i) using more saturated anchors and (ii)
% placing control points closer together at the transition.

    if nargin < 1 || isempty(nLevels)
        nLevels = 256;
    end
    validateattributes(nLevels, {'numeric'}, {'scalar','integer','>=',2}, mfilename, 'nLevels');

    % Parse options (same interface as earthColormap)
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
    % brown -> bright green -> deep blue -> light blue
    ctrl = [
        0.18 0.09 0.06  % dark brown
        0.55 0.30 0.10  % earthy brown
        0.05 0.72 0.18  % vivid green
        0.00 0.55 0.55  % teal (short bridge; helps separation)
        0.05 0.25 0.88  % deep blue (still readable)
        0.70 0.92 1.00  % light blue (sky)
    ];

    % Non-uniform spacing sharpens the green->blue transition
    xCtrl = [0.00 0.34 0.54 0.60 0.72 1.00];
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
                error('earthColormapDistinct:InvalidCLim', '''CLim'' must satisfy cmax > cmin.');
            end
            set(ax, 'CLim', clim);
        end
    end
end
