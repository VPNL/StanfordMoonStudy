function [limits, ticks] = Quad_inverse_distance_axis(x)
% QUAD_INVERSE_DISTANCE_AXIS Return readable limits and ticks starting at zero.

x = double(x(:));
x = x(isfinite(x) & x >= 0);
if isempty(x) || max(x) <= 0
    limits = [0 1];
    ticks = 0:0.2:1;
    return;
end

targetStep = max(x) / 4;
scale = 10.^floor(log10(targetStep));
candidates = [1 2 2.5 5 10] * scale;
niceStep = candidates(find(candidates >= targetStep, 1, 'first'));
upperLimit = ceil(max(x) / niceStep) * niceStep;
limits = [0 upperLimit];
ticks = 0:niceStep:upperLimit;
end
