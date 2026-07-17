function lme_logPM_by_logAngleNDistance=PM_by_Task_VA_Distance(tbl,tblName,ResultsDir,saveLME,mycolormap, sorted_idx)


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

tbl.log2real_visual_angle=log2(tbl.Real_Visual_Angle);
tbl.log2ratio_visual_angle=log2(tbl.Ratio_Visual_Angle);
tbl.log2Distance=log2(tbl.Distance);


lme_logPM_by_logAngle= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle +  (1| ID)');
lme_logPM_by_logDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2Distance +  (1| ID)');
lme_logPM_by_logAngleNDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2Distance + (1| ID)');

if saveLME
    savelmefile=fullfile(ResultsDir, [tblName '_PM_by_VA_Distance.txt']);
    diary(savelmefile)
    lme_logPM_by_logAngle
    lme_logPM_by_logDistance
    lme_logPM_by_logAngleNDistance
    
    % testing if distancen explains additional variance in the data
    modelcomp1=compare(lme_logPM_by_logAngle,lme_logPM_by_logAngleNDistance)  
    % testing if angle explains additional variance in the data
    modelcomp2=compare(lme_logPM_by_logDistance,lme_logPM_by_logAngleNDistance) 
    % comparing model R2
    fprintf('log PM by log angle:                  Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logAngle.Rsquared.Ordinary,lme_logPM_by_logAngle.Rsquared.Adjusted);
    fprintf('log PM by log distance:               Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logDistance.Rsquared.Ordinary,lme_logPM_by_logDistance.Rsquared.Adjusted);
    fprintf('log PM by log angle and log distance: Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logAngleNDistance.Rsquared.Ordinary,lme_logPM_by_logAngleNDistance.Rsquared.Adjusted);
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

mean_slope_angle=lme_logPM_by_logAngle.Coefficients.Estimate(2);
mean_intercept_angle=lme_logPM_by_logAngle.Coefficients.Estimate(1);
pval_angle=lme_logPM_by_logAngle.Coefficients.pValue(2);

subplot(1,3,1); 
hold on 
scatter(tbl.log2real_visual_angle, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled');    
%xlinerange=log2(.25):.05:log2(maxRealAngle); 
xlinerange=log2(minRealAngle):.01:log2(maxRealAngle);
ylinerange=zeros(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
plot (xlinerange, mean_intercept_angle+mean_slope_angle*xlinerange,'k-','LineWidth',3);
tickdelta=[log2(maxRealAngle)-log2(minRealAngle)]/3;
%set(gca,'XTick',log2(minRealAngle):tickdelta:log2(maxRealAngle),'XTickLabel',round(2.^[log2(minRealAngle):tickdelta:log2(maxRealAngle)],2),'XTickLabelRotation',90);

set(gca,'XTick',log2(minRealAngle):tickdelta:log2(maxRealAngle),'XTickLabel',round(2.^[log2(minRealAngle):tickdelta:log2(maxRealAngle)],2));
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim):1: ceil(log2(maxPMLim))]));
xlim([log2(minRealAngle*.95) log2(maxRealAngle*1.05)])

ylim([log2(minPMLim) ceil(log2(maxPMLim))])
xlabel ('Real Visual Angle [degree], log scale')
ylabel ('Perceptual Magnification, log scale')
titlestr=sprintf('PM=%.2fVA^{%.2f}\n p=%-.2e n=%d',2.^mean_intercept_angle,mean_slope_angle,pval_angle, nsubjects);
title(titlestr)


set(gca,'FontName','Avenir','FontSize',16)

%


%% plot by distance
mean_slope_Distance=lme_logPM_by_logDistance.Coefficients.Estimate(2);
mean_intercept_Distance=lme_logPM_by_logDistance.Coefficients.Estimate(1);
pval_Distance=lme_logPM_by_logDistance.Coefficients.pValue(2);

subplot(1,3,2)
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

%%  model log2real_visual_angle_log2distance

intercept_fe=lme_logPM_by_logAngleNDistance.Coefficients.Estimate(1);
VA_fe=lme_logPM_by_logAngleNDistance.Coefficients.Estimate(2);
pval_VA=lme_logPM_by_logAngleNDistance.Coefficients.pValue(2);
distance_fe=lme_logPM_by_logAngleNDistance.Coefficients.Estimate(3);
pval_distance=lme_logPM_by_logAngleNDistance.Coefficients.pValue(3);


%% full formula
subplot(1,3,3); 
hold on 


 % 1.  Fixed‑effects parameters from lme 
[fe_betas,  ~,  fe_stats] = fixedEffects(lme_logPM_by_logAngleNDistance);
intercept            = fe_betas(1);
beta_log_real_angle  = fe_betas(2);
beta_log_distance   = fe_betas(3);

% Build log2 ranges for angle (rows) and distance (columns) 
minAngle4plot = min(tbl.Real_Visual_Angle);
maxAngle4plot = max(tbl.Real_Visual_Angle);
minDistance   = min(tbl.Distance);
maxDistance   = max(tbl.Distance);

yTickVec = round(log2(maxAngle4plot)) : -1 : round(log2(minAngle4plot));    % ↓
xTickVec = round(log2(minDistance))   :  1  : round(log2(maxDistance));     % →

log2_angleRange    = linspace(log2(minAngle4plot), log2(maxAngle4plot), numel(yTickVec)*20);
log2_distanceRange = linspace(log2(minDistance),   log2(maxDistance),   numel(xTickVec)*20);

%  Evaluate model on the grid 
log2PM = zeros(numel(log2_angleRange), numel(log2_distanceRange));
for a= 1:numel(log2_angleRange)
    for d = 1:numel(log2_distanceRange)
        log2PM(a,d) = intercept ...
                    + beta_log_real_angle * log2_angleRange(a) ...
                    + beta_log_distance   * (log2_distanceRange(d)); % add 1 regularization term
    end
end

%  Plot the prediction
imagesc(flipud(2.^log2PM), [0.5 5]);          % PM back to linear units
colormap(jet);
cb = colorbar;
ylabel(cb, 'Perceptual Magnification', 'FontSize',14,'FontName','Avenir')

xlabel('Distance[m], (log scale)')
ylabel('Visual Angle [deg]  (log scale)')
set(gca,'FontSize',14,'FontName','Avenir','TickDir','out')

% Y (rows): convert each log2(angle) tick to its matrix row index
yIdx_unflipped = round( (yTickVec - log2(minAngle4plot)) ./ ...
                        (log2(maxAngle4plot)-log2(minAngle4plot)) .* ...
                        (numel(log2_angleRange)-1) ) + 1;
yIdx           = numel(log2_angleRange) - yIdx_unflipped + 1;   % flip rows

% X (columns): convert each log2(distance) tick to its column index
xIdx = round( (xTickVec - log2(minDistance)) ./ ...
              (log2(maxDistance)-log2(minDistance)) .* ...
              (numel(log2_distanceRange)) ) + 1;

% MATLAB requires ascending YTick values
[yIdxSorted, sortOrder] = sort(yIdx);
yTickLabelsSorted       = 2.^yTickVec(sortOrder);

set(gca, 'XTick', xIdx,        'XTickLabel', 2.^xTickVec)
set(gca, 'YTick', yIdxSorted,  'YTickLabel', yTickLabelsSorted)

axis square tight   % equal data‑unit lengths & no extra padding

% Title

titlestr=sprintf('joint model\n PM=%.2fVA^{%.2f}D^{%.2f}\n pVA=%-.2e pD%-.2e n=%d\n',...
    2.^intercept_fe,VA_fe,distance_fe,pval_VA,pval_distance, nsubjects);
title(titlestr)



%% save figure
filenamePNG=fullfile(ResultsDir, [tblName '_PM_by_VA_Distance.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);


% 