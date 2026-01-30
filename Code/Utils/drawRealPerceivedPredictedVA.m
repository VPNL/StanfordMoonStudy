function drawRealPerceivedPredictedVA(realRadius_mm, perceivedRadius_mm, predictedRadius_mm, textstring, saveFlag,saveFilename, mycolor)
% drawRealPerceivedPredictedVA(circleRadius_mm, perceivedRadius_mm, textstring, saveFlag,saveFilename, mycolor)
%
% draws three circles of radii:
% realRadius_mm, perceivedRadius_mm, predictedRadius_mm,
% in color mycolor:
%
% Defaults
%  mycolor=[1 .8 .1];
%  saveFlag = 0
%  saveFilename='Example.png';
%  plotgap=circleRadius_mm/4;
% KGS 1/26



% Defaults
if ~exist ('textstring','var')
    textstring=''
end
if ~exist('mycolor')
    mycolor=[1 .8 .1];
end

if ~exist ('saveFlag')
    saveFlag = 0;
end
if ~exist ('saveFilename')
    saveFilename='Example.png';
end
if ~exist('gap_mm','var')
    gap_mm=realRadius_mm;
end

if nargin<3 
    Disp('Error, need radii of 3 circles\n')
    return
end


% Define image dimensions and resolution (e.g., 100 pixels/cm)
imgWidth_mm = 2*(realRadius_mm+ perceivedRadius_mm+predictedRadius_mm)+4*gap_mm; % Width of the image in centimeters
imgHeight_mm = 2*max([realRadius_mm, perceivedRadius_mm, predictedRadius_mm])+4*gap_mm; % Height of the image in centimeters
resolution_pixels_per_mm = 10; 
fprintf('Image W=%.1f mm, H=%.1f\n',imgWidth_mm,imgHeight_mm);

% Convert image dimensions to pixels
imgWidth_pixels = ceil(imgWidth_mm * resolution_pixels_per_mm);
imgHeight_pixels = ceil(imgHeight_mm * resolution_pixels_per_mm);

% Create a white background image (RGB format, all channels 255 for white)
img = ones(imgHeight_pixels, imgWidth_pixels, 3, 'uint8') * 255; 


% Define circle properties in millimeters
realCenter_x_mm = gap_mm+realRadius_mm; % Center the 1st circle horizontally in the image
realCenter_y_mm = imgHeight_mm/2; % Center the 1st circle vertically in the image
perceivedCenter_x_mm = gap_mm*2+realRadius_mm*2+perceivedRadius_mm; % Center the 2nd circle horizontally in the image
perceivedCenter_y_mm = imgHeight_mm/2; % Center the 2nd circle vertically in the image
predictedCenter_x_mm = gap_mm*3+realRadius_mm*2+perceivedRadius_mm*2+predictedRadius_mm; % Center the 2nd circle horizontally in the image
predictedCenter_y_mm = imgHeight_mm/2; % Center the 2nd circle vertically in the image

% Convert circle properties from millimeters to pixels
realRadius_pixels = realRadius_mm * resolution_pixels_per_mm; 
realCenter_x_pixels = realCenter_x_mm * resolution_pixels_per_mm;
realCenter_y_pixels = realCenter_y_mm * resolution_pixels_per_mm;

perceivedRadius_pixels =perceivedRadius_mm * resolution_pixels_per_mm; 
perceivedCenter_x_pixels = perceivedCenter_x_mm * resolution_pixels_per_mm;
perceivedCenter_y_pixels = perceivedCenter_y_mm * resolution_pixels_per_mm;


predictedRadius_pixels =predictedRadius_mm * resolution_pixels_per_mm; 
predictedCenter_x_pixels = predictedCenter_x_mm * resolution_pixels_per_mm;
predictedCenter_y_pixels = predictedCenter_y_mm * resolution_pixels_per_mm;



% Draw a filled black circle using insertShape
% The position vector is [x, y, radius]
img= insertShape(img, 'FilledCircle', [realCenter_x_pixels, realCenter_y_pixels, realRadius_pixels], 'ShapeColor', mycolor,'Opacity',1);
img= insertShape(img, 'FilledCircle', [perceivedCenter_x_pixels, perceivedCenter_y_pixels,perceivedRadius_pixels], 'ShapeColor',mycolor ,'Opacity',1);
img= insertShape(img, 'FilledCircle', [predictedCenter_x_pixels, predictedCenter_y_pixels,predictedRadius_pixels], 'ShapeColor',mycolor ,'Opacity',1);

%%
fh=figure('Color',[1 1 1])

% Display the image
imshow(img);


% -------------------------------------------------------------------------
% Text annotations
%   - Labels above each circle: real / perceived / predicted
%   - Bottom-left label for parameters: VA / D / E
% Note: imshow uses image coordinates (x increases rightward; y increases
% downward). Therefore, "above" a circle means a smaller y value.
% -------------------------------------------------------------------------
ax = gca;
hold(ax,'on');

% Compute a common y-position (same height) for the three labels
yTop_real      = realCenter_y_pixels      - realRadius_pixels;
yTop_perceived = perceivedCenter_y_pixels - perceivedRadius_pixels;
yTop_predicted = predictedCenter_y_pixels - predictedRadius_pixels;

labelPad_pixels = 0.08 * max([realRadius_pixels, perceivedRadius_pixels, predictedRadius_pixels]);
yLabel_pixels = min([yTop_real, yTop_perceived, yTop_predicted]) - labelPad_pixels;
yLabel_pixels = max(1, yLabel_pixels); % keep on-canvas

text(realCenter_x_pixels,      yLabel_pixels, 'real', ...
    'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
    'Color','k','FontName','Avenir', 'FontSize', 24);
text(perceivedCenter_x_pixels, yLabel_pixels, 'perceived', ...
    'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
    'Color','k','FontName','Avenir', 'FontSize', 24);
text(predictedCenter_x_pixels, yLabel_pixels, 'predicted', ...
    'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
    'Color','k','FontName','Avenir', 'FontSize', 24);

% Bottom-left parameter text
xBL_pixels = resolution_pixels_per_mm;
yBL_pixels = imgHeight_pixels-resolution_pixels_per_mm;
text(xBL_pixels, yBL_pixels, textstring ,...
    'HorizontalAlignment','left', 'VerticalAlignment','bottom', ...
    'Color','k', 'FontName','Avenir', 'FontSize', 24);

% Optional: Save the image
if saveFlag
    exportgraphics(fh,saveFilename,'Resolution',600);
end