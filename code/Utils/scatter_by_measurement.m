function scatter_by_measurement(ax, x, y, subjectcolor, measurement)
% SCATTER_BY_MEASUREMENT
% Plot points with marker shape determined by the Measurement label.

measurement = string(measurement);
measurementLower = lower(measurement);

isBall = contains(measurementLower, "ball");
isProbeOrDisk = contains(measurementLower, "probe") | contains(measurementLower, "disk");
isLamp = contains(measurementLower, "lamp");
isStick = contains(measurementLower, "stick");
% Make the groups mutually exclusive so compound labels like "Lamp5Disk"
% are not plotted twice. Disk/probe takes precedence over lamp.
isProbeOrDisk = isProbeOrDisk & ~isBall;
isLamp = isLamp & ~isBall & ~isProbeOrDisk;
isStick = isStick & ~isBall & ~isProbeOrDisk & ~isLamp;
isOther = ~(isBall | isLamp | isStick | isProbeOrDisk);

if any(isBall)
    scatter(ax, x(isBall), y(isBall), 70, subjectcolor(isBall,:), '.', 'LineWidth', 1.2);
end
if any(isLamp)
    scatter(ax, x(isLamp), y(isLamp), 55, subjectcolor(isLamp,:), 'o', ...
        'LineWidth', 1.2, 'MarkerFaceColor', 'none');
end
% if any(isLamp)
%     scatter(ax, x(isLamp), y(isLamp), 30, subjectcolor(isLamp,:), ...
%           'o', 'filled', 'MarkerFaceAlpha', .8 , 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha', 0);
% end
if any(isStick)
    scatter(ax, x(isStick), y(isStick), 50, subjectcolor(isStick,:), 's', ...
        'LineWidth', 1.2, 'MarkerFaceColor', 'none');
end
% if any(isProbeOrDisk)
%     scatter(ax, x(isProbeOrDisk), y(isProbeOrDisk), 55, subjectcolor(isProbeOrDisk,:), 'o', ...
%         'LineWidth', 1.2, 'MarkerFaceColor', 'none');
% end
if any(isProbeOrDisk)
    scatter(ax, x(isProbeOrDisk), y(isProbeOrDisk), 30, subjectcolor(isProbeOrDisk,:), ...
          'o', 'filled', 'MarkerFaceAlpha', .8 , 'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha', 0);
end
if any(isOther)
    scatter(ax, x(isOther), y(isOther), 45, subjectcolor(isOther,:), 'filled');
end
end
