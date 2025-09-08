% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/MoonExperiments/';
cd(dataDir)
% replace all NA in FullMoonDataLong.csv to empty cells

datafile='FullMoonDataLong.csv'; % all data
basename = [ erase( datafile,'.csv')] ; % for saving
saveLME=1;

if ~exist('Results','dir')
    !mkdir Results
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


%% set colormap

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
cmap=jet(nsubjects)
markerScale=36;
%%
   
for i=1:nTasks
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    altitude=all_data.Altitude(task_i);
    
    % linear mixed model relating reported visual angle vs real visual
    % angle with zero intersept with subjects as a random effect, with
    % random slope effect per subject

    lme_by_altitude = fitlme(all_data(task_i,:),'Reported_Visual_Angle~Altitude   + (1|ID)')
   
    if strcmp(allTasks(i),'Adjusted') % adjusted task
        lme_by_altitude_adjusted=lme_by_altitude;
        if saveLME % save stats table
             savelmefile=fullfile('.','Results', [basename '_lme_reported_angle_by_altitude_adjusted.txt']);
             diary(savelmefile)
             lme_by_altitude_adjusted
             diary off
        end
    else
        lme_by_altitude_estimated=lme_by_altitude;
        if saveLME 
            savelmefile=fullfile('.','Results', [basename '_lme_reported_angle_by_altitude_estimated.txt']);
            diary(savelmefile)
            lme_by_altitude_estimated
            diary off
        end
    end
    
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
   
    figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .6],'Name',[basename 'Perceived vs Real Visual Angle'])

    % plot reported vs altitude
    subplot(1,4,1); hold on 
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



    % now on ratio 
    % subject is a random effect, on intercept only
    lme_ratio_by_altitude = fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Altitude + (1|ID)')
   
    if strcmp(allTasks(i),'Adjusted') % adjusted task
        lme_ratio_by_altitude_adjusted=lme_ratio_by_altitude;
        if saveLME % save stats table
             savelmefile=fullfile('.','Results', [basename '_lme_ratio_by_altitude_adjusted.txt']);
             diary(savelmefile)
             lme_ratio_by_altitude_adjusted
             diary off
        end
    else
        lme_ratio_by_altitude_estimated=lme_ratio_by_altitude;
        if saveLME 
            savelmefile=fullfile('.','Results', [basename '_lme_ratio_by_altitude_estimated.txt']);
            diary(savelmefile)
            lme_ratio_by_altitude_estimated
            diary off
        end
    end
    
    interceptR=lme_ratio_by_altitude.Coefficients.Estimate(1);
    slopeR=lme_ratio_by_altitude.Coefficients.Estimate(2);
    pvalR=lme_ratio_by_altitude.Coefficients.pValue(2);
    lower_slopeR=lme_ratio_by_altitude.Coefficients.Lower(2);
    upper_slopeR=lme_ratio_by_altitude.Coefficients.Upper(2);
    xvectoru= [0:maxAltitude];
    xvectord= [maxAltitude:-1:0];
    yvectoru=slopeR*xvectoru+interceptR;
    yvector1=lower_slopeR*xvectoru+interceptR;
    yvector2=upper_slopeR*xvectord+interceptR;
    xvector=[xvectoru xvectord];
    yvector=[yvector1 yvector2];
   
   
    % plot ratio vs altitude
    subplot(1,4,2); hold on 
     %setcolors
    clear subjectcolor;
    ID=all_data.ID(task_i);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        subjectcolor(c,:)=cmap(cindex,:);
    end
   
    plot (xvectoru, yvectoru,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    scatter(all_data.Altitude(task_i),all_data.Ratio_Visual_Angle(task_i),markerScale,subjectcolor,'o','filled');
    plot([0 maxAltitude], [1 1],'Color',[.8 .8 .8 ],'LineWidth',2)
   
    xlabel ('Moon Altitude (degrees)')
    ylabel ('Magnification') 
    ylim([0 maxRatio])
    set(gca,'FontSize',18)
    titlestr=sprintf('%s \n intercept=%3.2f \n slope=%3.2f p=%5.2e \n n=%d',string(allTasks(i)),interceptR,slopeR,pvalR,nsubjects);
    title(titlestr)


    % ratio vs disparity
    % need to exclude dates before we used the caliper
    disparity_data=all_data(task_i,:);
    allowed_dates = {'Nov 15th', 'Jan 12th', 'Jan 13th', 'May 13th'};  %  allowed dates
    disparity_data = disparity_data(ismember(disparity_data.Date, allowed_dates), :);
    idx=find(strcmp(disparity_data.Task,allTasks(i)));
    lme_ratio_by_disparity_FE = fitlme(disparity_data(idx,:),'Ratio_Visual_Angle~Disparity_VA'); %ignoring between subject effects
    disp(lme_ratio_by_disparity_FE)
  
    lme_ratio_by_disparity = fitlme(disparity_data(idx,:),'Ratio_Visual_Angle~Disparity_VA + (1|ID)');
    disp(lme_ratio_by_disparity)

    model_comp=compare(lme_ratio_by_disparity_FE,lme_ratio_by_disparity); % loglikelihood test comparing models
    disp(model_comp)

    % Extract and interpret key test results
    LR_stat = model_comp.LRStat(2);      % Likelihood ratio chi-square statistic
    p_value = model_comp.pValue(2);      % p-value for the test
    df = model_comp.DF(2);               % degrees of freedom for the test

    if strcmp(allTasks(i),'Adjusted') % adjusted task
        lme_ratio_by_disparity_adjusted=lme_ratio_by_disparity;
        if saveLME % save stats table
             savelmefile=fullfile('.','Results', [basename '_lme_ratio_by_disparity_adjusted.txt']);
             diary(savelmefile)
             lme_ratio_by_disparity_FE
             lme_ratio_by_disparity_adjusted
             model_comp
          diary off
        end
    else
        lme_ratio_by_disparity_estimated=lme_ratio_by_disparity;
        if saveLME 
            savelmefile=fullfile('.','Results', [basename '_lme_ratio_by_disparity_estimated.txt']);
            diary(savelmefile)
            lme_ratio_by_disparity_estimated
            lme_ratio_by_disparity_FE
            lme_ratio_by_disparity_adjusted
            model_comp
            diary off
        end
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

    if strcmp(allTasks(i),'Perceptual')
         % plot ratio vs disparity
        subplot(1,4,4); hold on 
        %setcolors
        clear subjectcolor;
    
        %ID=all_data.ID(idx);
        ID=disparity_data.ID(idx);
        for c=1:length(ID)
            cindex=find(uniqueID==ID(c));
            subjectcolor(c,:)=cmap(cindex,:);
        end
       
        plot (xvectoru, yvectoru,'k-','LineWidth',3);
        fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
        scatter(disparity_data.Disparity_VA(idx),disparity_data.Ratio_Visual_Angle(idx),markerScale,subjectcolor,'o','filled');
        plot([0 maxDisparity], [1 1],'Color',[.8 .8 .8 ],'LineWidth',2)
        xlabel ('Disparity (degrees)')
        ylabel ('Magnification') 
        ylim([0 maxRatio])
        set(gca,'FontSize',18)
        titlestr=sprintf('%s \n intercept=%3.2f \n  slope=%3.2f p=%5.2e \n n=%d',string(allTasks(i)),interceptD,slopeD,pvalD ,length(unique(ID)));
        title(titlestr)
  
       
        % add regression of disparity vs altitude
        % there is only one measure of disparity per altitude; it's the same for
        % both tasks
        lme_disparity_by_altitude = fitlme(disparity_data(idx,:),'Disparity_VA ~ Altitude  + (1|ID)')
     
        if saveLME % save stats table
             savelmefile=fullfile('.','Results', [basename '_lme_disparity_by_altitude.txt']);
             diary(savelmefile)
             lme_disparity_by_altitude
             diary off
        end
       
        interceptDis=lme_disparity_by_altitude.Coefficients.Estimate(1);
        slopeDis=lme_disparity_by_altitude.Coefficients.Estimate(2);
        pvalDis=lme_disparity_by_altitude.Coefficients.pValue(2);
        lower_slopeDis=lme_disparity_by_altitude.Coefficients.Lower(2);
        upper_slopeDis=lme_disparity_by_altitude.Coefficients.Upper(2);
        xvectoru= [0:maxAltitude];
        xvectord= [maxAltitude:-1:0];
        yvectoru=slopeDis*xvectoru+interceptDis;
        yvector1=lower_slopeDis*xvectoru+interceptDis;
        yvector2=upper_slopeDis*xvectord+interceptDis;
        xvector=[xvectoru xvectord];
        yvector=[yvector1 yvector2];
    
       % plot  disparity vs altitude 
        subplot(1,4,3); hold on 
        plot (xvectoru, yvectoru,'k-','LineWidth',3);
        fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
        scatter(disparity_data.Altitude(idx),disparity_data.Disparity_VA(idx),markerScale,subjectcolor,'o','filled');
        ylabel ('Disparity (degrees)')
        xlabel ('Altitude (degrees)') 
        titlestr=sprintf('intercept=%3.2f \n slope=%5.2f p=%5.2e\n n=%d',interceptDis,slopeDis,pvalDis, length(unique(ID)));
        title(titlestr)
        set(gca,'FontSize',18)
    end

    filenamePNG=fullfile('.','Results',[basename,'_' allTasks{i} ,'_', num2str(nsubjects),'.png']);
    exportgraphics(figh,filenamePNG,'Resolution',600);
 
end



%% test if there is a difference in tasks in estimated magnification
% this model allows different subjects to have different slopes vs real ID
% and forces a zero intercept.

lme_angle_by_altitude_and_task = fitlme(all_data,'Reported_Visual_Angle~Altitude*Task  + (1|ID)')
if saveLME % save stats table
     savelmefile=fullfile('.','Results', [basename '_lme_angle_by_altitudeNtask.txt']);
     diary(savelmefile)
     lme_angle_by_altitude_and_task
     diary off
end

lme_PM_by_altitude_and_task = fitlme(all_data,'Ratio_Visual_Angle~Altitude*Task  + (1|ID)')
if saveLME % save stats table
     savelmefile=fullfile('.','Results', [basename '_lme_ratio_by_altitudeNtask.txt']);
     diary(savelmefile)
     lme_PM_by_altitude_and_task
     diary off
end


%% calculated binocular PM
filtered_data=all_data(ismember(all_data.Date, allowed_dates), :);
disparity_data_adjusted=filtered_data(ismember(filtered_data.Task, allTasks(1)), :);
disparity_data_estimated=filtered_data(ismember(filtered_data.Task, allTasks(2)), :);
binocular_PM=disparity_data_estimated.Reported_Visual_Angle./disparity_data_adjusted.Reported_Visual_Angle;
disparity_data_estimated.binocularPM=binocular_PM;
lme_binocularPM__by_disparity = fitlme(disparity_data_estimated,'binocularPM~Disparity_VA + (1|ID)');
  

%ID=all_data.ID(idx);
ID=disparity_data.ID(idx);
for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    subjectcolor(c,:)=cmap(cindex,:);
end
figure('Color',[ 1 1 1])
scatter(disparity_data_estimated.Disparity_VA,disparity_data_estimated.binocularPM,markerScale,subjectcolor,'o','filled');
xlabel ('Disparity (degrees)')
ylabel ('Binocular Magnification') 
set(gca,'FontSize',18)
% titlestr=sprintf('%s \n intercept=%3.2f \n  slope=%3.2f p=%5.2e \n n=%d',string(allTasks(i)),interceptD,slopeD,pvalD ,length(unique(ID)));
% title(titlestr)
