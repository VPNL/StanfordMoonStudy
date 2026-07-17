function scatter_pm_by_measurement(ax, x, y, colors, measurements, markerSize)
% SCATTER_PM_BY_MEASUREMENT
% Plot PM scatter points with marker shapes determined by Measurement.

if nargin < 6 || isempty(markerSize)
    markerSize = 50;
end

measurementStr = lower(string(measurements));

maskBall = contains(measurementStr, "ball");
maskStick = contains(measurementStr, "stick");
maskLamp = contains(measurementStr, "lamp");
maskOther = ~(maskBall | maskStick | maskLamp);

hold(ax, 'on');

local_scatter_group(ax, x, y, colors, maskBall, '.', 70, true);
local_scatter_group(ax, x, y, colors, maskStick, 's', markerSize, true);
local_scatter_group(ax, x, y, colors, maskLamp, 'o', markerSize, true);
local_scatter_group(ax, x, y, colors, maskOther, 'o', markerSize, false);
end

function local_scatter_group(ax, x, y, colors, mask, markerSymbol, markerSize, isFilled)
if ~any(mask)
    return;
end

idx = find(mask);
for i = 1:numel(idx)
    ii = idx(i);
    if isFilled
        scatter(ax, x(ii), y(ii), markerSize, colors(ii, :), markerSymbol, 'filled','MarkerEdgeColor','none');
    else
        scatter(ax, x(ii), y(ii), markerSize, colors(ii, :), markerSymbol, 'LineWidth', 1.2);
    end
end
end
