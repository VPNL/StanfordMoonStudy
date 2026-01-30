function lme_logPM_by_logDistanceNElevation=PM_by_Task_Distance_Elevation(tbl,tblName,ResultsDir,saveLME,mycolormap, sorted_idx)


%% find max angle and maxRatio for graphs

uniqueID=unique(tbl.ID);
nsubjects=length(uniqueID);
maxRealAngle=max(tbl.Real_Visual_Angle);
minRealAngle=min(tbl.Real_Visual_Angle);
maxAngle=max(tbl.Reported_Visual_Angle);
minAngle=min(tbl.Reported_Visual_Angle);
maxRatio=max(tbl.Ratio_Visual_Angle);
minRatio=min(tbl.Ratio_Visual_Angle);
minDistance=min(tbl.Distance);
maxDistance=max(tbl.Distance);

maxPMLim=16;
minPMLim=.25;
if maxRatio>maxPMLim
    fprintf(1,'Warning: max Ratio %.2f exceeds Ylim max %.2f\n', maxRatio, maxPMLim)
end
if minRatio<minPMLim
    fprintf(1,'Warning: max Ratio %.2f less than Ylim ,om %.2f\n', minRatio, monPMLim)
end

tbl.log2Distance=log2(tbl.Distance);
tbl.log2elevation=log2(tbl.Elevation+1); % add a regularization term so that the log won't explode for an elevation of 0
tbl.log2ratio_visual_angle=log2(tbl.Ratio_Visual_Angle);

lme_logPM_by_logDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2Distance +  (1| ID)');
lme_logPM_by_logElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2elevation +  (1| ID)');
lme_logPM_by_logDistanceNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2Distance  + log2elevation + (1| ID)');

if saveLME
    savelmefile=fullfile(ResultsDir, [tblName '_PM_by_Distance_Elevation.txt']);
    diary(savelmefile)

    lme_logPM_by_logDistance
    lme_logPM_by_logElevation
    lme_logPM_by_logDistanceNElevation

    % testing if Distance explains additional variance in the data
    modelcomp1=compare(lme_logPM_by_logDistance,lme_logPM_by_logDistanceNElevation) 
    modelcomp2=compare(lme_logPM_by_logElevation,lme_logPM_by_logDistanceNElevation)  
    % testing if angle explains additional variance in the data
    % comparing model R2
   fprintf('log PM by log Distance:               Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logDistance.Rsquared.Ordinary,lme_logPM_by_logDistance.Rsquared.Adjusted);
   fprintf('log PM by log Elevation:              Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logElevation.Rsquared.Ordinary,lme_logPM_by_logElevation.Rsquared.Adjusted);
   fprintf('log PM by log Distance and Elevation: Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logDistanceNElevation.Rsquared.Ordinary,lme_logPM_by_logDistanceNElevation.Rsquared.Adjusted);
   diary off
end



%%
% set sorted mycolormap
ID=tbl.ID;
clear subjectcolor
for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=mycolormap(sorted_cindex,:);
end
% plot results
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5],'Name',tblName)
markerSize=50;



%% plot by Distance
mean_slope_Distance=lme_logPM_by_logDistance.Coefficients.Estimate(2);
mean_intercept_Distance=lme_logPM_by_logDistance.Coefficients.Estimate(1);
pval_Distance=lme_logPM_by_logDistance.Coefficients.pValue(2);

subplot(1,3,1); 
hold on 
scatter(tbl.log2Distance, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled');
minlogDistance=min(tbl.log2Distance);
maxlogDistance=max(tbl.log2Distance);
xlinerange=minlogDistance:.1:maxlogDistance; 
tickdelta=[log2(maxDistance)-log2(minDistance)]/3;

ylinerange=zeros(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
%plot (xlinerange, mean_intercept_Distance+mean_slope_Distance*xlinerange,'k-','LineWidth',3); % linear estimate
%tbl.log2Distance=log2(tbl.Distance); % add a regularization term so that the log won't explode for an Distance of 0
plot (xlinerange, mean_intercept_Distance+mean_slope_Distance*(xlinerange),'k-','LineWidth',3); % linear estimate

%set(gca,'XTick',0:.11:maxDistance,'XTickLabel',2.^[log2(minDistance):1:log2(maxDistance)],'XTickLabelRotation',0);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
%set(gca,'XTick',minlogDistance:1:maxlogDistance,'XTickLabel',2.^[minlogDistance:1:maxlogDistance],'XTickLabelRotation',0);
%set(gca,'XTick',minlogDistance:1:maxlogDistance,'XTickLabel',round(2.^[(minlogDistance):5:(maxlogDistance)],1),'XTickLabelRotation',0);
set(gca,'XTick',log2(minDistance):tickdelta:log2(maxDistance),'XTickLabel', round(2.^[log2(minDistance):tickdelta:log2(maxDistance)],2));

ylim([log2(minPMLim) ceil(log2(maxPMLim))])
xlabel ('Distance [m], logscale')
ylabel ('Perceptual Magnification, log scale')
titlestr=sprintf('PM=%.2f(D)^{%.2f}\n p=%-.2e n=%d',2.^mean_intercept_Distance,mean_slope_Distance,pval_Distance, nsubjects);
title(titlestr)
set(gca,'FontName','Avenir','FontSize',16)


%% plot by elevation
mean_slope_elevation=lme_logPM_by_logElevation.Coefficients.Estimate(2);
mean_intercept_elevation=lme_logPM_by_logElevation.Coefficients.Estimate(1);
pval_elevation=lme_logPM_by_logElevation.Coefficients.pValue(2);

subplot(1,3,2); 
hold on 
scatter(tbl.log2elevation, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled');
minlogElevation=min(tbl.log2elevation);
maxlogElevation=max(tbl.log2elevation);
xlinerange=minlogElevation:.05:maxlogElevation; 

ylinerange=zeros(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
%plot (xlinerange, mean_intercept_elevation+mean_slope_elevation*xlinerange,'k-','LineWidth',3); % linear estimate
%tbl.log2elevation=log2(tbl.Elevation+1); % add a regularization term so that the log won't explode for an elevation of 0
plot (xlinerange, mean_intercept_elevation+mean_slope_elevation*(xlinerange+1),'k-','LineWidth',3); % linear estimate

%set(gca,'XTick',0:.11:maxElevation,'XTickLabel',2.^[log2(minDistance):1:log2(maxDistance)],'XTickLabelRotation',0);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
%set(gca,'XTick',minlogElevation:1:maxlogElevation,'XTickLabel',2.^[minlogElevation:1:maxlogElevation],'XTickLabelRotation',0);
set(gca,'XTick',minlogElevation:1:maxlogElevation,'XTickLabel',round(2.^[(minlogElevation):1:(maxlogElevation)]-1,1),'XTickLabelRotation',0);

ylim([log2(minPMLim) ceil(log2(maxPMLim))])
xlabel ('Elevation [degree], logscale')
ylabel ('Perceptual Magnification, log scale')
titlestr=sprintf('PM=%.2f(1+E)^{%.2f}\n p=%-.2e n=%d',2.^mean_intercept_elevation,mean_slope_elevation,pval_elevation, nsubjects);
title(titlestr)
set(gca,'FontName','Avenir','FontSize',16)


%%  model log2Distance_log2Elevation

intercept_fe=lme_logPM_by_logDistanceNElevation.Coefficients.Estimate(1);
Distance_fe=lme_logPM_by_logDistanceNElevation.Coefficients.Estimate(2);
pval_Distance=lme_logPM_by_logDistanceNElevation.Coefficients.pValue(2);
Elevation_fe=lme_logPM_by_logDistanceNElevation.Coefficients.Estimate(3);
pval_Elevation=lme_logPM_by_logDistanceNElevation.Coefficients.pValue(3);

if saveLME
    diary(savelmefile)
    Distance=100*1000; % distance of outerspacc
    Elevation=2.5; % estimate at 2.5 degrees
    PM=evaluatePMbyDistanceElevation(lme_logPM_by_logDistanceNElevation,Distance,Elevation);
    fprintf('predicted PM=%.2f for outerspace distance %d and elevation %.2f\n',PM, Distance, Elevation);
  
    Elevation=40; % estimate at 40 degrees
    PM=evaluatePMbyDistanceElevation(lme_logPM_by_logDistanceNElevation,Distance,Elevation);
    fprintf('predicted PM=%.2f for outerspace distance %d and elevation %.2f\n',PM, Distance, Elevation);
  
    diary off
end

%% full formula
subplot(1,3,3); 
hold on 


 % 1.  Fixed‑effects parameters from lme 
[fe_betas,  ~,  fe_stats] = fixedEffects(lme_logPM_by_logDistanceNElevation);
intercept           = fe_betas(1);
beta_log_Distance   = fe_betas(2);
beta_log_elevation  = fe_betas(3);


% Build log2 ranges for angle (rows) and distance (columns) 

minDistance   = min(tbl.Distance);
maxDistance   = max(tbl.Distance);
minElevation   = min(tbl.Elevation);
maxElevation   = max(tbl.Elevation);

yTickVec = round(log2(minDistance))   :  2  : round(log2(maxDistance));     % →
xTickVec = round(log2(minElevation+1))   :  1  : round(log2(maxElevation+1));     % →

log2_elevationRange = linspace(log2(minElevation+1),   log2(maxElevation+1),   numel(xTickVec)*20);
log2_DistanceRange = linspace(log2(minDistance),   log2(maxDistance),   numel(xTickVec)*20);

%  Evaluate model on the grid 
log2PM = zeros( numel(log2_DistanceRange), numel(log2_elevationRange));
for d = 1:numel(log2_elevationRange) 
    for a = 1:numel(log2_DistanceRange)
        log2PM(a,d) = intercept ...
                    + beta_log_Distance   * (log2_DistanceRange(a)); 
                    + beta_log_elevation   * (log2_elevationRange(d));
    end
end

%  Plot the prediction
imagesc(flipud(2.^log2PM), [0.5 45]);          % PM bacsk to linear units
colormap(jet);
cb = colorbar;
ylabel(cb, 'Perceptual Magnification', 'FontSize',14,'FontName','Avenir')

xlabel('Elevation [deg]  (log scale)')
ylabel('Distance [m], (log scale)')
set(gca,'FontSize',12,'FontName','Avenir','TickDir','out')

% Y (rows): convert each log2(angle) tick to its matrix row index
yIdx_unflipped = round( (yTickVec - log2(minDistance)) ./ ...
                        (log2(maxDistance)-log2(minDistance)) .* ...
                        (numel(log2_DistanceRange)-1) ) + 1;

yIdx           = numel(log2_DistanceRange) - yIdx_unflipped + 1;   % flip rows

xIdx = round( (xTickVec - log2(minElevation)) ./ ...
              (log2(maxElevation)-log2(minElevation)) .* ...
              (numel(log2_elevationRange)) ) + 1;

% MATLAB requires ascending YTick values
[yIdxSorted, sortOrder] = sort(yIdx);
yTickLabelsSorted       = 2.^yTickVec(sortOrder);

set(gca, 'XTick', xIdx,        'XTickLabel', 2.^xTickVec);
ax.XAxis.FontSize = 8;
set(gca, 'YTick', yIdxSorted,  'YTickLabel', yTickLabelsSorted)
axis square tight   % equal data‑unit lengths & no extra padding

% Title

titlestr=sprintf('joint model\n PM=%.2f(Distance)^{%.2f}(1+E)^{%.2f}\n pDistance=%-.2e pElevation=%-.2e n=%d\n',...
    2.^intercept_fe,Distance_fe, Elevation_fe, pval_Distance,  pval_Elevation, nsubjects);
title(titlestr)



%% save figure
filenamePNG=fullfile(ResultsDir, [tblName '_PM_by_Distance_Elevation.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);


% 