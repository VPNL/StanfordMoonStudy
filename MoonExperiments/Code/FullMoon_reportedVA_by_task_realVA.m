
function [lme_reportedVA_by_VA_Elevation]=FullMoon_reportedVA_by_task_realVA(dataDir,datafile,ResultsDir,task, recomputeSort,saveLME)
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
disp(nameVars)
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

jj=~isnan(all_data.Elevation);
NotNaN=find(jj);
length(NotNaN);
all_data=all_data(NotNaN,:);

% find max angle and maxRatio for graphs
maxAngle=max(all_data.Reported_Visual_Angle);
maxRatio=max(all_data.Ratio_Visual_Angle);
maxDistance=max(all_data.Distance);
maxElevation=max(all_data.Elevation);
maxDisparity=max(all_data.Disparity_VA);
meanMoonSize=mean(all_data.Real_Visual_Angle);


% get the relevant data by task
task_i=find(strcmp(all_data.Task,task));
all_data=all_data(task_i,:);
Elevation=all_data.Elevation;

uniqueElevations=unique(all_data.Elevation);
nElevations=length(uniqueElevations);
% all_data.logRatio=log2(all_data.Ratio_Visual_Angle);
 all_data.logElevation=log2(all_data.Elevation+1); 
 all_data.logReal_Visual_Angle=log2(all_data.Real_Visual_Angle); 
 all_data.logReported_Visual_Angle=log2(all_data.Reported_Visual_Angle); 
 % add regularization term to elevation as log(0) is not defined and elevation can be zero
%% plotting defaults
% We will color the scatter points by *continuous elevation* (shown via a
% colorbar). The colormap below is only used for the colorbar.
markerScale=36;
cmap=cool(256);
%%
% linear mixed model relating reported visual angle vs real visual
% angle with zero intersept with subjects as a random effect,

%random intercepts model
lme_reportedVA_by_VA_Elevation = fitlme(all_data,'Reported_Visual_Angle ~ Real_Visual_Angle+ Elevation + (1|ID)'); % as log function doesn't deal with 0 and elevation can be 0 add 1 as a regularization factor

% %random intercepts and random slopes model
lme_reportedVA_by_VA_Elevation_log = fitlme(all_data,'logReported_Visual_Angle ~ logReal_Visual_Angle+logElevation + (1|ID)'); % as log function doesn't deal with 0 and elevation can be 0 add 1 as a regularization factor

% 
model_comp=compare(lme_reportedVA_by_VA_Elevation,lme_reportedVA_by_VA_Elevation_log);
if saveLME
   savelmefile=fullfile(''.',ResultsDir, [basename '_' task '_lme_moon_reportedVA_by_realVA_Elevation.txt']);
   diary(savelmefile)
   fprintf(1,'task %s median matched size %5.2f; mean matched size %5.2f stdev %5.2f \n',task,median(all_data.Reported_Visual_Angle),mean(all_data.Reported_Visual_Angle),std(all_data.Ratio_Visual_Angle))
   lme_reportedVA_by_VA_Elevation 
   lme_reportedVA_by_VA_Elevation_log
   % fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
   model_comp
   % diary off
end

% use random slopes model to plot invidual subject slopes; in the log vs log fit the random
% slopes model does not signigicantly explain more variance in the data for
% either perceptual or adjusted cases
% AIC comparison also suggests that the log-log model is a better fit than
% linear model
[reEfx_log,reNames_log,reStats_log] = randomEffects(lme_reportedVA_by_VA_Elevation);
[feEfx_log,feNames_log,festats_log] =fixedEffects(lme_reportedVA_by_VA_Elevation);

ID=all_data.ID;
uniqueID=unique(ID);
nsubjects=length(uniqueID);
% individualIntercepts = zeros(nsubjects,1);
% individualSlopes = zeros(nsubjects,1);
% for i = 1:nsubjects
%     % Indices for this subject's random effects
%     subjectRows = find(strcmp(reNames_log.Level, num2str(uniqueID(i)))); 
%     individualIntercepts(i) = feEfx_log(1) + reEfx_log(subjectRows(1));
%     individualSlopes(i)    = feEfx_log(2) + reEfx_log(subjectRows(2));
% end

% NOTE: Previously, the code attempted to build an RGB matrix (elevationcolor)
% via a sorting routine. For a cleaner visualization, we instead pass the
% numeric Elevation values directly to scatter() so color encodes elevation.
%
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename 'Moon Reported Visual Angle vs Real Visual Angle'])
%subplot(1,3,1); 
hold on 
% plot fixed effect

interceptL=feEfx_log(1);
slopeL=feEfx_log(2);                 % coefficient for Real_Visual_Angle
elevCoeffL=feEfx_log(3);             % coefficient for Elevation
pvalL=festats_log.pValue(2);
lower_slopeL=festats_log.Lower(2);
upper_slopeL=festats_log.Upper(2);

% For plotting the fixed-effect line, we evaluate the model at the mean
% elevation (so the line is interpretable in the same axes).
meanElev = mean(all_data.Elevation);

xvectoru=linspace(min(all_data.Real_Visual_Angle),max(all_data.Real_Visual_Angle),200);
xvectord = sort(xvectoru, 'descend');

% fixed effects estimate (at mean elevation)
y_fit = interceptL + slopeL*xvectoru + elevCoeffL*meanElev;


% fixed effects confidence interval
yvectoru = slopeL*xvectoru + interceptL + elevCoeffL*meanElev;
yvector1 = lower_slopeL*xvectoru + interceptL + elevCoeffL*meanElev;
yvector2 = upper_slopeL*xvectord + interceptL + elevCoeffL*meanElev;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot line fits only if significant 
if pvalL < 0.05
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    plot(xvectoru, y_fit, 'k-','LineWidth',5);
    
    titlestr=sprintf('%s Matching\n intercept=%3.2f VA slope=%5.3f elevation slope=%5.3f \n VA p=%5.2e E p=%5.2e \n n=%d',task, interceptL,slopeL,elevCoeffL, festats_log.pValue(2), festats_log.pValue(3), nsubjects);
 
else
    titlestr=sprintf('%s Matching\n intercept=%3.2f VA slope=%5.3f elevation slope=%5.3f \n VA p=%5.2f E p=%5.2f \n n=%d',task, interceptL,slopeL,elevCoeffL, festats_log.pValue(2), festats_log.pValue(3), nsubjects);

%    titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.2f\n n=%d',task, interceptL,slopeL,festats_log.pValue(2), nsubjects);
end

% plot scatter plot of individual data (colored by elevation)
scatter(all_data.Real_Visual_Angle, all_data.Reported_Visual_Angle, markerScale, all_data.Elevation,'o','filled');
colormap(cmap);
cb=colorbar;
cb.Label.String='Elevation (deg)';
cb.Label.FontName='Avenir';
cb.Label.FontSize=18;
caxis([min(all_data.Elevation) max(all_data.Elevation)]);
plot([min(all_data.Reported_Visual_Angle) max(all_data.Reported_Visual_Angle)],[min(all_data.Reported_Visual_Angle) max(all_data.Reported_Visual_Angle)] ,'Color',[.8 .8 .8],'LineWidth',3)
xlim([0 max(all_data.Reported_Visual_Angle)])
ylim([0 max(all_data.Reported_Visual_Angle)])
axis('square')
xlabel ('Real Visual Angle (degree)')
ylabel ('Reported Visual Angle (degree)')
set(gca,'FontSize',20, 'FontName','Avenir')
title(titlestr,'FontSize',12)
% put tick labels numbers rather than log numbers
% xticks=get(gca,'Xtick');set(gca,'XTickLabel', round(2.^xticks,1));
% yticks=get(gca,'Ytick');set(gca,'YTickLabel', round(2.^yticks,1));

filenamePNG=fullfile('.', ResultsDir,[basename,'_' task ,'_reportedvsrealVA_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);


%%





%%

savefile=fullfile('.', ResultsDir, [basename '_' task '_reportedvsrealVA']);
save(savefile)






