function drawPM(circleRadius_mm, perceivedRadius_mm, saveFlag,saveFilename)
% drawPM(PM,circleRadius_mm, saveFlag,saveFileame)
%
% draws two black circles one circleRadius_mm and one the
% perceptually magnified circle PM*circleRadius_mm
% if saveFlag==1 will save the image in saveFilename
% set defaults
%  if ~exist('PM' )
%     PM = 1;
% end
% if ~exist('circleRadius_mm' )
%     circleRadius_mm = 5;
% end
% 
% if ~exist ('saveFlag')
%     saveFlag = 0
%  end
% KGS 7/25
%s
if ~exist('PM' )
   PM = 1;
end
if ~exist('circleRadius_mm' )
    circleRadius_mm = 5;
end
if ~exist ('saveFlag')
    saveFlag = 0
end
if ~exist ('saveFilename')
    'PerceptualMagnification_example.png'
end

% Define image dimensions and resolution (e.g., 100 pixels/cm)
imgWidth_mm = 100; % Width of the image in centimeters
imgHeight_mm = 100; % Height of the image in centimeters
resolution_pixels_per_mm = 10; 


% Convert image dimensions to pixels
imgWidth_pixels = imgWidth_mm * resolution_pixels_per_mm;
imgHeight_pixels = imgHeight_mm * resolution_pixels_per_mm;

% Create a white background image (RGB format, all channels 255 for white)
img = ones(imgHeight_pixels, imgWidth_pixels, 3, 'uint8') * 255; 


% Define circle properties in millimeters
circleCenter_x_mm = imgWidth_mm/2-imgWidth_mm/8; % Center the 1st circle horizontally in the image
circleCenter_y_mm = imgHeight_mm/2; % Center the 1st circle vertically in the image
PMcircleCenter_x_mm = imgWidth_mm/2+imgWidth_mm/8; % Center the 2nd circle horizontally in the image
PMcircleCenter_y_mm = imgHeight_mm/2; % Center the 2nd circle vertically in the image

% Convert circle properties from millimeters to pixels
circleRadius_pixels = circleRadius_mm * resolution_pixels_per_mm; 
PMcircleRadius_pixels =perceivedRadius_mm * resolution_pixels_per_mm; 

circleCenter_x_pixels = circleCenter_x_mm * resolution_pixels_per_mm;
circleCenter_y_pixels = circleCenter_y_mm * resolution_pixels_per_mm;

PMcircleCenter_x_pixels = PMcircleCenter_x_mm * resolution_pixels_per_mm;


% Draw a filled black circle using insertShape
% The position vector is [x, y, radius]
img   = insertShape(img, 'FilledCircle', [circleCenter_x_pixels, circleCenter_y_pixels, circleRadius_pixels], 'Color', 'Black','Opacity',1);
img= insertShape(img, 'FilledCircle', [PMcircleCenter_x_pixels, circleCenter_y_pixels,PMcircleRadius_pixels], 'Color', 'Black','Opacity',1);

figure('Color',[1 1 1])

% Display the image
imshow(img);
% Optional: Save the image
if saveFlag
    imwrite(img, saveFilename);
end