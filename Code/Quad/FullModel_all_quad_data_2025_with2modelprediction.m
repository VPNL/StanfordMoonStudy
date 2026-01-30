%% load data

load_all_quad_data_2025
% analyze and plot data

% task='Perceptual'; 
% recomputeSort=1;
task='Adjusted';
recomputeSort=0;

%%
% get the relevant data 
task_i=find(strcmp(all_data.Task,task));
real_visual_angle=all_data.Real_Visual_Angle(task_i);
reported_visual_angle=all_data.Reported_Visual_Angle(task_i);
ratio_visual_angle=all_data.Ratio_Visual_Angle(task_i);
distance=all_data.Distance(task_i);
maxAngle=max(all_data.Reported_Visual_Angle);

% linear mixed model relating reported visual angle vs real visual
% angle with zero intersept with subjects as a random effect, with
% random slope effect per subject
lme_by_angle = fitlme(all_data(task_i,:),'Reported_Visual_Angle~Real_Visual_Angle -1  + (Real_Visual_Angle- 1|ID)')



% get individual subject slopes
[reSlopes, reNames,reStats] = randomEffects(lme_by_angle);
fixedSlope = fixedEffects(lme_by_angle);
individualSlopes=reSlopes+fixedSlope;
ipm=find(individualSlopes>1);


if saveLME % save stats table
     savelmefile=fullfile('.','Results', basename, [basename '_lme_reported_vs_real_angle_' task '.txt']);
     diary(savelmefile)
     fprintf(1,'Quad Experiment %s task, n=%d, percentage participants with slope>1: %.2f\n', string(task), nsubjects, 100*length(ipm)/nsubjects) 
     lme_by_angle
     diary off
end


if recomputeSort
    [sorted_individualSlopes, sorted_idx] = sort(individualSlopes);
    clear subjectcolor; % sort subjects by regression slope of reported visual angle vs real visual angle
    ID=all_data.ID(task_i);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
    end
    savefile=fullfile('.', 'Results', [basename  '_sorted_idx']);
    save(savefile ,'sorted_idx');
else
    loadfile=fullfile('.', 'Results', [basename  '_sorted_idx']);
    load(loadfile ,'sorted_idx');
    clear subjectcolor;
    ID=all_data.ID(task_i);
    cmap=jet(nsubjects);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
    end
end
  
% plot results
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .35],'Name',[basename '_logAxis_' task])

subplot(1,4,1);
hold on 
xvectorS= [0:maxRealAngle];
 
for s=1:nsubjects
    sortedID=sorted_idx(s);
    yvectorS= individualSlopes(sortedID)*xvectorS;
    plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
end



% plot regression results on data
mean_slope=lme_by_angle.Coefficients.Estimate;
pval=lme_by_angle.Coefficients.pValue;
lower_slope=lme_by_angle.Coefficients.Lower;
upper_slope=lme_by_angle.Coefficients.Upper;
xvectoru= [0:maxAngle];
xvectord= [maxAngle:-1:0];
yvector1=lower_slope*xvectoru;
yvector2=upper_slope*xvectord;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];


plot (0:maxAngle, 0:maxAngle,'k:','LineWidth',1);
plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
scatter(real_visual_angle,reported_visual_angle,markerScale,subjectcolor,'o','filled');

axis('equal'); axis([0 maxAngle 0 maxAngle]); 
xlabel ('Real Visual Angle (degree)')
ylabel ('Reported Visual Angle (degree)') 
set(gca,'FontSize',14,'FontName','Avenir')
titlestr=sprintf('%s \n slope=%-.2f, p=%-.2e \n n=%d',string(task),mean_slope,pval, nsubjects);
title(titlestr)
%

% calculate magnification vs perceived angle and task on a log-log axis
% organize data table for log metrics
log2real_visual_angle=log2(real_visual_angle);
log2ratio_visual_angle=log2(ratio_visual_angle);
log2distance=log2(distance);
IDs=all_data.ID(task_i);
tbl = table(IDs,log2real_visual_angle,log2ratio_visual_angle,log2distance,'VariableNames',{'ID','log2_real_visual_angle','log2_ratio_visual_angle', 'log2_distance'});

% linear mixed model on log magnification as function of log visual angle
% subjects are random effect(random intercept)
% PM for perceptual magnification
lme_logPM_by_logangle= fitlme(tbl,'log2_ratio_visual_angle ~ log2_real_visual_angle +  (1| ID)')

if saveLME
    savelmefile=fullfile('.','Results', basename, [basename '_lme_logPM_by_logangle_' task '.txt']);
    diary(savelmefile)
    lme_logPM_by_logangle
    diary off
end


meanA_intercept=lme_logPM_by_logangle.Coefficients.Estimate(1); % first coefficient-> intercept
pvalA_intercept=lme_logPM_by_logangle.Coefficients.pValue(1); % pvalue first coefficient-> slope

meanA_slope=lme_logPM_by_logangle.Coefficients.Estimate(2); % second coefficient-> slope on angle
pvalA_slope=lme_logPM_by_logangle.Coefficients.pValue(2); % pvalue second coefficient-> slope 
lower_slopeA=lme_logPM_by_logangle.Coefficients.Lower(2);
upper_slopeA=lme_logPM_by_logangle.Coefficients.Upper(2);
xvectorAu= log2(.25):1:log2(8);
xvectorAd= log2(8):-1:log2(.25);
yvectorA1=lower_slopeA*xvectorAu+ meanA_intercept;
yvectorA2=upper_slopeA*xvectorAd+ meanA_intercept;
xvectorA=[xvectorAu xvectorAd];
yvectorA=[yvectorA1 yvectorA2];

%% plot magnification vs real visual angle log-log axes
subplot(1,4,2)
hold on 
scatter(log2real_visual_angle,log2ratio_visual_angle,markerScale,subjectcolor,'o','filled');
plot (xvectorA, meanA_slope*xvectorA+meanA_intercept,'k-','LineWidth',3);
fill(xvectorA, yvectorA, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);

xlinerange=log2(.25):1:log2(8); 
ylinerange=zeros(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
 
set(gca,'XTick',log2(.25):1:log2(8),'XTickLabel',2.^[log2(.25):1:log2(8)],'XTickLabelRotation',0);
set(gca,'YTick',log2(.25):1:round(log2(maxRatio)),'YTickLabel',2.^[log2(.25):1:round(log2(maxRatio))]);
axis([log2(.25) log2(8) log2(.25) round(log2(maxRatio))])
xlabel ('Real Visual Angle (degree) log scale')
ylabel ('Perceptual Magnification log scale')

if pvalA_slope<0.001
titlestr=sprintf('%s \n slope=%-.2f, p=%-.2e \n intercept=%-.2f, p=%-.2e',...
    string(task),meanA_slope,pvalA_slope,meanA_intercept,pvalA_intercept);
else
    titlestr=sprintf('%s \n slope=%-.2f, p=%-.2f \n intercept=%-.2f, p=%-.2e',...
    string(task),meanA_slope,pvalA_slope,meanA_intercept,pvalA_intercept);
end
title(titlestr)
set(gca,'FontSize',14,'FontName','Avenir')

%
% linear mixed model on log magnification as function of log distance
% subjects are random effect (random intercept) 
lme_logPM_by_logdistance= fitlme(tbl,'log2_ratio_visual_angle ~ log2_distance +  (1| ID)')


lme_logPM_by_logdistance_adjusted=lme_logPM_by_logdistance;
if saveLME
    savelmefile=fullfile('.','Results', basename, [basename '_lme_logPM_by_logdistance_' task '.txt']);
    diary(savelmefile)
    lme_logPM_by_logdistance
    diary off
end

 
meanD_intercept=lme_logPM_by_logdistance.Coefficients.Estimate(1); % first coefficient-> intercept
pvalD_intercept=lme_logPM_by_logdistance.Coefficients.pValue(1); % pvalue first coefficient-> slope

meanD_slope=lme_logPM_by_logdistance.Coefficients.Estimate(2); % second coefficient-> slope on angle
pvalD_slope= lme_logPM_by_logdistance.Coefficients.pValue(2); % pvalue second coefficient-> slope
lower_slopeD=lme_logPM_by_logdistance.Coefficients.Lower(2);
upper_slopeD= lme_logPM_by_logdistance.Coefficients.Upper(2);
distanceRange=maxDistance*1.2;
xvectorDu= 0:10:distanceRange;
xvectorDd= distanceRange:-10:0;
yvectorD1=lower_slopeD*xvectorDu+meanD_intercept;
yvectorD2=upper_slopeD*xvectorDd+meanD_intercept;
xvectorD=[xvectorDu xvectorDd];
yvectorD=[yvectorD1 yvectorD2];

%% plot magnification vs distance 
subplot(1,4,3)
hold on 
plot(xvectorD, meanD_slope*xvectorD+meanD_intercept,'k-','LineWidth',3); % regression
fill(xvectorD, yvectorD, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1); %confidence interval over fixed effects
scatter(log2distance,log2ratio_visual_angle,markerScale,subjectcolor,'o','filled');
 
xlinerange=unique(log2distance);
ylinerange=zeros(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);
set(gca,'XTick',unique(log2distance),'XTickLabel',unique(distance),'XTickLabelRotation',90);
set(gca,'YTick',log2(.25):1:round(log2(maxRatio)),'YTickLabel',2.^[log2(.25):1:round(log2(maxRatio))]);
axis([.9*min(xlinerange) 1.1*max(xlinerange) log2(.25) round(log2(maxRatio))])
xlabel ('Distance (m) log scale')
ylabel ('Perceptual Magnification log scale')
if pvalD_slope<0.001
 titlestr=sprintf('%s \n slope=%-.2f, p=%-.2e \n intercept=%-.2f, p=%-.2e',...
     string(task),meanD_slope,pvalD_slope,meanD_intercept,pvalD_intercept);
else
 titlestr=sprintf('%s \n slope=%-.2f, p=%-.2f \n intercept=%-.2f, p=%-.2e',...
     string(task),meanD_slope,pvalD_slope,meanD_intercept,pvalD_intercept);
end
title(titlestr)
set(gca,'FontSize',14,'FontName','Avenir')


%%
% lme of log magnification as a factor of both log angle and log distance 
% subject is a random effect (random slopes)
% check that both factors significantly contribute to observations
lme_logPM_by_logangle_and_logdistance= fitlme(tbl,'log2_ratio_visual_angle ~ log2_real_visual_angle + log2_distance + (1| ID)')

if saveLME
    savelmefile=fullfile('.','Results', basename,...
        [basename '_lme_logPM_by_logangle_and_logdistance_' task '.txt']);
    diary(savelmefile)
    lme_logPM_by_logangle_and_logdistance
    diary off
end

%% model comparisons

if saveLME % save stats table
    savelmefile=fullfile('.','Results', basename ,[basename '_JointvsSingle_model_comparison_' task '.txt']);
    diary(savelmefile)
    fprintf(1,'task: %\n',task)
    compare(lme_logPM_by_logangle,     lme_logPM_by_logangle_and_logdistance)   
    compare(lme_logPM_by_logdistance  ,lme_logPM_by_logangle_and_logdistance) 
    diary off
end



%%


% plot predictions of joint model

 subplot (1,4,4)
 % 1.  Fixed‑effects parameters from lme 
[fe_betas,  ~,  fe_stats] = fixedEffects(lme_logPM_by_logangle_and_logdistance);
intercept            = fe_betas(1);
beta_log_real_angle  = fe_betas(2);
beta_log_distance    = fe_betas(3);

% Build log2 ranges for angle (rows) and distance (columns) 
minAngle4plot = min(all_data.Real_Visual_Angle);
maxAngle4plot = max(all_data.Real_Visual_Angle);
minDistance   = min(all_data.Distance);
maxDistance   = max(all_data.Distance);

yTickVec = round(log2(maxAngle4plot)) : -1 : round(log2(minAngle4plot));    % ↓
xTickVec = round(log2(minDistance))   :  1  : round(log2(maxDistance));     % →

log2_angleRange    = linspace(log2(minAngle4plot), log2(maxAngle4plot), numel(yTickVec)*20);
log2_distanceRange = linspace(log2(minDistance),   log2(maxDistance),   numel(xTickVec)*20);

%  Evaluate model on the grid 
log2PM = zeros(numel(log2_angleRange), numel(log2_distanceRange));
for d = 1:numel(log2_distanceRange)
    for a = 1:numel(log2_angleRange)
        log2PM(a,d) = intercept ...
                    + beta_log_real_angle * log2_angleRange(a) ...
                    + beta_log_distance   * log2_distanceRange(d);
    end
end

%  Plot the prediction
imagesc(flipud(2.^log2PM), [0.75 4]);          % PM bacsk to linear units
colormap(turbo);
cb = colorbar;
ylabel(cb, 'Perceptual Magnification', 'FontSize',14,'FontName','Avenir')

xlabel('Distance (m)  (log scale)')
ylabel('Visual Angle (deg)  (log scale)')
set(gca,'FontSize',14,'FontName','Avenir','TickDir','out')

% Y (rows): convert each log2(angle) tick to its matrix row index
yIdx_unflipped = round( (yTickVec - log2(minAngle4plot)) ./ ...
                        (log2(maxAngle4plot)-log2(minAngle4plot)) .* ...
                        (numel(log2_angleRange)-1) ) + 1;
yIdx           = numel(log2_angleRange) - yIdx_unflipped + 1;   % flip rows

% X (columns): convert each log2(distance) tick to its column index
xIdx = round( (xTickVec - log2(minDistance)) ./ ...
              (log2(maxDistance)-log2(minDistance)) .* ...
              (numel(log2_distanceRange)-1) ) + 1;

% MATLAB requires ascending YTick values
[yIdxSorted, sortOrder] = sort(yIdx);
yTickLabelsSorted       = 2.^yTickVec(sortOrder);

set(gca, 'XTick', xIdx,        'XTickLabel', 2.^xTickVec)
set(gca, 'YTick', yIdxSorted,  'YTickLabel', yTickLabelsSorted)

axis square tight   % equal data‑unit lengths & no extra padding

% Title
if fe_stats.pValue(3) < 0.001
    titlestr = sprintf(['Joint Model Prediction\nPM = %.2f · VA^{%.2f} · D^{%.2f}\n' ...
                        'p_{VA}=%.2e, p_{D}=%.2e'], ...
                       2^intercept, beta_log_real_angle, beta_log_distance, ...
                       fe_stats.pValue(2), fe_stats.pValue(3));
else
    titlestr = sprintf(['Joint Model Prediction\nPM = %.2f · VA^{%.2f} · D^{%.2f}\n' ...
                        'p_{VA}=%.2e, p_{D}=%.2f'], ...
                       2^intercept, beta_log_real_angle, beta_log_distance, ...
                       fe_stats.pValue(2), fe_stats.pValue(3));
end
title(titlestr)


% save figure

% filenameEPS= fullfile('.','Results', basename, [basename '_logAxis_', task ,'_', num2str(nsubjects),'.eps']);
% exportgraphics(figh,filenameEPS,'Resolution',600,'ContentType','vector');

filenamePNG=fullfile('.','Results',basename, [basename '_' task ,'_logAxis_prediction_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);
%% save
savefile=fullfile('.', 'Results', basename,[basename '_analysed']);
save(savefile)
%% plot magnification as a function of angle on regular axis use the results from lme above
% 
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0.4 1 .35],'Name',[basename '_' task])

mean_slope=lme_by_angle.Coefficients.Estimate;
pval=lme_by_angle.Coefficients.pValue;
lower_slope=lme_by_angle.Coefficients.Lower;
upper_slope=lme_by_angle.Coefficients.Upper;
xvectoru= [0:maxAngle];
xvectord= [maxAngle:-1:0];
yvector1=lower_slope*xvectoru;
yvector2=upper_slope*xvectord;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];


% get individual subject slopes
[reSlopes, reNames,reStats] = randomEffects(lme_by_angle);
fixedSlope = fixedEffects(lme_by_angle);
individualSlopes=reSlopes+fixedSlope;
[sorted_individualSlopes, sorted_idx] = sort(individualSlopes);

subplot(1,4,1); %plot results
hold on 
% clear subjectcolor; % sort subjects by regression slope of reported visual angle vs real visual angle
% ID=all_data.ID(task_i);
% for c=1:length(ID)
%     cindex=find(uniqueID==ID(c));
%     sorted_cindex=find(sorted_idx==cindex);
%     %subjectcolor(c,:)=cmap(cindex,:);
%     subjectcolor(c,:)=cmap(sorted_cindex,:);
% end
% for s=1:nsubjects
%     sortedID=sorted_idx(s);
%     yvectorS= individualSlopes(sortedID)*xvectorS;
%     plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
% end

plot (0:maxAngle, 0:maxAngle,'k:','LineWidth',1);
plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
scatter(real_visual_angle,reported_visual_angle,markerScale,subjectcolor,'o','filled');
axis('equal'); axis([0 maxAngle 0 maxAngle]); 
xlabel ('Real Visual Angle (degree)')
ylabel ('Reported Visual Angle (degree)') 
set(gca,'FontSize',14,'FontName','Avenir')
titlestr=sprintf('%s \n slope=%-.2f, p=%-.2e \n n=%d',string(task),mean_slope,pval, nsubjects);
title(titlestr)


% calculate regression line and confidence interval on fixed effect
meanA_intercept=lme_logPM_by_logangle.Coefficients.Estimate(1); % first coefficient-> intercept
pvalA_intercept=lme_logPM_by_logangle.Coefficients.pValue(1); % pvalue first coefficient-> slope

meanA_slope=lme_logPM_by_logangle.Coefficients.Estimate(2); % second coefficient-> slope 
pvalA_slope=lme_logPM_by_logangle.Coefficients.pValue(2); % pvalue second coefficient-> slope
lowerA_slopeR=lme_logPM_by_logangle.Coefficients.Lower(2);
upperA_slopeR=lme_logPM_by_logangle.Coefficients.Upper(2);


% the regression is log-log to linearize the curve
% lme_logPM_by_logangle= fitlme(tbl,'log2_ratio_visual_angle~log2_real_visual_angle + (log2_real_visual_angle| ID)')
% log2(ratio)=intercept+slope*log2(angle)
% ratio=2^intercept*2^(slope*angle)
% transform regression to regular axis
% ratio_visual_angle=2^meanR_intercept*real_visual_angle.^(meanR_slope)
% estimate regression line and confidence interval
xvectorAu= unique(real_visual_angle);
xvectorAd= flipud(xvectorAu);
yvectoru=(2.^meanA_intercept)*xvectorAu.^meanA_slope;
yvectorA1=(2.^meanA_intercept)*xvectorAu.^lower_slopeA;
yvectorA2=(2.^meanA_intercept)*xvectorAu.^upper_slopeA;% R2 is lower than R1

% plot magnification ratio vs real visual angle
subplot(1,4,2); 
hold on 
scatter(real_visual_angle,ratio_visual_angle,markerScale,subjectcolor,'o','filled');
plot (xvectorAu,yvectorA1 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
plot (xvectorAu,yvectorA2 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
plot (xvectorAu,yvectoru ,'k-','LineWidth',3);

% 
xlinerange=.25:.25:8; 
ylinerange=ones(size(xlinerange)); % no magnification
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line 
set(gca,'XTick',0:1:8)
set(gca,'YTick',0:2:maxRatio)
axis([0 8 0 maxRatio])

xlabel ('Real Visual Angle (degree)')
ylabel ('Perceptual Magnification')
if pvalA_slope<0.001
    titlestr=sprintf('%s \n PM= %3.2f*(Visual Angle)^{%3.2f}\n p_{I}=%-.2e p_{E}=%-.2e',...
    string(task),2^meanA_intercept, meanA_slope,pvalA_intercept,pvalA_slope);
else
    titlestr=sprintf('%s \n PM= %3.2f*(Visual Angle)^{%3.2f}\n p_{I}=%-.2e p_{E}=%-.2f',...
    string(task),2^meanA_intercept, meanA_slope,pvalA_intercept,pvalA_slope)
end
title(titlestr)
set(gca,'FontSize',14,'FontName','Avenir')


% get regression coefficients and confidence interval on fixed effect
meanD_intercept=lme_logPM_by_logdistance.Coefficients.Estimate(1);% first coefficient ->intercept
meanD_slope=lme_logPM_by_logdistance.Coefficients.Estimate(2); % second coefficient-> slope 
pvalD_intercept= lme_logPM_by_logdistance.Coefficients.pValue(1); % pvalue first coefficient-> intercept
pvalD_slope= lme_logPM_by_logdistance.Coefficients.pValue(2); % pvalue second coefficient-> slope
lower_slopeD= lme_logPM_by_logdistance.Coefficients.Lower(2);
upper_slopeD= lme_logPM_by_logdistance.Coefficients.Upper(2);

xvectorDu= unique(distance);
yvectorDu=(2.^meanD_intercept)*xvectorDu.^meanD_slope;
yvectorD1=(2.^meanD_intercept)*xvectorDu.^lower_slopeD;
yvectorD2=(2.^meanD_intercept)*xvectorDu.^upper_slopeD;

xvectorD=[xvectorDu flipud(xvectorDu)];
yvectorD=[yvectorD1 flipud(yvectorD2)];

subplot(1,4,3); 
hold on 
scatter(distance,ratio_visual_angle,markerScale,subjectcolor,'o','filled');

plot (xvectorDu,yvectorD1 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
plot (xvectorDu,yvectorD2 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
plot (xvectorDu,yvectorDu ,'k-','LineWidth',3);

xlinerange=0:1:max(distance)*1.1;
ylinerange=ones(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);
axis([0 1.1*max(distance) 0 maxRatio]); 
set(gca,'YTick',[0:2:maxRatio])
xlabel ('Distance (m)')
ylabel ('Perceptual Magnification')
if pvalD_slope<0.001
    titlestr=sprintf('%s \n PM= %3.2f*(Distance)^{%3.2f}\n p_{I}=%-.2e p_{E}=%-.2e',...
        string(task),2^meanD_intercept, meanD_slope,pvalD_intercept,pvalD_slope);
else
    titlestr=sprintf('%s \n PM= %3.2f*(Distance)^{%3.2f}\n p_{I}=%-.2e p_{E}=%-.2f',...
        string(task),2^meanD_intercept, meanD_slope,pvalD_intercept,pvalD_slope)
end
title(titlestr)
set(gca,'FontSize',14,'FontName','Avenir')


% plot predictions of joint model
% plot estimated values in image format
% add an if statement to use the joint model only if both effects are
% significant 

% get model fixed effects parameters
[fe_betas, fe_names, fe_stats] = fixedEffects(lme_logPM_by_logangle_and_logdistance);
intercept = fe_betas(1);
beta_log_real_angle = fe_betas(2);
beta_log_distance = fe_betas(3);
 
%
nXTicks   = 6;      % # distance ticks 
nYTicks   = 6;      % # angle  ticks 
gridSize  = 200;    % resolution of the prediction surface

minDistance = min(all_data.Distance);
maxDistance = max(all_data.Distance);
minAngle    = 0.25;         
maxAngle    = 8;

distanceRange = linspace(minDistance, maxDistance, gridSize);  % linear scale
angleRange    = linspace(minAngle   , maxAngle   , gridSize);  % linear scale

xTickVals = linspace(minDistance, maxDistance, nXTicks);   % m
yTickVals = linspace(minAngle   , maxAngle   , nYTicks);   % deg

%  Model predictions 
log2PM = zeros(numel(angleRange), numel(distanceRange));
for d = 1:numel(distanceRange)
    for a = 1:numel(angleRange)
        log2PM(a,d) = intercept ...
            + beta_log_real_angle * log2(angleRange(a)) ...
            + beta_log_distance   * log2(distanceRange(d));
    end
end

% Plot 
subplot (1,4,4)
imagesc(flipud(2.^log2PM), [0.75 4]);          % PM is shown in linear units

% Convert tick values to matrix indices (sorted version)
[~, xTickIdx] = min(abs(distanceRange.' - xTickVals), [], 1);
[~, yTickIdx] = min(abs(angleRange.' - yTickVals), [], 1);
yTickIdxFlipped = size(log2PM,1) - yTickIdx + 1; % need to flip Y index because this is an image not a graph 


% Sort flipped Y indices in ascending order for valid plotting
[yTickIdxFlippedSorted, sortIdx] = sort(yTickIdxFlipped);
yTickValsSorted = yTickVals(sortIdx);

set(gca, 'XTick', xTickIdx, 'XTickLabel', string(round(xTickVals,2)));
set(gca, 'YTick', yTickIdxFlippedSorted, 'YTickLabel', string(round(yTickValsSorted,2)));

axis square tight
colormap(turbo);

cb = colorbar; ylabel(cb, 'Perceptual Magnification', 'FontSize', 14,'FontName','Avenir');
xlabel('Distance (m)');  ylabel('Visual Angle (deg)');
%set(gca, 'FontSize', 14, 'TickDir', 'out');
if fe_stats.pValue(3)<0.001
 titlestr=sprintf('Joint Model Prediction \n PM=%-.2f· VA^{%-.2f}· D^{%-.2f}\n p=%-.2e, p=%-.2e',...
      2^intercept, beta_log_real_angle,beta_log_distance, ...
     fe_stats.pValue(2), fe_stats.pValue(3) );
else
    titlestr=sprintf('Joint Model Prediction \n PM=%-.2f· VA^{%-.2f}· D^{%-.2f}\n p_{VA}=%-.2e, p_{D}=%-.2f',...
      2^intercept, beta_log_real_angle,beta_log_distance, ...
     fe_stats.pValue(2), fe_stats.pValue(3) );

end

title(titlestr) 
set(gca,'FontSize',14,'FontName','Avenir')


filenamePNG=fullfile('.','Results', basename, [basename,'_', task ,'_prediction_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);








