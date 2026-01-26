function  lme_by_angle=Quad_PerceivedSize_by_task(dataDir,datafile,task, ResultsDir, recomputeSort, saveLME)
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

if ~exist('task')
       task='Perceptual'
       recomputeSort=1;
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
nameVars=all_data.Properties.VariableNames;
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
cmap=jet(nsubjects);
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
     savelmefile=fullfile(ResultsDir, [basename '_lme_reported_vs_real_angle_' task '.txt']);
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
    savefile=fullfile(ResultsDir, [basename  '_sorted_idx']);
    save(savefile ,'sorted_idx');
else
    loadfile=fullfile(ResultsDir, [basename  '_sorted_idx']);
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
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename '_' task])


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
xlabel ('Real Visual Angle (degree)')
ylabel ('Reported Visual Angle (degree)') 
titlestr=sprintf('%s \n slope=%-.2f, p=%-.2e \n n=%d',string(task),mean_slope,pval, nsubjects);
title(titlestr)
set(gca,'FontSize',30,'FontName','Avenir');




%%


filenamePNG=fullfile(ResultsDir, [basename,'_', task ,'_ReportedvsRealVisualAngle', num2str(nsubjects),'.png'])
exportgraphics(figh,filenamePNG,'Resolution',600);
