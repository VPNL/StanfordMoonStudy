function FullMoon_TaskComparison(dataDir,datafile,ResultsDir,saveLME)
% FullMoon_TaskComparison
% (dataDir,datafile,ResultsDir)
% test if there is significant differences across tasks and individual
% subject variability in PM across tasks
% load data
cd(dataDir)
basename = [erase( datafile,'.csv')] ; % for saving
all_data=readtable(datafile);
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end


%% test if there is a significant difference across tasks in estimated magnification
% this model allows different subjects to have different slopes vs real ID
% and forces a zero intercept.
% model comparisons between perceptual and adjusted matching.
lme_angle_by_Elevation_and_task = fitlme(all_data,'Reported_Visual_Angle~Elevation*Task  + (1|ID)')

lme_PM_by_Elevation_and_task = fitlme(all_data,'Ratio_Visual_Angle~Elevation*Task  + (1|ID)')
if saveLME % save stats table
     savelmefile=fullfile(ResultsDir, [basename '_lme_moon_task_comparison.txt']);
     summaryLines = {
         'Models test whether elevation effects differ across Perceptual and Adjusted tasks.'
         sprintf('Rows: %d', height(all_data))
         sprintf('Subjects: %d', numel(unique(all_data.ID)))
         };
     coeffCols = {'Name','Estimate','SE','tStat','DF','pValue','Lower','Upper'};
     angleCoeffTbl = lme_angle_by_Elevation_and_task.Coefficients(:, coeffCols);
     pmCoeffTbl = lme_PM_by_Elevation_and_task.Coefficients(:, coeffCols);
     write_moon_lme_report(savelmefile, ...
         'Moon task comparison models', ...
         summaryLines, ...
         {angleCoeffTbl, pmCoeffTbl}, ...
         {'lme_angle_by_Elevation_and_task.Coefficients', 'lme_PM_by_Elevation_and_task.Coefficients'}, ...
         {}, {});
end


%% test if mean perceived angle and magnification across elevations is consistent within participant across tasks 
% illustrates individual differences that are consistent across tasks

vars2keep = {'ID','Elevation','Task','Ratio_Visual_Angle'};
tmp = all_data(:,vars2keep);
% Convert Task to categorical (makes pivoting safer)
tmp.Task = categorical(tmp.Task);
% Pivot so each row has Perceptual and Adjusted side-by-side
data_rearrangedPM= unstack(tmp,'Ratio_Visual_Angle','Task');   % produces_Adjusted and Perceptual for ratio visual angle 

% now for visual angle
vars2keep = {'ID','Elevation','Task','Reported_Visual_Angle'};
tmp = all_data(:,vars2keep);
tmp.Task = categorical(tmp.Task);
data_rearrangedAngle= unstack(tmp,'Reported_Visual_Angle','Task');   % producesAdjusted and …_PerceptualValues for reported visual angle 

uniqueID=unique(data_rearrangedAngle.ID);
nsubjects=length(uniqueID);
for i=1:nsubjects
    ii=find(data_rearrangedAngle.ID==uniqueID(i));
    adjustedAngle(i)=nanmean(data_rearrangedAngle.Adjusted(ii));
    perceptualAngle(i)=nanmean(data_rearrangedAngle.Perceptual(ii));

    adjustedPM(i)=nanmean(data_rearrangedPM.Adjusted(ii));
    perceptualPM(i)=nanmean(data_rearrangedPM.Perceptual(ii));
end

%include only numeric values 
nonanP=find(perceptualAngle~=NaN);
nonanA=find(adjustedAngle~=NaN);
nonan=intersect(nonanP,nonanA);
adjustedAngle=adjustedAngle(nonan)';
perceptualAngle=perceptualAngle(nonan)';
adjustedPM=adjustedPM(nonan)';
perceptualPM=perceptualPM(nonan)';

% for visual angle
[cAngle,SAngle] = polyfit(adjustedAngle,perceptualAngle,1); % find linear fit
xFitAngle = linspace(0, max(perceptualAngle), 100); % 100 points for smoother line
yFitAngle = polyval(cAngle, xFitAngle); % estimate y values from linear  fit
[rAngle,pAngle]=corr(adjustedAngle,perceptualAngle); % calculate correlation

% correlation across tasks
[cPM,SPM] = polyfit(adjustedPM,perceptualPM,1);
xFitPM = linspace(0, max(perceptualPM), 100); % 100 points for smoother line
yFitPM = polyval(cPM, xFitPM);
[rPM,pPM]=corr(adjustedPM,perceptualPM);


% plot results
markerScale=36;
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename 'Perceived vs Adjusted'])
subplot(1,2,1); hold on 
scatter( adjustedAngle ,  perceptualAngle, markerScale,'k','o','filled')
%scatter(data_rearrangedAngle.Adjusted , data_rearrangedAngle.Perceptual, markerScale,subjectcolor,'o','filled');
plot(xFitAngle, yFitAngle, 'k--', 'LineWidth', 2); % Plot the fitted line
xlabel (' Average adjusted angle (degrees)')
ylabel (' Average perceptual angle (degrees)') 
set(gca,'FontSize',24, 'FontName','Avenir')
xlim([0 max(data_rearrangedAngle.Perceptual)])
ylim([0 max(data_rearrangedAngle.Perceptual)])
axis('square')
titlestr=sprintf('correlation=%5.2f p=%5.2e n=%d',rAngle,pAngle, nsubjects);
title(titlestr,'FontSize',20)


subplot(1,2,2); hold on 
scatter( adjustedPM , perceptualPM, markerScale,'k','o','filled')
%scatter(data_rearrangedAngle.Adjusted , data_rearrangedAngle.Perceptual, markerScale,subjectcolor,'o','filled');
plot(xFitPM, yFitPM, 'k--', 'LineWidth', 2); % Plot the fitted line
xlabel ('Adjusted Perceptual Magnification')
ylabel ('Perceptual Perceptual Magnification') 
set(gca,'FontSize',24, 'FontName','Avenir')
xlim([0 max(data_rearrangedPM.Perceptual)])
ylim([0 max(data_rearrangedPM.Perceptual)])
axis('square')
titlestr=sprintf('correlation=%5.2f p=%5.2e n=%d',rPM,pPM, nsubjects);
title(titlestr,'FontSize',20)

filenamePNG=fullfile(ResultsDir,[basename,'_' 'PM_Task_comparison.png']);
print(figh,filenamePNG,'-dpng','-r600');


