function [PM, realheight_mm, perceivedheight_mm] = visualizeRealPerceivedPredictedSize_VA_D_E_model(lme_logPM_by_logAngleNDistanceNElevation,VA,D,E,distance_mm, saveFilename)
% visualizeRealPerceivedPredictedSize_VA_D_E_model(lme_logPM_by_logAngleNDistanceNElevation,VA,D,E,distance_mm, saveFilename)
%  visualize real, perceived, and predicted size  size for
%  object of visual angle VA at a distance D and elevation E at aviewing distance of distance_mm
%  PM is evaluted by model: 
% PM=2^intercept_fe*(Distance).^Distance_fe*(1+Elevation).^Elevation_fe
% where model parameters are estimated from lme_logPM_by_logAngleNDistanceNElevation
%
% default visualization parameters
% VA=.5;
% D=100;
% E=0;
% distance_mm=500;
% 

if ~exist('lme_logPM_by_logAngleNDistanceNElevation','var')
    disp('Error: no model cannot visualize perceived size')
end

% default parameters
if ~exist ('VA', 'var')
    VA=.5;
end
if ~exist ('D', 'var')
    D=100;
end
if ~exist('E')
    E=0;
end
if ~exist('distance_mm','var')
    distance_mm=500;
end
if ~exist('saveFilename','var')
    saveFlag=0;
    saveFilename=[];
else
    saveFlag = 1; % Default value for saveFlag
end

% estimate perceptual magnification PM

PM=evaluatePMbyVisualAngleDistanceElevation(lme_logPM_by_logAngleNDistanceNElevation,VA,D,E);
fprintf('Perceptual magnification of %.1f of VA=%.1f[deg] D=%d[m] E=%.1f[deg]\n', PM, VA, round(D), E);
perceivedVA=VA*PM; % estimate perceived VA

[realheight_mm,perceivedheight_mm] = visualizePM(VA,perceivedVA,distance_mm,saveFlag,saveFilename)


end