% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/MoonExperiments/';
cd(dataDir)
% replace all NA in FullMoonDataLong.csv to empty cells

datafile='FullMoonDataLong.csv'; % all data
basename = [ erase( datafile,'.csv')] ; % for saving
saveLME=1;

if ~exist('PaperFigures','dir')
    !mkdir PaperFigures
end

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
length(NotNaN)
all_data=all_data(NotNaN,:);

% find max angle and maxRatio for graphs
maxAngle=max(all_data.Reported_Visual_Angle);
maxRatio=max(all_data.Ratio_Visual_Angle);
maxDistance=max(all_data.Distance);
maxAltitude=max(all_data.Altitude);
maxDisparity=max(all_data.Disparity_VA);
meanMoonSize=mean(all_data.Real_Visual_Angle);

%set colormap
cmap=jet(nsubjects);
markerScale=36;
%%
  

 figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .8 .8],'Name',[basename 'Perceived vs Real Visual Angle'])

for i=nTasks:-1:1
    % start with perceptual task
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    task=allTasks{i};
    altitude=all_data.Altitude(task_i);
    
    % linear mixed model relating reported visual angle vs real visual
    % angle with subjects as a random effect, with random intercepts
    % per subject

    lme_by_altitude = fitlme(all_data(task_i,:),'Reported_Visual_Angle~Altitude   + (1|ID)')

    % linear mixed model relating reported visual angle vs real visual
    % angle with subjects as a random effect, with random intercepts and
    % slopes per subject

    %random intercepts and random slopes model
    lme_by_altitude_RS=fitlme(all_data, 'Reported_Visual_Angle~Altitude  + (Altitude|ID)');
    model_comp=compare(lme_by_altitude,lme_by_altitude_RS);

    if saveLME
        savelmefile=fullfile(''.','PaperFigures', [basename '_' task '_lme_reported_angle_by_altitude_RS.txt']);
        diary(savelmefile)
        lme_by_altitude
        lme_by_altitude_RS
        fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
        model_comp
        diary off
    end



    % <strong>Theoretical Likelihood Ratio Test</strong>
    % 
    % Model                 DF    AIC       BIC       LogLik     LRStat     deltaDF    pValue
    % lme_by_altitude       4     446.71    461.39    -219.36                                
    % lme_by_altitude_RS    6     897.64    923.79    -442.82    -446.93    2          1     
    % 
    % use random slopes model does not explains significant more variance
    % in the data for perceptual case nevertheless we are going to use this
    % to color the subjects by slope

    [reEfx,reNames,reStats] = randomEffects(lme_by_altitude_RS);
    [feEfx,feNames,festats] = fixedEffects(lme_by_altitude_RS);
    
    ID=all_data.ID;
    uniqueID=unique(ID);
    nsubjects=length(uniqueID);
    individualIntercepts = zeros(nsubjects,1);
    individualSlopes = zeros(nsubjects,1);
    for s = 1:nsubjects
        % Indices for this subject's random effects
        subjectRows = find(strcmp(reNames.Level, num2str(uniqueID(s)))); 
        individualIntercepts(s) = feEfx(1) + reEfx(subjectRows(1));
        individualSlopes(s)    = feEfx(2) + reEfx(subjectRows(2));
    end

    if strcmp(task,'Perceptual')
        recomputeSort=1;
    else
        recomputeSort=0;
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
    end
    %
    
    intercept=lme_by_altitude.Coefficients.Estimate(1);
    slope=lme_by_altitude.Coefficients.Estimate(2);
    pval=lme_by_altitude.Coefficients.pValue(2);
    lower_slope=lme_by_altitude.Coefficients.Lower(2);
    upper_slope=lme_by_altitude.Coefficients.Upper(2);
    xvectoru= [0:maxAltitude];
    xvectord= [maxAltitude:-1:0];
    yvectoru=slope*xvectoru+intercept;
    yvector1=lower_slope*xvectoru+intercept;
    yvector2=upper_slope*xvectord+intercept;
    xvector=[xvectoru xvectord];
    yvector=[yvector1 yvector2];
   
    % plot reported vs altitude
    subplot(1,2,i); hold on 
     %setcolors
    clear subjectcolor;
    ID=all_data.ID(task_i);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        subjectcolor(c,:)=cmap(cindex,:);
    end
   
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    scatter(all_data.Altitude(task_i),all_data.Reported_Visual_Angle(task_i),markerScale,subjectcolor,'o','filled');
    plot([0 maxAltitude], [meanMoonSize meanMoonSize],'Color',[.8 .8 .8],'LineWidth',2)
    ylim([0 maxAngle])
    xlabel ('Moon Altitude (degrees)')
    ylabel ('Reported Visual Angle (degrees)') 
    set(gca,'FontSize',18)
    titlestr=sprintf('%s \n intercept=%3.2f \n slope=%5.2f p=%5.2e\n n=%d',string(allTasks(i)),intercept,slope,pval, nsubjects);
    title(titlestr)


    % 
    % % now on ratio 
    % % subject is a random effect, on intercept only
    % lme_ratio_by_altitude = fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Altitude + (1|ID)')
    % 
    % if strcmp(allTasks(i),'Adjusted') % adjusted task
    %     lme_ratio_by_altitude_adjusted=lme_ratio_by_altitude;
    %     if saveLME % save stats table
    %          savelmefile=fullfile('.','PaperFigures', [basename '_lme_ratio_by_altitude_adjusted.txt']);
    %          diary(savelmefile)
    %          lme_ratio_by_altitude_adjusted
    %          diary off
    %     end
    % else
    %     lme_ratio_by_altitude_estimated=lme_ratio_by_altitude;
    %     if saveLME 
    %         savelmefile=fullfile('.','PaperFigures', [basename '_lme_ratio_by_altitude_estimated.txt']);
    %         diary(savelmefile)
    %         lme_ratio_by_altitude_estimated
    %         diary off
    %     end
    % end
    % 
    % interceptR=lme_ratio_by_altitude.Coefficients.Estimate(1);
    % slopeR=lme_ratio_by_altitude.Coefficients.Estimate(2);
    % pvalR=lme_ratio_by_altitude.Coefficients.pValue(2);
    % lower_slopeR=lme_ratio_by_altitude.Coefficients.Lower(2);
    % upper_slopeR=lme_ratio_by_altitude.Coefficients.Upper(2);
    % xvectoru= [0:maxAltitude];
    % xvectord= [maxAltitude:-1:0];
    % yvectoru=slopeR*xvectoru+interceptR;
    % yvector1=lower_slopeR*xvectoru+interceptR;
    % yvector2=upper_slopeR*xvectord+interceptR;
    % xvector=[xvectoru xvectord];
    % yvector=[yvector1 yvector2];
    % 
    % 
    % % plot ratio vs altitude
    % subplot(1,2,2); hold on 
    %  %setcolors
    % clear subjectcolor;
    % ID=all_data.ID(task_i);
    % for c=1:length(ID)
    %     cindex=find(uniqueID==ID(c));
    %     subjectcolor(c,:)=cmap(cindex,:);
    % end
    % 
    % plot (xvectoru, yvectoru,'k-','LineWidth',3);
    % fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    % scatter(all_data.Altitude(task_i),all_data.Ratio_Visual_Angle(task_i),markerScale,subjectcolor,'o','filled');
    % plot([0 maxAltitude], [1 1],'Color',[.8 .8 .8 ],'LineWidth',2)
    % 
    % xlabel ('Moon Altitude (degrees)')
    % ylabel ('Magnification') 
    % ylim([0 maxRatio])
    % set(gca,'FontSize',18)
    % titlestr=sprintf('%s \n intercept=%3.2f \n slope=%3.2f p=%5.2e \n n=%d',string(allTasks(i)),interceptR,slopeR,pvalR,nsubjects);
    % title(titlestr)
    % 
    % 
    % 
    % filenamePNG=fullfile('.','PaperFigures',[basename,'_' allTasks{i} ,'_', num2str(nsubjects),'.png']);
    % exportgraphics(figh,filenamePNG,'Resolution',600);
 
end



%% test if there is a difference in tasks in estimated magnification
% this model allows different subjects to have different slopes vs real ID
% and forces a zero intercept.

lme_angle_by_altitude_and_task = fitlme(all_data,'Reported_Visual_Angle~Altitude*Task  + (1|ID)')
if saveLME % save stats table
     savelmefile=fullfile('.','PaperFigures', [basename '_lme_angle_by_altitudeNtask.txt']);
     diary(savelmefile)
     lme_angle_by_altitude_and_task
     diary off
end

lme_PM_by_altitude_and_task = fitlme(all_data,'Ratio_Visual_Angle~Altitude*Task  + (1|ID)')
if saveLME % save stats table
     savelmefile=fullfile('.','PaperFigures', [basename '_lme_ratio_by_altitudeNtask.txt']);
     diary(savelmefile)
     lme_PM_by_altitude_and_task
     diary off
end


