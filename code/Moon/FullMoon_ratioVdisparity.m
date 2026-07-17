function [feEfxR,feNamesR,festatsR,reEfxR,reNamesR,reStatsR] = FullMoon_ratioVdisparity(dataDir, datafile,task, ResultsDir, saveLME, subplotNum, sorteduniqueIDD)
% 
% 
% Gets moon data table & find the subjects that have disparity data for the
% task
% calculates linear models relating perceptual magnification to disparity
% compares models to test if random subject and random intercept is a
% better model than random intercept model
% returns fixed and random effects model parameters
%
% KGS 8/2025


% data loading and setting up some basic information
if ~exist('dataDir')
    dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiment/';
end
cd(dataDir)

if ~exist('datafile')
   datafile='FullMoonDataLong821.csv'; % all data

end
basename = [erase( datafile,'.csv')] ; % for saving

if ~exist('ResultsDir')
  ResultsDir='PaperFig4_821'; % all data
end

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end

if ~exist('saveLME')
        saveLME=1;
end

if ~exist('task')
       task='Perceptual'
end


%% read data 
cd(dataDir)
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


% find max angle and maxRatio for graphs
maxAngle=max(all_data.Reported_Visual_Angle);
maxRatio=max(all_data.Ratio_Visual_Angle);
maxDistance=max(all_data.Distance);
maxElevation=max(all_data.Elevation);
maxDisparity=max(all_data.Disparity_VA);
minDisparity=min(all_data.Disparity_VA);
meanMoonSize=mean(all_data.Real_Visual_Angle);


% get the relevant data by task
task_i=find(strcmp(all_data.Task,task));
disparity_data=all_data(task_i,:);
Elevation=disparity_data.Elevation;

% adjust disparity measure by size of moon as we took measurements that include themoon
disparity_data.Disparity_VA=disparity_data.Disparity_VA-disparity_data.Real_Visual_Angle;

% find participants IDs
IDD=disparity_data.ID; 
uniqueIDD=unique(IDD);
nsubjectsD=length(uniqueIDD);

% set colormap & markerscale
markerScale=36;
cmap=jet(nsubjectsD);
clear subjectcolor;

%%
lme_ratio_by_disparity = fitlme(disparity_data,'Ratio_Visual_Angle~Disparity_VA + (1|ID)');
lme_ratio_by_disparity_RS = fitlme(disparity_data,'Ratio_Visual_Angle~Disparity_VA + (Disparity_VA|ID)');
model_comp=compare(lme_ratio_by_disparity,lme_ratio_by_disparity_RS); % loglikelihood test comparing models

% test log model
disparity_data.logRatio_Visual_Angle=log2(disparity_data.Ratio_Visual_Angle);
disparity_data.logDisparity=log2(disparity_data.Disparity_VA);
lme_logratio_by_logdisparity = fitlme(disparity_data,'logRatio_Visual_Angle~logDisparity + (1|ID)');
lme_logratio_by_logdisparity_RS = fitlme(disparity_data,'logRatio_Visual_Angle~logDisparity + (logDisparity|ID)');
log_model_comp=compare(lme_logratio_by_logdisparity,lme_logratio_by_logdisparity_RS); % loglikelihood test comparing models


% Extract and interpret key test results
LR_stat = model_comp.LRStat(2);      % Likelihood ratio chi-square statistic
p_value = model_comp.pValue(2);      % p-value for the test
df = model_comp.DF(2);               % degrees of freedom for the test

disp('PM as disparity model random intercepts and slopes vs random intercepts comparison')
if model_comp.pValue <0.05
    fprintf('%s: Random slopes and Random intercepts model is better, pval=%f df=%d\n',task ,p_value,df);
else
    fprintf('%s: Random intercepts model is better, pval=%.2f df=%d\n',task, p_value, df);
end

% test if Elevation and disparity are independent or not by adding a model
% that includes both factors and testing if the second model with both
% factors explains more variance than the first
lme_ratio_by_disparity_Elevation_RS = fitlme(disparity_data,'Ratio_Visual_Angle~Disparity_VA + Elevation+ (Elevation|ID)');
lme_ratio_by_Elevation_RS = fitlme(disparity_data,'Ratio_Visual_Angle~ Elevation+ (Elevation|ID)');
model_compAvD=compare(lme_ratio_by_disparity_RS,lme_ratio_by_disparity_Elevation_RS); % loglikelihood test comparing models
disp(model_compAvD)

disp('PM by disparity and Elevation model vs PM by disparity comparison')
if model_comp.pValue <0.05
    fprintf('%s: disparity and Elevation independently contribute to PM, pval=%f df=%d\n',task, model_compAvD.pValue(2),model_compAvD.DF(2));
else
    fprintf('%s: disparity and Elevation are not independen factors of  PM, pval=%.2f df=%d\n',task, model_compAvD.pValue(2),model_compAvD.DF(2));
end


if saveLME % save stats 
     savelmefile=fullfile('.',ResultsDir, [basename '_' task '_lme_moon_PM_vs_disparity.txt']);
     diary(savelmefile)
     lme_ratio_by_disparity
     lme_ratio_by_disparity_RS
     model_comp
     lme_ratio_by_disparity_Elevation_RS
     model_compAvD
     lme_logratio_by_logdisparity 
     lme_logratio_by_logdisparity_RS
     log_model_comp
     diary off
end


%% plot results
% fixed effects: slope and intercepts + CI
[feEfxR,feNamesR,festatsR] = fixedEffects(lme_ratio_by_disparity_RS);
interceptR=feEfxR(1);
slopeR=feEfxR(2);
lower_slopeR=festatsR.Lower(2);
upper_slopeR=festatsR.Upper(2);
lower_InterceptR=festatsR.Lower(1);
upper_InterceptR=festatsR.Upper(1);

xvectoru= [0:maxDisparity];
xvectord= [maxDisparity:-1:0];
yvectoru=slopeR*xvectoru+interceptR;
yvector1=lower_slopeR*xvectoru+lower_InterceptR;
yvector2=upper_slopeR*xvectord+upper_InterceptR;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% random effects on slopes and intercepts

[reEfxR,reNamesR,reStatsR] = randomEffects(lme_ratio_by_disparity_RS);
intercept_indicesR = contains(reNamesR.Name, '(Intercept)');
slope_indicesR = contains(reNamesR.Name, 'Elevation');
random_interceptsR = reEfxR(intercept_indicesR);
random_slopesR=reEfxR(slope_indicesR);
subjInterceptsR = random_interceptsR + feEfxR(1);  % subject intercept = fixed + random
subjSlopesR = random_slopesR + feEfxR(2); 


subplot(1,3,subplotNum)
hold on
% 
% === Use colormap of disparity vs elevation for the PM plot ===
IDD2 = disparity_data.ID;   % IDs in the ratio-vs-disparity dataset
subjectcolor2 = zeros(length(IDD2),3);
for c = 1:length(IDD2)
    idx = IDD2(c);
    ii = find(idx == sorteduniqueIDD);  % find position in sorted intercept order
    subjectcolor2(c,:) = cmap(ii,:);    % assign matching color
end

% plot individual subject lines
plotindividual=0;
if plotindividual
    for s=1:nsubjectsD
         sortedID=sortedIdx(s);
         sindex=find(uniqueIDD==IDD(sortedID));
        jj=find(disparity_data.ID==uniqueIDD(sindex));
        if length(jj>1)
            sdata=disparity_data(jj,:);
            lower=find(strcmp(sdata.Session,'Lower'));
            higher=find(strcmp(sdata.Session,'Higher'));
            xvectorS=[sdata.Disparity_VA(lower) sdata.Disparity_VA(higher)]
           %  xvectorS=[sdata.Disparity_VA(lower) maxDisparity]
           % rand effex: each subject has different intercept
             yvectorS= subjSlopesR(sortedID)*xvectorS+subjInterceptsR(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
end
% plot line fit only if significant
festatsR.pValue(2)
if festatsR.pValue(2)<0.05
    if ~plotindividual
        fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.05);
    end
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
end
scatter(disparity_data.Disparity_VA, disparity_data.Ratio_Visual_Angle, markerScale, subjectcolor2, 'o', 'filled');


yline(1,'Color',[.8 .8 .8 ],'LineWidth',3)
xlabel ('Disparity (degrees)')
ylabel ('Perceptual Magnification') 
ylim([0 maxRatio])
xlim ([0 15])
set(gca,'FontSize',20,'FontName','Avenir')
if festatsR.pValue(2)<0.001
    titlestr=sprintf('%s \n intercept=%3.2f \n  slope=%3.2f p=%5.2e \n n=%d',task,interceptR,slopeR,festatsR.pValue(2) ,length(unique(IDD)));
else
    titlestr=sprintf('%s \n intercept=%3.2f \n  slope=%3.2f p=%.3f \n n=%d',task,interceptR,slopeR,festatsR.pValue(2) ,length(unique(IDD)));
end

title(titlestr,'FontSize',16,'FontName','Avenir')

end