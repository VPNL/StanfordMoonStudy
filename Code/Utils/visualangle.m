function [visual_angle] = visualangle(height,distance)
% [visual_angle] = visual_angle(height,distance)
% calculates visual angle in degrees based on object height and distance
% which should be in the same units
%  
visual_angle=2*180*atan(height/(2*distance))/pi;
end