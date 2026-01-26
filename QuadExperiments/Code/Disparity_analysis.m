clx
%% load data
load_all_quad_data_2025
savedir=fullfile('Results',basename)
if ~exist(savedir,'dir')
    !mkdir savedir
end

%%
first=1; % if this is first pass need to create table that only contains subjects with disparity data and calcuates mean and adjusted disparity
if first
    % calculate mean disparity and adjusted disparity to the table and save new disparity file
    % calculate mean disparity
    idx=find(~isnan(all_data.Disparity_VA_1)); % find all subjects that belong to the disparity experiment 
    all_data=all_data(idx,:);

    all_data.Disparity_VA_mean=nanmean([all_data.Disparity_VA_1, all_data.Disparity_VA_2]')'; % mean disparity
    
    % load Quad ground truth data
    groundTruthDataFile = fullfile(expDir, 'Data', 'QuadGroundTruthInformation.csv');
    groundTruthData=readtable(groundTruthDataFile);
    % addvisualangle for width and resave table
    
    width=groundTruthData.Width_m;
    distance=groundTruthData.Distance_m;
    for i=1:length(width)
        groundTruthData.Width_degrees(i) = visualangle(width(i),distance(i));
    end
    writetable(groundTruthData,groundTruthDataFile);
    
    uniqueObject=unique(groundTruthData.ObjectName);
    nObjects=length(uniqueObject);
    all_data.Disparity_VA_mean_adjusted=all_data.Disparity_VA_mean;% initalize with original value
    all_data.Disparity_VA_1_adjusted=all_data.Disparity_VA_1; %
    idx2=find(~isnan(all_data.Disparity_VA_2)); % some participants do not have second disparity measurement
    all_data.Disparity_VA_2_adjusted(idx2)=all_data.Disparity_VA_2(idx2);
    % adjust by removing object width visual angle for each measurement
    for obj=1:nObjects
        obj_i=find(contains(all_data.Measurement,uniqueObject(obj)));
        groundTruth_index=find(strcmp(groundTruthData.ObjectName,uniqueObject(obj)));


        object_Width_degrees=groundTruthData.Width_degrees(groundTruth_index);
        fprintf(1,' %s: width %2f \n',       uniqueObject{obj}, object_Width_degrees);
        if strcmp( uniqueObject{obj},'Spikeball')
           disp(all_data.Disparity_VA_mean_adjusted(obj_i),all_data.Disparity_VA_mean(obj_i))
        end
        all_data.Disparity_VA_1_adjusted(obj_i)=all_data.Disparity_VA_1_adjusted(obj_i)-object_Width_degrees;
        all_data.Disparity_VA_2_adjusted(obj_i)=all_data.Disparity_VA_2_adjusted(obj_i)-object_Width_degrees;
        all_data.Disparity_VA_mean_adjusted(obj_i)=all_data.Disparity_VA_mean_adjusted(obj_i)-object_Width_degrees;
    end
    % save disparity_data
    expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
    cd(expDir)
    
    writefile=fullfile(expDir,'Data',['disparity_' csvfile]);
    writetable(all_data,writefile);
else % if disparity file exist can just load it

    expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
    cd(expDir)
    readfile=fullfile(expDir,'Data',['disparity_' csvfile]);
    all_data=readtable(readfile);
end

%% plot disparity vs distance
uniqueTasks=unique(all_data.Task)
ntasks=length(uniqueTasks)
onlynewversion=1;
saveLMEfiltered_data=1;

%for i=ntasks:-1:1
task='Perceptual'; % There is only disparity for the perceptual taskfilt
filtered_data=all_data;
filtered_data=filtered_data(contains(filtered_data.Task,task),:) % and perceptual task
% onlynewversion from July 2025
removeOutlier=0;
if removeOutlier
    ii=find(filtered_data.Disparity_VA_mean_adjusted ==max( filtered_data.Disparity_VA_mean_adjusted))
    idx=find(filtered_data.ID~=filtered_data.ID(ii));
    filtered_data=filtered_data(idx,:);
end


if onlynewversion
    % now filter the data to include just the new objects
    ball_idx = contains(filtered_data.Measurement, 'Ball');
    lamp5_idx = contains(filtered_data.Measurement, 'Lamp5');
    lamp6_idx = contains(filtered_data.Measurement, 'Lamp6');
    lamp7_idx = contains(filtered_data.Measurement, 'Lamp7');
    stick5b_idx=contains(filtered_data.Measurement, 'Stick5b');
    stick7_idx=contains(filtered_data.Measurement, 'Stick7');
    stick8_idx=contains(filtered_data.Measurement, 'Stick8');
    stick9_idx=contains(filtered_data.Measurement, 'Stick9');
       
    % Combine all conditions with logical 
    combined_idx = ball_idx | lamp5_idx | lamp6_idx | lamp7_idx | stick5b_idx | stick7_idx| stick8_idx | stick9_idx;
    
    % Filter the table using the combined index
    filtered_data = filtered_data(combined_idx, :);
    
    % Display the number of rows in the filtered table
    disp(['Number of rows after filtering: ', num2str(height(filtered_data))]);
    
    % Display the first few rows of the filtered table
    head(filtered_data);
    filtered_data.logDisparity_VA_mean_adjusted=log2(filtered_data.Disparity_VA_mean_adjusted);
    filtered_data.logDistance=log2(filtered_data.Distance);
end 

% test if there is a linear relation between disparity and distance 
% here the model allows each subject to have a different intercept and all
% subjects have same slope
% if you want to do random intercept and slope model will change to 
% lmeDvD = fitlme(all_data, 'Disparity_VA ~ Distance + (Distance|ID)'); 
%

% random intercepts model
lmeDisparity_mean_adjustedvDistance = fitlme(filtered_data, 'Disparity_VA_mean_adjusted ~ Distance + (1|ID)'); 
 % random slopes model
lmeRS_Disparity_mean_adjustedvDistance = fitlme(filtered_data, 'Disparity_VA_mean_adjusted ~ Distance + (Distance|ID)'); 

% log model
lmelogDisparity_mean_adjustedvlogDistance = fitlme(filtered_data, 'logDisparity_VA_mean_adjusted ~ logDistance + (1|ID)'); 

% original disparity
lmeDisparity_mean_vDistance = fitlme(filtered_data, 'Disparity_VA_mean ~ Distance + (1|ID)'); 
% 
if saveLMEfiltered_data
    if removeOutlier
         savelmefile=fullfile('.',savedir, [basename '_' task 'outlierRemoved_lme_Disparity_vs_Distance.txt']);
    else
        savelmefile=fullfile('.',savedir, [basename '_' task '_lme_Disparity_vs_Distance.txt']);
    end

    diary(savelmefile)
    fprintf(1,'Adusted Disparity vs Distance \n') 
    lmeDisparity_mean_adjustedvDistance 
    lmeRS_Disparity_mean_adjustedvDistance
    fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
    compare(lmeDisparity_mean_adjustedvDistance,lmeRS_Disparity_mean_adjustedvDistance)
    fprintf(1,'log2(Adusted Disparity) vs log2(Distance) \n') 
    lmelogDisparity_mean_adjustedvlogDistance 
    fprintf(1,'compare log to linear model \n') 
    compare(lmeDisparity_mean_adjustedvDistance,lmelogDisparity_mean_adjustedvlogDistance)
    diary off
end


% log model best based on state
% as lmeRSDvD we will get the slopes and intercepts from lmelogDisparity_mean_adjustedvlogDistance
[reEfx,reNames,reStats] = randomEffects(lmelogDisparity_mean_adjustedvlogDistance );
[feEfx,feNames,festats] =fixedEffects(lmelogDisparity_mean_adjustedvlogDistance );

ID=filtered_data.ID;
uniqueID=unique(ID);
nsubjects=length(uniqueID);
individualIntercepts = zeros(nsubjects,1);

for i = 1:nsubjects
    % Indices for this subject's random effects
    subjectRows = find(strcmp(reNames.Level, num2str(uniqueID(i)))); % use random interscept model
    individualIntercepts(i) = feEfx(1) + reEfx(subjectRows(1)); % all subjects have the same slope
    individualSlopes(i)    = feEfx(2) ;
end
% sort by intercepts
[sorted_individualIntercepts, sorted_idx] = sort(individualIntercepts);

% set colormap
clear subjectcolor;
cmap=jet(nsubjects);
for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=cmap(sorted_cindex,:);
end

%%
%%
fh=figure ('Color',[ 1 1 1],'Name', [basename '_Disparity vs Distance'], 'Units','normalized','Position', [0 0 1 1]);
% plot log disparity vs. log distance


% range of distance (log2values)
xvector=linspace(min(filtered_data.logDistance)*.9, max(filtered_data.logDistance)*1.1,10); % log scale
xdistances=2.^xvector; % linear scale

%linear scale original, non adjusted data
subplot (1,3,1)
hold on;

% show individual data
scatter(filtered_data.Distance, filtered_data.Disparity_VA_mean, markerScale,subjectcolor,'o','filled');

[reEfxO,reNamesO,reStatsO] = randomEffects(lmeDisparity_mean_vDistance );
[feEfxO,feNamesO,festatsO] =fixedEffects(lmeDisparity_mean_vDistance );

% plot fixed effect on linear scale
y_fit=feEfxO(1)+feEfxO(2)*xdistances;
plot( xdistances, y_fit, 'k-','LineWidth',5);
set(gca,'Fontsize',18,'FontName','Avenir')
xlim([0 maxDistance]);
ylim([0 maxDisparity]);
xlabel('Distance [m] ');
ylabel(' Mean Disparity [deg]');
 titlestr=sprintf(['Disparity=%.2f+%.3f*Distance \n p=%5.2e n=%d'],...
    feEfxO(1), feEfxO(2),festatsO.pValue(2), length(unique(ID)));
title(titlestr)


  %  linear scale adjusted disparity with log fit
subplot (1,3,2)
hold on;

 % show individual data
scatter(filtered_data.Distance, filtered_data.Disparity_VA_mean_adjusted, markerScale,subjectcolor,'o','filled');
[reEfxA,reNamesA,reStatsA] = randomEffects(lmeDisparity_mean_adjustedvDistance  );
[feEfxA,feNamesA,festatsA] =fixedEffects(lmeDisparity_mean_adjustedvDistance );

% plot fixed effect on linear scale
y_fit=feEfxA(1)+feEfxA(2)*xdistances;
plot(xdistances, y_fit, 'k-','LineWidth',5);

set(gca,'Fontsize',18,'FontName','Avenir')
xlim([0 maxDistance]);
ylim([0 maxDisparity]);
xlabel('Distance [m] ');
ylabel('Adjusted Mean Disparity [deg]');
if festats.pValue(2)<.01
 titlestr=sprintf(['Disparity=%.2f+%.3f*Distance \n p=%5.2e n=%d'],...
    feEfxA(1), feEfxA(2),festatsA.pValue(2), length(unique(ID)));
else
     titlestr=sprintf(['Disparity=%.2f+%.3f*Distance \n p=%.2f n=%d'],...
    feEfxA(1), feEfxA(2),festatsA.pValue(2), length(unique(ID)));
end
title(titlestr)



 %  log scale adjusted disparity vs log distance
subplot (1,3,3)
hold on;

% show individual data
scatter(filtered_data.logDistance, filtered_data.logDisparity_VA_mean_adjusted, markerScale,subjectcolor,'o','filled');

% plot fixed effect
y_fit =feEfx(1)+feEfx(2)*xvector;
plot(xvector, y_fit, 'k-','LineWidth',5);
set(gca,'Fontsize',18,'FontName','Avenir')
set(gca,'XTick',xvector)
set(gca,'XTickLabel',round(2.^xvector,1));
yticks=get(gca,'YTick');
set(gca,'YTickLabel',round(2.^yticks,1));
xlabel('Distance [m], log scale');
ylabel('Adjusted Mean Disparity [deg], log scale');
if festats.pValue(2)<.01
 titlestr=sprintf(['log2disparity vs log2(distance) \n slope=%.3f, p=%5.2e n=%d'],...
    feEfx(2),festats.pValue(2), length(unique(ID)));
else
     titlestr=sprintf(['Disparity=%.2f*Distance^{%.3f} \n p=%.2f n=%d'],...
    2^feEfx(1), feEfx(2),festats.pValue(2), length(unique(ID)));
end


 title(titlestr)


if removeOutlier
    filenamePNG=fullfile('.',savedir,[basename,'_outlierRemoved_disparity_vs_distance', num2str(length(unique(ID))),'.png']);
    exportgraphics(fh,filenamePNG,'Resolution',600);
else
    filenamePNG=fullfile('.',savedir,[basename,'_disparity_vs_distance', num2str(length(unique(ID))),'.png']);
    exportgraphics(fh,filenamePNG,'Resolution',600);
end
  
%end
%     % 
%     % % plot perceptual magnification vs distance on subjects in the disparity experiment
%     % 
%     % lmePMvDistance = fitlme(filtered_data, 'Ratio_Visual_Angle ~ Distance + (1|ID)');
%     % disp(lmePMvDistance)
%     % if saveLME
%     %     savelmefile=fullfile('.',savedir, [basename '_lme_Quad_PM_vs_Distance.txt']);
%     %     diary(savelmefile)
%     %     lmePMvDistance
%     %     diary off
%     % end
% 
%     % intercept= lmePMvDistance.Coefficients.Estimate(1);
%     % slope=lmePMvDistance.Coefficients.Estimate(2);
%     % slope_pval=lmePMvDistance.Coefficients.pValue(2);
%     % nsubjects=num2str(length(unique(ID)));
%     % 
%     % % perhaps can do nicer color coding of the subjects
% 
%     % 
%     % %fh=figure ('Color',[ 1 1 1],'Name', 'Perceptual Magnification vs Distance' ,'Units','normalized','Position', [0 0 .5 1]);
%     % subplot(1,3,2) 
%     % hold on;
%     % scatter(filtered_data.Distance, filtered_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
%     % xvector=linspace(min(filtered_data.Distance), max(filtered_data.Distance),10);
%     % y_fit =lmePMvDistance.Coefficients.Estimate(1)+lmePMvDistance.Coefficients.Estimate(2)*xvector;
%     % plot(xvector, y_fit, 'k-','LineWidth',3);
%     % yline(1,'-','Linewidth',2,'Color',[ .8 .8 .8])
%     % ylabel('Perceptual Magnification');
%     % xlabel('Distance [m]');
%     % ylim([0 maxRatio])
%     % set(gca,'Fontsize',18,'FontName','Avenir')
%     % if lmePMvDistance.Coefficients.pValue(2)<0.01
%     %     titlestr=sprintf(['%s PM vs distance \n intercept=%5.2f slope=%5.2f, p=%.3f \n n=%d'],...
%     %         task, lmePMvDistance.Coefficients.Estimate(1),lmePMvDistance.Coefficients.Estimate(2),lmePMvDistance.Coefficients.pValue(2), length(unique(ID)));
%     % else
%     %      titlestr=sprintf(['%s PM vs distance \n intercept=%5.2f slope=%5.2f, p=%.3e \n n=%d'],...
%     %         task, lmePMvDistance.Coefficients.Estimate(1),lmePMvDistance.Coefficients.Estimate(2),lmePMvDistance.Coefficients.pValue(2), length(unique(ID)));
%     % 
%     % end
%     % title(titlestr,'Fontsize',18)
%     % 
%     % subplot(1,3,3)
%     % hold on
%     % lmePMvDisparity = fitlme(filtered_data, 'Ratio_Visual_Angle ~ Disparity_VA + (1|ID)');
%     % disp(lmePMvDisparity)
%     % if saveLME
%     %     savelmefile=fullfile('.',savedir, [basename '_lme_Quad_PM_vs_Disparity.txt']);
%     %     diary(savelmefile)
%     %     lmePMvDisparity
%     %     diary off
%     % end
%     % intercept= lmePMvDisparity.Coefficients.Estimate(1);
%     % slope=lmePMvDisparity.Coefficients.Estimate(2);
%     % slope_pval=lmePMvDisparity.Coefficients.pValue(2);
%     % nsubjects=num2str(length(unique(ID)));
%     % 
%     % scatter(filtered_data.Disparity_VA, filtered_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
%     % xvector=linspace(min(filtered_data.Disparity_VA), max(filtered_data.Disparity_VA),10);
%     % y_fit =lmePMvDisparity.Coefficients.Estimate(1)+lmePMvDisparity.Coefficients.Estimate(2)*xvector;
%     % plot(xvector, y_fit, 'k-','LineWidth',3);
%     % yline(1,'-','Linewidth',2,'Color',[ .8 .8 .8])
%     % ylabel('Perceptual Magnification');
%     % xlabel('Disparity[degrees]');
%     % ylim([0 maxRatio])
%     % set(gca,'Fontsize',18,'FontName','Avenir')
%     % titlestr=sprintf(['%s PM vs disparity \n intercept=%5.2f slope=%5.2f, p=%.3f \n n=%d'],...
%     %    task, lmePMvDisparity.Coefficients.Estimate(1),lmePMvDisparity.Coefficients.Estimate(2),lmePMvDisparity.Coefficients.pValue(2), length(unique(ID)));
%     % 
%     % % title(titlestr,'Fontsize',18)
%     % filenamePNG=fullfile('.',savedir,[basename,'_PM_vs_distance', num2str(length(unique(ID))),'.png']);
%     % exportgraphics(fh,filenamePNG,'Resolution',600);
% end
% 
% 
% %% plot binocular vs monocular magnification vs disparity separately for each lamp as perceptual magnification depends on both distance and visual angle
% 
% % test if there is a linear relation between PM and disparity for each lamp
% idx=find(~isnan(all_data.Disparity_VA)); % find all subjects that belong to the disparity experiment 
% filtered_data=all_data(idx,:);
% 
% % onlynewversion from July 2025
% if onlynewversion
%     % now filter the data to include just the new objects
%     ball_idx = contains(filtered_data.Measurement_Type, 'Ball');
%     lamp5_idx = contains(filtered_data.Measurement_Type, 'Lamp5');
%     lamp6_idx = contains(filtered_data.Measurement_Type, 'Lamp6');
%     lamp7_idx = contains(filtered_data.Measurement_Type, 'Lamp7');
%     stick5b_idx=contains(filtered_data.Measurement_Type, 'Stick5b');
%     stick7_idx=contains(filtered_data.Measurement_Type, 'Stick7');
%     stick8_idx=contains(filtered_data.Measurement_Type, 'Stick8');
%     stick9_idx=contains(filtered_data.Measurement_Type, 'Stick9');
% 
%     % Combine all conditions with logical 
%     combined_idx = ball_idx | lamp5_idx | lamp6_idx | lamp7_idx | stick5b_idx | stick7_idx| stick8_idx | stick9_idx;
% 
%     % Filter the table using the combined index
%     filtered_data = filtered_data(combined_idx, :);
% 
%     % Display the number of rows in the filtered table
%     disp(['Number of rows after filtering: ', num2str(height(filtered_data))]);
% 
%     % Display the first few rows of the filtered table
%     head(filtered_data);
% end
% %%
% uniqueTasks=unique(filtered_data.Task)
% ntasks=length(uniqueTasks)
% 
% for i=ntasks:-1:1
% 
%     fh=figure ('Color',[ 1 1 1],'Units','Norm', 'Position',[ 0 0 1 1],'Name', 'Perceptual Magnification vs Disparity' );
% 
%     % first filter by task
%     task=uniqueTasks{i}
% 
% 
%     % then filter by objects
%     task_data=filtered_data(contains(filtered_data.Task, task), :);
%     uniqueObject=unique(task_data.Measurement_Type);
%     nObjects=length(uniqueObject);
%     if nObjects<=4
%           nrows=1
%           ncols=nObjects;
%     else
%          nrows=ceil(nObjects/4);
%          ncols=4;
%     end
%     for i=1:nObjects
%         %lamp_data=filtered_data(contains(filtered_data.Measurement_Type,uniqueObject(i)),:)
%         lamp_data=task_data(contains(task_data.Measurement_Type,uniqueObject(i)),:)
%         clear subjectcolor
%         ID=lamp_data.ID;
%         for c=1:length(ID)
%          cindex=find(uniqueID==ID(c));
%          subjectcolor(c,:)=cmap(cindex,:);
%         end
% 
%         lmePMvDisparity = fitlme(lamp_data, 'Ratio_Visual_Angle ~ Disparity_VA + (1|ID)');
%         disp(lmePMvDisparity)
% 
%         subplot(nrows,ncols,i)
%         hold on;
%         scatter(lamp_data.Disparity_VA, lamp_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
%         xvector=linspace(min(lamp_data.Disparity_VA), max(lamp_data.Disparity_VA),10);
%         y_fit =lmePMvDisparity.Coefficients.Estimate(1)+lmePMvDisparity.Coefficients.Estimate(2)*xvector;
% 
%         plot(xvector, y_fit, 'k-','LineWidth',3);
%         ylabel('Perceptual Magnification');
%         xlabel('Disparity [deg]');
%         ylim([0 maxRatio])
%         set(gca,'Fontsize',8,'FontName','Avenir')
%         titlestr=sprintf(['PM vs disparity \n' ...
%             '%s\n intercept=%5.2f slope=%5.2f\n p=%5.4f\n n=%d'],...
%             string(uniqueObject(i)),lmePMvDisparity.Coefficients.Estimate(1),lmePMvDisparity.Coefficients.Estimate(2),lmePMvDisparity.Coefficients.pValue(2), length(unique(ID)));
%         % remove '_'
%         titlestr = strrep(titlestr, '_', '');
%         title(titlestr)
%     end
%     savefile=sprintf('basename_%d_PM_vs_disparity_byobjt.png',length(unique(ID)))
%     filenamePNG=fullfile('.',savedir,savefile);
%     exportgraphics(fh,filenamePNG,'Resolution',600);
% end
% 
% 
% %% 
% % Assumes your table is named T and includes:
% % T.Distance (numeric) and T.Disparity_VA_adjusted (each row: 1xN double or in a cell)
% % If you want a different field (e.g., 'Disparity_VA_mean'), change disparityField below.
% T=all_data;
% disparityField = 'Disparity_VA_adjusted';
% 
% % --- Gather unique distances ---
% distVals = T.Distance;
% distVals = distVals(~isnan(distVals));
% uniqDist = unique(distVals(:)');
% uniqDist = sort(uniqDist);
% 
% % --- Collect distributions per distance ---
% perDist = cell(numel(uniqDist),1);
% for i = 1:height(T)
%     d = T.Distance(i);
%     if isnan(d); continue; end
% 
%     % Extract disparity vector from row i
%     if iscell(T.(disparityField))
%         v = T.(disparityField){i};
%     else
%         v = T.(disparityField)(i,:);  % e.g., if stored as a 1xN row
%     end
%     if isempty(v); continue; end
% 
%     v = v(:);
%     v = v(~isnan(v));   % drop NaNs
% 
%     % Append to the appropriate distance bin
%     idx = find(uniqDist == d, 1, 'first');
%     if ~isempty(idx) && ~isempty(v)
%         perDist{idx} = [perDist{idx}; v]; %#ok<AGROW>
%     end
% end
% 
% % --- Prepare data for plotting ---
% % Option A (preferred): violinplot with grouping vector
% yAll = [];
% grpAll = [];
% for k = 1:numel(uniqDist)
%     if ~isempty(perDist{k})
%         yAll  = [yAll;  perDist{k}(:)]; %#ok<AGROW>
%         grpAll = [grpAll; repmat(string(uniqDist(k)), numel(perDist{k}), 1)]; %#ok<AGROW>
%     end
% end
% 
% % Make a nice categorical for display
% grpAll = categorical(grpAll, string(uniqDist), compose('%.1f m', uniqDist));
% 
% figure('Color','w'); 
% 
% if exist('violinplot','file') == 2
%     % --- Violin plots (File Exchange function or built-in if available) ---
%     violinplot(yAll, grpAll);
%     ylabel('Disparity (arcmin or chosen units)');
%     xlabel('Distance (m)');
%     title('Disparity Distributions by Distance');
%     set(gca,'Box','off');
% 
%     % Optional: overlay medians as markers
%     hold on;
%     for k = 1:numel(uniqDist)
%         vk = perDist{k};
%         if isempty(vk); continue; end
%         medk = median(vk,'omitnan');
%         plot(k, medk, 'k.', 'MarkerSize', 18); % median dot
%     end
%     hold off;
% 
% else
%     % --- Fallback: use boxchart grouped by distance (no violin) ---
%     boxchart(grpAll, yAll);
%     ylabel('Disparity (arcmin or chosen units)');
%     xlabel('Distance (m)');
%     title('Disparity Distributions by Distance (boxplot fallback)');
%     set(gca,'Box','off');
% end
% 
% % --- Optional: tweak axes/ticks ---
% % If you want distances as numeric ticks without 'm', use:
% % set(gca,'XTickLabel', string(uniqDist));
