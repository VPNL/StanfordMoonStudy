function limits = Quad_expand_linear_limits(x, includeZero)
% QUAD_EXPAND_LINEAR_LIMITS Add stable padding to finite linear data limits.

if nargin < 2 || isempty(includeZero)
    includeZero = false;
end
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
    limits = [0 1];
    return;
end
if includeZero
    x = [x; 0];
end
limits = [min(x) max(x)];
if limits(1) == limits(2)
    padding = max(1, abs(limits(1)) * 0.05);
else
    padding = 0.05 * diff(limits);
end
limits = limits + [-padding padding];
end
