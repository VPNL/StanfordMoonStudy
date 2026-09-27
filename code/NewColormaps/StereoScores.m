function cmap = StereoScores(nLevels, varargin)
% StereoScores  Colormap for stereo score values using anchored RGB colors.
%
%   cmap = StereoScores(nLevels)
%   cmap = StereoScores(nLevels, 'CLim', [cmin cmax])
%   cmap = StereoScores(nLevels, 'CLim', [cmin cmax], 'Axes', ax)
%   cmap = StereoScores(..., 'Apply', tf)
%
% 
%  anchorVals = [0; 40; 60; 80; 90;  100];
%  ctrl = [
%     0.9    0.1   0.1;    % 0
%     0.8    0.0   0.8;    % 40
%     0.5    0.5   1.0;    % 60
%     0.65    0.65   1.0;    % 80
%     0.7    0.7    .7;     % 90
%     0.7     0.7   0.7];  % 100


    if nargin < 1 || isempty(nLevels)
        nLevels = 256;
    end
    validateattributes(nLevels, {'numeric'}, {'scalar','integer','>=',2}, mfilename, 'nLevels');

    p = inputParser;
    p.FunctionName = mfilename;
    addParameter(p, 'CLim', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && numel(x)==2 && isfinite(x(1)) && isfinite(x(2))));
    addParameter(p, 'Axes', [], @(x) isempty(x) || isgraphics(x,'axes'));
    addParameter(p, 'Apply', true, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    clim = p.Results.CLim;
    ax = p.Results.Axes;
    doApply = p.Results.Apply;

    if isempty(ax)
        ax = gca;
    end

    anchorVals = [0; 40; 60; 80; 90;  100];
    ctrl = [
        0.9    0.1   0.1;    % 0
        0.8    0.0   0.8;    % 40
        0.5    0.5   1.0;    % 60
        0.65    0.65   1.0;    % 80
        0.7    0.7    .7;     % 90
        0.7     0.7   0.7];  % 100

    x = linspace(anchorVals(1), anchorVals(end), nLevels);
    cmap = zeros(nLevels, 3);
    for c = 1:3
        cmap(:, c) = interp1(anchorVals, ctrl(:, c), x, 'linear');
    end
    cmap = max(0, min(1, cmap));

    if doApply
        colormap(ax, cmap);
        if ~isempty(clim)
            if clim(2) <= clim(1)
                error('StereoScores:InvalidCLim', '''CLim'' must satisfy cmax > cmin.');
            end
            set(ax, 'CLim', clim);
        end
    end
end
