clx
%% load data
load_all_quad_data_2025
savedir=fullfile('Results',basename)
if ~exist(savedir,'dir')
    !mkdir savedir
end

%% plot disparity vs distance

idx=find(~isnan(all_data.Disparity_VA)); % find all subjects that belong to the disparity experiment 
filtered_data=all_data(idx,:);
filtered_data=filtered_data(contains(filtered_data.Task,'Perceptual'),:) % and perceptual task
   
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
   savelmefile=fullfile('.',savedir, [basename '_lmeRSDvD_Quad_Disparity_vs_Distance.txt']);
   diary(savelmefile)
   lmeDvD
   diary off
end
% compare models
if saveLME % save stats table
    savelmefile=fullfile('.','Results', [basename '_RandomSlopesvsRandomIntercepts_model_comparison.txt']);
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
fh=figure ('Color',[ 1 1 1],'Name', 'Disparity vs Distance', 'Units','normalized','Position', [0 0 .5 1]);
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
set(gca,'Fontsize',18)
titlestr=sprintf(['Quad Experiments show that disparity decreases with distance \n slope=%5.2f, p=%5.2e \n n=%d'],...
    lmeDvD.Coefficients.Estimate(2),lmeDvD.Coefficients.pValue(2), length(unique(ID)));
title(titlestr,'Fontsize',14)
filenamePNG=fullfile('.',savedir,[basename,'_disparity_vs_distance', num2str(length(unique(ID))),'.png']);
exportgraphics(fh,filenamePNG,'Resolution',600);
  


%% plot perceptual magnification vs distance on subjects in the disparity experiment
  

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

fh=figure ('Color',[ 1 1 1],'Name', 'Perceptual Magnification vs Distance' );
hold on;
scatter(filtered_data.Distance, filtered_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
xvector=linspace(min(filtered_data.Distance), max(filtered_data.Distance),10);
y_fit =lmePMvDistance.Coefficients.Estimate(1)+lmePMvDistance.Coefficients.Estimate(2)*xvector;

plot(xvector, y_fit, 'k-','LineWidth',3);
ylabel('Perceptual Magnification');
xlabel('Distance [m]');
ylim([0 maxRatio])
set(gca,'Fontsize',18)


titlestr=sprintf(['PM vs distance \n intercept=%5.2f slope=%5.2f, p=%5.2e \n n=%d'],...
    lmePMvDistance.Coefficients.Estimate(1),lmePMvDistance.Coefficients.Estimate(2),lmePMvDistance.Coefficients.pValue(2), length(unique(ID)));
title(titlestr,'Fontsize',18)
filenamePNG=fullfile('.',savedir,[basename,'_PM_vs_distance', num2str(length(unique(ID))),'.png']);
exportgraphics(fh,filenamePNG,'Resolution',600);

%% plot binocular vs monocular magnification vs disparity separately for each lamp as perceptual magnification depends on both distance and visual angle

% test if there is a linear relation between PM and disparity for each lamp
idx=find(~isnan(all_data.Disparity_VA)); % find all subjects that belong to the disparity experiment 
filtered_data=all_data(idx,:);

perceptual_data = filtered_data(contains(filtered_data.Measurement_Type, 'Perceptual'), :);
adjusted_data = filtered_data(contains(filtered_data.Measurement_Type, 'Adjusted'), :);

uniqueObject=unique(filtered_data.Measurement_Type);
nObjects=length(uniqueObject);
fh=figure ('Color',[ 1 1 1],'Units','Norm', 'Position',[ 0 0 1 .5],'Name', 'Perceptual Magnification vs Disparity' );

for i=1:nObjects
    lamp_data=filtered_data(contains(filtered_data.Measurement_Type,uniqueObject(i)),:)
    
    clear subjectcolor
    ID=lamp_data.ID;
    for c=1:length(ID)
     cindex=find(uniqueID==ID(c));
     subjectcolor(c,:)=cmap(cindex,:);
    end

    lmePMvDisparity = fitlme(lamp_data, 'Ratio_Visual_Angle ~ Disparity_VA + (1|ID)');
    disp(lmePMvDisparity)
    
    subplot(1,nObjects,i)
    hold on;
    scatter(lamp_data.Disparity_VA, lamp_data.Ratio_Visual_Angle, markerScale,subjectcolor,'o','filled');
    xvector=linspace(min(lamp_data.Disparity_VA), max(lamp_data.Disparity_VA),10);
    y_fit =lmePMvDisparity.Coefficients.Estimate(1)+lmePMvDisparity.Coefficients.Estimate(2)*xvector;
    
    plot(xvector, y_fit, 'k-','LineWidth',3);
    ylabel('Perceptual Magnification');
    xlabel('Disparity [deg]');
    ylim([0 maxRatio])
    set(gca,'Fontsize',8)
    titlestr=sprintf(['PM vs disparity \n' ...
        '%s\n intercept=%5.2f slope=%5.2f\n p=%5.4f\n n=%d'],...
        string(uniqueObject(i)),lmePMvDisparity.Coefficients.Estimate(1),lmePMvDisparity.Coefficients.Estimate(2),lmePMvDisparity.Coefficients.pValue(2), length(unique(ID)));
    % remove '_'
    titlestr = strrep(titlestr, '_', '');
    title(titlestr)
end

filenamePNG=fullfile('.',savedir,[basename,'_PM_vs_disparity', num2str(length(unique(ID))),'.png']);
exportgraphics(fh,filenamePNG,'Resolution',600);
  