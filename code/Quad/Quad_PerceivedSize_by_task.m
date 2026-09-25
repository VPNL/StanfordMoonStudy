function  lme_by_angle=Quad_PerceivedSize_by_task(dataDir,datafile,task,ObserverFlag, ResultsDir, recomputeSort, saveLME)
%
% lme_by_angle=Quad_PercievedSize_by_task(dataDir,datafile,task, ResultsDir,recomputeSort, saveLME)
% This function visualizes and calculates the relationship between the reported visual angle 
% and the ground truth (real) visual angle
% for the Stanford Quad Experiments
%
% dataDir       Directory where the data resides
% datafile      csv file with subjects data
% ResultsDir    Directory where the data is output resides,task, recomputeSort, saveLME)
% KGS
% Nov 2025

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
   datafile='AllQuadDataLong916.csv'; % all data
end
basename = [erase( datafile,'.csv')] ; % for saving
datafileChar = char(string(datafile));
if ~isempty(regexp(datafileChar, '^(\/|[A-Za-z]:[\\/])', 'once'))
    sourceCsv = datafileChar;
else
    sourceCsv = fullfile(dataDir, datafileChar);
end

if ~exist('task')
       task='Perceptual'
       recomputeSort=1;
end

% Backward compatibility for older calls:
% Quad_PerceivedSize_by_task(dataDir, datafile, task, ResultsDir, recomputeSort, saveLME)
if nargin >= 4 && nargin <= 6 && (ischar(ObserverFlag) || isstring(ObserverFlag))
    if nargin >= 6
        saveLME = recomputeSort;
    end
    if nargin >= 5
        recomputeSort = ResultsDir;
    end
    ResultsDir = ObserverFlag;
    ObserverFlag = 1;
end

if ~exist('ObserverFlag')
    ObserverFlag=1;
end
if ~exist('ResultsDir')
    ResultsDir=fullfile(dataDir,'Results',basename);
end
if ~exist('recomputeSort')
    recomputeSort=0;
end

if ~exist('saveLME')
        saveLME=1;
end

%%

all_data=readtable(datafile);
%
% nameVars=all_data.Properties.VariableNames;
% nVars=length(all_data.Properties.VariableNames);
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

maxRatio=max(all_data.Ratio_Visual_Angle);
% transform distances from cm to m 
if ObserverFlag
    all_data.Distance=all_data.Observer_Distance;
    all_data.Elevation=all_data.Observer_Elevation;
else
    all_data.Distance=all_data.Ground_Distance;
    all_data.Elevation=all_data.Ground_Elevation;
end
all_data.Distance=all_data.Distance/100;



%% set colormap
%cmap=jet(nsubjects);
cmap=brighten(colormap(plasma(nsubjects*1.1)),0);
markerScale=50;

%%
% get the relevant data 
task_i=find(strcmp(all_data.Task,task));
task_data=all_data(task_i,:);
real_visual_angle=task_data.Real_Visual_Angle;
reported_visual_angle=task_data.Reported_Visual_Angle;
ratio_visual_angle=task_data.Ratio_Visual_Angle;
distance=task_data.Distance;

maxAngle=max(all_data.Reported_Visual_Angle);

% linear mixed model relating reported visual angle vs real visual
% angle with zero intersept with subjects as a random effect, with
% random slope effect per subject
lme_by_angle = fitlme(task_data,'Reported_Visual_Angle ~ -1 + Real_Visual_Angle + (-1 + Real_Visual_Angle|ID)')

% get individual subject slopes
[reSlopes, reNames,reStats] = randomEffects(lme_by_angle);
fixedSlope = fixedEffects(lme_by_angle);
isSlopeRow = strcmp(string(reNames.Name), 'Real_Visual_Angle');
individualSlopes = reSlopes(isSlopeRow) + fixedSlope(1);
ipm=find(individualSlopes>1);
nTaskSubjects = numel(unique(task_data.ID));
if nTaskSubjects > 0
    percentSlopeGreaterThanOne = 100*length(ipm)/nTaskSubjects;
else
    percentSlopeGreaterThanOne = NaN;
end

if saveLME % save stats table
     savelmefile=fullfile(ResultsDir, [basename '_lme_reported_vs_real_angle_' task '.txt']);
     fixedEffectsCsvFile = fullfile(ResultsDir, [basename '_lme_reported_vs_real_angle_' task '_fixed_effects.csv']);
     reportOpts = struct();
     reportOpts.ReportTitle = sprintf('Quad Perceived Size LME Report: %s task', char(string(task)));
     reportOpts.GeneratedBy = mfilename;
     reportOpts.SourceFile = sourceCsv;
     reportOpts.ModelLabel = 'Reported visual angle predicted by real visual angle';
     reportOpts.Task = task;
     reportOpts.SummaryLines = { ...
         sprintf('Experiment: Quad'), ...
         sprintf('Participants in task: %d', nTaskSubjects), ...
         sprintf('Rows in task model: %d', height(task_data)), ...
         sprintf('Participants with individual slope > 1: %d of %d (%.2f%%)', ...
             length(ipm), nTaskSubjects, percentSlopeGreaterThanOne)};
     reportOpts.FixedEffectsCsvFile = fixedEffectsCsvFile;
     write_lme_stats_report(lme_by_angle, savelmefile, reportOpts);
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
    savefile=fullfile(ResultsDir, [basename  '_sorted_idx']);
    save(savefile ,'sorted_idx');
else
    loadfile=fullfile(ResultsDir, [basename  '_sorted_idx']);
    load(loadfile ,'sorted_idx');
    clear subjectcolor;
    ID=all_data.ID(task_i);
    
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
    end
end

% plot results
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename '_' task],'Visible','On')

hold on 
xvectorS= [0:maxRealAngle];
% plot individual subjects line estimates
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
plot (0:maxAngle, 0:maxAngle,':','Color', [  .8 .8 .8], 'LineWidth',5); % line of equality - no perceptual magnification
plot (xvector, mean_slope*xvector,'k-','LineWidth',7); % fixed effect
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.4); % confidence interval on fixed effect
scatter(real_visual_angle,reported_visual_angle,markerScale,subjectcolor,'o','filled');
xlim([0 maxAngle]);
ylim([0 maxAngle]);
axis('square');
ytick=0:2:maxAngle;xtick=ytick;
set(gca,'XTick',xtick,'YTick',ytick); % make x and y ticks the same
xlabel ('Visual Angle [degrees]')
ylabel ('Perceived Angular Size [degrees]')
set(gca,'FontSize',32,'FontName','Avenir');
set(gca,'XTickLabelRotation',0)
titlestr=sprintf('%s \n slope=%-.2f, p=%-.2e n=%d',string(task),mean_slope,pval, nsubjects);
title(titlestr,'FontWeight', 'normal','FontSize',28,'FontName','Avenir')




%%


filenamePNG=fullfile(ResultsDir, [basename,'_', task ,'_ReportedvsRealVisualAngle', num2str(nsubjects),'.png'])
exportgraphics(figh,filenamePNG,'Resolution',600);
