function [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
    lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
    lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task_rad(tbl,tblName,ResultsDir,saveLME,colormap, sorted_idx,ElevationTransform,degreeFlag)
% [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
% lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
% lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(tbl,tblName,ResultsDir,saveLME,colormap, sorted_idx,ElevationTransform)
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
% E: elevation in radians (as elevation is relative to the horizon and can
% start at zero we add a regularization term (1)
% the tables are in degrees so we will need to transform to radian
% 
% tbl:        data table
% tblname:    table name that indicates the original file and the task
% ResultsDir: directory where the results are saved
% saveLME:    save flag 1: saves the fitlme results; 0: doesn't save
% colormap:   which colormap to use for scatter plot  
% sorted_idx: index of sorted colormap 
% ObserverFlag: 1 for line of sight referred distances and elevations; 
%               0  for ground referred values
% 
% It returns all of the lme it estimates on the way
% single factor lmes
% lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
% dual factor lmes
% lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
% tripple factor lme
% lme_logPM_by_logAngleNDistanceNElevation

% KGS Nov 2025
%
% defaults
if ~exist('dataDir')
    dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
end

if ~exist('ElevationTransform')
    ElevationTransform=3;
end
if ~exist('degreeFlag')
    degreeFlag=0;
end
ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'rad');



%% find max angle and maxRatio for graphs
% minElevation=min(tbl.Elevation);
% if minElevation<1
%     disp('error: there are negative elevations, log not defined')
%     return
% end
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

if ElevationTransform==3 
    % tranform to radian
    tbl.ElevationRad=pi*(tbl.Elevation)/180;
    tbl.log2elevation=log2(tbl.ElevationRad+1); % add a regularization term so that the log won't explode for an elevation of 0
elseif ElevationTransform==4
    % tranform to radian and take absoluted value
    tbl.ElevationRad=pi*(tbl.Elevation)/180;
    tbl.log2elevation=log2(abs(tbl.ElevationRad)+1); % take absolute values of elevations to deal with negative elevations
else
    error('Invalid elevation transform value')
    return
end

lme_logPM_by_logAngle= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle +  (1| ID)');
lme_logPM_by_logDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2distance +  (1| ID)');
lme_logPM_by_logElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2elevation +  (1| ID)');

lme_logPM_by_logAngleNDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + (1| ID)');
lme_logPM_by_logAngleNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2elevation + (1| ID)');
lme_logPM_by_logDistanceNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2distance + log2elevation + (1| ID)');

lme_logPM_by_logAngleNDistanceNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + log2elevation+ (1| ID)');
if saveLME
    savelmefile=fullfile(ResultsDir, [tblName '.txt']);
    diary(savelmefile)
    lme_logPM_by_logAngle
    fprintf('log PM by log angle:                          Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logAngle.Rsquared.Ordinary,lme_logPM_by_logAngle.Rsquared.Adjusted);
    lme_logPM_by_logDistance
    fprintf('log PM by log distance                        Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logDistance.Rsquared.Ordinary,lme_logPM_by_logDistance.Rsquared.Adjusted);
    lme_logPM_by_logElevation
    fprintf('log PM by log elevation                       Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logElevation.Rsquared.Ordinary,lme_logPM_by_logElevation.Rsquared.Adjusted);
    lme_logPM_by_logAngleNDistance
    lme_logPM_by_logAngleNElevation
    lme_logPM_by_logDistanceNElevation
    lme_logPM_by_logAngleNDistanceNElevation
    fprintf('log PM by log visualangle, distance,elevation Rsq=%.3f RsqAdjusted=%.3f\n',...
        lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Ordinary,lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Adjusted);
  
    % testing if models with 2 parameters better explain the data
    compare(lme_logPM_by_logAngle,lme_logPM_by_logAngleNDistance) 
    compare(lme_logPM_by_logAngle,lme_logPM_by_logAngleNElevation) 
    compare(lme_logPM_by_logDistance,lme_logPM_by_logAngleNDistance)
    compare(lme_logPM_by_logDistance,lme_logPM_by_logDistanceNElevation)
    compare(lme_logPM_by_logElevation,lme_logPM_by_logAngleNElevation) 
    compare(lme_logPM_by_logElevation,lme_logPM_by_logDistanceNElevation)
    
    % test if model with 3 parameters is better than models with 2
    % parameters
    compare(lme_logPM_by_logAngleNDistance,lme_logPM_by_logAngleNDistanceNElevation) 
    compare(lme_logPM_by_logAngleNElevation,lme_logPM_by_logAngleNDistanceNElevation) 
    compare(lme_logPM_by_logDistanceNElevation,lme_logPM_by_logAngleNDistanceNElevation) 
    
    % compare model with all 3 parameters compared to single parameter
    % modes
    compare(lme_logPM_by_logAngle,lme_logPM_by_logAngleNDistanceNElevation) 
    compare(lme_logPM_by_logDistance,lme_logPM_by_logAngleNDistanceNElevation) 
    compare(lme_logPM_by_logElevation,lme_logPM_by_logAngleNDistanceNElevation)  
    fprintf('log PM by logAngle logDistance and logElevation: Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Ordinary,lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Adjusted);
    diary off
end


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
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .7],'Name',tblName)
markerSize=50;

mean_intercept_angle=lme_logPM_by_logAngle.Coefficients.Estimate(1);
mean_slope_angle=lme_logPM_by_logAngle.Coefficients.Estimate(2);
pval_angle=lme_logPM_by_logAngle.Coefficients.pValue(2);

% get upper and lower coeffiecents
mean_intercept_angleL=lme_logPM_by_logAngle.Coefficients.Lower(1)
mean_slope_angleL=lme_logPM_by_logAngle.Coefficients.Lower(2)
mean_intercept_angleU=lme_logPM_by_logAngle.Coefficients.Upper(1)
mean_slope_angleU=lme_logPM_by_logAngle.Coefficients.Upper(2)
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

[angleTickPos, angleTickLabels] = local_adaptive_log_ticks(minRealAngle, maxRealAngle, 1);
set(gca,'XTick',angleTickPos,'XTickLabel',angleTickLabels);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim):1: ceil(log2(maxPMLim))]));
xlim([log2(minRealAngle*.95) log2(maxRealAngle*1.05)]);
ylim([log2(minPMLim) ceil(log2(maxPMLim))]);
set(gca,'FontName','Avenir','FontSize', 20)
xlabel ({'Real Visual Angle [degree]','log scale'},'FontSize', 24)
ylabel ({'Perceptual Magnification', 'log scale'},'FontSize', 24)

titlestr=sprintf('PM=%.2fVA^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_angle,mean_slope_angle,pval_angle, nsubjects);
title(titlestr,'FontSize',18,'FontWeight','normal')

% plot PM by distance different colors per subject sorted by PM in perceptual task
%
mean_slope_distance=lme_logPM_by_logDistance.Coefficients.Estimate(2);
mean_intercept_distance=lme_logPM_by_logDistance.Coefficients.Estimate(1);
pval_distance=lme_logPM_by_logDistance.Coefficients.pValue(2);

% get upper and lower coeffiecents
mean_intercept_distanceL=lme_logPM_by_logDistance.Coefficients.Lower(1)
mean_slope_distanceL=lme_logPM_by_logDistance.Coefficients.Lower(2)
mean_intercept_distanceU=lme_logPM_by_logDistance.Coefficients.Upper(1)
mean_slope_distanceU=lme_logPM_by_logDistance.Coefficients.Upper(2)
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

[distanceTickPos, distanceTickLabels] = local_adaptive_log_ticks(minDistance, maxDistance, 0);
set(gca,'XTick',distanceTickPos,'XTickLabel',distanceTickLabels);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
xlim([log2(minDistance*.95) log2(maxDistance*1.05)]);
ylim([log2(minPMLim) ceil(log2(maxPMLim))])
set(gca,'FontName','Avenir','FontSize', 20)
xlabel ({'Distance [m]', 'log scale'},'FontSize', 24)
ylabel ('')

ax = gca;
ax.YColor = 'w';
mean_slope=lme_logPM_by_logDistance.Coefficients.Estimate(2);
pval=lme_logPM_by_logDistance.Coefficients.pValue(2);
titlestr=sprintf('PM=%.2fD^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_distance,mean_slope_distance,pval_distance, nsubjects);
title(titlestr,'FontSize',18,'FontWeight','normal')

%% plot by elevation
mean_slope_elevation=lme_logPM_by_logElevation.Coefficients.Estimate(2);
mean_intercept_elevation=lme_logPM_by_logElevation.Coefficients.Estimate(1);
pval_elevation=lme_logPM_by_logElevation.Coefficients.pValue(2);


% get upper and lower coeffiecents
mean_intercept_elevationL=lme_logPM_by_logElevation.Coefficients.Lower(1)
mean_slope_elevationL=lme_logPM_by_logElevation.Coefficients.Lower(2)
mean_intercept_elevationU=lme_logPM_by_logElevation.Coefficients.Upper(1)
mean_slope_elevationU=lme_logPM_by_logElevation.Coefficients.Upper(2)
% 
% set plotting range
minlogElevation=min(tbl.log2elevation);
maxlogElevation=max(tbl.log2elevation);
elevationMargin = max(0.05 * (maxlogElevation - minlogElevation), 0.05);
xlinerange=(minlogElevation - elevationMargin):.05:(maxlogElevation + elevationMargin); 
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

set(gca,'FontName','Avenir','FontSize', 20);
XTicks = unique([minlogElevation maxlogElevation], 'stable'); % log2(elevation_rad+1)
set(gca,'XTick',XTicks);
xlim([minlogElevation - elevationMargin maxlogElevation + elevationMargin]);
el_rad=2.^XTicks-1;
if degreeFlag
    set(gca,'XTickLabel',local_format_tick_labels(round(180*el_rad/pi)));
else
    set(gca,'XTickLabel',local_format_tick_labels(round(el_rad,2)));
end
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));

ylim([log2(minPMLim) ceil(log2(maxPMLim))])
ylabel ('')

ax = gca;
ax.YColor = 'w';
%titlestr=sprintf('slope=%-.2f, p=%-.2e \n n=%d',mean_slope_elevation,pval_elevation, nsubjects);
if ElevationTransform==3
    titlestr=sprintf('PM=%.2f(1+E_{RAD})^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);
    if degreeFlag
        xlabel ({'Elevation [degree]','logscale'},'FontSize', 24);
    else
        xlabel ({'Elevation [Radian]','logscale'},'FontSize', 24);
    end
elseif ElevationTransform==4
    titlestr=sprintf('PM=%.2f(1+|E_{RAD}|)^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);
    if degreeFlag
        xlabel ({'|Elevation| [degree]','logscale'},'FontSize', 24);
    else
         xlabel ({'|Elevation| [Radian]','logscale'},'FontSize', 24);
    end
end
title(titlestr,'FontSize',18,'FontWeight','normal')

%% save figure
filenamePNG=fullfile(ResultsDir, [tblName '.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);

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

end

function labels = local_format_tick_labels(vals)
labels = strings(size(vals));
for i = 1:numel(vals)
    if abs(vals(i)) > 1000
        labels(i) = sprintf('%.1e', vals(i));
    else
        labels(i) = string(vals(i));
    end
end
end

function [tickPos, tickLabels] = local_adaptive_log_ticks(minVal, maxVal, roundDigits)
if ~isfinite(minVal) || ~isfinite(maxVal) || minVal <= 0 || maxVal <= 0
    tickPos = [];
    tickLabels = strings(0,1);
    return
end

if maxVal < minVal
    tmp = minVal;
    minVal = maxVal;
    maxVal = tmp;
end

if minVal == maxVal
    rawTicks = minVal;
else
    logMin = log2(minVal);
    logMax = log2(maxVal);
    logSpan = logMax - logMin;

    if logSpan < 1
        nTicks = 2;
    elseif logSpan < 2.5
        nTicks = 3;
    elseif logSpan < 4.5
        nTicks = 4;
    else
        nTicks = 2;
    end

    rawTicks = 2.^linspace(logMin, logMax, nTicks);
    rawTicks(1) = minVal;
    rawTicks(end) = maxVal;
end

rawTicks = unique(rawTicks, 'stable');
tickPos = log2(rawTicks);
tickLabels = local_format_tick_labels(round(rawTicks, roundDigits));
end
