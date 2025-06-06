% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/'
cd(dataDir)
datafile='QuadDataLong.csv'; % all data

basename = [ erase( datafile,'.csv') '_justballs'] ; % for saving
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
uniqueObject=unique(all_data.Measurement_Type);
nObjects=length(uniqueObject);


%% remove subject 26, 78, 80 86 who are outliers
ii=find(all_data.ID~=26);
all_data=all_data(ii,:);

ii=find(all_data.ID~=78);
all_data=all_data(ii,:);

ii=find(all_data.ID~=80);
all_data=all_data(ii,:);

ii=find(all_data.ID~=86);
all_data=all_data(ii,:);
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);

%% remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
length(NotNaN)
all_data=all_data(NotNaN,:);

all_data = all_data(~contains(all_data.Measurement_Type, 'Stick'), :);
%% find max angle and maxRatio for graphs
maxAngle=max(all_data.Reported_Visual_Angle);

task_1=find(strcmp(all_data.Task,allTasks(1)));
task_2=find(strcmp(all_data.Task,allTasks(2)));
maxRatio=max(all_data.Ratio_Visual_Angle([task_1 ; task_2]));
% transform distances from cm to m 
all_data.Distance=all_data.Distance/100;
maxDistance=max(all_data.Distance);

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
markerScale=36;
%% Examine relationship between perceived and real visual angle
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename 'Perceived vs Real Visual Angle'])
   
for i=1:nTasks
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    real_visual_angle=all_data.Real_Visual_Angle(task_i);
    
    reported_visual_angle=all_data.Reported_Visual_Angle(task_i);
    ratio_visual_angle=all_data.Ratio_Visual_Angle(task_i);
    distance=all_data.Distance(task_i);
    max_angle=max(reported_visual_angle);

    if strcmp(allTasks(i),'Perceptual')
        estimated_visual_angle=reported_visual_angle;
        estimated_magnification=ratio_visual_angle;
        estimated_real_visual_angle=real_visual_angle;
        estimated_distance=distance;

    else
        adjusted_visual_angle=reported_visual_angle;
        adjusted_magnification=ratio_visual_angle;
        adjusted_real_visual_angle=real_visual_angle;
        adjusted_distance=distance;
    end


    %setcolors
    clear subjectcolor;
    ID=all_data.ID(task_i);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        subjectcolor(c,:)=cmap(cindex,:);
    end
   
    % linear mixed model relating reported visual angle vs real visual
    % angle with zero intersept with subjects as a random effect, with
    % random slope effect per subject

    lme_by_angle = fitlme(all_data(task_i,:),'Reported_Visual_Angle~Real_Visual_Angle -1  + (Real_Visual_Angle- 1|ID)')
   
    if strcmp(allTasks(i),'Adjusted') % adjusted task
        lme_by_angle_adjusted=lme_by_angle;
        if saveLME % save stats table
             savelmefile=fullfile('.','Results', [basename '_lme_reported_vs_real_angle_adjusted.txt']);
             diary(savelmefile)
             lme_by_angle_adjusted
             diary off
        end
    else
        lme_by_angle_estimated=lme_by_angle;
        if saveLME 
            savelmefile=fullfile('.','Results', [basename '_lme_reported_vs_real_angle_estimated.txt']);
            diary(savelmefile)
            lme_by_angle_estimated
            diary off
        end
    end

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

    % plot reported vs real visual angle
    subplot(1,2,i); hold on 
    plot (0:maxAngle, 0:maxAngle,'k:','LineWidth',1);
    plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    scatter(real_visual_angle,reported_visual_angle,markerScale,subjectcolor,'o','filled');
    
    axis('equal'); axis([0 maxAngle 0 maxAngle]); 
    xlabel ('Real Visual Angle (degrees)')
    ylabel ('Reported Visual Angle (degrees)') 
    set(gca,'FontSize',36)
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n n=%d',string(allTasks(i)),mean_slope,pval, nsubjects);
    title(titlestr)
   
end

% filenameEPS=fullfile('.','Results',[basename , '_', num2str(nsubjects),'.eps']);
% exportgraphics(figh,filenameEPS,'Resolution',600,'ContentType','vector'); %% vector graphics

filenamePNG=fullfile('.','Results',[basename,'_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);
%saveas(figh,filenamePNG);

%% test if relation between perceived and reported visual angle varies across tasks
% this model allows different subjects to have different slopes vs real ID
% and forces a zero intercept.

lme_by_angleNtask = fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task -1  + ( Real_Visual_Angle - 1|ID)')
if saveLME % save stats table
     savelmefile=fullfile('.','Results', [basename '_lme_reported_angle_vs_angle_and_task.txt']);
     diary(savelmefile)
     lme_by_angleNtask
     diary off
end
   
%% Plot results by task also calculate magnification vs perceived angle and task on a log-log axis
for i=1:nTasks
    % set figure
    figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5],'Name',[basename '_logAxis_' allTasks{i}])
   
    % get the relevant data 
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    real_visual_angle=all_data.Real_Visual_Angle(task_i);
    reported_visual_angle=all_data.Reported_Visual_Angle(task_i);
    ratio_visual_angle=all_data.Ratio_Visual_Angle(task_i);
    distance=all_data.Distance(task_i);
    max_angle=max(reported_visual_angle);

    % linear mixed model relating reported visual angle vs real visual
    % angle with zero intersept with subjects as a random effect, with
    % random slope effect per subject
    lme_by_angle = fitlme(all_data(task_i,:),'Reported_Visual_Angle~Real_Visual_Angle -1  + (Real_Visual_Angle- 1|ID)')
   
   if strcmp(allTasks(i),'Adjusted') % adjusted task
        lme_by_angle_adjusted=lme_by_angle;
        if saveLME % save stats table
             savelmefile=fullfile('.','Results', [basename '_lme_reported_vs_real_angle_adjusted.txt']);
             diary(savelmefile)
             lme_by_angle_adjusted
             diary off
        end
    else
        lme_by_angle_estimated=lme_by_angle;
        if saveLME 
            savelmefile=fullfile('.','Results', [basename '_lme_reported_vs_real_angle_estimated.txt']);
            diary(savelmefile)
            lme_by_angle_estimated
            diary off
        end
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

    % setcolors
    clear subjectcolor;
    ID=all_data.ID(task_i);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        subjectcolor(c,:)=cmap(cindex,:);
    end
    
    subplot(1,3,1); 
    hold on 
    plot (0:maxAngle, 0:maxAngle,'k:','LineWidth',1);
    plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
    scatter(real_visual_angle,reported_visual_angle,markerScale,subjectcolor,'o','filled');
  
    axis('equal'); axis([0 maxAngle 0 maxAngle]); 
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Reported Visual Angle (degree)') 
    set(gca,'FontSize',18)
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n n=%d',string(allTasks(i)),mean_slope,pval, nsubjects);
    title(titlestr)

    % organized data table for log metrics
    log2real_visual_angle=log2(real_visual_angle);
    log2ratio_visual_angle=log2(ratio_visual_angle);
    log2distance=log2(distance);
    IDs=all_data.ID(task_i);
    tbl = table(IDs,log2real_visual_angle,log2ratio_visual_angle,log2distance,'VariableNames',{'ID','log2_real_visual_angle','log2_ratio_visual_angle', 'log2_distance'});

    % linear mixed model on log magnification as function of log visual angle
    % subjects are random effect(random intercept)
    % PM for perceptual magnification
    lme_logPM_by_logangle= fitlme(tbl,'log2_ratio_visual_angle ~ log2_real_visual_angle +  (1| ID)')
   
    if strcmp(allTasks(i),'Adjusted')
       lme_logPM_by_logangle_adjusted=lme_logPM_by_logangle;
       if saveLME
            savelmefile=fullfile('.','Results', [basename '_lme_logPM_by_logangle_adjusted.txt']);
            diary(savelmefile)
            lme_logPM_by_logangle
            diary off
       end
    else
       lme_logPM_by_logangle_estimated=lme_logPM_by_logangle;
       if saveLME
            savelmefile=fullfile('.','Results', [basename '_lme_logPM_by_logangle_estimated.txt']);
            diary(savelmefile)
            lme_logPM_by_logangle
            diary off
       end     
    end
    
    meanA_intercept=lme_logPM_by_logangle.Coefficients.Estimate(1); % first coefficient-> intercept
    pvalA_intercept=lme_logPM_by_logangle.Coefficients.pValue(1); % pvalue first coefficient-> slope
   
    meanA_slope=lme_logPM_by_logangle.Coefficients.Estimate(2); % second coefficient-> slope on angle
    pvalA_slope=lme_logPM_by_logangle.Coefficients.pValue(2); % pvalue second coefficient-> slope 
    lower_slopeA=lme_logPM_by_logangle.Coefficients.Lower(2);
    upper_slopeA=lme_logPM_by_logangle.Coefficients.Upper(2);
    xvectorAu= log2(.25):1:log2(8);
    xvectorAd= log2(8):-1:log2(.25);
    yvectorA1=lower_slopeA*xvectorAu+ meanA_intercept;
    yvectorA2=upper_slopeA*xvectorAd+ meanA_intercept;
    xvectorA=[xvectorAu xvectorAd];
    yvectorA=[yvectorA1 yvectorA2];

    % plot magnification vs real visual angle log-log axes
    subplot(1,3,2)
    hold on 
    scatter(log2real_visual_angle,log2ratio_visual_angle,markerScale,subjectcolor,'o','filled');
    plot (xvectorA, meanA_slope*xvectorA+meanA_intercept,'k-','LineWidth',3);
    fill(xvectorA, yvectorA, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    
    xlinerange=log2(.25):1:log2(8); 
    ylinerange=zeros(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
     
    set(gca,'XTick',log2(.25):1:log2(8),'XTickLabel',2.^[log2(.25):1:log2(8)]);
    set(gca,'YTick',log2(.25):1:round(log2(maxRatio)),'YTickLabel',2.^[log2(.25):1:round(log2(maxRatio))]);
    axis([log2(.25) log2(8) log2(.25) round(log2(maxRatio))])
    
    xlabel ('Real Visual Angle (degree) log scale')
    ylabel ('Magnification (Reported/Real) log scale')
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n intercept=%5.2f, p=%5.2e',...
        string(allTasks(i)),meanA_slope,pvalA_slope,meanA_intercept,pvalA_intercept);
    title(titlestr)
    set(gca,'FontSize',18)

    % linear mixed model on log magnification as function of log distance
    % subjects are random effect (random intercept) 
    lme_logPM_by_logdistance= fitlme(tbl,'log2_ratio_visual_angle ~ log2_distance +  (1| ID)')
   
    if strcmp(allTasks(i),'Adjusted')
       lme_logPM_by_logdistance_adjusted=lme_logPM_by_logdistance;
       if saveLME
            savelmefile=fullfile('.','Results', [basename '_lme_logPM_by_logdistance_adjusted.txt']);
            diary(savelmefile)
            lme_logPM_by_logdistance
            diary off
       end
    else
       lme_logPM_by_logdistance_estimated=lme_logPM_by_logdistance;
       if saveLME
            savelmefile=fullfile('.','Results', [basename '_lme_logPM_by_logdistance_estimated.txt']);
            diary(savelmefile)
            lme_logPM_by_logdistance
            diary off
       end      
    end
     
    meanD_intercept=lme_logPM_by_logdistance.Coefficients.Estimate(1); % first coefficient-> intercept
    pvalD_intercept=lme_logPM_by_logdistance.Coefficients.pValue(1); % pvalue first coefficient-> slope
   
    meanD_slope=lme_logPM_by_logdistance.Coefficients.Estimate(2); % second coefficient-> slope on angle
    pvalD_slope= lme_logPM_by_logdistance.Coefficients.pValue(2); % pvalue second coefficient-> slope
    lower_slopeD=lme_logPM_by_logdistance.Coefficients.Lower(2);
    upper_slopeD= lme_logPM_by_logdistance.Coefficients.Upper(2);
    distanceRange=maxDistance*1.2;
    xvectorDu= 0:10:distanceRange;
    xvectorDd= distanceRange:-10:0;
    yvectorD1=lower_slopeD*xvectorDu+meanD_intercept;
    yvectorD2=upper_slopeD*xvectorDd+meanD_intercept;
    xvectorD=[xvectorDu xvectorDd];
    yvectorD=[yvectorD1 yvectorD2];

    % plot magnification vs distance 
    subplot(1,3,3)
    hold on 
    plot(xvectorD, meanD_slope*xvectorD+meanD_intercept,'k-','LineWidth',3); % regression
    fill(xvectorD, yvectorD, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1); %confidence interval over fixed effects
    scatter(log2distance,log2ratio_visual_angle,markerScale,subjectcolor,'o','filled');
     
    xlinerange=unique(log2distance);
    ylinerange=zeros(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',1);
    set(gca,'XTick',unique(log2distance),'XTickLabel',unique(distance),'XTickLabelRotation',90);
    set(gca,'YTick',log2(.25):1:round(log2(maxRatio)),'YTickLabel',2.^[log2(.25):1:round(log2(maxRatio))]);
    axis([.9*min(xlinerange) 1.1*max(xlinerange) log2(.25) round(log2(maxRatio))])
  
    xlabel ('Distance (m) log scale')
    ylabel ('Magnification (Reported/Real) log scale')
     titlestr=sprintf('%s \n slope=%5.2e, p=%5.2e \n intercept=%5.2f, p=%5.2e',...
         string(allTasks(i)),meanD_slope,pvalD_slope,meanD_intercept,pvalD_intercept);
    title(titlestr)
    set(gca,'FontSize',18)

    % save figure

    % filenameEPS= fullfile('.','Results', [basename '_logAxis_', allTasks{i} ,'_', num2str(nsubjects),'.eps']);
    % exportgraphics(figh,filenameEPS,'Resolution',600,'ContentType','vector');

    filenamePNG=fullfile('.','Results',[basename,'_logAxis_', allTasks{i} ,'_', num2str(nsubjects),'.png']);
    exportgraphics(figh,filenamePNG,'Resolution',600);
  
    % lme of log magnification as a factor of both log angle and log distance 
    % subject is a random effect (random slopes)
    % check that both factors significantly contribute to observations
    lme_logPM_by_logangle_and_logdistance= fitlme(tbl,'log2_ratio_visual_angle ~ log2_real_visual_angle + log2_distance + (1| ID)')
   
    if strcmp(allTasks(i),'Adjusted')
       lme_logPM_by_logangle_and_logdistance_adjusted=lme_logPM_by_logangle_and_logdistance;
       if saveLME
            savelmefile=fullfile('.','Results', [basename '_lme_logPM_by_logangle_and_logdistance_adjusted.txt']);
            diary(savelmefile)
            lme_logPM_by_logangle_and_logdistance
            diary off
       end
    else
       lme_logPM_by_logangle_and_logdistance_estimated=lme_logPM_by_logangle_and_logdistance;
       if saveLME
            savelmefile=fullfile('.','Results', [basename '_lme_logPM_by_logangle_and_logdistance_estimated.txt']);
            diary(savelmefile)
            lme_logPM_by_logangle_and_logdistance
            diary off
       end  
    end
    
end

%% plot magnification as a function of angle on regular axis use the results from lme above
for i=1:nTasks
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    real_visual_angle=all_data.Real_Visual_Angle(task_i);
    reported_visual_angle=all_data.Reported_Visual_Angle(task_i);
    ratio_visual_angle=all_data.Ratio_Visual_Angle(task_i);
    distance=all_data.Distance(task_i);
    max_angle=max(reported_visual_angle);

    %setcolors
    clear subjectcolor;
    ID=all_data.ID(task_i);
    for c=1:length(ID)
        cindex=find(uniqueID==ID(c));
        subjectcolor(c,:)=cmap(cindex,:);
    end

    figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5],'Name',[basename '_' allTasks{i}])
  
    % get the relevant lme data
    if strcmp(allTasks(i),'Perceptual')
       lme_by_angle= lme_by_angle_estimated ;   
    else
       lme_by_angle=lme_by_angle_adjusted;
    end

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

    % plot reported vs real visual angle
    subplot(1,3,1); 
    hold on 
    plot (0:maxAngle, 0:maxAngle,'k:','LineWidth',1);
    plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    scatter(real_visual_angle,reported_visual_angle,markerScale,subjectcolor,'o','filled');
    axis('equal'); axis([0 maxAngle 0 maxAngle]); 
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Reported Visual Angle (degree)') 
    set(gca,'FontSize',18)
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n n=%d',string(allTasks(i)),mean_slope,pval, nsubjects);
    title(titlestr)


    % plot magnification vs real visual angle on normal scale
    % get the relevant lme data
    % linear mixed model on magification as a function of real visual angle
    if strcmp(allTasks(i),'Perceptual')
       lme_logPM_by_logangle=lme_logPM_by_logangle_estimated;   
    else
       lme_logPM_by_logangle=lme_logPM_by_logangle_adjusted;
    end
    
    % calculate regression line and confidence interval on fixed effect
    meanA_intercept=lme_logPM_by_logangle.Coefficients.Estimate(1); % first coefficient-> intercept
    pvalA_intercept=lme_logPM_by_logangle.Coefficients.pValue(1); % pvalue first coefficient-> slope
   
    meanA_slope=lme_logPM_by_logangle.Coefficients.Estimate(2); % second coefficient-> slope 
    pvalA_slope=lme_logPM_by_logangle.Coefficients.pValue(2); % pvalue second coefficient-> slope
    lowerA_slopeR=lme_logPM_by_logangle.Coefficients.Lower(2);
    upperA_slopeR=lme_logPM_by_logangle.Coefficients.Upper(2);
   

    % the regression is log-log to linearize the curve
    % lme_logPM_by_logangle= fitlme(tbl,'log2_ratio_visual_angle~log2_real_visual_angle + (log2_real_visual_angle| ID)')
    % log2(ratio)=intercept+slope*log2(angle)
    % ratio=2^intercept*2^(slope*angle)
    % transform regression to regular axis
    % ratio_visual_angle=2^meanR_intercept*real_visual_angle.^(meanR_slope)
    % estimate regression line and confidence interval
    xvectorAu= unique(real_visual_angle);
    xvectorAd= flipud(xvectorAu);
    yvectoru=(2.^meanA_intercept)*xvectorAu.^meanA_slope;
    yvectorA1=(2.^meanA_intercept)*xvectorAu.^lower_slopeA;
    yvectorA2=(2.^meanA_intercept)*xvectorAu.^upper_slopeA;% R2 is lower than R1

    % plot magnification ratio vs real visual angle
    subplot(1,3,2); 
    hold on 
    scatter(real_visual_angle,ratio_visual_angle,markerScale,subjectcolor,'o','filled');
    plot (xvectorAu,yvectorA1 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
    plot (xvectorAu,yvectorA2 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
    plot (xvectorAu,yvectoru ,'k-','LineWidth',3);
   
    % 
    xlinerange=.25:.25:8; 
    ylinerange=ones(size(xlinerange)); % no magnificatio
    plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line 
    set(gca,'XTick',0:1:8)
    set(gca,'YTick',0:2:maxRatio)
    axis([0 8 0 maxRatio])
    
    xlabel ('Real Visual Angle (degree)')
    ylabel (' Magnification (Reported/Real)')
    titlestr=sprintf('%s \n PM= %3.2f*(visual angle)^{%3.2f},\n pI=%5.2e pE=%5.2e',...
        string(allTasks(i)),2^meanA_intercept, meanA_slope,pvalA_intercept,pvalA_slope);
    title(titlestr)
    set(gca,'FontSize',18)

 
   % plot magnification vs distance 
    % get the relevant lme data
    if strcmp(allTasks(i),'Perceptual')
       lme_magnification_by_distance=lme_logPM_by_logdistance_estimated;
    else
       lme_magnification_by_distance=lme_logPM_by_logdistance_adjusted;
    end

   % get regression coefficients and confidence interval on fixed effect
    meanD_intercept=lme_magnification_by_distance.Coefficients.Estimate(1);% first coefficient ->intercept
    meanD_slope=lme_magnification_by_distance.Coefficients.Estimate(2); % second coefficient-> slope 
    pvalD_intercept= lme_magnification_by_distance.Coefficients.pValue(1); % pvalue first coefficient-> intercept
    pvalD_slope= lme_magnification_by_distance.Coefficients.pValue(2); % pvalue second coefficient-> slope
    lower_slopeD= lme_magnification_by_distance.Coefficients.Lower(2);
    upper_slopeD= lme_magnification_by_distance.Coefficients.Upper(2);
    
    xvectorDu= unique(distance);
    yvectorDu=(2.^meanD_intercept)*xvectorDu.^meanD_slope;
    yvectorD1=(2.^meanD_intercept)*xvectorDu.^lower_slopeD;
    yvectorD2=(2.^meanD_intercept)*xvectorDu.^upper_slopeD;
    
    xvectorD=[xvectorDu flipud(xvectorDu)];
    yvectorD=[yvectorD1 flipud(yvectorD2)];

    subplot(1,3,3); 
    hold on 
    scatter(distance,ratio_visual_angle,markerScale,subjectcolor,'o','filled');
    
    plot (xvectorDu,yvectorD1 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
    plot (xvectorDu,yvectorD2 ,'Color', [0.8 0.8 0.8],'LineWidth',3);
    plot (xvectorDu,yvectorDu ,'k-','LineWidth',3);
   
    xlinerange=0:1:max(distance)*1.1;
    ylinerange=ones(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',1);
    axis([0 1.1*max(distance) 0 maxRatio]); 
    set(gca,'YTick',[0:2:maxRatio])
    xlabel ('Distance (m)')
    ylabel ('Magnification (Reported/Real)')
    titlestr=sprintf('%s \n PM= %3.2f*(distance)^{%3.2f},\n pI=%5.2e pE=%5.2e',...
        string(allTasks(i)),2^meanD_intercept, meanD_slope,pvalD_intercept,pvalD_slope);
    title(titlestr)
    set(gca,'FontSize',18)

        
    % save figure
    % filenameEPS=fullfile('.','Results',[basename '_', allTasks{i} ,'_', num2str(nsubjects),'.eps']);
    % exportgraphics(figh,filenameEPS,'Resolution',600,'ContentType','vector'); %% vector graphics
    % 
    filenamePNG=fullfile('.','Results',[basename,'_', allTasks{i} ,'_', num2str(nsubjects),'.png']);
    exportgraphics(figh,filenamePNG,'Resolution',600);
end

% %% 
% lme_by_angle_and_task=fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task -1  + (Real_Visual_Angle*Task-1 |ID)')
% lme_by_distance_and_task=fitlme(all_data,'Reported_Visual_Angle~Distance*Task   + (Distance*Task|ID)')
% lme_by_angle_task_distace=fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task*Distance  + (Real_Visual_Angle*Task*Distance |ID)')


%% save
savefile=[basename '_analysed'];
save(savefile)

