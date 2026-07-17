function [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
    lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
    lme_logPM_by_logAngleNDistanceNElevation]=PM_lmes(tbl,tblName)
% [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
% lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
% lme_logPM_by_logAngleNDistanceNElevation]=PM_lmes(tbl,tblName)
% 
% 
% This function evalutes several lmes for PM:
% single factor lmes
% lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
% dual factor lmes
% lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
% tripple factor lme
% lme_logPM_by_logAngleNDistanceNElevation
%
% Inputs: 
% tbl:        data table
% tblname:    table name 
% It returns the lme it estimates 
% 
% KGS Jan 2026

%% find max angle and maxRatio for graphs


tbl.log2real_visual_angle=log2(tbl.Real_Visual_Angle);
tbl.log2ratio_visual_angle=log2(tbl.Ratio_Visual_Angle); % Ratio_Visual_Angle is PM
tbl.log2distance=log2(tbl.Distance);
tbl.log2elevation=log2(tbl.Elevation+1); % add a regularization term so that the log won't explode for an elevation of 0

lme_logPM_by_logAngle= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle +  (1| ID)');
lme_logPM_by_logDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2distance +  (1| ID)');
lme_logPM_by_logElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2elevation +  (1| ID)');

lme_logPM_by_logAngleNDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + (1| ID)');
lme_logPM_by_logAngleNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2elevation + (1| ID)');
lme_logPM_by_logDistanceNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2distance + log2elevation + (1| ID)');

lme_logPM_by_logAngleNDistanceNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + log2elevation+ (1| ID)');



% 