function [height] = visualangle2height(visual_angle,distance)
% 
% [height] = visualangle2height(visual_angle,distance)
% calculates the height of an object that extends a certain visual angle at a certain distance
% height is the same units as the distance
% visual angle is in degrees
    height=2*distance.*tan([pi*visual_angle/180]/2);
end