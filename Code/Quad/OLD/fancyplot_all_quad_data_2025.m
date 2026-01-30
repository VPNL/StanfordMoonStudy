%% read dataTables
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

%%  make colormap

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
% set participant colors
clear subjectcolor;
ID=all_data.ID;
for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    subjectcolor(c,:)=cmap(cindex,:);
end

markerScale=30;

%% perceived angle by visual angle, task, distance
% plot
fig1=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .8 .8],'Name','Perceived Size');
max_reported_angle=max(all_data.Reported_Visual_Angle);
   
for i=nTasks:-1:1
    task_i=find(strcmp(all_data.Task,allTasks(i)))

    real_visual_angle=all_data.Real_Visual_Angle(task_i);
    reported_visual_angle=all_data.Reported_Visual_Angle(task_i);
    distance=all_data.Distance(task_i);
    markercolors=subjectcolor(task_i, :);  
    if i==2
        sb=1;
    else
        sb=2;
    end
    disp(allTasks(i))
    lmeData=all_data(task_i,:);
    
    lme_by_angle = fitlme(lmeData,'Reported_Visual_Angle~Real_Visual_Angle-1  + (Real_Visual_Angle-1|ID)');

  
    mean_slope=lme_by_angle.Coefficients.Estimate;
    pval=lme_by_angle.Coefficients.pValue;
    lower_slope=lme_by_angle.Coefficients.Lower;
    upper_slope=lme_by_angle.Coefficients.Upper;
    xvectoru= [0:max_reported_angle];
    xvectord= [max_reported_angle:-1:0];
    yvector1=lower_slope*xvectoru;
    yvector2=upper_slope*xvectord;
    xvector=[xvectoru xvectord];
    yvector=[yvector1 yvector2];

    subplot(2,2,sb); hold on
     
    plot (0:max_reported_angle, 0:max_reported_angle,'k:','LineWidth',1);
    plot (xvector, mean_slope*xvector,'k-','LineWidth',3);
    scatter(all_data.Real_Visual_Angle,all_data.Reported_Visual_Angle,markerScale,subjectcolor,'.');
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
  
    axis('equal')
    axis([0 max_reported_angle+1 0 max_reported_angle+1]); 
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Reported Visual Angle (degree)')
    titlestr=sprintf('%s: slope=%5.2f, main effect p=%5.2e',string(allTasks(i)),mean_slope,pval);
    title(titlestr)
   
    set(gca,'FontSize',14)
    
    if saveLME
        if i==1
            lme_by_angle_adjusted = lme_by_angle;
             diary('lme_size_by_angle_adjusted.txt')
             lme_by_angle_adjusted
             diary off
        else
            lme_by_angle_estimated=lme_by_angle;
            diary('lme_size_by_angle_estimated.txt')
            lme_by_angle_estimated
            diary off
        end
    end

    if i==2
        sb=3;
    else
        sb=4;
    end
    
    lme_by_distance= fitlme(all_data(task_i,:),'Reported_Visual_Angle~Distance  + (Distance|ID)');
    % lme_by_distanceNobject= fitlme(all_data(task_i,:),'Reported_Visual_Angle~Distance*Object  + (Distance*Object|ID)');
    % 
    if saveLME
        if i==1
            lme_by_distance_adjusted=lme_by_distance;
            diary('lme_size_by_distance_adjusted.txt');
            lme_by_distance_adjusted
            diary off

        %     lme_size_by_distanceNobject_adjusted=lme_by_distanceNobject;
        %     diary('lme_size_by_distanceNobject_adjusted.txt');
        %     lme_size_by_distanceNobject_adjusted
        %     diary off
        % else
            lme_by_distance_estimated=lme_by_distance;
            diary('lme_size_by_distance_estimated.txt');
            lme_by_distance_estimated
            diary off

            % lme_size_by_distanceNobject_estimated=lme_by_distanceNobject;
            % diary('lme_size_by_distanceNobject_estimated.txt');
            % lme_size_by_distanceNobject_estimated
            % diary off
        end
    end
    % mean_i=lme_by_distanceNobject.Coefficients(1,:).Estimate;
    % mean_il=lme_by_distanceNobject.Coefficients(1,:).Lower;
    % mean_iu=lme_by_distanceNobject.Coefficients(1,:).Upper;
    % 
    % pole_i= mean_i+lme_by_distanceNobject.Coefficients(2,:).Estimate;
    % poleu= mean_i+lme_by_distanceNobject.Coefficients(2,:).Upper;
    % polel= mean_i+lme_by_distanceNobject.Coefficients(2,:).Lower;
    % 
    % mean_slope=lme_by_distanceNobject.Coefficients(4,:).Estimate;
    % mean_slope_l=lme_by_distanceNobject.Coefficients(4,:).Lower;
    % mean_slope_u=lme_by_distanceNobject.Coefficients(4,:).Upper;
    % 
    % mean_pole_slope=lme_by_distanceNobject.Coefficients(5,:).Estimate;
    % mean_pole_slope_l=lme_by_distanceNobject.Coefficients(5,:).Lower;
    % mean_pole_slope_u=lme_by_distanceNobject.Coefficients(5,:).Upper;
    % 
    % pval1=lme_by_distanceNobject.Coefficients(2,:).pValue;
    % pval2=lme_by_distanceNobject.Coefficients(5,:).pValue;
    % 

    % xvectoru= [0:max(distance)];
    % xvectord= [max(distance):-1:0];
    % yvector1=mean_il+mean_slope_l*xvectoru;
    % yvector2=mean_iu+mean_slope_u*xvectord;
    % pole1=polel+mean_pole_slope_l*xvectoru;
    % pole2=poleu+mean_pole_slope_u*xvectord;
    %
    %     lower_i=lme_by_distance.Coefficients(1,:).Lower;
    %     lower_slope=lme_by_distance.Coefficients(2,:).Lower;
    %     upper_i=lme_by_distance.Coefficients(1,:).Upper;
    %     upper_slope=lme_by_distance.Coefficients(2,:).Upper;
    %    
    %     yvector1=lower_i+lower_slope*xvectoru;
    %     yvector2=upper_i+upper_slope*xvectord;
    
    xvector=[xvectoru xvectord];
    yvector=[yvector1 yvector2];
    % ypole=[pole1 pole2];
    % 
    subplot(2,2,sb); hold on
    plot(xvector, mean_i+mean_slope*xvector,'k-','LineWidth',3);
    plot(xvector, pole_i+mean_pole_slope*xvector,'k-','LineWidth',3);
     for no=i:nObjects       
       ploti=find(strcmp(all_data.Task,allTasks(i)) & strcmp(all_data.Object,uniqueObject(no)));
        if no==1
                scatter(all_data.Distance(ploti),all_data.Reported_Visual_Angle(ploti),markerScale*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'*');
        elseif no==2
                scatter(all_data.Distance(ploti),all_data.Reported_Visual_Angle(ploti),markerScale*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'o');
    
        else
          scatter(all_data.Distance(ploti),all_data.Reported_Visual_Angle(ploti),markerScale*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'square');
        end
    
    end
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
    fill(xvector, ypole, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);

    axis([0 max(distance) 0 max_reported_angle+1]); axis('square')
    xlabel ('Distance (m)')
    ylabel ('Reported Visual Angle (degree)')
    titlestr=sprintf('%s: \n main effect:%5.4f p=%5.2e \n interaction:%5.4f p=%5.2e',string(allTasks(i)),mean_slope,pval1,mean_pole_slope ,pval2);
    title(titlestr)
    set(gca,'FontSize',14)
   
    
end

saveas(fig1,'PerceivedSize_quad_task.png')


%% Magnification
% perceived angle by visual angle, task, distance
% plot
fig2=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .8 .8],'Name','Magnification');
max_mag=max(all_data.Ratio_Visual_Angle);
max_visual_angle=max(all_data.Real_Visual_Angle)+1;   
for i=nTasks:-1:1
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    real_visual_angle=all_data.Real_Visual_Angle(task_i);
    ratio_visual_angle=all_data.Ratio_Visual_Angle(task_i);
    distance=all_data.Distance(task_i);
    markercolors=subjectcolor(task_i, :);
    disp(allTasks(i))
    % analysis by real visual angle
    lme_mag_by_angle = fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Real_Visual_Angle  + (Real_Visual_Angle|ID)');
    if saveLME
        if i==1
             lme_mag_by_angle_adjusted = lme_mag_by_angle;
             diary('lme_mag_by_angle_adjusted.txt')
             lme_mag_by_angle_adjusted
             diary off
        else
            lme_mag_by_angle_estimated=lme_mag_by_angle;
            diary('lme_mag_by_angle_estimated.txt')
            lme_mag_by_angle_estimated
            diary off
        end
    end
   
    % use LME coefficients to draw fixed effects and confidence intervals
    mean_mag_i=lme_mag_by_angle.Coefficients(1,:).Estimate;
    lower_mag_i=lme_mag_by_angle.Coefficients(1,:).Lower;
    upper_mag_i=lme_mag_by_angle.Coefficients(1,:).Upper;

    mean_mag_slope=lme_mag_by_angle.Coefficients(2,:).Estimate;
    mag_pval=lme_mag_by_angle.Coefficients(2,:).pValue;
    lower_mag_slope=lme_mag_by_angle.Coefficients(2,:).Lower;
    upper_mag_slope=lme_mag_by_angle.Coefficients(2,:).Upper;


    xvectoru= [0:max_visual_angle];
    xvectord= [max_visual_angle:-1:0];
    yvector1=lower_mag_i+lower_mag_slope*xvectoru;
    yvector2=upper_mag_i+upper_mag_slope*xvectord;
    xvector=[xvectoru xvectord];
    yvector=[yvector1 yvector2];

    if i==2
        sb=1;
    else
        sb=3;
    end

    subplot(2,2,sb); hold on
    plot(xvector, mean_mag_i+mean_mag_slope*xvector,'k-','LineWidth',3); % fixed effects
    % make different marker per object type
    for no=i:nObjects       
       ploti=find(strcmp(all_data.Task,allTasks(i)) & strcmp(all_data.Object,uniqueObject(no)));
        if no==1
            scatter(all_data.Real_Visual_Angle(ploti),all_data.Ratio_Visual_Angle(ploti),markerScale*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'o');
        elseif no==2
                scatter(all_data.Real_Visual_Angle(ploti),all_data.Ratio_Visual_Angle(ploti),10*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'*');
    
        else
          scatter(all_data.Real_Visual_Angle(ploti),all_data.Ratio_Visual_Angle(ploti),30*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'square');
        end
    
    end
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1); % confidence intervals
    axis([0 max_visual_angle+1 0 max_mag+1]); 
    xlabel ('Real Visual Angle (degree)')
    ylabel ('Magnification (Reported/Real)')
    titlestr=sprintf('%s\n intercept=%5.2f, slope=%5.2f, p=%5.2e',string(allTasks(i)),mean_mag_i, mean_mag_slope,mag_pval);
    title(titlestr)
    set(gca,'FontSize',14)
   

    if i==2
        sb=2;
    else
        sb=4;
    end
    
    % analysis by distance
    lme_mag_by_distance= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Distance+ (Distance|ID)');
  
    if saveLME
        if i==1
            lme_mag_by_distance_adjusted=lme_mag_by_distance;
            diary('lme_mag_by_distance_adjusted.txt');
            lme_mag_by_distance_adjusted
            diary off
          
        else
            lme_mag_by_distance_estimated=lme_mag_by_distance;
            diary('lme_size_by_distance_estimated.txt');
            lme_mag_by_distance_estimated
            diary off
        end
    end
    mean_i=lme_mag_by_distance.Coefficients(1,:).Estimate;
    mean_i_l=lme_mag_by_distance.Coefficients(1,:).Lower;
    mean_i_u=lme_mag_by_distance.Coefficients(1,:).Upper;
    
    mean_slope=lme_mag_by_distance.Coefficients(2,:).Estimate;
    mean_slope_l=lme_mag_by_distance.Coefficients(2,:).Lower;
    mean_slope_u=lme_mag_by_distance.Coefficients(2,:).Upper;
   
    pval=lme_mag_by_distance.Coefficients(2,:).pValue;
   

    xvectoru=[0:max(distance)+5];
    xvectord=[max(distance)+5:-1:0];
    yvector1=mean_i_l+mean_slope_l*xvectoru;
    yvector2=mean_i_u+mean_slope_u*xvectord;
     
    xvector=[xvectoru xvectord];
    yvector=[yvector1 yvector2];
 
  
    subplot(2,2,sb); hold on
    plot(xvector, mean_i+mean_slope*xvector,'k-','LineWidth',3);
    for no=i:nObjects       
       ploti=find(strcmp(all_data.Task,allTasks(i)) & strcmp(all_data.Object,uniqueObject(no)));
        if no==1
            scatter(all_data.Distance(ploti),all_data.Ratio_Visual_Angle(ploti),markerScale*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'o');
        elseif no==2
                scatter(all_data.Distance(ploti),all_data.Ratio_Visual_Angle(ploti),10*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'*');
    
        else
          scatter(all_data.Distance(ploti),all_data.Ratio_Visual_Angle(ploti),30*all_data.Ratio_Visual_Angle(ploti),subjectcolor(ploti,:),'square');
        end
    
    end
    fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.1);
   
    axis([0 max(distance)+5 0 max_mag+1 ]);
    xlabel ('Distance (m)')
    ylabel ('Magnification (Reported/Real)')
    titlestr=sprintf('%s \n intercept=%4.2f, slope=%5.4f, p=%5.4e',string(allTasks(i)),mean_i, mean_slope,pval);
    title(titlestr)
    set(gca,'FontSize',14)
   
    
end

saveas(fig2,'Magnification_quad_task.png')

%% Magnification
% stats for perceived angle by visual angle and distance for each task
for i=nTasks:-1:1
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    real_visual_angle=all_data.Real_Visual_Angle(task_i);
    ratio_visual_angle=all_data.Ratio_Visual_Angle(task_i);
    distance=all_data.Distance(task_i); 

    lme_mag_by_distanceNangle=fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Real_Visual_Angle*Distance + (Real_Visual_Angle*Distance|ID)');
  
    if i==1 
          lme_mag_by_distanceNangle_adjusted=lme_mag_by_distanceNangle;  
    else
          lme_mag_by_distanceNangle_estimated=lme_mag_by_distanceNangle;
          
    end 
end

% junk

%     % analysis by distance
%     lme_mag_by_distance= fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Distance  + (Distance|ID)');
%     lme_mag_by_distanceNobject=fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Distance*Object  + (Distance*Object|ID)');
%   
%     if saveLME
%         if i==1
%             lme_mag_by_distance_adjusted=lme_by_distance;
%             diary('lme_mag_by_distance_adjusted.txt');
%             lme_mag_by_distance_adjusted
%             diary off
%             
%             lme_mag_by_distanceNobject_adjusted=lme_by_distanceNobject;
%             diary('lme_mag_by_distanceNobject_adjusted.txt');
%             lme_mag_by_distanceNobject_adjusted
%             diary off
%         else
%             lme_mag_by_distance_estimated=lme_by_distance;
%             diary('lme_size_by_distance_estimated.txt');
%             lme_mag_by_distance_estimated
%             diary off
% 
%             lme_mag_by_distanceNobject_estimated=lme_by_distanceNobject;
%             diary('lme_mag_by_distanceNobject_estimate.txt');
%             lme_mag_by_distanceNobject_estimated
%             diary off
%         end
%     end
%     mean_i=lme_mag_by_distanceNobject.Coefficients(1,:).Estimate;
%     mean_il=lme_mag_by_distanceNobject.Coefficients(1,:).Lower;
%     mean_iu=lme_mag_by_distanceNobject.Coefficients(1,:).Upper;
%     
%     pole_i= mean_i+lme_mag_by_distanceNobject.Coefficients(2,:).Estimate;
%     poleu= mean_i+lme_mag_by_distanceNobject.Coefficients(2,:).Upper;
%     polel= mean_i+lme_mag_by_distanceNobject.Coefficients(2,:).Lower;
%    
%     mean_slope=lme_mag_by_distanceNobject.Coefficients(4,:).Estimate;
%     mean_slope_l=lme_mag_by_distanceNobject.Coefficients(4,:).Lower;
%     mean_slope_u=lme_mag_by_distanceNobject.Coefficients(4,:).Upper;
%    
%     mean_pole_slope=lme_mag_by_distanceNobject.Coefficients(5,:).Estimate;
%     mean_pole_slope_l=lme_mag_by_distanceNobject.Coefficients(5,:).Lower;
%     mean_pole_slope_u=lme_mag_by_distanceNobject.Coefficients(5,:).Upper;
%   
%     pval1=lme_mag_by_distanceNobject.Coefficients(2,:).pValue;
%     pval2=lme_mag_by_distanceNobject.Coefficients(5,:).pValue;
%   
% 
%     xvectoru= [0:max(distance)];
%     xvectord= [max(distance):-1:0];
%     yvector1=mean_il+mean_slope_l*xvectoru;
%     yvector2=mean_iu+mean_slope_u*xvectord;
%     pole1=polel+mean_pole_slope_l*xvectoru;
%     pole2=poleu+mean_pole_slope_u*xvectord;
%     %
%     %     lower_i=lme_by_distance.Coefficients(1,:).Lower;
%     %     lower_slope=lme_by_distance.Coefficients(2,:).Lower;
%     %     upper_i=lme_by_distance.Coefficients(1,:).Upper;
%     %     upper_slope=lme_by_distance.Coefficients(2,:).Upper;
%     %    
%     %     yvector1=lower_i+lower_slope*xvectoru;
%     %     yvector2=upper_i+upper_slope*xvectord;
%     
%     xvector=[xvectoru xvectord];
%     yvector=[yvector1 yvector2];
%     ypole=[pole1 pole2];