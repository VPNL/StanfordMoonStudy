function cmap = purpleVioletBlueTurquoiseColorMap(nLevels)
% purpleVioletBlueTurquoiseGreen  Colormap: dark purple -> violet -> blue -> turquoise -> cheerful green
%
%   cmap = purpleVioletBlueTurquoiseGreen(nLevels)
%
% Input
%   nLevels : (optional) number of colormap levels (default = 256)
%
% Output
%   cmap    : nLevels-by-3 RGB colormap in [0,1]
%
% Example
%   imagesc(peaks(200)); axis image off
%   colormap(purpleVioletBlueTurquoiseGreen(256)); colorbar

    if nargin < 1 || isempty(nLevels)
        nLevels = 256;
    end
    validateattributes(nLevels, {'numeric'}, {'scalar','integer','>=',2}, mfilename, 'nLevels');

    % Control points (RGB in [0,1]) tuned for a smooth, saturated but not neon ramp.
    % dark purple -> violet -> blue -> turquoise -> cheerful green
    ctrl = [
        0.20 0.00 0.3  % dark purple
        0.55 0.20 0.80  % violet
        %0.10 0.1  0.55   % dark blue
        0.10 0.35 0.9  % blue
        0.10 0.70 0.7  % turquoise
        0.60 1 1 % vyan
    ];

    xCtrl = linspace(0, 1, size(ctrl,1));
    x     = linspace(0, 1, nLevels);

    cmap = zeros(nLevels, 3);
    for c = 1:3
        cmap(:,c) = interp1(xCtrl, ctrl(:,c), x, 'pchip'); % smooth interpolation
    end

    % Clamp to valid RGB range
    cmap = max(0, min(1, cmap));
end
