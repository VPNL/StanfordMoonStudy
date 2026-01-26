function [realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveFlag,saveFilename,mycolor)
%[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveFlag,saveFilename)
%  Function visualizes perceptual magnification
%  Default distance is hand length ~ 50cm or 500mm from the observer  
%  In this functiona ll distances are in mm
%
% KGS 7/25
%
if ~exist('realVA')
     realVA=0.5398 ;% average visual angle in our experiments
end
if ~exist('perceivedVA')
     perceivedVA=1.89; % estimated moon size at horizon from our measurements
end
if ~exist('distance_mm')
   distance_mm=500; % mm from observer
end
if ~exist('saveFlag')
    saveFlag=0;
end
if ~exist('saveFilename')
    saveFilename='test.png';
end
if ~exist('mycolor')
    mycolor=[1 0.8 0.1];
end

realheight_mm=visualangle2height(realVA,distance_mm);
perceivedheight_mm=visualangle2height(perceivedVA,distance_mm);
drawPM(realheight_mm/2, perceivedheight_mm/2, saveFlag,saveFilename,mycolor)

end