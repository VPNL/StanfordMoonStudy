function [lme_logPM_by_logAngleNDistanceNElevation]=test_PM_by_task(tbl,tblName,ResultsDir,saveLME,colormap, sorted_idx)
% [lme_logPM_by_logAngleNDistanceNElevation]=test_PM_by_task(tbl,tblName,ResultsDir,saveLME,colormap, sorted_idx)
% 
% This function gets the task relevant data of the Stanford Quad Experiment
% and plots the relation 
% between log2(PM) and each of log2(VA), log2(D), log2(E)
% then uses fitlme to determine if all factors are signficant 
% and estimates the coeffients of the function:
% PM=C*VA^n1*D^n2*(1+E)^n3
% PM: Perceptual magnification
% VA: visual angle (degrees)
% D: distance (meters)
% E: elevation in degrees (as elevation is relative to the ground and can
% start at zero we add a regularization term (1)
% 
% tbl:        data table
% tblname:    table name that indicates the original file and the task
% ResultsDir: directory where the results are saved
% saveLME:    save flag 1: saves the fitlme results; 0: doesn't save
% colormap:   which colormap to use for scatter plot  
% sorted_idx: index of sorted colormap 
% 
% It returns  the lme it estimates: lme_logPM_by_logAngleNDistanceNElevation
% KGS Nov 2025
%
% defaults
% if ~exist('dataDir')
%     dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
% end
% 
% 


%% find max angle and maxRatio for graphs

uniqueID=unique(tbl.ID);
nsubjects=length(uniqueID);
maxRealAngle=max(tbl.Real_Visual_Angle);
minRealAngle=min(tbl.Real_Visual_Angle);
maxAngle=max(tbl.Reported_Visual_Angle);
minAngle=min(tbl.Reported_Visual_Angle);
maxRatio=max(tbl.Ratio_Visual_Angle);
minRatio=min(tbl.Ratio_Visual_Angle);
maxDistance=max(tbl.Distance);
minDistance=min(tbl.Distance);
maxPMLim=16;
minPMLim=.25;
if maxRatio>maxPMLim
    fprintf(1,'Warning: max Ratio %.2f exceeds Ylim max %.2f\n', maxRatio, maxPMLim)
end
if minRatio<minPMLim
    fprintf(1,'Warning: max Ratio %.2f less than Ylim ,om %.2f\n', minRatio, monPMLim)
end

tbl.log2real_visual_angle=log2(tbl.Real_Visual_Angle);
tbl.log2ratio_visual_angle=log2(tbl.Ratio_Visual_Angle);
tbl.log2distance=log2(tbl.Distance);
tbl.log2elevation=log2(tbl.Elevation+1); % add a regularization term so that the log won't explode for an elevation of 0


lme_logPM_by_logAngleNDistanceNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + log2elevation+ (1| ID)');
if saveLME
    lme_logPM_by_logAngleNDistanceNElevation
    fprintf('log PM by log visualangle, distance,elevation Rsq=%.3f RsqAdjusted=%.3f\n',...
        lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Ordinary,lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Adjusted);
  
        diary off
end

%% full model
%lme_logPM_by_logAngleNDistanceNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + log2elevation+ (1| ID)');
% first coefficient intercept
%log2real_visual_angle
%log2distance
%log2elevation

intercept_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(1);
VA_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(2);
pval_VA=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.pValue(2);
distance_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(3);
pval_distance=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.pValue(3);
elevation_fe=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(4);
pval_elevation=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.pValue(4);
% full formula
fprintf(1,'PM=%.2f(visual_angle)^{%.2f}(distance)^{%.2f}(1+elevation)^{%.2f}\n p_VA=%-.2e, p_distance=%-.2e, p_elevation=%-.2e n=%d\n',...
    2.^intercept_fe,VA_fe,distance_fe,elevation_fe,pval_VA,pval_distance,pval_elevation, nsubjects);

%%
% set sorted colormap
ID=tbl.ID;
clear subjectcolor
for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=colormap(sorted_cindex,:);
end


% plot results
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5],'Name',tblName)
markerSize=50;

mean_intercept_angle=intercept_fe;
mean_slope_angle=VA_fe; 
pval_angle=pval_VA;

% get upper and lower coeffiecents
mean_intercept_angleL=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Lower(1)
mean_slope_angleL=lme_lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Lower(2)
mean_intercept_angleU=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Upper(1)
mean_slope_angleU=llme_logPM_by_logAngleNDistanceNElevation.Coefficients.Upper(2)
% 
% set plotting range
xlinerange=log2(minRealAngle):.01:log2(maxRealAngle);
ylinerange=zeros(size(xlinerange));
xvectoru=xlinerange;
xvectord = sort(xvectoru, 'descend');

% fixed effects estimate
y_fit =mean_intercept_angle+mean_slope_angle*xlinerange;


% fixed effects confidence interval
yvector1=mean_slope_angleL*xvectoru+mean_intercept_angleL;
yvector2=mean_slope_angleU*xvectord+mean_intercept_angleU;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

subplot(1,3,1); 
hold on 
scatter(tbl.log2real_visual_angle, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled');    % individual data scatter; colroed by subject color
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
plot (xlinerange, mean_intercept_angle+mean_slope_angle*xlinerange,'k-','LineWidth',3); % fixed effect
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.4); % confidence interval

tickdelta=[log2(maxRealAngle)-log2(minRealAngle)]/3;
%set(gca,'XTick',log2(minRealAngle):tickdelta:log2(maxRealAngle),'XTickLabel',round(2.^[log2(minRealAngle):tickdelta:log2(maxRealAngle)],2),'XTickLabelRotation',90);

set(gca,'XTick',log2(minRealAngle):tickdelta:log2(maxRealAngle),'XTickLabel',round(2.^[log2(minRealAngle):tickdelta:log2(maxRealAngle)],2));
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim):1: ceil(log2(maxPMLim))]));
xlim([log2(minRealAngle*.95) log2(maxRealAngle*1.05)])

ylim([log2(minPMLim) ceil(log2(maxPMLim))])
xlabel ('Real Visual Angle [degree], log scale')
ylabel ('Perceptual Magnification, log scale')
titlestr=sprintf('PM=%.2fVA^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_angle,mean_slope_angle,pval_angle, nsubjects);
title(titlestr)
set(gca,'FontName','Avenir','FontSize',16)

% plot PM by distance different colors per subject sorted by PM in perceptual task
%
mean_slope_distance=lme_logPM_by_logAngleNDistanceNElevation.Estimate(3);
mean_intercept_distance=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(1);
pval_distance=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.pValue(3);

% get upper and lower coeffiecents
mean_intercept_distanceL=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Lower(1);
mean_slope_distanceL=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Lower(3);
mean_intercept_distanceU=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Upper(1);
mean_slope_distanceU=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Upper(3);
% 
% set plotting range
xlinerange=log2(minDistance-1):.05:log2(maxDistance+1); 
ylinerange=zeros(size(xlinerange));
xvectoru=xlinerange;
xvectord = sort(xvectoru, 'descend');

% fixed effects confidence interval
yvector1=mean_slope_distanceL*xvectoru+mean_intercept_distanceL;
yvector2=mean_slope_distanceU*xvectord+mean_intercept_distanceU;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

subplot(1,3,2); 
hold on 
scatter(tbl.log2distance, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled'); % individual subject data
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
plot (xlinerange, mean_intercept_distance+mean_slope_distance*xlinerange,'k-','LineWidth',3); % fixed effects linear estimate
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.4); % confidence interval on fixed effect

%set(gca,'XTick',log2(minDistance):.05:log2(maxDistance),'XTickLabel',2.^[log2(minDistance):1:log2(maxDistance)],'XTickLabelRotation',90);
tickdelta=[log2(maxDistance)-log2(minDistance)]/3;
%set(gca,'XTick',log2(minDistance):tickdelta:log2(maxDistance),'XTickLabel', round(2.^[log2(minDistance):tickdelta:log2(maxDistance)],2),'XTickLabelRotation',90);
set(gca,'XTick',log2(minDistance):tickdelta:log2(maxDistance),'XTickLabel', round(2.^[log2(minDistance):tickdelta:log2(maxDistance)],2));
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
xlim([log2(minDistance*.95) log2(maxDistance*1.05)]);
ylim([log2(minPMLim) ceil(log2(maxPMLim))])
xlabel ('Distance [m], log scale')
ylabel ('Perceptual Magnification, log scale')
mean_slope=lme_logPM_by_logDistance.Coefficients.Estimate(2);
pval=lme_logPM_by_logDistance.Coefficients.pValue(2);
titlestr=sprintf('PM=%.2fD^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_distance,mean_slope_distance,pval_distance, nsubjects);

title(titlestr)
set(gca,'FontName','Avenir','FontSize',16)

%% plot by elevation
mean_slope_elevation=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(4);
mean_intercept_elevation=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Estimate(1);
pval_elevation=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.pValue(4);


% get upper and lower coeffiecents
mean_intercept_elevationL=lme_logPM_by_logAngleNDistanceNElevation.Lower(1);
mean_slope_elevationL=lme_lme_logPM_by_logAngleNDistanceNElevation.Lower(4);
mean_intercept_elevationU=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Upper(1);
mean_slope_elevationU=lme_logPM_by_logAngleNDistanceNElevation.Coefficients.Upper(4);
% 
% set plotting range
minlogElevation=min(tbl.log2elevation);
maxlogElevation=max(tbl.log2elevation);
xlinerange=minlogElevation:.05:maxlogElevation; 
ylinerange=zeros(size(xlinerange));

xvectoru=xlinerange;
xvectord = sort(xvectoru, 'descend');

% fixed effects confidence interval
yvector1=mean_slope_elevationL*xvectoru+mean_intercept_elevationL;
yvector2=mean_slope_elevationU*xvectord+mean_intercept_elevationU;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

subplot(1,3,3); 
hold on 
scatter(tbl.log2elevation, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled');

plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
plot (xlinerange, mean_intercept_elevation+mean_slope_elevation*xlinerange,'k-','LineWidth',3); % fixed effects linear estimate
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.4); % confidence interval on fixed effect

%set(gca,'XTick',0:.11:maxElevation,'XTickLabel',2.^[log2(minDistance):1:log2(maxDistance)],'XTickLabelRotation',0);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
%set(gca,'XTick',minlogElevation:1:maxlogElevation,'XTickLabel',2.^[minlogElevation:1:maxlogElevation],'XTickLabelRotation',0);
set(gca,'XTick',minlogElevation:1:maxlogElevation,'XTickLabel',round(2.^[(minlogElevation):1:(maxlogElevation)]-1,2),'XTickLabelRotation',0);

ylim([log2(minPMLim) ceil(log2(maxPMLim))])
xlabel ('Elevation [degree], logscale')
ylabel ('Perceptual Magnification, log scale')
titlestr=sprintf('slope=%-.2f, p=%-.2e \n n=%d',mean_slope_elevation,pval_elevation, nsubjects);
titlestr=sprintf('PM=%.2f(1+E)^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);

title(titlestr)
set(gca,'FontName','Avenir','FontSize',16)

%% save figure
filenamePNG=fullfile(ResultsDir, [tblName '.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);







% 