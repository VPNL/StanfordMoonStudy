function  PM=evaluatePMbyDistanceElevation(lme_logPM_by_logDistanceNElevation,Distance,Elevation)
%  PM=evaluatePMbyDistanceElevation(lme_logPM_by_logDistanceNElevation,Distance,Elevation)
% Input lme of the form:
% log2PM ~ log2D  + log2E + (1| ID)');
% Evaluate PM for the input distance and elevation
% PM=2^intercept_fe*(Distance).^Distance_fe*(1+Elevation).^Elevation_fe


intercept_fe=lme_logPM_by_logDistanceNElevation.Coefficients.Estimate(1);
Distance_fe=lme_logPM_by_logDistanceNElevation.Coefficients.Estimate(2);
Elevation_fe=lme_logPM_by_logDistanceNElevation.Coefficients.Estimate(3);

PM=2^intercept_fe*(Distance).^Distance_fe*(1+Elevation).^Elevation_fe;

