
function [lme_by_logRatio_by_Elevation]=SMS_FullMoon_PM_by_task_log(dataDir,datafile,ResultsDir,task, recomputeSort,saveLME)
%
% FullMoon_PM_by_task_log(dataDir,datafile,ResultsDir,task, recomputeSort,saveLME)
% Plots the perceived size and perceived perceptual magnification by
% Elevation of the moon usinf the data in dataDir/datafile
% for each task
% results are stored in ResultsDir
% saveLME will output the stats into a text file
% recomputeSort - will sort the subjects by their slopes
% % defaults
% if ~exist('datDir')
%     dataDir='/Users/kalanit/Projects/PerceptualMagnification/MoonExperiments/';
% end
% cd(dataDir)
% 
% if ~exist('datafile')
%    datafile='FullMoonDataLong.csv'; % all data
% 
% end
% basename = [erase( datafile,'.csv')] ; % for saving
% 
% if ~exist('ResultsDir')
%   ResultsDir='PaperFigures'; % all data
% end
% 
% if ~exist(ResultsDir,'dir')
%     mkdir(ResultsDir)
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
    dataDir='/Users/kalanit/Projects/PerceptualMagnification/MoonExperiments/';
end
cd(dataDir)

if ~exist('datafile')
   datafile='FullMoonDataLong.csv'; % all data

end
basename = [erase( datafile,'.csv')] ; % for saving

if ~exist('ResultsDir')
  ResultsDir='PaperFigures'; % all data
end

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end

if ~exist('saveLME')
        saveLME=1;
end

if ~exist('task')
       task='Perceptual'
       recomputeSort=1;
end

%
all_data=readtable(datafile);
nameVars=all_data.Properties.VariableNames;
nVars=length(all_data.Properties.VariableNames);
allTasks =unique(all_data.Task);disp(allTasks)
nTasks=length(allTasks);
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);

%remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
length(NotNaN);
all_data=all_data(NotNaN,:);

% find max angle and maxRatio for graphs
maxAngle=max(all_data.Reported_Visual_Angle);
maxRatio=max(all_data.Ratio_Visual_Angle);
maxDistance=max(all_data.Distance);
minElevation=min(all_data.Elevation);
maxElevation=max(all_data.Elevation);
meanMoonSize=mean(all_data.Real_Visual_Angle);


% get the relevant data by task
task_i=find(strcmp(all_data.Task,task));
all_data=all_data(task_i,:);
Elevation=all_data.Elevation;
all_data.logRatio=log2(all_data.Ratio_Visual_Angle);
all_data.logElevation=log2(all_data.Elevation+1); % add regularization term to elevation as log(0) is not defined and elevation can be zero
%% set colormap
cmap=jet(nsubjects);
markerScale=36;
%%
% linear mixed model relating log PM vs log Elevation

%random intercepts model
lme_by_logRatio_by_Elevation = fitlme(all_data,'logRatio~logElevation+ (1|ID)'); % as log function doesn't deal with 0 and elevation can be 0 add 1 as a regularization factor

%random intercepts and random slopes model
lme_by_logRatio_by_Elevation_RS=fitlme(all_data, 'logRatio~logElevation + (logElevation|ID)');  % as log function doesn't deal with 0 and elevation can be 0 add 1 as a regularization factor

model_comp_log=compare(lme_by_logRatio_by_Elevation,lme_by_logRatio_by_Elevation_RS); % compare RS and random intercepts models

if saveLME
   savelmefile=fullfile(''.',ResultsDir, [basename '_' task '_lme_moon_logRatio_by_Elevation.txt']);
   summaryLines = {
       sprintf('Task: %s', task)
       sprintf('Median matched size: %.2f', median(all_data.Reported_Visual_Angle))
       sprintf('Mean matched size: %.2f', mean(all_data.Reported_Visual_Angle))
       sprintf('Matched-size SD: %.2f', std(all_data.Ratio_Visual_Angle))
       };
   write_moon_lme_report(savelmefile, ...
       sprintf('Moon perceptual magnification by elevation %s %s ', datafile, task), ...
       summaryLines, ...
       {lme_by_logRatio_by_Elevation, lme_by_logRatio_by_Elevation_RS}, ...
       {'lme_by_logRatio_by_Elevation', 'lme_by_logRatio_by_Elevation_RS'}, ...
       {model_comp_log}, ...
       {'model_comp_log'});
end

% use random slopes model to plot invidual subject slopes; in the log vs log fit the random
% slopes model does not signigicantly explain more variance in the data for
% either perceptual or adjusted cases
% AIC comparison also suggests that the log-log model is a better fit than
% linear model

[reEfx_log,reNames_log,reStats_log] = randomEffects(lme_by_logRatio_by_Elevation_RS);
[feEfx_log,feNames_log,festats_log] =fixedEffects(lme_by_logRatio_by_Elevation); % we are going to plot the fixed effect model in the second plot

ID=all_data.ID;
uniqueID=unique(ID);
nsubjects=length(uniqueID);
individualIntercepts = zeros(nsubjects,1);
individualSlopes = zeros(nsubjects,1);
for i = 1:nsubjects
    % Indices for this subject's random effects
    subjectRows = find(strcmp(reNames_log.Level, num2str(uniqueID(i)))); 
    individualIntercepts_log(i) = feEfx_log(1) + reEfx_log(subjectRows(1));
    individualSlopes_log(i)    = feEfx_log(2) + reEfx_log(subjectRows(2));
end

% set colormap
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end
if recomputeSort
   % sort by intercepts
   [sorted_individualIntercepts_log, sorted_idx_log] = sort(individualIntercepts_log);
    clear subjectcolor;
    cmap=jet(nsubjects);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        sorted_cindex=find(sorted_idx_log==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
    end
    savefile=fullfile(ResultsDir, [basename  '_sortedidx']);
    save(savefile ,'sorted_idx_log');
else
    loadfile=fullfile(ResultsDir, [basename '_sortedidx']);
    load(loadfile);
    clear subjectcolor;
    cmap=jet(nsubjects);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        sorted_cindex=find(sorted_idx_log==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
    end
end

%% plot random slopes model on a log-log scale and fixed effect model on a linear scale
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .8 .6],'Name',[basename 'Perceptual Magnification vs Elevation RS log scale RI linear scale'])
subplot(1,2,2); hold on 


interceptL=feEfx_log(1);
slopeL=feEfx_log(2);
pvalL=festats_log.pValue(2);
lower_slopeL=festats_log.Lower(2);
upper_slopeL=festats_log.Upper(2);
xvectoru=linspace(min(all_data.logElevation),max(all_data.logElevation));
xvectord = sort(xvectoru, 'descend');
% fixed effects estimate
y_fit =interceptL+slopeL*xvectoru;


% fixed effects confidence interval
yvectoru=slopeL*xvectoru+interceptL;
yvector1=lower_slopeL*xvectoru+interceptL;
yvector2=upper_slopeL*xvectord+interceptL;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot line fits only if significant 
if pvalL < 0.05
       % plot individual subjects slopes
    for s=1:nsubjects
        sortedID=sorted_idx_log(s);
        sindex=find(uniqueID==ID(sortedID));
        jj=find(all_data.ID==uniqueID(sindex));
        if numel(jj) > 1
            sdata=all_data(jj,:);
            lower=find(strcmp(sdata.Session,'Lower'));
            higher=find(strcmp(sdata.Session,'Higher'));
            %xvectorS=[sdata.logElevation(lower) sdata.logElevation(higher)];
             xvectorS=xvectoru;
           % rand effex: each subject has different intercept
             yvectorS=  individualSlopes_log(sortedID)*xvectorS+individualIntercepts_log(sortedID);
             plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
     end
    % fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    % plot(xvectoru, y_fit, 'k-','LineWidth',5);
    if pvalL < 0.001
        titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%5.2e\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
    else
        titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.2f\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
    end 
else
    titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.2f\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
end

% plot scatter plot of individual data
scatter(all_data.logElevation, all_data.logRatio, markerScale,subjectcolor,'o','filled');
plot([1 max(all_data.logElevation)], [0  0],'Color',[.8 .8 .8],'LineWidth',3)
% ylim([0 maxAngle])
xlabel ('Moon Elevation (degree), log scale')
ylabel ('Perceptual Magnification, log scale')
set(gca,'FontSize',20, 'FontName','Avenir')
title(titlestr,'FontSize',16,'FontName','Avenir')

% put tick labels numbers rather than log numbers
xticks=get(gca,'Xtick');set(gca,'XTickLabel', round(2.^xticks,1));
yticks=get(gca,'Ytick');set(gca,'YTickLabel', round(2.^yticks,1));

% estimate function PM= 2^interceptL*elevation^slopeL
interceptL=feEfx_log(1);
slopeL=feEfx_log(2);
xvector=linspace(1,max(all_data.Elevation));%linspace(min(all_data.Elevation),max(all_data.Elevation));  %estimate from 1 degree and up
yvector=2^interceptL*(xvector.^slopeL);

subplot (1,2,1); hold on

% plot PM vs Elevation using power law fit
scatter(all_data.Elevation,all_data.Ratio_Visual_Angle,markerScale,subjectcolor,'o','filled');
plot(xvector,yvector,'k-','LineWidth',3); % plot fixed effects
% fixed effects confidence interval

% confidence interval
yvector1=2^interceptL*(xvector.^lower_slopeL);
xvectord = sort(xvector, 'descend');
yvector2=2^interceptL*(xvectord.^upper_slopeL);
xvectorCI=[xvector xvectord];
yvectorCI=[yvector1 yvector2];

fill(xvectorCI, yvectorCI, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);

plot([0 maxElevation], [1 1],'Color',[.8 .8 .8 ],'LineWidth',3)
xlabel ('Moon Elevation (degrees)')
ylabel ('Perceptual Magnification') 
ylim([0 maxRatio])
set(gca,'YTick', [0:1:maxRatio],'YtickLabel', [0:1:maxRatio], 'FontSize',20,'FontName','Avenir')
if pvalL < 0.001
        titlestr=sprintf('%s Matching\n PM=%.1f(1+Elevation)^{%.2f}  \n p=%5.2e\n n=%d',task, round(2^interceptL,1),slopeL,festats_log.pValue(2), nsubjects);
    else
        titlestr=sprintf('%s Matching\n PM=%.1f(1+Elevation)^{%.2f}\n p=%.4f\n n=%d',task, round(2^interceptL,1),slopeL,festats_log.pValue(2), nsubjects);
end 
title(titlestr,'FontSize',16,'FontName','Avenir')

% save figure 
filenamePNG=fullfile(ResultsDir,['Fig1_' basename,'_' task ,'_', num2str(nsubjects),'.png']);
%print(figh,filenamePNG,'-dpng','-r600');
exportgraphics(figh, filenamePNG, 'Resolution', 600)

filenameEPS=fullfile(ResultsDir,['Fig1_' basename,'_' task ,'_', num2str(nsubjects),'.eps']);
print(figh,filenameEPS,'-depsc','-r600');

%%
% Supplemental figure comparing the RS linear and RS log-log models
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .8 .6],'Name',[basename 'Perceptual Magnification vs Elevation'])
subplot(1,2,2); hold on 
% get the stats from the Random Effects models as this is what we are
% plotting the RS model
[reEfx_log,reNames_log,reStats_log] = randomEffects(lme_by_logRatio_by_Elevation_RS);
[feEfx_log,feNames_log,festats_log] =fixedEffects(lme_by_logRatio_by_Elevation_RS);


interceptL=feEfx_log(1);
slopeL=feEfx_log(2);
pvalL=festats_log.pValue(2);
lower_slopeL=festats_log.Lower(2);
upper_slopeL=festats_log.Upper(2);
xvectoru=linspace(min(all_data.logElevation),max(all_data.logElevation));
xvectord = sort(xvectoru, 'descend');
% fixed effects estimate
y_fit =interceptL+slopeL*xvectoru;


% fixed effects confidence interval
yvectoru=slopeL*xvectoru+interceptL;
yvector1=lower_slopeL*xvectoru+interceptL;
yvector2=upper_slopeL*xvectord+interceptL;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot line fits only if significant 
if pvalL < 0.05
       % plot individual subjects slopes
    for s=1:nsubjects
        sortedID=sorted_idx_log(s);
        sindex=find(uniqueID==ID(sortedID));
        jj=find(all_data.ID==uniqueID(sindex));
        if numel(jj) > 1
            sdata=all_data(jj,:);
            lower=find(strcmp(sdata.Session,'Lower'));
            higher=find(strcmp(sdata.Session,'Higher'));
            %xvectorS=[sdata.logElevation(lower) sdata.logElevation(higher)]; % use subject specific xVector
            xvectorS=xvectoru;
           % rand effex: each subject has different intercept
             yvectorS=  individualSlopes_log(sortedID)*xvectorS+individualIntercepts_log(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    plot(xvectoru, y_fit, 'k-','LineWidth',5);
    if pvalL < 0.001
        titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%5.2e\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
    else
        titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.2f\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
    end 
else
    titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.2f\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
end

% plot scatter plot of individual data
scatter(all_data.logElevation, all_data.logRatio, markerScale,subjectcolor,'o','filled');
plot([1 max(all_data.logElevation)], [0  0],'Color',[.8 .8 .8],'LineWidth',3)
% ylim([0 maxAngle])
xlabel ('Moon Elevation (degree), log scale')
ylabel ('Perceptual Magnification, log scale')
set(gca,'FontSize',20, 'FontName','Avenir')
title(titlestr,'FontSize',16,'FontName','Avenir')

% put tick labels numbers rather than log numbers
xticks=get(gca,'Xtick');set(gca,'XTickLabel', round(2.^xticks,1));
yticks=get(gca,'Ytick');set(gca,'YTickLabel', round(2.^yticks,1));

% estimate function PM= 2^interceptL*elevation^slopeL
interceptL=feEfx_log(1);
slopeL=feEfx_log(2);
xvector=linspace(1,max(all_data.Elevation));%linspace(min(all_data.Elevation),max(all_data.Elevation));  %estimate from 1 degree and up
yvector=2^interceptL*(xvector.^slopeL);





%% Linear model: estimate relation between perceptual magnification (ratio) and Elevation 
%
% subject is a random effect, on intercept only
lme_ratio_by_Elevation = fitlme(all_data,'Ratio_Visual_Angle~Elevation + (1|ID)')
% subject is a random effect, on intercept & slope
lme_ratio_by_Elevation_RS = fitlme(all_data,'Ratio_Visual_Angle~Elevation + (Elevation|ID)')
% compare models
model_comp=compare(lme_ratio_by_Elevation,lme_ratio_by_Elevation_RS); % compare RS and random intercepts models


%
[reEfx,reNames,reStats] = randomEffects(lme_ratio_by_Elevation_RS);
[feEfx,feNames,festats] =fixedEffects(lme_ratio_by_Elevation_RS);

interceptR=feEfx(1);
slopeR=feEfx(2);
pvalR=festats.pValue(2);
lower_slopeR=festats.Lower(2);
upper_slopeR=festats.Upper(2);
xvectoru=linspace(minElevation,maxElevation);
xvectord = sort(xvectoru, 'descend');
yvectoru=slopeR*xvectoru+interceptR;
yvector1=lower_slopeR*xvectoru+interceptR;
yvector2=upper_slopeR*xvectord+interceptR;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];



% plot ratio vs Elevation
subplot(1,2,1); hold on 
scatter(all_data.Elevation,all_data.Ratio_Visual_Angle,markerScale,subjectcolor,'o','filled');
plot([0 maxElevation], [1 1],'Color',[.8 .8 .8 ],'LineWidth',3)
xlabel ('Moon Elevation (degrees)')
ylabel ('Perceptual Magnification') 
ylim([0 maxRatio])
set(gca,'YTick', [0:1:maxRatio],'YtickLabel', [0:1:maxRatio], 'FontSize',20,'FontName','Avenir')
title(titlestr,'FontSize',16,'FontName','Avenir')

% plot line fit only if significant

if pvalR<0.05
    % plot individual subjects slopes
    individualIntercepts = zeros(nsubjects,1);
    individualSlopes = zeros(nsubjects,1);
    for i = 1:nsubjects
        % Indices for this subject's random effects
        subjectRows = find(strcmp(reNames.Level, num2str(uniqueID(i)))); 
        individualIntercepts(i) = feEfx(1) + reEfx(subjectRows(1));
        individualSlopes(i)    = feEfx(2) + reEfx(subjectRows(2));        
    end
   
    for s=1:nsubjects
        sortedID=sorted_idx_log(s);
        sindex=find(uniqueID==ID(sortedID));
        jj=find(all_data.ID==uniqueID(sindex));
        if numel(jj) > 1
            sdata=all_data(jj,:);
            lower=find(strcmp(sdata.Session,'Lower'));
            higher=find(strcmp(sdata.Session,'Higher'));
            %xvectorS=[sdata.Elevation(lower) sdata.Elevation(higher)]; % use subject specific xVector
            xvectorS=xvectoru;
           % rand effex: each subject has differnet intercept
             yvectorS=  individualSlopes(sortedID)*xvectorS+individualIntercepts(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    if pvalR<0.001
        titlestr=sprintf('%s Matching\n PM=%3.2f + (%3.3f)*Elevation \n p=%5.2e \n n=%d',task,interceptR,slopeR,pvalR,nsubjects);
    else
       titlestr=sprintf('%s Matching\n PM=%3.2f + (%3.3f)*Elevation \n p=%.3f \n n=%d',task,interceptR,slopeR,pvalR,nsubjects);
    end
else
   titlestr=sprintf('%s Matching \n \n p=%.2f \n n=%d',task,pvalR,nsubjects);
end
scatter(all_data.Elevation,all_data.Ratio_Visual_Angle,markerScale,subjectcolor,'o','filled');
plot([0 maxElevation], [1 1],'Color',[.8 .8 .8 ],'LineWidth',3)
xlabel ('Moon Elevation (degrees)')
ylabel ('Perceptual Magnification') 
ylim([0 maxRatio])
set(gca,'YTick', [0:1:maxRatio],'YtickLabel', [0:1:maxRatio], 'FontSize',20,'FontName','Avenir')
title(titlestr,'FontSize',16,'FontName','Avenir')

% save figure 
filenamePNG=fullfile(ResultsDir,['SuppFig_LogLinModelComps_' basename,'_' task ,'_', num2str(nsubjects),'.png']);
exportgraphics(figh, filenamePNG, 'Resolution', 600)
filenameEPS=fullfile(ResultsDir,['SuppFig_LogLinModelComps_' basename,'_' task ,'_', num2str(nsubjects),'.eps']);
print(figh,filenameEPS,'-depsc','-r600');

ncount=length(find(individualSlopes<0));
if saveLME
   savelmefile=fullfile(''.',ResultsDir, [basename '_' task '_lme_moon_ratio_by_Elevation.txt']);
   summaryLines = {
       sprintf('Task: %s', task)
       sprintf('Median PM: %.2f', median(all_data.Ratio_Visual_Angle))
       sprintf('Mean PM: %.2f', mean(all_data.Ratio_Visual_Angle))
       sprintf('PM SD: %.2f', std(all_data.Ratio_Visual_Angle))
       sprintf('Participants with negative slopes: %.2f%%', 100*ncount/nsubjects)
       };
   write_moon_lme_report(savelmefile, ...
       sprintf('Moon perceptual magnification by elevation %s %s ', datafile, task), ...
       summaryLines, ...
       {lme_ratio_by_Elevation, lme_ratio_by_Elevation_RS}, ...
       {'lme_ratio_by_Elevation', 'lme_ratio_by_Elevation_RS'}, ...
       {model_comp}, ...
       {'model_comp'});
end



%% visualize illusion at the horizon and at 40 degrees
realVA=mean(all_data.Real_Visual_Angle);


distance_mm=500; % simulate illusion at arms-length distance of ~50cm=500mm;

% PM=interscept*(1+elevation)^(slope)
% so we will estimate the perceived visual angle at an elevation of 0.25 degrees (half the size of the moon) to
% estimate perceived visual angle at horizon


elevation=2.5; % lowest elevation we measured
perceivedVA=(2^interceptL)*((1+elevation)^slopeL)*realVA;
pmSuffix25 = strrep(sprintf('PMx%.2f', perceivedVA/realVA), '.', 'p');
filenamePNG=fullfile(ResultsDir,[basename,'_' task ,'_', num2str(nsubjects),'visualize_2p5deg_' pmSuffix25 '.png']);
[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveLME,filenamePNG);

elevation=40; % highest elevation we measured
perceivedVA40=(2^interceptL)*((1+elevation)^slopeL)*realVA;
pmSuffix40 = strrep(sprintf('PMx%.2f', perceivedVA40/realVA), '.', 'p');
filenamePNG=fullfile(ResultsDir,[basename,'_' task ,'_', num2str(nsubjects),'visualiz_40deg_' pmSuffix40 '.png']);
[realheight_mm,perceivedheight40_mm] = visualizePM(realVA,perceivedVA40,distance_mm,saveLME,filenamePNG);

fprintf(1,'%s task, moon visual angle:%.2f, perceived size at 2.5 degrees: %.2f, perceived size at 40 degrees: %.2f\n',task, realVA,perceivedVA, perceivedVA40)
%% visualize Moon illusion across elevations

figMoonIllusion=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .6 1],'Name',[basename 'MoonIllusion']);
hold;
markerDiameter = 22; % diameter in points for PM = 1
moonColor = [1 .8 0];
moonVA = (markerDiameter)^2; % scatter uses area, not diameter
Rmoon=.1;
Rperceived=Rmoon*1.2;

% so we will estimate the perceived visual angle at an elevation of 0.25 degrees (half the size of the moon) to
% estimate perceived visual angle at horizon
elevationVector=[2.5 12 20 30 40];
elevationRad=deg2rad(elevationVector);
for nE=1:length(elevationVector)
    PM(nE)=(2^interceptL)*((1+elevationVector(nE))^slopeL);
    perceivedVA(nE) = (PM(nE) * markerDiameter)^2; % scatter uses area, not diameter
  
    xMoon=-Rmoon*cos(elevationRad(nE));yMoon=Rmoon*sin(elevationRad(nE));
    xPerceived=-Rperceived*cos(elevationRad(nE));yPerceived=Rperceived*sin(elevationRad(nE)); 
    plot([0 xPerceived], [0 yPerceived], '-', 'LineWidth', 1,'Color',[.8 .8 .8])
    if elevationVector(nE)<50
        scatter(xMoon, yMoon, moonVA,[1 .8 0],'filled');
        scatter(xPerceived, yPerceived,perceivedVA(nE),[1 .8 0],'filled');
    else % change scatter colors for ranges that are extrapolated from experimental data
        scatter(xMoon, yMoon, moonVA,[1 .9 .5],'filled');
        scatter(xPerceived, yPerceived,perceivedVA(nE),[1 .9 .5],'filled');
    end
end

axis ('equal')
xlim([-Rperceived*1.1 0])
ylim([0 Rperceived*1.1])
set(gca,  'XColor', 'w','YColor', 'w')
fprintf(1,'Elevation\n');
disp(elevationVector);
fprintf(1,'Perceptual magnification\n');
disp(PM);
% save figure 
filenamePNG=fullfile(ResultsDir,['Fig1_MoonIllusion_' basename,'_' task ,'_', num2str(nsubjects),'.png']);
print(figMoonIllusion,filenamePNG,'-dpng','-r600');
filenameEPS=fullfile(ResultsDir,['Fig1_MoonIllusion_' basename,'_' task ,'_', num2str(nsubjects),'.eps']);
print(figMoonIllusion,filenameEPS,'-depsc','-r600');








