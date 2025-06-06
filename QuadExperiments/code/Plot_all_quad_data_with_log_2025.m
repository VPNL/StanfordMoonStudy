dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/'
cd(dataDir)
datafile='QuadDataLong.csv';

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
saveLME=1;
% % remove Lamp1a till indexing error is resolved
% all_data = all_data(~contains(all_data.Measurement_Type, 'Lamp1a'), :);
%% remove subject 26 & 86 who are outliers
ii=find(all_data.ID~=26);
all_data=all_data(ii,:);

ii=find(all_data.ID~=86);
all_data=all_data(ii,:);

nsubjects=length(uniqueID);
%% remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
length(NotNaN)
all_data=all_data(NotNaN,:);



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
markerScale=60;
    %% plot data and linear mixed model results
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
    basename = erase( datafile,'.csv');
    figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5],'Name',[basename '_' allTasks{i}])
   
    % linear mixed model relating reported visual angle vs real visual angle 
    lme_by_angle = fitlme(all_data(task_i,:),'Reported_Visual_Angle~Real_Visual_Angle -1  + (Real_Visual_Angle- 1|ID)')
   
    if i==1
        lme_by_angle_adjusted=lme_by_angle;
    else
        lme_by_angle_estimated=lme_by_angle;
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
    subplot(1,3,1); hold on 
    plot (0:maxAngle, 0:maxAngle,'k:','LineWidth',1);
    plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    scatter(real_visual_angle,reported_visual_angle,60,subjectcolor,'.');
    
    axis('equal'); axis([0 maxAngle 0 maxAngle]); 
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Reported Visual Angle (degree)') 
    set(gca,'FontSize',14)
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n n=%d',string(allTasks(i)),mean_slope,pval, nsubjects);
    title(titlestr)

    lme_magnification_by_angle= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Real_Visual_Angle + (Real_Visual_Angle| ID)')
    if i==1
        lme_magnification_by_angle_adjusted=lme_magnification_by_angle;
    else
        lme_magnification_by_angle_estimated=lme_magnification_by_angle;
    end
    
    % plot magnification vs real visual angle log-log axes
    subplot(1,3,2); hold on 
    log2real_visual_angle=log2(real_visual_angle);
    log2ratio_visual_angle=log2(ratio_visual_angle);
    IDs=all_data.ID(task_i);
    tbl = table(IDs,log2real_visual_angle,log2ratio_visual_angle,'VariableNames',{'ID','log2_real_visual_angle','log2_ratio_visual_angle'});

    % linear mixed model on magification as a function of real visual angle
    lme_logmagnification_by_logangle= fitlme(tbl,'log2_ratio_visual_angle~log2_real_visual_angle + (log2_real_visual_angle| ID)')
    if i==1
       lme_logmagnification_by_angle_adjusted=lme_logmagnification_by_logangle;
    else
       lme_logmagnification_by_angle_estimated=lme_logmagnification_by_logangle;
    end
    
    % calculate regression line and confidence interval on fixed effect
    meanR_intercept=lme_logmagnification_by_logangle.Coefficients.Estimate(1); % first coefficient-> intercept
    pvalR_intercept=lme_logmagnification_by_logangle.Coefficients.pValue(1); % pvalue first coefficient-> slope
   
    meanR_slope=lme_logmagnification_by_logangle.Coefficients.Estimate(2); % second coefficient-> slope 
    pvalR_slope=lme_logmagnification_by_logangle.Coefficients.pValue(2); % pvalue second coefficient-> slope
    lower_slopeR=lme_logmagnification_by_logangle.Coefficients.Lower(2);
    upper_slopeR=lme_logmagnification_by_logangle.Coefficients.Upper(2);
    xvectorRu= log2(.25):1:log2(8);
    xvectorRd= log2(8):-1:log2(.25);
    yvectorR1=lower_slopeR*xvectorRu+ meanR_intercept;
    yvectorR2=upper_slopeR*xvectorRd+ meanR_intercept;
    xvectorR=[xvectorRu xvectorRd];
    yvectorR=[yvectorR1 yvectorR2];

    scatter(log2real_visual_angle,log2ratio_visual_angle,60,subjectcolor,'.');
    plot (xvectorR, meanR_slope*xvectorR+meanR_intercept,'k-','LineWidth',3);
    fill(xvectorR, yvectorR, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    
    xlinerange=log2(.25):1:log2(8); 
    ylinerange=zeros(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
     
    set(gca,'XTick',log2(.25):1:log2(8),'XTickLabel',2.^[log2(.25):1:log2(8)]);
    set(gca,'YTick',log2(.25):1:log2(16),'YTickLabel',2.^[log2(.25):1:log2(16)]);
    axis([log2(.25) log2(8) log2(.25) log2(16)])
    
    xlabel ('Real Visual Angle (degree) Log scale')
    ylabel (' Magnification (Reported/Real) Log scale')
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n intercept=%5.2f, p=%5.2e',...
        string(allTasks(i)),meanR_slope,pvalR_slope,meanR_intercept,pvalR_intercept);
    title(titlestr)
    set(gca,'FontSize',14)
    % 
    % log2distance=log2(distance);
    % 
    % IDs=all_data.ID(task_i);
    % tbl = table(IDs,log2distance,log2ratio_visual_angle,'VariableNames',{'ID','Distance','log2_ratio_visual_angle'});
    % 
    % % linear mixed model on magification as a function of real visual angle
    % lme_logmagnification_by_logdistance= fitlme(tbl,'log2_ratio_visual_angle~log2distance + (log2_real_visual_angle| ID)')
    % if i==1
    %    lme_logmagnification_by_angle_adjusted=lme_logmagnification_by_logdistance;
    % else
    %    lme_logmagnification_by_angle_estimated=lme_logmagnification_by_logdistance;
    % end
    % run linear mixed model relating magnification to distace
    lme_magnification_by_distance= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~ Distance + (Distance|ID)')
    lme_magnification_by_distanceNangle= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~ Real_Visual_Angle*Distance + (Real_Visual_Angle*Distance|ID)')

    if i==1
           lme_by_distance_adjusted=lme_magnification_by_distance;
           lme_magnification_by_distanceNangle_adjusted=lme_magnification_by_distanceNangle;
    else
           lme_by_distance_estimated=lme_magnification_by_distance;
           lme_magnification_by_distanceNangle_estimated=lme_magnification_by_distanceNangle;
    end

    % calculate regression line and confidence interval on fixed effect
    meanD_intercept=lme_magnification_by_distance.Coefficients.Estimate(1);% first coefficient ->intercept
    meanD_slope=lme_magnification_by_distance.Coefficients.Estimate(2); % second coefficient-> slope 
    pvalD_intercept= lme_magnification_by_distance.Coefficients.pValue(1); % pvalue first coefficient-> intercept
    pvalD_slope= lme_magnification_by_distance.Coefficients.pValue(2); % pvalue second coefficient-> slope
    lower_slopeD= lme_magnification_by_distance.Coefficients.Lower(2);
    upper_slopeD= lme_magnification_by_distance.Coefficients.Upper(2);
    xvectorDu= 0:10:maxDistance*1.1;
    xvectorDd= 1.1*maxDistance:-10:0;
    yvectorD1=lower_slopeD*xvectorDu+meanD_intercept;
    yvectorD2=upper_slopeD*xvectorDd+meanD_intercept;
    xvectorD=[xvectorDu xvectorDd];
    yvectorD=[yvectorD1 yvectorD2];

    % plot magnificaton vs distance 
    subplot(1,3,3); hold on 

    plot (xvectorD, meanD_slope*xvectorD+meanD_intercept,'k-','LineWidth',3); % regression
    fill(xvectorD, yvectorD, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1); %confidence interval over fixed effects
    scatter(distance,ratio_visual_angle,60,subjectcolor,'.');
     
    xlinerange=0:1:max(distance)*1.1;
    ylinerange=ones(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',1);
    axis([0 max(distance)*1.1 0 maxRatio]); 
    set(gca,'YTick',[0:2:maxRatio])
    xlabel ('Distance (m)')
    ylabel ('Magnification (Reported/Real)')
     titlestr=sprintf('%s \n slope=%5.2e, p=%5.2e \n intercept=%5.2f, p=%5.2e',...
         string(allTasks(i)),meanD_slope,pvalD_slope,meanD_intercept,pvalD_intercept);
    title(titlestr)
    set(gca,'FontSize',14)

    % save figure
    basename = erase( datafile,'.csv');
    
    filenameEPS= fullfile('.','Results', [basename '_log_', allTasks{i} ,'_', num2str(nsubjects),'.eps']);
    exportgraphics(figh,filenameEPS,'Resolution',600,'ContentType','vector');

    filenamePNG=fullfile('.','Results',[basename,'_log_', allTasks{i} ,'_', num2str(nsubjects),'.png']);
    saveas(figh,filenamePNG);
    %exportgraphics(figh,filenamePNG,'Resolution',600);
   
end



%% plot magnification as a function of angle on regular axis
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
    
    basename = erase( datafile,'.csv');
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
    scatter(real_visual_angle,reported_visual_angle,60,subjectcolor,'.');
    axis('equal'); axis([0 maxAngle 0 maxAngle]); 
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Reported Visual Angle (degree)') 
    set(gca,'FontSize',14)
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n n=%d',string(allTasks(i)),mean_slope,pval, nsubjects);
    title(titlestr)



    % plot magnification vs real visual angle on normal scale
    % get the relevant lme data
    % linear mixed model on magification as a function of real visual angle
    if strcmp(allTasks(i),'Perceptual')
       lme_logmagnification_by_logangle=lme_logmagnification_by_angle_estimated;   
    else
       lme_logmagnification_by_logangle=lme_logmagnification_by_angle_adjusted;
    end
    
    % calculate regression line and confidence interval on fixed effect
    meanR_intercept=lme_logmagnification_by_logangle.Coefficients.Estimate(1); % first coefficient-> intercept
    pvalR_intercept=lme_logmagnification_by_logangle.Coefficients.pValue(1); % pvalue first coefficient-> slope
   
    meanR_slope=lme_logmagnification_by_logangle.Coefficients.Estimate(2); % second coefficient-> slope 
    pvalR_slope=lme_logmagnification_by_logangle.Coefficients.pValue(2); % pvalue second coefficient-> slope
    lower_slopeR=lme_logmagnification_by_logangle.Coefficients.Lower(2);
    upper_slopeR=lme_logmagnification_by_logangle.Coefficients.Upper(2);
   

    % the regression is log-log to linearize the curve
    % lme_logmagnification_by_logangle= fitlme(tbl,'log2_ratio_visual_angle~log2_real_visual_angle + (log2_real_visual_angle| ID)')
    % log2(ratio)=intercept+slope*log2(angle)
    % ratio=2^intercept*2^(slope*angle)
    % transform regression to regular axis
    % ratio_visual_angle=2^meanR_intercept*real_visual_angle.^(meanR_slope)
    % estimate regression line and confidence interval
    xvectorRu= .25:0.25:8;
    xvectorRd= 8:.25:.25;

    yvectoru=(2.^meanR_intercept)*xvectorRu.^meanR_slope;
    yvectorR1= (2.^meanR_intercept)*xvectorRu.^lower_slopeR;
    yvectorR2=(2.^meanR_intercept)*xvectorRd.^upper_slopeR;
   
    xvectorR=[xvectorRu xvectorRd];
    yvectorR=[yvectorR1 yvectorR2];


    % plot magnification ratio vs real visual angle
    subplot(1,3,2); 
    hold on 
    scatter(real_visual_angle,ratio_visual_angle,60,subjectcolor,'.');
    plot (xvectorRu,yvectoru ,'k-','LineWidth',3);
    %fill(xvectorR, yvectorR, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    
    xlinerange=.25:.25:8; 
    ylinerange=ones(size(xlinerange)); % no magnificatio
    plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line 
    set(gca,'XTick',0:1:8)
    set(gca,'YTick',0:1:16)
    axis([0 8 0 16])
    
    xlabel ('Real Visual Angle (degree)')
    ylabel (' Magnification (Reported/Real)')
    titlestr=sprintf('%s \n slope=%5.2f, p=%5.2e \n intercept=%5.2f, p=%5.2e',...
        string(allTasks(i)),meanR_slope,pvalR_slope,meanR_intercept,pvalR_intercept);
    title(titlestr)
    set(gca,'FontSize',14)



   % plot magnification vs distance 
    % get the relevant lme data
    if strcmp(allTasks(i),'Perceptual')
       lme_magnification_by_distance=lme_by_distance_estimated;
    else
       lme_magnification_by_distance=lme_by_distance_adjusted;
    end

     % get regression line and confidence interval on fixed effect
    meanD_intercept=lme_magnification_by_distance.Coefficients.Estimate(1);% first coefficient ->intercept
    meanD_slope=lme_magnification_by_distance.Coefficients.Estimate(2); % second coefficient-> slope 
    pvalD_intercept= lme_magnification_by_distance.Coefficients.pValue(1); % pvalue first coefficient-> intercept
    pvalD_slope= lme_magnification_by_distance.Coefficients.pValue(2); % pvalue second coefficient-> slope
    lower_slopeD= lme_magnification_by_distance.Coefficients.Lower(2);
    upper_slopeD= lme_magnification_by_distance.Coefficients.Upper(2);
    xvectorDu= 0:10:maxDistance*1.1;
    xvectorDd= 1.1*maxDistance:-10:0;
    yvectorD1=lower_slopeD*xvectorDu+meanD_intercept;
    yvectorD2=upper_slopeD*xvectorDd+meanD_intercept;
    xvectorD=[xvectorDu xvectorDd];
    yvectorD=[yvectorD1 yvectorD2];

    subplot(1,3,3); 
    hold on 
    plot (xvectorD, meanD_slope*xvectorD+meanD_intercept,'k-','LineWidth',3); % 
    fill(xvectorD, yvectorD, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1); %confidence interval over fixed effects
    scatter(distance,ratio_visual_angle,60,subjectcolor,'.');
     
    xlinerange=0:1:max(distance)*1.1;
    ylinerange=ones(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',1);
    axis([0 1.1*max(distance) 0 maxRatio]); 
    set(gca,'YTick',[0:2:maxRatio])
    xlabel ('Distance (m)')
    ylabel ('Magnification (Reported/Real)')
    titlestr=sprintf('%s \n slope=%5.2e, p=%5.2e \n intercept=%5.2f, p=%5.2e',...
         string(allTasks(i)),meanD_slope,pvalD_slope,meanD_intercept,pvalD_intercept);
    title(titlestr)
    set(gca,'FontSize',14)

        
    % save figure
    basename = erase( datafile,'.csv');
    
    filenameEPS=fullfile('.','Results',[basename '_', allTasks{i} ,'_', num2str(nsubjects),'.eps']);
    exportgraphics(figh,filenameEPS,'Resolution',600,'ContentType','vector'); %% vector graphics
    
    filenamePNG=fullfile('.','Results',[basename,'_', allTasks{i} ,'_', num2str(nsubjects),'.png']);
    %exportgraphics(figh,filenamePNG,'Resolution',600);
    saveas(figh,filenamePNG);

   
end

% %% 
% lme_by_angle_and_task=fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task -1  + (Real_Visual_Angle*Task-1 |ID)')
% lme_by_distance_and_task=fitlme(all_data,'Reported_Visual_Angle~Distance*Task   + (Distance*Task|ID)')
% lme_by_angle_task_distace=fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task*Distance  + (Real_Visual_Angle*Task*Distance |ID)')


%% save
savefile=[basename '_analysed'];
save(savefile)


