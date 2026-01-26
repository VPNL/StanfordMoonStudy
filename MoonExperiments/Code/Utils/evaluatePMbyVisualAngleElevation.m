function  PM=evaluatePMbyVisualAngleElevation(lme_logPM_by_logAngleNElevation,VisualAngle,Elevation)
%  PM=evaluatePMbyVAElevation(lme_logPM_by_logDistanceNElevation,VisualAngle,Elevation)
% Input lme of the form:
% log2PM ~ log2D  + log2E + (1| ID)');
% Evaluate PM for the input distance and elevation
% PM=2^intercept_fe*(Distance).^Distance_fe*(1+Elevation).^Elevation_fe


intercept_fe=lme_logPM_by_logAngleNElevation.Coefficients.Estimate(1);
VA_fe=lme_logPM_by_logAngleNElevation.Coefficients.Estimate(2);
Elevation_fe=lme_logPM_by_logAngleNElevation.Coefficients.Estimate(3);

PM=2^intercept_fe*(VisualAngle).^VA_fe*(1+Elevation).^Elevation_fe;

