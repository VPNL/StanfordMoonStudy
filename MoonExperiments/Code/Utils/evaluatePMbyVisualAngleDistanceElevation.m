function  PM=evaluatePMbyVisualAngleDistanceElevation(lme_logPM_by_logAngleNDistanceNElevation,VisualAngle,Distance,Elevation)
%  PM=evaluatePMbyVAElevation(lme_logPM_by_logAngleNDistanceNElevation,VisualAngle,Distance,Elevation)
% Input lme of the form:
% log2PM ~ log2D  + log2E + (1| ID)');
% Evaluate PM for the input distance and elevation
% PM=2^intercept_fe*(Distance).^Distance_fe*(1+Elevation).^Elevation_fe


intercept_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(1);
VA_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(2);
Distance_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(3);
Elevation_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(4);

PM=2^intercept_fe*(VisualAngle).^VA_fe*Distance.^Distance_fe*(1+Elevation).^Elevation_fe;

