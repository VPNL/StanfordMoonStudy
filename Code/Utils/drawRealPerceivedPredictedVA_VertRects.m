function drawRealPerceivedPredictedVA_VertRects(real_width_mm, perceived_width_mm, predicted_width_mm, textstring, saveFlag, saveFilename, mycolor)
% drawRealPerceivedPredictedVA_VertRects(real_width_mm, perceived_width_mm, predicted_width_mm, textstring, saveFlag, saveFilename, mycolor)
%
% Like drawRealPerceivedPredictedVA, but draws THREE *vertical filled rectangles*
% instead of circles.
%
% Geometry convention:
%   Each input is interpreted as the rectangle WIDTH (mm).
%   Rectangles are constrained to an aspect ratio (width:height) of 1:28.5,
%     so rectHeight_mm = rectWidth_mm * 28.5
%
% Inputs
%   real_width_mm, perceived_width_mm, predicted_width_mm : (scalar) widths in mm
%   textstring   : (char/string) text at bottom-left (default: '')
%   saveFlag     : (logical) export figure if true (default: false)
%   saveFilename : (char/string) output filename (default: 'Example.png')
%   mycolor      : RGB triplet in [0..1] (default: [1 .8 .1])
%
% Notes
%   - Uses insertShape (Computer Vision Toolbox) for raster drawing.
%   - Labels "real / perceived / predicted" are placed above the tallest
%     element, similar to the circle version.
%
% KGS 1/26 (based on drawRealPerceivedPredictedVA)

% ------------------------- Defaults & checks -----------------------------
if nargin < 3
    error('Need widths (mm) for 3 rectangles: real, perceived, predicted.');
end

if ~exist('textstring','var') || isempty(textstring)
    textstring = '';
end
if ~exist('mycolor','var') || isempty(mycolor)
    mycolor = [.5 .5 1];
end
if ~exist('saveFlag','var') || isempty(saveFlag)
    saveFlag = false;
end
if ~exist('saveFilename','var') || isempty(saveFilename)
    saveFilename = 'Example.png';
end

% Aspect ratio width:height
ar_h_over_w = 28.5;

% Rectangle sizes (mm)
realW_mm      = real_width_mm;
perceivedW_mm = perceived_width_mm;
predictedW_mm = predicted_width_mm;

realH_mm      = realW_mm      * ar_h_over_w;
perceivedH_mm = perceivedW_mm * ar_h_over_w;
predictedH_mm = predictedW_mm * ar_h_over_w;

% Gap between shapes (mm)
% (Chosen to preserve the prior visual spacing when widths are derived from
% the previous radius convention: width = (2*radius)/28.5.)
gap_mm = realW_mm * ar_h_over_w / 2;

% -------------------- Canvas size & resolution --------------------------
resolution_pixels_per_mm = 1;

% Total width = sum widths + outer margins + inter-shape gaps
imgWidth_mm  = (realW_mm + perceivedW_mm + predictedW_mm) + 4*gap_mm;
imgHeight_mm = max([realH_mm, perceivedH_mm, predictedH_mm]) + 4*gap_mm;
fprintf('Image W=%.1f mm, H=%.1f mm\n', imgWidth_mm, imgHeight_mm);

imgWidth_pixels  = ceil(imgWidth_mm  * resolution_pixels_per_mm);
imgHeight_pixels = ceil(imgHeight_mm * resolution_pixels_per_mm);

% White background image (uint8 RGB)
img = ones(imgHeight_pixels, imgWidth_pixels, 3, 'uint8') * 255;

% --------------------- Rectangle placement (mm) -------------------------
% Centers are placed left-to-right with fixed gaps.
centerY_mm = imgHeight_mm/2;

realCenterX_mm      = gap_mm + realW_mm/2;
perceivedCenterX_mm = realCenterX_mm + realW_mm/2 + gap_mm + perceivedW_mm/2;
predictedCenterX_mm = perceivedCenterX_mm + perceivedW_mm/2 + gap_mm + predictedW_mm/2;

% Convert to pixels
cx = [realCenterX_mm, perceivedCenterX_mm, predictedCenterX_mm] * resolution_pixels_per_mm;
cy = centerY_mm * resolution_pixels_per_mm;

Wpx = [realW_mm, perceivedW_mm, predictedW_mm] * resolution_pixels_per_mm;
Hpx = [realH_mm, perceivedH_mm, predictedH_mm] * resolution_pixels_per_mm;

% Convert center-based representation to top-left for insertShape
% insertShape 'FilledRectangle' expects [x y width height] where (x,y) is top-left
xTL = cx - Wpx/2;
yTL = cy - Hpx/2;

rects = [xTL(:), yTL(:), Wpx(:), Hpx(:)];

% ---------------------------- Draw --------------------------------------
img = insertShape(img, 'FilledRectangle', rects, 'ShapeColor', mycolor, 'Opacity', 1);

fh = figure('Color',[1 1 1]);
imshow(img);
ax = gca;
hold(ax,'on');

% ------------------------- Text annotations -----------------------------
% "Above" means smaller y (image coordinates)
yTop_all = yTL; % top edges in pixels
labelPad_pixels = 0.08 * max(Hpx);
yLabel_pixels = min(yTop_all) - labelPad_pixels;
yLabel_pixels = max(1, yLabel_pixels);

labels = {'R','P','E'};
for i = 1:3
    text(cx(i), yLabel_pixels, labels{i}, ...
        'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
        'Color','k', 'FontName','Avenir', 'FontSize', 24);
end

% Bottom-left parameter text
xBL_pixels = resolution_pixels_per_mm;
yBL_pixels = imgHeight_pixels - resolution_pixels_per_mm;
text(xBL_pixels, yBL_pixels, textstring, ...
    'HorizontalAlignment','left', 'VerticalAlignment','bottom', ...
    'Color','k', 'FontName','Avenir', 'FontSize', 24);

% ----------------------------- Save -------------------------------------
if saveFlag
    exportgraphics(fh, saveFilename, 'Resolution', 600);
end

end
