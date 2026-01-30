function Quad_PM_by_task_old(dataDir,datafile,ResultsDir,task, recomputeSort, saveLME)
% 
% Quad_PM_by_task(dataDir,datafile,ResultsDir,task, recomputeSort, saveLME)
% defaults
% if ~exist('dataDir')
%     dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
% end
% cd(dataDir)
% 
% if ~exist('datafile')
%    datafile='DataLongKeithan071025.csv'; % all data
% 
% end
% basename = [erase( datafile,'.csv')] ; % for saving
% 
% if ~exist('ResultsDir')
%   ResultsDir='PaperFigures'; % all data
% end
% 
% if ~exist('saveLME')
%         saveLME=1;
% end
% 
% if ~exist('task')
%        task='Perceptual'
%        recomputeSort=1;
% end

%set defaults
% data loading and setting up some basic information
if ~exist('dataDir')
    dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
end
cd(dataDir)

if ~exist('datafile')
   datafile='DataLongKeithan071025.csv'; % all data

end
basename = [erase( datafile,'.csv')] ; % for saving

if ~exist('ResultsDir')
  ResultsDir='PaperFigures'; % all data
end

if ~exist('ResultsDir','dir')
    mkdir(ResultsDir)
end

if ~exist('saveLME')
        saveLME=1;
end

if ~exist('task')
       task='Perceptual'
       recomputeSort=1;
end



all_data=readtable(datafile);
nameVars=all_data.Properties.VariableNames;
disp(nameVars)
nVars=length(all_data.Properties.VariableNames);
allTasks =unique(all_data.Task);disp(allTasks)
nTasks=length(allTasks);
uniqueID=unique(all_data.ID);
uniqueObject=unique(all_data.Measurement);
nObjects=length(uniqueObject);

% %% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task

 ii=find(all_data.ID~=26); 
 all_data=all_data(ii,:);  
 uniqueID=unique(all_data.ID);
 nsubjects=length(uniqueID);

%% remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
all_data=all_data(NotNaN,:);


%% find max angle and maxRatio for graphs
maxRealAngle=max(all_data.Real_Visual_Angle);
maxAngle=max(all_data.Reported_Visual_Angle);

task_1=find(strcmp(all_data.Task,allTasks(1)));
task_2=find(strcmp(all_data.Task,allTasks(2)));
maxRatio=max(all_data.Ratio_Visual_Angle);
% transform distances from cm to m 
all_data.Distance=all_data.Distance/100;
maxDistance=max(all_data.Distance);
minDistance=min(all_data.Distance);
% check that NA in QuadDataLong.csv has been replaced with empty cell
minDisparity=min([all_data.Disparity_VA_1; all_data.Disparity_VA_2]);
maxDisparity=max([all_data.Disparity_VA_1; all_data.Disparity_VA_2]);


%% set colormap
cmapflag=2;
if cmapflag==1
    tmp_cmap_cool=cool(round(nsubjects/4)+1);
    tmp_cmap_hot=autumn(round(nsubjects/4)+1);
    tmp_cmap_copper=copper(round(nsubjects/4)+1);
    tmp_cmap_jet=jet(round(nsubjects/4)+1);

    for i=1:nsubjects
        if (mod(i,4)==0)
            cmap(i,:)=tmp_cmap_cool(i/4,:);
        elseif (mod(i,4)==1)
            cmap(i,:)=tmp_cmap_hot(ceil(i/4),:);
        elseif (mod(i,4)==2)
            cmap(i,:)=tmp_cmap_copper(ceil(i/4),:);
        else
            cmap(i,:)=tmp_cmap_jet(ceil(i/4),:);
        end
    end
else
    % alt cmap
    cmap=jet(nsubjects);
end
markerScale=36;

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
     savelmefile=fullfile('.',ResultsDir, [basename '_lme_reported_vs_real_angle_' task '.txt']);
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
    savefile=fullfile('.', ResultsDir, [basename  '_sorted_idx']);
    save(savefile ,'sorted_idx');
else
    loadfile=fullfile('.', ResultsDir, [basename  '_sorted_idx']);
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
    savelmefile=fullfile('.',ResultsDir, [basename '_lme_logPM_by_logangle_' task '.txt']);
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
    savelmefile=fullfile('.',ResultsDir, [basename '_lme_logPM_by_logdistance_' task '.txt']);
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
    savelmefile=fullfile('.',ResultsDir,...
        [basename '_lme_logPM_by_logangle_and_logdistance_' task '.txt']);
    diary(savelmefile)
    lme_logPM_by_logangle_and_logdistance
    diary off
end

%% model comparisons

if saveLME % save stats table
    savelmefile=fullfile('.',ResultsDir,[basename '_JointvsSingle_model_comparison_' task '.txt']);
    diary(savelmefile)
    fprintf(1,'task: %\n',task)
    compare(lme_logPM_by_logangle,     lme_logPM_by_logangle_and_logdistance)   
    compare(lme_logPM_by_logdistance  ,lme_logPM_by_logangle_and_logdistance) 
    diary off
end



%%

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


filenamePNG=fullfile('.',ResultsDir, [basename,'_', task ,'_PM_by_VA_Distance', num2str(nsubjects),'.png'])
exportgraphics(figh,filenamePNG,'Resolution',600);
