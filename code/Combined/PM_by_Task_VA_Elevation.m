function lme_logPM_by_logAngleNElevation=PM_by_Task_VA_Elevation(tbl,tblName,ResultsDir,saveLME,mycolormap, sorted_idx)


%% find max angle and maxRatio for graphs

uniqueID=unique(tbl.ID);
nsubjects=length(uniqueID);
maxRealAngle=max(tbl.Real_Visual_Angle);
minRealAngle=min(tbl.Real_Visual_Angle);
maxAngle=max(tbl.Reported_Visual_Angle);
minAngle=min(tbl.Reported_Visual_Angle);
maxRatio=max(tbl.Ratio_Visual_Angle);
minRatio=min(tbl.Ratio_Visual_Angle);

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
tbl.log2elevation=log2(tbl.Elevation+1); % add a regularization term so that the log won't explode for an elevation of 0

lme_logPM_by_logAngle= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle +  (1| ID)');
lme_logPM_by_logElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2elevation +  (1| ID)');
lme_logPM_by_logAngleNElevation= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2elevation + (1| ID)');

if saveLME
    savelmefile=fullfile(ResultsDir, [tblName '_PM_by_VA_Elevation.txt']);
    diary(savelmefile)
    lme_logPM_by_logAngle
    lme_logPM_by_logElevation
    lme_logPM_by_logAngleNElevation
    
    % testing if elevation explains additional variance in the data
    modelcomp1=compare(lme_logPM_by_logAngle,lme_logPM_by_logAngleNElevation)  
    % testing if angle explains additional variance in the data
    modelcomp2=compare(lme_logPM_by_logElevation,lme_logPM_by_logAngleNElevation) 
    % comparing model R2
    fprintf('log PM by log angle:                   Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logAngle.Rsquared.Ordinary,lme_logPM_by_logAngle.Rsquared.Adjusted);
    fprintf('log PM by log elevation:               Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logElevation.Rsquared.Ordinary,lme_logPM_by_logElevation.Rsquared.Adjusted);
    fprintf('log PM by log angle and log elevation: Rsq=%.3f RsqAdjusted=%.3f\n',lme_logPM_by_logAngleNElevation.Rsquared.Ordinary,lme_logPM_by_logAngleNElevation.Rsquared.Adjusted);
   
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



%%  model log2real_visual_angle_log2elevation

intercept_fe=lme_logPM_by_logAngleNElevation.Coefficients.Estimate(1);
VA_fe=lme_logPM_by_logAngleNElevation.Coefficients.Estimate(2);
pval_VA=lme_logPM_by_logAngleNElevation.Coefficients.pValue(2);
elevation_fe=lme_logPM_by_logAngleNElevation.Coefficients.Estimate(3);
pval_elevation=lme_logPM_by_logAngleNElevation.Coefficients.pValue(3);

if saveLME
    diary(savelmefile)
    VisualAngle=0.5; % visual angle of moon 0.5 degrees
    Elevation=2.5;
    
    PM=evaluatePMbyVisualAngleElevation(lme_logPM_by_logAngleNElevation,VisualAngle,Elevation);
    fprintf('predicted PM=%.2f for visual angle %.2f and elevation %.2f\n',PM, VisualAngle, Elevation);
  
    Elevation=40; % estimate at 40 degrees
    PM=evaluatePMbyVisualAngleElevation(lme_logPM_by_logAngleNElevation,VisualAngle,Elevation);
    fprintf('predicted PM=%.2f for moon, visual angle %.2f and elevation %.2f\n',PM, VisualAngle, Elevation);
  
    diary off
end

%% full formula
subplot(1,3,3); 
hold on 


 % 1.  Fixed‑effects parameters from lme 
[fe_betas,  ~,  fe_stats] = fixedEffects(lme_logPM_by_logAngleNElevation);
intercept            = fe_betas(1);
beta_log_real_angle  = fe_betas(2);
beta_log_elevation    = fe_betas(3);

% Build log2 ranges for angle (rows) and distance (columns) 
minAngle4plot = min(tbl.Real_Visual_Angle);
maxAngle4plot = max(tbl.Real_Visual_Angle);
minElevation   = min(tbl.Elevation);
maxElevation   = max(tbl.Elevation);

yTickVec = round(log2(maxAngle4plot)) : -1 : round(log2(minAngle4plot));    % ↓
xTickVec = round(log2(minElevation+1))   :  1  : round(log2(maxElevation+1));     % →

log2_angleRange    = linspace(log2(minAngle4plot), log2(maxAngle4plot), numel(yTickVec)*20);
log2_elevationRange = linspace(log2(minElevation+1),   log2(maxElevation+1),   numel(xTickVec)*20);

%  Evaluate model on the grid 
log2PM = zeros(numel(log2_angleRange), numel(log2_elevationRange));
for d = 1:numel(log2_elevationRange)
    for a = 1:numel(log2_angleRange)
        log2PM(a,d) = intercept ...
                    + beta_log_real_angle * log2_angleRange(a) ...
                    + beta_log_elevation   * (log2_elevationRange(d)); % add 1 regularization term
    end
end

%  Plot the prediction
imagesc(flipud(2.^log2PM), [0.5 5]);          % PM back to linear units
colormap(jet);
cb = colorbar;
ylabel(cb, 'Perceptual Magnification', 'FontSize',14,'FontName','Avenir')

xlabel('Elevation [deg], (log scale)')
ylabel('Visual Angle [deg]  (log scale)')
set(gca,'FontSize',14,'FontName','Avenir','TickDir','out')

% Y (rows): convert each log2(angle) tick to its matrix row index
yIdx_unflipped = round( (yTickVec - log2(minAngle4plot)) ./ ...
                        (log2(maxAngle4plot)-log2(minAngle4plot)) .* ...
                        (numel(log2_angleRange)-1) ) + 1;
yIdx           = numel(log2_angleRange) - yIdx_unflipped + 1;   % flip rows

% X (columns): convert each log2(elevation) tick to its column index
xIdx = round( (xTickVec - log2(minElevation)) ./ ...
              (log2(maxElevation)-log2(minElevation)) .* ...
              (numel(log2_elevationRange)) ) + 1;

% MATLAB requires ascending YTick values
[yIdxSorted, sortOrder] = sort(yIdx);
yTickLabelsSorted       = 2.^yTickVec(sortOrder);

set(gca, 'XTick', xIdx,        'XTickLabel', 2.^xTickVec)
set(gca, 'YTick', yIdxSorted,  'YTickLabel', yTickLabelsSorted)

axis square tight   % equal data‑unit lengths & no extra padding

% Title

titlestr=sprintf('joint model\n PM=%.2f(VA)^{%.2f}(1+Elevation)^{%.2f}\n pVA=%-.2e pElevation=%-.2e n=%d\n',...
    2.^intercept_fe,VA_fe,elevation_fe,pval_VA,pval_elevation, nsubjects);
title(titlestr)



%% save figure
filenamePNG=fullfile(ResultsDir, [tblName '_PM_by_VA_Elevation.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);


% 