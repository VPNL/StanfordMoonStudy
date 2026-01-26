function cmap = extendedearthColormap2(nLevels, varargin)
% earthColormap  Earth-like colormap: brown -> green -> blue -> light blue
%
%   cmap = earthColormap(nLevels)
%   cmap = earthColormap(nLevels, 'CLim', [cmin cmax])
%   cmap = earthColormap(nLevels, 'CLim', [cmin cmax], 'Axes', ax)
%   cmap = earthColormap(..., 'Apply', tf)
%
% Inputs
%   nLevels : (optional) number of colormap levels (default = 256)
%
% Name-Value pairs
%   'CLim'  : [cmin cmax] range to apply to the target axes (sets caxis/CLim)
%   'Axes'  : axes handle to apply settings to (default = gca)
%   'Apply' : true/false. If true, applies colormap (and CLim if provided)
%             to the target axes. Default = true.
%
% Output
%   cmap    : nLevels-by-3 RGB colormap in [0,1]
%
% Example
%   imagesc(peaks(200)); axis image off
%   earthColormap(256, 'CLim', [-5 5]); colorbar
%
% Notes
%   - Colormap itself is independent of data range; MATLAB maps data values
%     to the colormap via the axes CLim (aka caxis).

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
    clim  = p.Results.CLim;
    ax    = p.Results.Axes;
    doApply = p.Results.Apply;

    if isempty(ax)
        ax = gca;
    end

    % Control points (RGB in [0,1]):
    % brown -> green -> blue -> light blue (kept relatively light)
    ctrl = [
        .2   .1   .05   % dark brown
   
        0.1 0.35 0.10    % dark green
     
        0.1  0.35 .40   %  blue green(sky)
       % 0.0 0.0 0.70  % medium blue (not too dark)
         0.20 0.4 0.70  % medium blue (not too dark)
        0.50 0.90 1.00  % light blue (sky)
    ];

    % Interpolate to nLevels
    xCtrl = linspace(0, 1, size(ctrl,1));
    x     = linspace(0, 1, nLevels);

    cmap = zeros(nLevels, 3);
    for c = 1:3
        cmap(:,c) = interp1(xCtrl, ctrl(:,c), x, 'pchip');
    end
    cmap = max(0, min(1, cmap)); % clamp

    % Optionally apply to axes
    if doApply
        colormap(ax, cmap);
        if ~isempty(clim)
            if clim(2) <= clim(1)
                error('earthColormap:InvalidCLim', '''CLim'' must satisfy cmax > cmin.');
            end
            set(ax, 'CLim', clim); % equivalent to caxis(ax, clim)
        end
    end
end
