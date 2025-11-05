function [distance] = visualangle2distance(visual_angle,height)
% 
% [distance] = visualangle2distance(visual_angle,height)
% calculates the distance of an object of certain height that extends a certain visual angle
% distace is the same units as height
% visual angle is in degrees
    distance =2*height/(2*tan(pi*visual_angle/180));
end