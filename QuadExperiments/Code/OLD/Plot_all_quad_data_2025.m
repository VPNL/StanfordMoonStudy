dataDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/'
cd(dataDir)
datafile='QuadDataLong.csv';

all_data=readtable(datafile);
nameVars =all_data.Properties.VariableNames;
disp(nameVars)
nVars=length(all_data.Properties.VariableNames);
allTasks =unique(all_data.Task);
allTasks=allTasks([2,3]); % remove 'NaN'
nTasks=length(allTasks);
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);
uniqueObject=unique(all_data.Measurement_Type);
nObjects=length(uniqueObject)
saveLME=1;
%% remove subject 26 who didn't follow instructions
ii=find(all_data.ID~=26);
all_data=all_data(ii,:);


%% remove missing measurements (NaN)
jj=~isnan(all_data.Reported_Visual_Angle);
NotNaN=find(jj);
length(NotNaN)
all_data=all_data(NotNaN,:);

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

%% find max angle and maxRatio for graphs
maxAngle=max(all_data.Reported_Visual_Angle);

task_1=find(strcmp(all_data.Task,allTasks(1)));
task_2=find(strcmp(all_data.Task,allTasks(2)));
maxRatio=max(all_data.Ratio_Visual_Angle([task_1 ; task_2]));


    %%
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

    figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .4],'Name',allTasks{i})
     % if i==1
    %     lme_by_angle_adjusted = fitlme(all_data(task_i,:),'Reported_Visual_Angle~Real_Visual_Angle -1  + (Real_Visual_Angle- 1|ID)')
    % else
    %     lme_by_angle_estimated=fitlme(all_data(task_i,:),'Reported_Visual_Angle~Real_Visual_Angle -1  + (Real_Visual_Angle- 1|ID)')
    % end

     
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

    subplot(1,4,1); hold on % plot reported vs real visual angle
    plot (0:maxAngle, 0:maxAngle,'k:','LineWidth',1);
    plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    scatter(real_visual_angle,reported_visual_angle,60,subjectcolor,'.');
    
    axis('equal'); axis([0 maxAngle 0 maxAngle]); 
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Reported Visual Angle (degree)') 
    set(gca,'FontSize',14)
    titlestr=sprintf('%s: slope=%5.2f, main effect p=%5.2e',string(allTasks(i)),mean_slope,pval);
    title(titlestr)

 

    lme_magnification_by_angle= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Real_Visual_Angle + (Real_Visual_Angle| ID)')
    if i==1
           lme_magnification_by_angle_adjusted=lme_magnification_by_angle;
    else
           lme_magification_by_angle_estimated=lme_magnification_by_angle;
    end
    

    % meanR_slope=lme_magnification_by_angle.Coefficients.Estimate;
    % pvalR=lme_magnification_by_angle.Coefficients.pValue;
    % lower_slopeR=lme_magnification_by_angle.Coefficients.Lower;
    % upper_slopeR=lme_magnification_by_angle.Coefficients.Upper;
    % xvectoru= [0:maxAngle];
    % xvectord= [maxAngle:-1:0];
    % yvector1=lower_slopeR*xvectoru;
    % yvector2=upper_slopeR*xvectord;
    % xvector=[xvectoru xvectord];
    % yvector=[yvector1 yvector2];

     subplot(1,4,3); hold on % plot magnification vs real visual angle
    %scatter(real_visual_angle,ratio_visual_angle,40*ratio_visual_angle,subjectcolor,'.');
    % plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
    % fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    % 
    scatter(real_visual_angle,ratio_visual_angle,60,subjectcolor,'.');
    
    xlinerange=0:1:max(real_visual_angle)+1;
    ylinerange=ones(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',3);
    axis([0 max(real_visual_angle) 0 maxRatio]); 
    set(gca,'XTick',[0:1:max(real_visual_angle)+1])
    set(gca,'YTick',[0:2:maxRatio])
   
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Magnification (Reported/Real)')
    title(allTasks(i))
    set(gca,'FontSize',14)
   
   
  
    subplot(1,4,4); hold on % plot magnificaton vs distance
    %scatter(distance/100,ratio_visual_angle,40*ratio_visual_angle,subjectcolor,'.');
    scatter(distance/100,ratio_visual_angle,60,subjectcolor,'.');
     
    xlinerange=0:1:max(distance)+1;
    ylinerange=ones(size(xlinerange));
    plot (xlinerange, ylinerange,'k:','LineWidth',3);
    axis([0 max(distance/100) 0 maxRatio]); 
    set(gca,'YTick',[0:2:maxRatio])
    xlabel ('Distance (m)')
    ylabel ('Magnification (Reported/Real)')
    title(allTasks(i))
    set(gca,'FontSize',14)

    lme_magnification_by_distance= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~ Distance + (Distance|ID)')
    lme_magnification_by_distanceNangle= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~ Real_Visual_Angle*Distance + (Real_Visual_Angle*Distance|ID)')
   
    if i==1
           lme_by_distance_adjusted=lme_magnification_by_distance;
           lme_magnification_by_distanceNangle_adjusted=lme_magnification_by_distanceNangle;
    else
           lme_by_distance_estimated=lme_magnification_by_distance;
           lme_magnification_by_distanceNangle_estimated=lme_magnification_by_distanceNangle;
    end

% save figure
filenameEPS=['QuadData_', allTasks{i} ,'_', num2str(nsubjects),'.eps'];
filenamePNG=['QuadData_', allTasks{i} ,'_', num2str(nsubjects),'.png'];

exportgraphics(figh,filenameEPS,'Resolution',600,'ContentType','vector');
exportgraphics(figh,filenamePNG,'Resolution',600);

   
end



% %% 
% lme_by_angle_and_task=fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task -1  + (Real_Visual_Angle*Task-1 |ID)')
% lme_by_distance_and_task=fitlme(all_data,'Reported_Visual_Angle~Distance*Task   + (Distance*Task|ID)')
% lme_by_angle_task_distace=fitlme(all_data,'Reported_Visual_Angle~Real_Visual_Angle*Task*Distance  + (Real_Visual_Angle*Task*Distance |ID)')


%% save
save all_quad_data_analysed


