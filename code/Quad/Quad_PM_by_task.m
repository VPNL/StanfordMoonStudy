function [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
    lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
    lme_logPM_by_logAngleNDistanceNElevation]=Quad_PM_by_task(tbl,tblName,ResultsDir,saveLME,colormap, sorted_idx,ElevationTransform)
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
% E: elevation in degrees (as elevation is relative to the ground and can
% start at zero we add a regularization term (1)
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
% Can use different models for elevation
%if ElevationTransform==1 
%     tbl.log2elevation=log2(tbl.Elevation+1); % add a regularization term so that the log won't explode for an elevation of 0
% elseif ElevationTransform==2
%     tbl.log2elevation=log2(abs(tbl.Elevation)+1); % take absolute values of elevations to deal with negative elevations
% elseif ElevationTransform==3
%     tbl.log2elevation=log2((tbl.Elevation)/90+1);% divide by 90 to clamp values from -90:90
% elseif ElevationTransform==4
%     tbl.log2elevation=log2(abs(tbl.Elevation)/90+1); % take absolute values of elevations to deal with negative elevations

% KGS Nov 2025
%
% defaults
if ~exist('dataDir')
    dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
end

if ~exist('ElevationTransform')
    ElevationTransform=1;
end
ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'standard');




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
    fprintf(1,'Warning: max Ratio %.2f less than Ylim ,om %.2f\n', minRatio, maxPMLim)
end

tbl.log2real_visual_angle=log2(tbl.Real_Visual_Angle);
tbl.log2ratio_visual_angle=log2(tbl.Ratio_Visual_Angle);
tbl.log2distance=log2(tbl.Distance);

if ElevationTransform==1 
    tbl.log2elevation=log2(tbl.Elevation+1); % add a regularization term so that the log won't explode for an elevation of 0
elseif ElevationTransform==2
    tbl.log2elevation=log2(abs(tbl.Elevation)+1); % take absolute vakues of elevations to deal with negative elevations
elseif ElevationTransform==5
    tbl.log2elevation=log2((tbl.Elevation)/90+1);% divide by 90 to clamp values from -90:90
elseif ElevationTransform==6
    tbl.log2elevation=log2(abs(tbl.Elevation)/90+1); % take absolute values of elevations to deal with negative elevations
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
    sourceCsv = char(string(tblName));
    try
        if isstruct(tbl.Properties.UserData) && isfield(tbl.Properties.UserData, 'SourceFile')
            sourceCsv = char(string(tbl.Properties.UserData.SourceFile));
        end
    catch
    end
    if ~endsWith(string(sourceCsv), ".csv", "IgnoreCase", true)
        sourceCsv = sprintf('%s.csv (inferred from tblName; function input is a table)', sourceCsv);
    end

    reportOpts = struct();
    reportOpts.ReportTitle = sprintf('Quad PM Multi-Factor LME Report: %s', char(string(tblName)));
    reportOpts.GeneratedBy = mfilename;
    reportOpts.SourceFile = sourceCsv;
    reportOpts.ModelLabel = 'Log perceptual magnification predicted by log visual angle, log distance, and log elevation';
    reportOpts.SummaryLines = { ...
        sprintf('Rows in model table: %d', height(tbl)), ...
        sprintf('Participants in model table: %d', nsubjects), ...
        sprintf('Elevation transform: %s', char(string(ElevationTransform))), ...
        sprintf('Full model R-squared: ordinary = %.3f; adjusted = %.3f', ...
        lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Ordinary, ...
        lme_logPM_by_logAngleNDistanceNElevation.Rsquared.Adjusted)};
    reportOpts.Models = { ...
        lme_logPM_by_logAngle, ...
        lme_logPM_by_logDistance, ...
        lme_logPM_by_logElevation, ...
        lme_logPM_by_logAngleNDistance, ...
        lme_logPM_by_logAngleNElevation, ...
        lme_logPM_by_logDistanceNElevation, ...
        lme_logPM_by_logAngleNDistanceNElevation};
    reportOpts.ModelLabels = { ...
        'Model: log2ratio_visual_angle ~ log2real_visual_angle + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2distance + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2elevation + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2real_visual_angle + log2distance + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2real_visual_angle + log2elevation + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2distance + log2elevation + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2real_visual_angle + log2distance + log2elevation + (1|ID)'};
    reportOpts.Comparisons = { ...
        compare(lme_logPM_by_logAngle, lme_logPM_by_logAngleNDistance), ...
        compare(lme_logPM_by_logAngle, lme_logPM_by_logAngleNElevation), ...
        compare(lme_logPM_by_logDistance, lme_logPM_by_logAngleNDistance), ...
        compare(lme_logPM_by_logDistance, lme_logPM_by_logDistanceNElevation), ...
        compare(lme_logPM_by_logElevation, lme_logPM_by_logAngleNElevation), ...
        compare(lme_logPM_by_logElevation, lme_logPM_by_logDistanceNElevation), ...
        compare(lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNDistanceNElevation), ...
        compare(lme_logPM_by_logAngleNElevation, lme_logPM_by_logAngleNDistanceNElevation), ...
        compare(lme_logPM_by_logDistanceNElevation, lme_logPM_by_logAngleNDistanceNElevation), ...
        compare(lme_logPM_by_logAngle, lme_logPM_by_logAngleNDistanceNElevation), ...
        compare(lme_logPM_by_logDistance, lme_logPM_by_logAngleNDistanceNElevation), ...
        compare(lme_logPM_by_logElevation, lme_logPM_by_logAngleNDistanceNElevation)};
    reportOpts.ComparisonLabels = { ...
        'Model comparison: visual angle vs visual angle + distance', ...
        'Model comparison: visual angle vs visual angle + elevation', ...
        'Model comparison: distance vs visual angle + distance', ...
        'Model comparison: distance vs distance + elevation', ...
        'Model comparison: elevation vs visual angle + elevation', ...
        'Model comparison: elevation vs distance + elevation', ...
        'Model comparison: visual angle + distance vs visual angle + distance + elevation', ...
        'Model comparison: visual angle + elevation vs visual angle + distance + elevation', ...
        'Model comparison: distance + elevation vs visual angle + distance + elevation', ...
        'Model comparison: visual angle vs visual angle + distance + elevation', ...
        'Model comparison: distance vs visual angle + distance + elevation', ...
        'Model comparison: elevation vs visual angle + distance + elevation'};
    reportOpts.RemoveGroupError = false;
    write_lme_stats_report(lme_logPM_by_logAngleNDistanceNElevation, savelmefile, reportOpts);

    objectReportVars = {'Measurement','ID','Real_Visual_Angle','Distance','Elevation','Ratio_Visual_Angle'};
    missingObjectReportVars = setdiff(objectReportVars, tbl.Properties.VariableNames);
    if isempty(missingObjectReportVars)
        objectReportOpts = struct();
        objectReportOpts.ReportTitle = sprintf('Quad PM Object Prediction Summary: %s', char(string(tblName)));
        objectReportOpts.GeneratedBy = mfilename;
        objectReportOpts.SourceFile = sourceCsv;
        objectReportOpts.ModelLabel = '3-factor fixed-effect prediction: log2(PM) ~ log2(VA) + log2(D) + log2(E) + (1|ID)';
        objectReportFile = fullfile(ResultsDir, [tblName '_Object_Sorted_by_PM.txt']);
        write_quad_pm_object_prediction_report(tbl, lme_logPM_by_logAngleNDistanceNElevation, objectReportFile, objectReportOpts);
    else
        warning('Quad_PM_by_task:ObjectReportSkipped', ...
            'Skipping object-level PM report for %s because tbl is missing variable(s): %s.', ...
            char(string(tblName)), strjoin(missingObjectReportVars, ', '));
    end
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
xlabel ({'Visual Angle [degree]','log scale'},'FontSize', 24)
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

set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
elevationTicks = unique([minlogElevation maxlogElevation], 'stable');
if ElevationTransform==5 || ElevationTransform==6
    elevationTickLabels = round(90*(2.^elevationTicks - 1),1);
else
    elevationTickLabels = round(2.^elevationTicks - 1,1);
end
set(gca,'XTick',elevationTicks,'XTickLabel',local_format_tick_labels(elevationTickLabels),'XTickLabelRotation',0);
xlim([minlogElevation - elevationMargin maxlogElevation + elevationMargin]);
set(gca,'FontName','Avenir','FontSize', 20)
ylim([log2(minPMLim) ceil(log2(maxPMLim))])
ylabel ('')

ax = gca;
ax.YColor = 'w';
%titlestr=sprintf('slope=%-.2f, p=%-.2e \n n=%d',mean_slope_elevation,pval_elevation, nsubjects);
if ElevationTransform==1
    titlestr=sprintf('PM=%.2f(1+E)^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);
    xlabel ({'Elevation [degree]','logscale'},'FontSize', 24)
elseif ElevationTransform==2
    titlestr=sprintf('PM=%.2f(1+|E|)^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);
    xlabel ({'|Elevation| [degree]','logscale'},'FontSize', 24)
elseif ElevationTransform==5
    titlestr=sprintf('PM=%.2f(1+E/90)^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);
    xlabel ({'Elevation [degree]','logscale'},'FontSize', 24)
elseif  ElevationTransform==6
    titlestr=sprintf('PM=%.2f(1+|E|/90)^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);
    xlabel ({'|Elevation| [degree]','logscale'},'FontSize', 24)
end
title(titlestr,'FontSize',18,'FontWeight','normal')

%% save figure
filenamePNG=fullfile(ResultsDir, [tblName 'single.png']);
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
