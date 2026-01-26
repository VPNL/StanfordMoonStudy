
close all; clear all;

% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Data/MoonExperiments/';
cd(dataDir)
% replace all NA in FullMoonDataLong.csv to empty cells

datafile='FullMoonDataLong.csv'; % all data
basename = [erase( datafile,'.csv')] ; % for saving
saveLME=0;

if ~exist('Results','dir')
    !mkdir Results
end
task='Perceptual';
%recomputeSort=1;
%task='Adjusted';
recomputeSort=0; % for adjusted task set recomputeSort=0




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
maxAltitude=max(all_data.Altitude);
maxDisparity=max(all_data.Disparity_VA);
meanMoonSize=mean(all_data.Real_Visual_Angle);


% get the relevant data by task
task_i=find(strcmp(all_data.Task,task));
all_data=all_data(task_i,:);
altitude=all_data.Altitude;


%% set colormap
cmap=jet(nsubjects);
markerScale=36;
%%
% linear mixed model relating reported visual angle vs real visual
% angle with zero intersept with subjects as a random effect, with
% random slope effect per subject

lme_by_altitude = fitlme(all_data,'Reported_Visual_Angle~Altitude   + (1|ID)'); % random intercepts

%random intercepts and random slopes model
lme_by_altitude_RS=fitlme(all_data, 'Reported_Visual_Angle~Altitude  + (Altitude|ID)');
model_comp=compare(lme_by_altitude,lme_by_altitude_RS);
if saveLME
   savelmefile=fullfile(''.','Results', [basename '_' task '_lme_reported_angle_by_altitude_RS.txt']);
   diary(savelmefile)
   lme_by_altitude
   lme_by_altitude_RS
   fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
   model_comp
   diary off
end

% use random slopes model as it explains more variance in the data for the perceptual case
[reEfx,reNames,reStats] = randomEffects(lme_by_altitude_RS);
[feEfx,feNames,festats] =fixedEffects(lme_by_altitude_RS);

ID=all_data.ID;
uniqueID=unique(ID);
nsubjects=length(uniqueID);
individualIntercepts = zeros(nsubjects,1);
individualSlopes = zeros(nsubjects,1);
for i = 1:nsubjects
    % Indices for this subject's random effects
    subjectRows = find(strcmp(reNames.Level, num2str(uniqueID(i)))); 
    individualIntercepts(i) = feEfx(1) + reEfx(subjectRows(1));
    individualSlopes(i)    = feEfx(2) + reEfx(subjectRows(2));
end

% set colormap
if recomputeSort
    % sort by intercepts
   [sorted_individualIntercepts, sorted_idx] = sort(individualIntercepts);
    clear subjectcolor;
    cmap=jet(nsubjects);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
    end
    savefile=fullfile('.', 'Results', [basename  '_sortedidx']);
    save(savefile ,'sorted_idx');
else
    loadfile=fullfile('.', 'Results', [basename '_sortedidx']);
    load(loadfile);
    clear subjectcolor;
    cmap=jet(nsubjects);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        sorted_cindex=find(sorted_idx==cindex);
        subjectcolor(c,:)=cmap(sorted_cindex,:);
    end
end
%
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .6],'Name',[basename 'Perceived vs Real Visual Angle'])
subplot(1,4,1); hold on 



% plot fixed effect

interceptA=feEfx(1);
slopeA=feEfx(2);
pvalA=festats.pValue(2);
lower_slopeA=festats.Lower(2);
upper_slopeA=festats.Upper(2);
xvectoru=linspace(0,maxAltitude);
xvectord = sort(xvectoru, 'descend');
% fixed effects estimate
y_fit =interceptA+slopeA*xvectoru;


% fixed effects confidence interval
yvectoru=slopeA*xvectoru+interceptA;
yvector1=lower_slopeA*xvectoru+interceptA;
yvector2=upper_slopeA*xvectord+interceptA;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot line fits only if sigificant 
if pvalA < 0.05
       % plot individual subjects slopes
    for s=1:nsubjects
        sortedID=sorted_idx(s);
        sindex=find(uniqueID==ID(sortedID));
        jj=find(all_data.ID==uniqueID(sindex));
        if length(jj>1)
            sdata=all_data(jj,:);
            lower=find(strcmp(sdata.Session,'Lower'));
            higher=find(strcmp(sdata.Session,'Higher'));
            xvectorS=[sdata.Altitude(lower) sdata.Altitude(higher)];
           % rand effex: each subject has different intercept
             yvectorS=  individualSlopes(sortedID)*xvectorS+individualIntercepts(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    plot(xvectoru, y_fit, 'k-','LineWidth',5);
end

% plot scatter plot of individual data
scatter(all_data.Altitude, all_data.Reported_Visual_Angle, markerScale,subjectcolor,'o','filled');
plot([0 maxAltitude], [meanMoonSize meanMoonSize],'Color',[.8 .8 .8],'LineWidth',3)
ylim([0 maxAngle])
xlabel ('Moon Altitude (degrees)')
ylabel ('Reported Visual Angle (degrees)') 
set(gca,'FontSize',18)
titlestr=sprintf('%s \n intercept=%3.2f \n slope=%5.2f p=%5.2e\n n=%d',task, interceptA,slopeA,festats.pValue(2), nsubjects);
title(titlestr)


%%
% Estimate relation between perceptual magnification ratio and altitude
% subject is a random effect, on intercept only
lme_ratio_by_altitude = fitlme(all_data,'Ratio_Visual_Angle~Altitude + (1|ID)')
% subject is a random effect, on intercept & slope
lme_ratio_by_altitude_RS = fitlme(all_data,'Ratio_Visual_Angle~Altitude + (Altitude|ID)')
% compare models
model_comp=compare(lme_ratio_by_altitude,lme_ratio_by_altitude_RS); % model with random slopes is more significant
if saveLME
   savelmefile=fullfile(''.','Results', [basename '_' task '_lme_reported_ratio_by_altitude_RS.txt']);
   diary(savelmefile)
   lme_ratio_by_altitude
   lme_ratio_by_altitude_RS
   fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
   model_comp
   diary off
end

%
[reEfx,reNames,reStats] = randomEffects(lme_ratio_by_altitude_RS);
[feEfx,feNames,festats] =fixedEffects(lme_ratio_by_altitude_RS);

interceptR=feEfx(1);
slopeR=feEfx(2);
pvalR=festats.pValue(2);
lower_slopeR=festats.Lower(2);
upper_slopeR=festats.Upper(2);
xvectoru=linspace(0,maxAltitude);
xvectord = sort(xvectoru, 'descend');
yvectoru=slopeR*xvectoru+interceptR;
yvector1=lower_slopeR*xvectoru+interceptR;
yvector2=upper_slopeR*xvectord+interceptR;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot ratio vs altitude
subplot(1,4,2); hold on 

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
        sortedID=sorted_idx(s);
        sindex=find(uniqueID==ID(sortedID));
        jj=find(all_data.ID==uniqueID(sindex));
        if length(jj>1)
            sdata=all_data(jj,:);
            lower=find(strcmp(sdata.Session,'Lower'));
            higher=find(strcmp(sdata.Session,'Higher'));
            xvectorS=[sdata.Altitude(lower) sdata.Altitude(higher)];
           % rand effex: each subject has differnet intercept
             yvectorS=  individualSlopes(sortedID)*xvectorS+individualIntercepts(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
end

scatter(all_data.Altitude,all_data.Ratio_Visual_Angle,markerScale,subjectcolor,'o','filled');
plot([0 maxAltitude], [1 1],'Color',[.8 .8 .8 ],'LineWidth',3)
xlabel ('Moon Altitude (degrees)')
ylabel ('Magnification') 
ylim([0 maxRatio])
set(gca,'FontSize',18)
titlestr=sprintf('%s \n intercept=%3.2f \n slope=%3.2f p=%5.2e \n n=%d',task,interceptR,slopeR,pvalR,nsubjects);
title(titlestr)


%% Estimate relationship between disparity and altitude
disparity_data=all_data;
allowed_dates = {'Nov 15th', 'Jan 12th', 'Jan 13th', 'May 13th'};  %  allowed dates
disparity_data = disparity_data(ismember(disparity_data.Date, allowed_dates), :);

IDD=disparity_data.ID;
uniqueIDD=unique(IDD);
nsubjectsD=length(uniqueIDD);

% set colormap
clear subjectcolor;
cmap=jet(nsubjects);
for c=1:length(IDD)
    cindex=find(uniqueIDD==IDD(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=cmap(sorted_cindex,:);
end

% add regression of disparity vs altitude
% there is only one measure of disparity per altitude; it's the same for
% both tasks
lme_disparity_by_altitude = fitlme(disparity_data,'Disparity_VA ~ Altitude  + (1|ID)')
lme_disparity_by_altitude_RS = fitlme(disparity_data,'Disparity_VA ~ Altitude  + (Altitude|ID)')
model_comp=compare(lme_disparity_by_altitude,lme_disparity_by_altitude_RS); % loglikelihood test comparing models

if saveLME % save stats table
     savelmefile=fullfile('.','Results', [basename '_' task '_lme_disparity_by_altitude.txt']);
     diary(savelmefile)
     lme_disparity_by_altitude
     lme_disparity_by_altitude_RS
     model_comp
     diary off
end

[reEfx,reNames,reStats] = randomEffects(lme_disparity_by_altitude_RS);
[feEfx,feNames,festats] =fixedEffects(lme_disparity_by_altitude_RS);

interceptDis=feEfx(1);
slopeDis=feEfx(2);
pvalDis=festats.pValue(2);
lower_slopeDis=festats.Lower(2);
upper_slopeDis=festats.Upper(2);
xvectoru=linspace(0,maxAltitude);
xvectord = sort(xvectoru, 'descend');
yvectoru=slopeDis*xvectoru+interceptDis;
yvector1=lower_slopeDis*xvectoru+interceptDis;
yvector2=upper_slopeDis*xvectord+interceptDis;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot  disparity vs altitude 
subplot(1,4,3); hold on 
% plot linefit if significant
if pvalDis<0.05
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
end
scatter(disparity_data.Altitude,disparity_data.Disparity_VA,markerScale,subjectcolor,'o','filled');
ylabel ('Disparity (degrees)')
xlabel ('Altitude (degrees)') 
titlestr=sprintf('intercept=%3.2f \n slope=%5.2f p=%5.2e\n n=%d',interceptDis,slopeDis,pvalDis, length(unique(IDD)));
title(titlestr)
set(gca,'FontSize',18)
%% plot ratio vs disparity
%
% ratio vs disparity
% need to exclude dates before we used the caliper
disparity_data=all_data;
allowed_dates = {'Nov 15th', 'Jan 12th', 'Jan 13th', 'May 13th'};  %  allowed dates
disparity_data = disparity_data(ismember(disparity_data.Date, allowed_dates), :);

lme_ratio_by_disparity = fitlme(disparity_data,'Ratio_Visual_Angle~Disparity_VA + (1|ID)');
lme_ratio_by_disparity_RS = fitlme(disparity_data,'Ratio_Visual_Angle~Disparity_VA + (Disparity_VA|ID)');

disp(lme_ratio_by_disparity)
disp(lme_ratio_by_disparity_RS)

model_comp=compare(lme_ratio_by_disparity,lme_ratio_by_disparity_RS); % loglikelihood test comparing models
disp(model_comp)

% Extract and interpret key test results
LR_stat = model_comp.LRStat(2);      % Likelihood ratio chi-square statistic
p_value = model_comp.pValue(2);      % p-value for the test
df = model_comp.DF(2);               % degrees of freedom for the test


if saveLME % save stats table
     savelmefile=fullfile('.','Results', [basename '_' task '_lme_ratio_by_disparity.txt']);
     diary(savelmefile)
     lme_ratio_by_disparity
     lme_ratio_by_disparity_RS
     model_comp
     diary off
end

interceptD=lme_ratio_by_disparity.Coefficients.Estimate(1);
slopeD=lme_ratio_by_disparity.Coefficients.Estimate(2);
pvalD=lme_ratio_by_disparity.Coefficients.pValue(2);
lower_slopeD=lme_ratio_by_disparity.Coefficients.Lower(2);
upper_slopeD=lme_ratio_by_disparity.Coefficients.Upper(2);
xvectoru= [0:maxDisparity];
xvectord= [maxDisparity:-1:0];
yvectoru=slopeD*xvectoru+interceptD;
yvector1=lower_slopeD*xvectoru+interceptD;
yvector2=upper_slopeD*xvectord+interceptD;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

subplot(1,4,4); hold on 
% plot line fit only if significant
if pvalD<0.05
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
end
scatter(disparity_data.Disparity_VA,disparity_data.Ratio_Visual_Angle,markerScale,subjectcolor,'o','filled');
plot([0 maxDisparity], [1 1],'Color',[.8 .8 .8 ],'LineWidth',3)
xlabel ('Disparity (degrees)')
ylabel ('Magnification') 
ylim([0 maxRatio])
set(gca,'FontSize',18)
titlestr=sprintf('%s \n intercept=%3.2f \n  slope=%3.2f p=%5.2e \n n=%d',task,interceptD,slopeD,pvalD ,length(unique(ID)));
title(titlestr)


filenamePNG=fullfile('.','Results',[basename,'_' task ,'_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);

savefile=fullfile('.', 'Results', [basename '_' task '_analysed']);
save(savefile)


