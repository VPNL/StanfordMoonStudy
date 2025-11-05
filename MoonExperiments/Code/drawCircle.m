function drawcircle(circleRadius_mm, imgWidth, imgHeight,resolution_pixels_per_mm)
% drawcircle(circleRadius_mm, imgWidth, imgHeight,resolution_pixels_per_cm)
%
% set defaults
% if ~exist('circleRadius_mm' )
%     circleRadius_mm = 5;
% end
% 
% % Define image dimensions and resolution (e.g., 100 pixels/cm)
% if ~exist ('imgWidth')
%     imgWidth_cm = 10; % Width of the image in centimeters
% end
% if ~exist ('imgHeight')
%    imgHeight_cm = 10; % Height of the image in centimeters
% end
%  %
%  if ~exist ('resolution_pixels_per_cm')
%     resolution_pixels_per_cm = 100; 
%  end


if ~exist('circleRadius_mm' )
    circleRadius_mm = 5;
end
% Define image dimensions and resolution (e.g., 100 pixels/cm)
if ~exist ('imgWidth')
    imgWidth_mm = 100; % Width of the image in centimeters
end
if ~exist ('imgHeight')
   imgHeight_mm = 100; % Height of the image in centimeters
end
 %
 if ~exist ('resolution_pixels_per_cm')
    resolution_pixels_per_mm = 10; 
 end

% Convert image dimensions to pixels
imgWidth_pixels = imgWidth_mm * resolution_pixels_per_mm;
imgHeight_pixels = imgHeight_mm * resolution_pixels_per_mm;

% Create a white background image (RGB format, all channels 255 for white)
img = ones(imgHeight_pixels, imgWidth_pixels, 3, 'uint8') * 255; 


% Define circle properties in millimeters
circleCenter_x_mm = imgWidth_mm/2; % Center the circle horizontally in the image
circleCenter_y_mm = imgHeight_mm/2; % Center the circle vertically in the image

% Convert circle properties from millimeters to pixels
circleRadius_pixels = circleRadius_mm * resolution_pixels_per_mm; 
circleCenter_x_pixels = circleCenter_x_mm * resolution_pixels_per_mm;
circleCenter_y_pixels = circleCenter_y_mm * resolution_pixels_per_mm;

% Draw a filled black circle using insertShape
% The position vector is [x, y, radius]
img = insertShape(img, 'FilledCircle', [circleCenter_x_pixels, circleCenter_y_pixels, circleRadius_pixels], 'Color', 'black','Opacity',1);

figure('Color',[1 1 1])

% Display the image
imshow(img);

% Optional: Save the image
% imwrite(img, 'black_circle.png');
