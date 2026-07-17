function cm_data = magmaShine(m)
% MAGMASHINE
% Variant of magma that preserves 0-0.7 of magma, then linearly
% interpolates from the 0.7 color to a custom final color.

targetColor = [0.8 0.8 0];

if nargin < 1
    cm_data = local_apply_shine(magma(), targetColor);
else
    cm_data = local_apply_shine(magma(m), targetColor);
end
end

function cm = local_apply_shine(cm, targetColor)
x = linspace(0, 1, size(cm, 1))';
anchorX = 0.7;
anchorColor = interp1(x, cm, anchorX, 'linear');

tailMask = x > anchorX;
tailWeights = (x(tailMask) - anchorX) ./ (1 - anchorX);
cm(tailMask, :) = (1 - tailWeights) .* anchorColor + tailWeights .* targetColor;

cm = min(max(cm, 0), 1);
end
