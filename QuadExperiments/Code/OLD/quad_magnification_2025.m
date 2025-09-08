
dataDir='/Users/kalanit/Projects/PerceptualMagnification/2024Results/'
cd(dataDir)
datafile="all_data_long_withobject.csv";
all_data=readtable(datafile);
% load all_quad_data_analysed.mat
%disp(all_data.Properties.VariableNames)
allTasks =unique(all_data.Task);
nTasks=length(allTasks);
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);
uniqueObject=unique(all_data.Object)
nObjects=length(uniqueObject)
saveLME=1;


%% Magnification
% perceived angle by visual angle and distance for each task
% stats for magnification for each task using factors of visual angle,distance, object 
for i=nTasks:-1:1
    task_i=find(strcmp(all_data.Task,allTasks(i)));
    real_visual_angle=all_data.Real_Visual_Angle(task_i);
    ratio_visual_angle=all_data.Ratio_Visual_Angle(task_i);
    distance=all_data.DistanceM(task_i); 

    lme_mag_by_distanceNangle=fitlme(all_data(task_i,:),'Ratio_Visual_Angle~Real_Visual_Angle*DistanceM + (Real_Visual_Angle*DistanceM|ID)');
  
    if i==1 
          lme_mag_by_distanceNangle_adjusted=lme_mag_by_distanceNangle;  
    else
          lme_mag_by_distanceNangle_estimated=lme_mag_by_distanceNangle;
          
    end 
end

%%
[betaAdjusted,betanamesAdjusted,statsAdjusted] = fixedEffects(lme_mag_by_distanceNangle_adjusted);
[betaREAdjusted,betanamesREAdjusted,statsREAdjusted] = randomEffects(lme_mag_by_distanceNangle_adjusted);

[betaEstimated,betanamesEstimated,statEstimated] = fixedEffects(lme_mag_by_distanceNangle_estimated);
[betaREEstimated,betaREnamesEstimated,statREEstimated] = randomEffects(lme_mag_by_distanceNangle_estimated);

%%

% make predictions
maxangle=7; nsteps=10; maxdistance=69;
new_visual_angles=[0.1:.1:maxangle]';[lv cv]=size(new_visual_angles);
new_distances=[0:1:maxdistance]';[ld cv]=size(new_distances);
vA=repmat(new_visual_angles, ld,1);
dist=repmat(new_distances, lv, 1);
dc=ones(size(vA));
Xnew=[ dc vA dist vA.*dist ];
predictedEstimatedmag=Xnew*betaEstimated;
predictedEstimatedmag=reshape(predictedEstimatedmag,ld,lv);
predictedAdjustedmag=Xnew*betaAdjusted;
predictedAdjustedmag=reshape(predictedAdjustedmag,ld,lv);

minmag=min([ min(min(predictedAdjustedmag)) min(min(predictedEstimatedmag))])
maxmag=max([ max(max(predictedAdjustedmag)) max(max(predictedEstimatedmag))])

figure('color',[1 1 1],'Name','predicted magnification')
subplot(1,2,1)
% surf(predictedEstimatedmag);
% set(gca,'Zlim', [ 0 max(max(predictedEstimatedmag))]);
imagesc(predictedEstimatedmag);
colorbar; clim([minmag maxmag]);
set(gca,'Xtick',[1:lv/nsteps:lv],'XtickLabel',[0:maxangle/nsteps: maxangle]);
set(gca,'Ytick',[1:ld/nsteps:ld],'YtickLabel',[0:maxdistance/nsteps: maxdistance]);

xlabel('visual angle (degrees)'); ylabel('distance (m)');
title ('Estimated: predicted magnification')
set(gca,'FontSize',12);

subplot(1,2,2)
% surf(predictedAdjustedmag);colorbar;
% set(gca,'Zlim', [ 0 max(max(predictedEstimatedmag))]);
imagesc(predictedAdjustedmag);
colorbar; clim([minmag maxmag])
set(gca,'Xtick',[1:lv/nsteps:lv],'XtickLabel',[0:maxangle/nsteps: maxangle]);
set(gca,'Ytick',[1:ld/nsteps:ld],'YtickLabel',[0:maxdistance/nsteps: maxdistance]);

xlabel('visual angle (degrees)'); ylabel('distance (m)');
title ('Adjusted: predicted magnification')
set(gca,'FontSize',12);

