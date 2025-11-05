
%% Moon Disparity Analysis
close all; clear all;

% data loading and setting up some basic information
%dataDir='/Users/kalanit/Projects/PerceptualMagnification/ExperimentalData/MoonExperiments/'
%old computer
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/'
cd(dataDir)
% replace all NA in FullMoonDataLong.csv to empty cells

%datafile='Disparity_BothElevations_FullMoonDataLong821.csv'; % all data
%datafile='Excluding_AdjustedOutliers_Disparity_BothElevations_Disparity_BothElevations_FullMoonDataLong821.csv'
datafile='Disparity_BothElevations_FullMoonDataLong090225';
basename = [erase( datafile,'.csv')] ; % for saving

ResultsDir='PaperFig4_090225';
if ~exist('ResultsDir','dir')
    mkdir(ResultsDir)
end

saveLME=1; % save stats

%% read data 
all_data=readtable(datafile);
nameVars=all_data.Properties.VariableNames;
nVars=length(all_data.Properties.VariableNames);
allTasks =unique(all_data.Task);
nTasks=length(allTasks);
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);

% find max angle and maxRatio for graphs
maxAngle=max(all_data.Reported_Visual_Angle);
maxRatio=max(all_data.Ratio_Visual_Angle);
maxDistance=max(all_data.Distance);
maxElevation=max(all_data.Elevation);
maxDisparity=max(all_data.Disparity_VA);
minDisparity=min(all_data.Disparity_VA);
meanMoonSize=mean(all_data.Real_Visual_Angle);

task='Perceptual';
disparity_data=all_data;
task_i=find(strcmp(disparity_data.Task,task));
% get the relevant data by task
disparity_data=all_data(task_i,:);
Elevation=all_data.Elevation;

% adjust disparity measure by size of moon as we took measurements that
% included the moon
disparity_data.Disparity_VA=disparity_data.Disparity_VA-disparity_data.Real_Visual_Angle;

uniqueDate=unique(disparity_data.Date);
disp('dates'); disp(uniqueDate)
IDD=disparity_data.ID;
uniqueIDD=unique(IDD);
nsubjectsD=length(uniqueIDD);
fprintf('%d subjects for full moon disparity data\n ',nsubjectsD);


%%
% Estimate relationship between disparity and Elevation
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .6],'Name',[basename 'Perceived vs Real Visual Angle'])

% regression of disparity vs Elevation there is only one measure of disparity per Elevation; 
% it's the same for both tasks
lme_disparity_by_Elevation = fitlme(disparity_data,'Disparity_VA ~ Elevation  + (1|ID)')
lme_disparity_by_Elevation_RS = fitlme(disparity_data,'Disparity_VA ~ Elevation  + (Elevation|ID)')
model_comp=compare(lme_disparity_by_Elevation,lme_disparity_by_Elevation_RS); % loglikelihood test comparing models

disp('disparity by Elevation model comparison')
if model_comp.pValue <0.05
    fprintf('Random slopes and Random intercepts model is better, %f\n',model_comp.pValue(2))
else
    fprintf('Random intercepts model is better, pval=%.2f\n',model_comp.pValue(2))
end

if saveLME % save stats table
     savelmefile=fullfile('.',ResultsDir, [basename  '_lme_disparity_by_Elevation.txt']);
     diary(savelmefile)
     lme_disparity_by_Elevation
     lme_disparity_by_Elevation_RS
     model_comp
     diary off
end

% no matter what the model comparison shows
% i am still going to plot individual slopes just to see the effect
% in each participant

[reEfx,reNames,reStats] = randomEffects(lme_disparity_by_Elevation_RS);
[feEfx,feNames,festats] = fixedEffects(lme_disparity_by_Elevation_RS);


% reEfx has both random effects for intercepts and slopes; odd numbers have
% intercepts and even numbers have slopes
% 
% e.g., reNames =
%     Group        Level            Name      
%     ______    ___________    _______________
% 
%     {'ID'}    {'6'      }    {'(Intercept)'}
%     {'ID'}    {'6'      }    {'Elevation'   }
%     {'ID'}    {'1028'   }    {'(Intercept)'}
%     {'ID'}    {'1028'   }    {'Elevation'   }

intercept_indices = contains(reNames.Name, '(Intercept)');
slope_indices = contains(reNames.Name, 'Elevation');
random_intercepts = reEfx(intercept_indices);
random_slopes=reEfx(slope_indices);
[sorted_random_intercepts, sortedIdx]=sort(random_intercepts); % sort participants by intercepts
sorted_random_slopes=random_slopes(sortedIdx);
subjIntercepts = random_intercepts + feEfx(1);  % subject intercept = fixed + random
subjSlopes = random_slopes + feEfx(2); 
%Find the indices corresponding to the random intercepts


% set colormap & markerscale
markerScale=36;
cmap=jet(nsubjectsD);
clear subjectcolor;

sorteduniqueIDD=uniqueIDD(sortedIdx);
for c=1:length(IDD) 
    idx=IDD(c);
    ii=find(idx==sorteduniqueIDD);
    sorted_idx(c)=ii;
    subjectcolor(c,:)=cmap(ii,:);
end
savefile=fullfile('.', ResultsDir, [basename  '_sortedidx']);
save(savefile ,'sorted_idx');

% fixed effects lines
interceptDis=feEfx(1);
slopeDis=feEfx(2);
pvalDis=festats.pValue(2);
lower_slopeDis=festats.Lower(2);
upper_slopeDis=festats.Upper(2);
lower_interceptDis=festats.Lower(1);
upper_interceptDis=festats.Upper(1);

xvectoru=linspace(0,maxElevation);
xvectord = sort(xvectoru, 'descend');
yvectoru=slopeDis*xvectoru+interceptDis;
yvector1=lower_slopeDis*xvectoru+lower_interceptDis;
yvector2=upper_slopeDis*xvectord+upper_interceptDis;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];


% plot  disparity vs Elevation 
subplot(1,3,1); hold on 
plotinvidual=1
if plotinvidual
% % plot individual subject lines
    for s=1:nsubjectsD
        sortedID=sortedIdx(s);
        sindex=find(uniqueIDD==IDD(sortedID));
        jj=find(disparity_data.ID==uniqueIDD(sindex));
        if length(jj>1)
            sdata=disparity_data(jj,:);
            lower=find(strcmp(sdata.Session,'Lower'));
            higher=find(strcmp(sdata.Session,'Higher'));
            xvectorS=[0 sdata.Elevation(higher)];
            % rand effex: each subject has different intercept
            yvectorS=  subjSlopes(sortedID)*xvectorS+subjIntercepts(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
end
if pvalDis<0.05
     if ~plotinvidual
         fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
     end
     plot (xvectoru, yvectoru,'k-','LineWidth',3);
end
scatter(disparity_data.Elevation, disparity_data.Disparity_VA, markerScale, subjectcolor, 'o','filled');

xlim([0 max(disparity_data.Elevation)]);
ylim ([0 max(disparity_data.Disparity_VA )]);

ylabel ('Disparity (degrees)')
xlabel ('Elevation (degrees)') 
set(gca,'FontSize',24,'FontName','Avenir')

if pvalDis<0.05 % nice writing of p-values
    titlestr=sprintf('%s \n intercept=%3.2f \n slope=%5.2f p=%5.2e\n n=%d',task, interceptDis,slopeDis,pvalDis, length(unique(IDD)));
else
    titlestr=sprintf('%s \n intercept=%3.2f \n slope=%5.2f p=%.3f\n n=%d',task, interceptDis,slopeDis,pvalDis, length(unique(IDD)));
end
title(titlestr,'FontSize',16,'FontName','Avenir')


%%
task='Perceptual';
 subplotNum=2
[feEfxRP,feNamesRP,festatsRP,reEfxRP,reNamesRP,reStatsRP] = FullMoon_ratioVdisparity(dataDir, datafile,task, ResultsDir, saveLME, subplotNum, sorteduniqueIDD);
%%
task='Adjusted';
 subplotNum=3
[feEfxRA,feNamesRA,festatsR,reEfxRA,reNamesRA,reStatsRA] = FullMoon_ratioVdisparity(dataDir, datafile,task, ResultsDir, saveLME, subplotNum, sorteduniqueIDD);

%%
filenamePNG=fullfile(dataDir,ResultsDir,[basename,'_', num2str(nsubjectsD),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);

savefile=fullfile(dataDir, ResultsDir, [basename '_' task '_analysed']);
save(savefile)


%% test if effect of disparity varies by task

lme_PM_by_disparity_and_task = fitlme(all_data,'Ratio_Visual_Angle~Disparity_VA*Task  + (1|ID)')

if saveLME % save stats 
     savelmefile=fullfile('.',ResultsDir, [basename  '_lme_moon_PM_vs_disparity_and_task.txt']);
     diary(savelmefile)
     lme_PM_by_disparity_and_task
     
     diary off
end

