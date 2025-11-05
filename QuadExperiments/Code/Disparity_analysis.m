clx
%% load data
load_all_quad_data_2025
savedir=fullfile('Results',basename)
if ~exist(savedir,'dir')
    !mkdir savedir
end
onlynewversion=1;

 %% Add mean disparity and adujsted disparity to the table and save new disparity file
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
all_data.Disparity_VA_adjusted=nan(height(all_data));
for obj=1:nObjects
    obj_i=find(contains(all_data.Measurement,uniqueObject(obj)));
    groundTruth_index=find(strcmp(groundTruthData.ObjectName,uniqueObject(obj)));

    object_Width_degrees=groundTruthData.Width_degrees(groundTruth_index);
    all_data.Disparity_VA_adjusted(obj_i)=all_data.Disparity_VA_adjusted(obj_i)-object_Width_degrees;
end
% save disparity_data
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
cd(expDir)

writefile=fullfile(expDir,'Data',['disparity_' csvfile]);
writetable(all_data,writefile);

%%

uniqueTasks=unique(all_data.Task)
ntasks=length(uniqueTasks)
%% plot disparity vs distance
for i=ntasks:-1:1
    task='Perceptual'; % need to add loop on task
    task=uniqueTasks{i};
    filtered_data=all_data(idx,:);
    filtered_data=filtered_data(contains(filtered_data.Task,task),:) % and perceptual task
    % onlynewversion from July 2025
    
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
    end 
    
    % test if there is a linear relation between disparity and distance 
    % here the model allows each subject to have a different intercept and all
    % subjects have same slope
    % if you want to do random intercept and slope model will change to 
    % lmeDvD = fitlme(all_data, 'Disparity_VA ~ Distance + (Distance|ID)'); 
    %
    
    % random intercepts model
    lmeDvD = fitlme(all_data, 'Disparity_VA ~ Distance + (1|ID)'); 
    disp(lmeDvD)
    if saveLME
        savelmefile=fullfile('.',savedir, [basename '_lmeDvD_Quad_Disparity_vs_Distance.txt']);
        diary(savelmefile)
        lmeDvD
        diary off
    end
    % [feBetas,feNames,festats] =fixedEffects(lmeDvD);
    % individualIntercepts=reIntercepts+feBetas(1);
    % feSlope=feBetas(2);
    % [sorted_individualSlopes, sorted_idx] = sort(individualIntercepts);
    
    %random intercepts and random slopes model
    lmeRSDvD=fitlme(all_data, 'Disparity_VA ~ Distance + (Distance|ID)');
    if saveLME
       savelmefile=fullfile('.',savedir, [basename '_' task '_lmeRSDvD_Quad_Disparity_vs_Distance.txt']);
       diary(savelmefile)
       lmeDvD
       diary off
    end
    % compare models
    if saveLME % save stats table
        savelmefile=fullfile('.','Results', [basename '_' task '_RandomSlopesvsRandomIntercepts_model_comparison.txt']);
        diary(savelmefile)
        fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n') 
        compare(lmeDvD,lmeRSDvD)
        diary off
    end
    
    
    % as lmeRSDvD we will get the slopes and intercepts from the lmeRSDvD model
    [reEfx,reNames,reStats] = randomEffects(lmeRSDvD);
    [feEfx,feNames,festats] =fixedEffects(lmeRSDvD);
    
    ID=filtered_data.ID;
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
    % plot disparity vs. distance
    subplot(1,3,1) 
    hold on;
    
    % plot individual subjects slopes
    xvectorS=linspace(min(all_data.Distance), max(all_data.Distance),10)
    
    for s=1:nsubjects
        sortedID=sorted_idx(s);
        % rand effex: each subject has differnet intercept
        yvectorS=  individualSlopes(sortedID)*xvectorS+individualIntercepts(sortedID)
        plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',2);
    end
    % plot fixed effect
    %scatter(all_data.Distance, all_data.Disparity_VA, markerScale,subjectcolor,'o','filled');
    scatter(filtered_data.Distance, filtered_data.Disparity_VA, markerScale,subjectcolor,'o','filled');
    xvector=linspace(min(all_data.Distance), max(all_data.Distance),10)
    y_fit =lmeDvD.Coefficients.Estimate(1)+lmeDvD.Coefficients.Estimate(2)*xvector;
    
    plot(xvector, y_fit, 'k-','LineWidth',5);
    xlabel('Distance [m]');
    ylabel('Disparity [deg]');
    ylim([0 maxDisparity])
    set(gca,'Fontsize',18,'FontName','Avenir')
    titlestr=sprintf(['Quad Experiments show that disparity decreases with distance \n slope=%5.4f, p=%5.2e \n n=%d'],...
        lmeDvD.Coefficients.Estimate(2),lmeDvD.Coefficients.pValue(2), length(unique(ID)));
    title(titlestr,'Fontsize',18)
    filenamePNG=fullfile('.',savedir,[basename,'_disparity_vs_distance', num2str(length(unique(ID))),'.png']);
    exportgraphics(fh,filenamePNG,'Resolution',600);
      
    
    % plot perceptual magnification vs distance on subjects in the disparity experiment
      
    lmePMvDistance = fitlme(filtered_data, 'Ratio_Visual_Angle ~ Distance + (1|ID)');
    disp(lmePMvDistance)
    if saveLME
        savelmefile=fullfile('.',savedir, [basename '_lme_Quad_PM_vs_Distance.txt']);
        diary(savelmefile)
        lmePMvDistance
        diary off
    end
    
    intercept= lmePMvDistance.Coefficients.Estimate(1);
    slope=lmePMvDistance.Coefficients.Estimate(2);
    slope_pval=lmePMvDistance.Coefficients.pValue(2);
    nsubjects=num2str(length(unique(ID)));
    
    % perhaps can do nicer color coding of the subjects
    
    
    %fh=figure ('Color',[ 1 1 1],'Name', 'Perceptual Magnification vs Distance' ,'Units','normalized','Position', [0 0 .5 1]);
    subplot(1,3,2) 
    hold on;
    scatter(filtered_data.Distance, filtered_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
    xvector=linspace(min(filtered_data.Distance), max(filtered_data.Distance),10);
    y_fit =lmePMvDistance.Coefficients.Estimate(1)+lmePMvDistance.Coefficients.Estimate(2)*xvector;
    plot(xvector, y_fit, 'k-','LineWidth',3);
    yline(1,'-','Linewidth',2,'Color',[ .8 .8 .8])
    ylabel('Perceptual Magnification');
    xlabel('Distance [m]');
    ylim([0 maxRatio])
    set(gca,'Fontsize',18,'FontName','Avenir')
    if lmePMvDistance.Coefficients.pValue(2)<0.01
        titlestr=sprintf(['%s PM vs distance \n intercept=%5.2f slope=%5.2f, p=%.3f \n n=%d'],...
            task, lmePMvDistance.Coefficients.Estimate(1),lmePMvDistance.Coefficients.Estimate(2),lmePMvDistance.Coefficients.pValue(2), length(unique(ID)));
    else
         titlestr=sprintf(['%s PM vs distance \n intercept=%5.2f slope=%5.2f, p=%.3e \n n=%d'],...
            task, lmePMvDistance.Coefficients.Estimate(1),lmePMvDistance.Coefficients.Estimate(2),lmePMvDistance.Coefficients.pValue(2), length(unique(ID)));
        
    end
    title(titlestr,'Fontsize',18)
    
    subplot(1,3,3)
    hold on
    lmePMvDisparity = fitlme(filtered_data, 'Ratio_Visual_Angle ~ Disparity_VA + (1|ID)');
    disp(lmePMvDisparity)
    if saveLME
        savelmefile=fullfile('.',savedir, [basename '_lme_Quad_PM_vs_Disparity.txt']);
        diary(savelmefile)
        lmePMvDisparity
        diary off
    end
    intercept= lmePMvDisparity.Coefficients.Estimate(1);
    slope=lmePMvDisparity.Coefficients.Estimate(2);
    slope_pval=lmePMvDisparity.Coefficients.pValue(2);
    nsubjects=num2str(length(unique(ID)));
    
    scatter(filtered_data.Disparity_VA, filtered_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
    xvector=linspace(min(filtered_data.Disparity_VA), max(filtered_data.Disparity_VA),10);
    y_fit =lmePMvDisparity.Coefficients.Estimate(1)+lmePMvDisparity.Coefficients.Estimate(2)*xvector;
    plot(xvector, y_fit, 'k-','LineWidth',3);
    yline(1,'-','Linewidth',2,'Color',[ .8 .8 .8])
    ylabel('Perceptual Magnification');
    xlabel('Disparity[degrees]');
    ylim([0 maxRatio])
    set(gca,'Fontsize',18,'FontName','Avenir')
    titlestr=sprintf(['%s PM vs disparity \n intercept=%5.2f slope=%5.2f, p=%.3f \n n=%d'],...
       task, lmePMvDisparity.Coefficients.Estimate(1),lmePMvDisparity.Coefficients.Estimate(2),lmePMvDisparity.Coefficients.pValue(2), length(unique(ID)));
    
    title(titlestr,'Fontsize',18)
    filenamePNG=fullfile('.',savedir,[basename,'_PM_vs_distance', num2str(length(unique(ID))),'.png']);
    exportgraphics(fh,filenamePNG,'Resolution',600);
end


%% plot binocular vs monocular magnification vs disparity separately for each lamp as perceptual magnification depends on both distance and visual angle

% test if there is a linear relation between PM and disparity for each lamp
idx=find(~isnan(all_data.Disparity_VA)); % find all subjects that belong to the disparity experiment 
filtered_data=all_data(idx,:);

% onlynewversion from July 2025
if onlynewversion
    % now filter the data to include just the new objects
    ball_idx = contains(filtered_data.Measurement_Type, 'Ball');
    lamp5_idx = contains(filtered_data.Measurement_Type, 'Lamp5');
    lamp6_idx = contains(filtered_data.Measurement_Type, 'Lamp6');
    lamp7_idx = contains(filtered_data.Measurement_Type, 'Lamp7');
    stick5b_idx=contains(filtered_data.Measurement_Type, 'Stick5b');
    stick7_idx=contains(filtered_data.Measurement_Type, 'Stick7');
    stick8_idx=contains(filtered_data.Measurement_Type, 'Stick8');
    stick9_idx=contains(filtered_data.Measurement_Type, 'Stick9');
       
    % Combine all conditions with logical 
    combined_idx = ball_idx | lamp5_idx | lamp6_idx | lamp7_idx | stick5b_idx | stick7_idx| stick8_idx | stick9_idx;
    
    % Filter the table using the combined index
    filtered_data = filtered_data(combined_idx, :);
    
    % Display the number of rows in the filtered table
    disp(['Number of rows after filtering: ', num2str(height(filtered_data))]);
    
    % Display the first few rows of the filtered table
    head(filtered_data);
end
%%
uniqueTasks=unique(filtered_data.Task)
ntasks=length(uniqueTasks)

for i=ntasks:-1:1

    fh=figure ('Color',[ 1 1 1],'Units','Norm', 'Position',[ 0 0 1 1],'Name', 'Perceptual Magnification vs Disparity' );

    % first filter by task
    task=uniqueTasks{i}
    
       
    % then filter by objects
    task_data=filtered_data(contains(filtered_data.Task, task), :);
    uniqueObject=unique(task_data.Measurement_Type);
    nObjects=length(uniqueObject);
    if nObjects<=4
          nrows=1
          ncols=nObjects;
    else
         nrows=ceil(nObjects/4);
         ncols=4;
    end
    for i=1:nObjects
        %lamp_data=filtered_data(contains(filtered_data.Measurement_Type,uniqueObject(i)),:)
        lamp_data=task_data(contains(task_data.Measurement_Type,uniqueObject(i)),:)
        clear subjectcolor
        ID=lamp_data.ID;
        for c=1:length(ID)
         cindex=find(uniqueID==ID(c));
         subjectcolor(c,:)=cmap(cindex,:);
        end
    
        lmePMvDisparity = fitlme(lamp_data, 'Ratio_Visual_Angle ~ Disparity_VA + (1|ID)');
        disp(lmePMvDisparity)
        
        subplot(nrows,ncols,i)
        hold on;
        scatter(lamp_data.Disparity_VA, lamp_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
        xvector=linspace(min(lamp_data.Disparity_VA), max(lamp_data.Disparity_VA),10);
        y_fit =lmePMvDisparity.Coefficients.Estimate(1)+lmePMvDisparity.Coefficients.Estimate(2)*xvector;
        
        plot(xvector, y_fit, 'k-','LineWidth',3);
        ylabel('Perceptual Magnification');
        xlabel('Disparity [deg]');
        ylim([0 maxRatio])
        set(gca,'Fontsize',8,'FontName','Avenir')
        titlestr=sprintf(['PM vs disparity \n' ...
            '%s\n intercept=%5.2f slope=%5.2f\n p=%5.4f\n n=%d'],...
            string(uniqueObject(i)),lmePMvDisparity.Coefficients.Estimate(1),lmePMvDisparity.Coefficients.Estimate(2),lmePMvDisparity.Coefficients.pValue(2), length(unique(ID)));
        % remove '_'
        titlestr = strrep(titlestr, '_', '');
        title(titlestr)
    end
    savefile=sprintf('basename_%d_PM_vs_disparity_byobjt.png',length(unique(ID)))
    filenamePNG=fullfile('.',savedir,savefile);
    exportgraphics(fh,filenamePNG,'Resolution',600);
end


