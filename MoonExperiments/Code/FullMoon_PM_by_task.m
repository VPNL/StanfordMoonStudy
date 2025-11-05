
function FullMoon_PM_by_task(dataDir,datafile,ResultsDir,task, recomputeSort,saveLME)
%
% FullMoon_PM_by_task(dataDir,datafile,ResultsDir,task, recomputeSort,saveLME)
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


%% set colormap
cmap=jet(nsubjects);
markerScale=36;
%%
% linear mixed model relating reported visual angle vs real visual
% angle with zero intersept with subjects as a random effect,

%random intercepts model
lme_by_Elevation = fitlme(all_data,'Reported_Visual_Angle~Elevation   + (1|ID)'); % random intercepts

%random intercepts and random slopes model
lme_by_Elevation_RS=fitlme(all_data, 'Reported_Visual_Angle~Elevation  + (Elevation|ID)');
model_comp=compare(lme_by_Elevation,lme_by_Elevation_RS);
if saveLME
   savelmefile=fullfile(''.',ResultsDir, [basename '_' task '_lme_moon_visualangle_by_Elevation.txt']);
   diary(savelmefile)
   fprintf(1,'task %s median matched size %5.2f; mean matched size %5.2f stdev %5.2f \n',task,median(all_data.Reported_Visual_Angle),mean(all_data.Reported_Visual_Angle),std(all_data.Ratio_Visual_Angle))
   lme_by_Elevation
   lme_by_Elevation_RS
   fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
   model_comp
   diary off
end

% use random slopes model as it explains more variance in the data for the perceptual case
[reEfx,reNames,reStats] = randomEffects(lme_by_Elevation_RS);
[feEfx,feNames,festats] =fixedEffects(lme_by_Elevation_RS);

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
    savefile=fullfile('.', ResultsDir, [basename  '_sortedidx']);
    save(savefile ,'sorted_idx');
else
    loadfile=fullfile('.', ResultsDir, [basename '_sortedidx']);
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
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename 'Perceived vs Real Visual Angle'])
subplot(1,2,1); hold on 



% plot fixed effect

interceptA=feEfx(1);
slopeA=feEfx(2);
pvalA=festats.pValue(2);
lower_slopeA=festats.Lower(2);
upper_slopeA=festats.Upper(2);
xvectoru=linspace(0,maxElevation);
xvectord = sort(xvectoru, 'descend');
% fixed effects estimate
y_fit =interceptA+slopeA*xvectoru;


% fixed effects confidence interval
yvectoru=slopeA*xvectoru+interceptA;
yvector1=lower_slopeA*xvectoru+interceptA;
yvector2=upper_slopeA*xvectord+interceptA;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot line fits only if significant 
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
            xvectorS=[sdata.Elevation(lower) sdata.Elevation(higher)];
           % rand effex: each subject has different intercept
             yvectorS=  individualSlopes(sortedID)*xvectorS+individualIntercepts(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    plot(xvectoru, y_fit, 'k-','LineWidth',5);
    if pvalA < 0.001
        titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%5.2e\n n=%d',task, interceptA,slopeA,festats.pValue(2), nsubjects);
    else
        titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.2f\n n=%d',task, interceptA,slopeA,festats.pValue(2), nsubjects);
    end 
else
    titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.2f\n n=%d',task, interceptA,slopeA,festats.pValue(2), nsubjects);
end

% plot scatter plot of individual data
scatter(all_data.Elevation, all_data.Reported_Visual_Angle, markerScale,subjectcolor,'o','filled');
plot([0 maxElevation], [meanMoonSize meanMoonSize],'Color',[.8 .8 .8],'LineWidth',3)
ylim([0 maxAngle])
xlabel ('Moon Elevation (degrees)')
ylabel ('Reported Visual Angle (degrees)') 
set(gca,'FontSize',24, 'FontName','Avenir')
title(titlestr)

%%
% Estimate relation between perceptual magnification (ratio) and 
% Elevation (elevation in old papers)
%
% subject is a random effect, on intercept only
lme_ratio_by_Elevation = fitlme(all_data,'Ratio_Visual_Angle~Elevation + (1|ID)')
% subject is a random effect, on intercept & slope
lme_ratio_by_Elevation_RS = fitlme(all_data,'Ratio_Visual_Angle~Elevation + (Elevation|ID)')
% compare models
model_comp=compare(lme_ratio_by_Elevation,lme_ratio_by_Elevation_RS); % model with random slopes is more significant


%
[reEfx,reNames,reStats] = randomEffects(lme_ratio_by_Elevation_RS);
[feEfx,feNames,festats] =fixedEffects(lme_ratio_by_Elevation_RS);

interceptR=feEfx(1);
slopeR=feEfx(2);
pvalR=festats.pValue(2);
lower_slopeR=festats.Lower(2);
upper_slopeR=festats.Upper(2);
xvectoru=linspace(0,maxElevation);
xvectord = sort(xvectoru, 'descend');
yvectoru=slopeR*xvectoru+interceptR;
yvector1=lower_slopeR*xvectoru+interceptR;
yvector2=upper_slopeR*xvectord+interceptR;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

% plot ratio vs Elevation
subplot(1,2,2); hold on 

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
            xvectorS=[sdata.Elevation(lower) sdata.Elevation(higher)];
           % rand effex: each subject has differnet intercept
             yvectorS=  individualSlopes(sortedID)*xvectorS+individualIntercepts(sortedID);
            plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
        end
    end
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%3.3f \n p=%5.2e \n n=%d',task,interceptR,slopeR,pvalR,nsubjects);

else
   titlestr=sprintf('%s Matching\n intercept=%3.2f slope=%3.3f \n p=%.2f \n n=%d',task,interceptR,slopeR,pvalR,nsubjects);
end


scatter(all_data.Elevation,all_data.Ratio_Visual_Angle,markerScale,subjectcolor,'o','filled');
plot([0 maxElevation], [1 1],'Color',[.8 .8 .8 ],'LineWidth',3)
xlabel ('Moon Elevation (degrees)')
ylabel ('Perceptual Magnification') 
ylim([0 maxRatio])
set(gca,'YTick', [0:1:maxRatio],'YtickLabel', [0:1:maxRatio], 'FontSize',24,'FontName','Avenir')
title(titlestr)

filenamePNG=fullfile('.', ResultsDir,[basename,'_' task ,'_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);
ncount=length(find(individualSlopes<0));
if saveLME
   savelmefile=fullfile(''.',ResultsDir, [basename '_' task '_lme_moon_ratio_by_Elevation.txt']);
   diary(savelmefile)
   fprintf(1,'task %s median PM %5.2f mean PM %5.2f stdev %5.2f \n',task,median(all_data.Ratio_Visual_Angle), mean(all_data.Ratio_Visual_Angle),std(all_data.Ratio_Visual_Angle));
   fprintf(1,'percentage participants with negative slopes %5.2f  \n',100*ncount/nsubjects);
   lme_ratio_by_Elevation
   lme_ratio_by_Elevation_RS
   fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
   model_comp
    diary off
end

savefile=fullfile('.', ResultsDir, [basename '_' task '_analysed']);
save(savefile)


%% visualize illusion
realVA=mean(all_data.Real_Visual_Angle);
%interceptA is the estimated PM at the horizon
%
perceivedVA=interceptA*realVA;
distance_mm=500; % simulate illusion at handlength distance of ~50cm=500mm;
filenamePNG=fullfile('.', ResultsDir,[basename,'_' task ,'_', num2str(nsubjects),'visualize.png']);
[realheight_mm,perceivedheight_mm] = visualizePM(realVA,perceivedVA,distance_mm,saveLME,filenamePNG);





