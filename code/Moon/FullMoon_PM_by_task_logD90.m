function [lme_by_logRatio_by_ElevationD90] = FullMoon_PM_by_task_logD90(dataDir,datafile,ResultsDir,task,recomputeSort,saveLME)
% FullMoon_PM_by_task_logD90
% Plots perceived magnification by moon elevation for one task.
%
% This version differs from FullMoon_PM_by_task_logv2 in two ways:
% 1) The first panel of the 3-panel figure uses a linear elevation axis.
% 2) The fit and confidence interval in that first panel come from the
%    random-intercepts model:
%       logRatio ~ log2(1 + Elevation/90) + (1|ID)
%
% The obsolete random-slopes model has been removed.
%
% Inputs
%   dataDir        - directory containing the csv data file
%   datafile       - csv file name (default: FullMoonDataLong.csv)
%   ResultsDir     - directory for output figures and text files
%   task           - task name, e.g. 'Perceptual'
%   recomputeSort  - if true, recompute subject sorting by random intercept
%   saveLME        - if true, save model summaries to text files
%
% Output
%   lme_by_logRatio_by_ElevationD90 - fitted LinearMixedModel object
%
% Notes
%   This function still expects visualizePM.m to be on the MATLAB path if
%   you want the visualization figures at the end of the pipeline.

% ----------------------
% defaults
% ----------------------
if nargin < 1 || isempty(dataDir)
    dataDir = '/Users/kalanit/Projects/PerceptualMagnification/MoonExperiments/';
end
if nargin < 2 || isempty(datafile)
    datafile = 'FullMoonDataLong.csv';
end
if nargin < 3 || isempty(ResultsDir)
    ResultsDir = 'PaperFigures';
end
if nargin < 4 || isempty(task)
    task = 'Perceptual';
end
if nargin < 5 || isempty(recomputeSort)
    recomputeSort = 1;
end
if nargin < 6 || isempty(saveLME)
    saveLME = 1;
end

basename = erase(datafile,'.csv');

startDir = pwd;
cleanupObj = onCleanup(@() cd(startDir)); %#ok<NASGU>
cd(dataDir)

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end

% ----------------------
% load and filter data
% ----------------------
all_data = readtable(datafile);
nameVars = all_data.Properties.VariableNames;
disp(nameVars)
allTasks = unique(all_data.Task);
disp(allTasks)

% remove missing measurements (NaN)
all_data = all_data(~isnan(all_data.Reported_Visual_Angle),:);

% get relevant data by task
all_data = all_data(strcmp(all_data.Task,task),:);
if isempty(all_data)
    error('No rows found for task "%s".', task);
end

% derived variables
all_data.logRatio = log2(all_data.Ratio_Visual_Angle);
all_data.logElevation = log2(all_data.Elevation + 1);
all_data.ElevationD90 = all_data.Elevation/90;
all_data.logElevationD90 = log2(all_data.Elevation/90 + 1);

% basic summary values for axes/visualization
maxRatio = max(all_data.Ratio_Visual_Angle);
maxElevation = max(all_data.Elevation);
realVA = mean(all_data.Real_Visual_Angle);

% subject bookkeeping
ID = all_data.ID;
uniqueID = unique(ID);
nsubjects = length(uniqueID);

% colormap / marker size
cmap = jet(nsubjects);
markerScale = 36;

% ----------------------
% mixed models in log space
% ----------------------
lme_by_logRatio_by_Elevation = fitlme(all_data,'logRatio ~ logElevation + (1|ID)');
lme_by_logRatio_by_ElevationD90 = fitlme(all_data,'logRatio ~ logElevationD90 + (1|ID)');
lme_by_logRatio_by_ElevationD90_RS = fitlme(all_data,'logRatio ~ logElevationD90 + (logElevationD90|ID)');
model_complog = compare(lme_by_logRatio_by_ElevationD90,lme_by_logRatio_by_ElevationD90_RS);
model_complogElevation = compare(lme_by_logRatio_by_Elevation,lme_by_logRatio_by_ElevationD90);

plottedLogModel = lme_by_logRatio_by_ElevationD90_RS;

if saveLME
    savelmefile = fullfile(ResultsDir,[basename '_' task '_lme_moon_logRatio_by_Elevation.txt']);
    summaryLines = {
        sprintf('Task: %s', task)
        sprintf('Median matched size: %.2f', median(all_data.Reported_Visual_Angle))
        sprintf('Mean matched size: %.2f', mean(all_data.Reported_Visual_Angle))
        sprintf('Matched-size SD: %.2f', std(all_data.Ratio_Visual_Angle))
        };
    write_moon_lme_report(savelmefile, ...
        sprintf('%s Moon log PM by log elevation/90', task), ...
        summaryLines, ...
        {lme_by_logRatio_by_ElevationD90, lme_by_logRatio_by_ElevationD90_RS}, ...
        {'lme_by_logRatio_by_ElevationD90', 'lme_by_logRatio_by_ElevationD90_RS'}, ...
        {model_complog, model_complogElevation}, ...
        {'model_complog', 'model_complogElevation'});
end

% fixed/random effects from the plotted D90 model
[reEfx_log,reNames_log,~] = randomEffects(lme_by_logRatio_by_ElevationD90);
[feEfx_log,~,festats_log] = fixedEffects(plottedLogModel);
coefCov_log = plottedLogModel.CoefficientCovariance;
[reEfx_log_rs,reNames_log_rs,~] = randomEffects(plottedLogModel);
[feEfx_log_rs,~,~] = fixedEffects(plottedLogModel);

interceptL = feEfx_log(1);
slopeL = feEfx_log(2);
pvalL = festats_log.pValue(2);

% model-prediction CI in log space for plotting
xFit = linspace(0,maxElevation,200)';
xFitD90 = log2(xFit/90 + 1);
Xlog = [ones(size(xFitD90)) xFitD90];
yFit_log = Xlog * feEfx_log;
seFit_log = sqrt(sum((Xlog * coefCov_log) .* Xlog, 2));
tCrit_log = tinv(0.975, min(festats_log.DF));
yLow_log = yFit_log - tCrit_log * seFit_log;
yHigh_log = yFit_log + tCrit_log * seFit_log;

% subject-specific random intercepts from the D90 random-intercepts model
individualIntercepts_log = zeros(nsubjects,1);
individualSlopes_log = zeros(nsubjects,1);
reLevels = string(reNames_log.Level);
reLevelsRS = string(reNames_log_rs.Level);
for i = 1:nsubjects
    subjectRows = find(reLevels == string(uniqueID(i)));
    if isempty(subjectRows)
        error('Could not find random effect for subject ID %s.', string(uniqueID(i)));
    end
    individualIntercepts_log(i) = interceptL + reEfx_log(subjectRows(1));

    subjectRowsRS = find(reLevelsRS == string(uniqueID(i)));
    if numel(subjectRowsRS) >= 2
        individualSlopes_log(i) = feEfx_log_rs(2) + reEfx_log_rs(subjectRowsRS(2));
    else
        individualSlopes_log(i) = feEfx_log_rs(2);
    end
end

% sort subjects by random intercept (used only for coloring)
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end
sortfile = fullfile(ResultsDir, [basename '_sortedidx.mat']);
if recomputeSort || ~exist(sortfile,'file')
    [~, sorted_idx_log] = sort(individualIntercepts_log);
    save(sortfile,'sorted_idx_log');
else
    load(sortfile,'sorted_idx_log');
end

subjectcolor = zeros(height(all_data),3);
for c = 1:length(ID)
    cindex = find(uniqueID == ID(c), 1, 'first');
    sorted_cindex = find(sorted_idx_log == cindex, 1, 'first');
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    subjectcolor(c,:) = cmap(sorted_cindex,:);
end

% ----------------------
% Figure with 3 panels
% ----------------------
figh = figure('Color',[1 1 1], ...
    'Units','normalized', ...
    'Position',[0 0 1 1], ...
    'Name',[basename ' Perceptual Magnification vs Elevation']);

% Panel 2: linear elevation axis, D90 model in log space
subplot(1,3,2); hold on
if pvalL < 0.05
    for s = 1:nsubjects
        sortedID = sorted_idx_log(s);
        sindex = find(uniqueID == ID(sortedID), 1, 'first');
        jj = find(all_data.ID == uniqueID(sindex));
        if numel(jj) > 1
            sdata = all_data(jj,:);
            lower = find(strcmp(sdata.Session,'Lower'));
            higher = find(strcmp(sdata.Session,'Higher'));
            xvectorS = [sdata.Elevation(lower) sdata.Elevation(higher)];
            yvectorS = individualIntercepts_log(sortedID) + ...
                individualSlopes_log(sortedID) * log2(1 + xvectorS/90);
            plot(xvectorS, yvectorS, ':', 'Color', cmap(s,:), 'LineWidth', 1);
        end
    end
end
scatter(all_data.Elevation, all_data.logRatio, markerScale, subjectcolor, 'o', 'filled');
fill([xFit; flipud(xFit)], [yLow_log; flipud(yHigh_log)], 1, ...
    'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot(xFit, yFit_log, 'k-', 'LineWidth', 5);
plot([0 maxElevation], [0 0], 'Color',[.8 .8 .8], 'LineWidth', 3)

if pvalL < 0.001
    titlestr = sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%5.2e\n n=%d', ...
        task, interceptL, slopeL, pvalL, nsubjects);
else
    titlestr = sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.4f\n n=%d', ...
        task, interceptL, slopeL, pvalL, nsubjects);
end
xlabel('Moon Elevation (degrees)')
ylabel('Perceptual Magnification (log scale)')
set(gca,'FontSize',20,'FontName','Avenir')

title(titlestr,'FontSize',16,'FontName','Avenir')
xlim([0 maxElevation])
yticks = get(gca,'YTick');
set(gca,'YTickLabel', round(2.^yticks,1));

% Panel 1: ratio vs elevation with D90-model fit transformed back to ratio units
subplot(1,3,1); hold on
scatter(all_data.Elevation, all_data.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
plot(xFit, 2.^yFit_log, 'k-', 'LineWidth', 3);
fill([xFit; flipud(xFit)], [2.^yLow_log; flipud(2.^yHigh_log)], 1, ...
    'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot([0 maxElevation], [1 1], 'Color',[.8 .8 .8], 'LineWidth', 3)
xlabel('Moon Elevation (degrees)')
ylabel('Perceptual Magnification')
ylim([0 maxRatio])
set(gca,'YTick',0:1:maxRatio,'YTickLabel',0:1:maxRatio,'FontSize',20,'FontName','Avenir')

if pvalL < 0.001
    titlestr = sprintf('%s Matching\n PM=%.1f * (1+Elevation/90)^{%.2f}\n p=%5.2e\n n=%d', ...
        task, round(2^interceptL,1), slopeL, pvalL, nsubjects);
else
    titlestr = sprintf('%s Matching\n PM=%.1f * (1+Elevation/90)^{%.2f}\n p=%.4f\n n=%d', ...
        task, round(2^interceptL,1), slopeL, pvalL, nsubjects);
end
title(titlestr,'FontSize',16,'FontName','Avenir')

% ----------------------
% linear model in ratio space for comparison
% ----------------------
lme_ratio_by_ElevationD90 = fitlme(all_data,'Ratio_Visual_Angle ~ ElevationD90 + (1|ID)');
lme_ratio_by_ElevationD90_RS = fitlme(all_data,'Ratio_Visual_Angle ~ ElevationD90 + (ElevationD90|ID)');
model_comp = compare(lme_ratio_by_ElevationD90, lme_ratio_by_ElevationD90_RS);

[reEfx_ratio,reNames_ratio,~] = randomEffects(lme_ratio_by_ElevationD90_RS);
[feEfx_ratio,~,festats_ratio] = fixedEffects(lme_ratio_by_ElevationD90_RS);
coefCov_ratio = lme_ratio_by_ElevationD90_RS.CoefficientCovariance;

interceptR = feEfx_ratio(1);
slopeR = feEfx_ratio(2);
pvalR = festats_ratio.pValue(2);

xFit_lin = linspace(0,maxElevation,200)';
Xlin = [ones(size(xFit_lin)) xFit_lin/90];
yFit_ratio = Xlin * feEfx_ratio;
seFit_ratio = sqrt(sum((Xlin * coefCov_ratio) .* Xlin, 2));
tCrit_ratio = tinv(0.975, min(festats_ratio.DF));
yLow_ratio = yFit_ratio - tCrit_ratio * seFit_ratio;
yHigh_ratio = yFit_ratio + tCrit_ratio * seFit_ratio;
individualSlopes_ratio = nan(nsubjects,1);

subplot(1,3,3); hold on
scatter(all_data.Elevation, all_data.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
plot([0 maxElevation], [1 1], 'Color',[.8 .8 .8], 'LineWidth', 3)

if pvalR < 0.05
    individualIntercepts_ratio = zeros(nsubjects,1);
    individualSlopes_ratio = zeros(nsubjects,1);
    reLevels_ratio = string(reNames_ratio.Level);
    for i = 1:nsubjects
        subjectRows = find(reLevels_ratio == string(uniqueID(i)));
        if isempty(subjectRows)
            continue;
        end
        individualIntercepts_ratio(i) = interceptR + reEfx_ratio(subjectRows(1));
        if numel(subjectRows) >= 2
            individualSlopes_ratio(i) = slopeR + reEfx_ratio(subjectRows(2));
        else
            individualSlopes_ratio(i) = slopeR;
        end
    end

    for s = 1:nsubjects
        sortedID = sorted_idx_log(s);
        sindex = find(uniqueID == ID(sortedID), 1, 'first');
        jj = find(all_data.ID == uniqueID(sindex));
        if numel(jj) > 1
            sdata = all_data(jj,:);
            lower = find(strcmp(sdata.Session,'Lower'));
            higher = find(strcmp(sdata.Session,'Higher'));
            xvectorS = [sdata.Elevation(lower) sdata.Elevation(higher)];
            yvectorS = individualSlopes_ratio(sortedID) * (xvectorS/90) + individualIntercepts_ratio(sortedID);
            plot(xvectorS, yvectorS, ':', 'Color', cmap(s,:), 'LineWidth', 1);
        end
    end

    plot(xFit_lin, yFit_ratio, 'k-', 'LineWidth', 3);
    fill([xFit_lin; flipud(xFit_lin)], [yLow_ratio; flipud(yHigh_ratio)], 1, ...
        'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
    if pvalR < 0.001
        titlestr = sprintf('%s Matching\n PM=%3.2f + (%3.3f)*(Elevation/90)\n p=%5.2e\n n=%d', ...
            task, interceptR, slopeR, pvalR, nsubjects);
    else
        titlestr = sprintf('%s Matching\n PM=%3.2f + (%3.3f)*(Elevation/90)\n p=%.4f\n n=%d', ...
            task, interceptR, slopeR, pvalR, nsubjects);
    end
else
    titlestr = sprintf('%s Matching\n p=%.4f\n n=%d', task, pvalR, nsubjects);
end

xlabel('Moon Elevation (degrees)')
ylabel('Perceptual Magnification')
ylim([0 maxRatio])
set(gca,'YTick',0:1:maxRatio,'YTickLabel',0:1:maxRatio,'FontSize',20,'FontName','Avenir')
title(titlestr,'FontSize',16,'FontName','Avenir')

% save 3-panel figure
filenamePNG = fullfile(ResultsDir, ['SuppFigModelComps_' basename '_' task '_' num2str(nsubjects) '.png']);
print(figh,filenamePNG,'-dpng','-r600');

plot_moon_pm_log_model2panels(all_data, plottedLogModel, ...
    subjectcolor, cmap, sorted_idx_log, basename, task, ResultsDir, markerScale);

% if saveLME
%     savelmefile = fullfile(ResultsDir,[basename '_' task '_lme_moon_ratio_by_Elevation.txt']);
%     diary(savelmefile)
%     fprintf(1,'task %s median PM %5.2f mean PM %5.2f stdev %5.2f \n', ...
%         task, median(all_data.Ratio_Visual_Angle), mean(all_data.Ratio_Visual_Angle), std(all_data.Ratio_Visual_Angle));
%     ncount = sum(individualSlopes_ratio < 0);
%     fprintf(1,'percentage participants with negative slopes %5.2f  \n',100*ncount/nsubjects);
%     lme_ratio_by_ElevationD90
%     lme_ratio_by_ElevationD90_RS
%     fprintf(1,'RandomSlopes vs RandomIntercepts model comparison \n')
%     model_comp
%     diary off
% end

% ----------------------
% single-panel summary figure using the D90 fit
% ----------------------
fig1h = figure('Color',[1 1 1], ...
    'Units','normalized', ...
    'Position',[0 0 .5 1], ...
    'Name',['Fig1_' basename '_' task '_' num2str(nsubjects) '.png']);

hold on
scatter(all_data.Elevation, all_data.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
plot(xFit, 2.^yFit_log, 'k-', 'LineWidth', 3);
fill([xFit; flipud(xFit)], [2.^yLow_log; flipud(2.^yHigh_log)], 1, ...
    'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot([0 maxElevation], [1 1], 'Color',[.8 .8 .8], 'LineWidth', 3)
xlabel('Moon Elevation (degrees)')
ylabel('Perceptual Magnification')
ylim([0 maxRatio])
set(gca,'YTick',0:1:maxRatio,'YTickLabel',0:1:maxRatio,'FontSize',28,'FontName','Avenir')

titlestr = sprintf('%s Matching\n PM=%.1f * (1+Elevation/90)^{%.2f}\n n=%d', ...
    task, round(2^interceptL,1), slopeL, nsubjects);
title(titlestr,'FontSize',18,'FontName','Avenir')

filenamePNG = fullfile(ResultsDir, ['Fig1_' basename '_' task '_' num2str(nsubjects) '.png']);
print(fig1h,filenamePNG,'-dpng','-r600');

% ----------------------
% save analysis workspace summary
% ----------------------
savefile = fullfile(ResultsDir, [basename '_' task '_analysed.mat']);
save(savefile, ...
    'all_data', ...
    'lme_by_logRatio_by_Elevation', ...
    'lme_by_logRatio_by_ElevationD90', ...
    'lme_by_logRatio_by_ElevationD90_RS', ...
    'lme_ratio_by_ElevationD90', ...
    'model_complog', ...
    'sorted_idx_log', ...
    'interceptL', 'slopeL', 'interceptR', 'slopeR', ...
    'xFit', 'yFit_log', 'yLow_log', 'yHigh_log');

% ----------------------
% visualize illusion
% ----------------------
distance_mm = 500; % hand length distance of ~50 cm

% PM = 2^intercept * (1 + elevation/90)^slope

elevation = 0.25; % moon just passed the horizon
perceivedVAH = (2^interceptL) * ((1 + elevation/90)^slopeL) * realVA;
pmSuffixH = strrep(sprintf('PMx%.2f', perceivedVAH/realVA), '.', 'p');
filenamePNG = fullfile(ResultsDir, [basename '_' task '_' num2str(nsubjects) 'visualize_horizon_' pmSuffixH '.png']);
[~,~] = visualizePM(realVA,perceivedVAH,distance_mm,saveLME,filenamePNG);

elevation = 2.5; % lowest elevation measured
perceivedVA = (2^interceptL) * ((1 + elevation/90)^slopeL) * realVA;
pmSuffix25 = strrep(sprintf('PMx%.2f', perceivedVA/realVA), '.', 'p');
filenamePNG = fullfile(ResultsDir, [basename '_' task '_' num2str(nsubjects) 'visualize_2p5deg_' pmSuffix25 '.png']);
[~,~] = visualizePM(realVA,perceivedVA,distance_mm,saveLME,filenamePNG);

elevation = 40; % highest elevation measured
perceivedVA40 = (2^interceptL) * ((1 + elevation/90)^slopeL) * realVA;
pmSuffix40 = strrep(sprintf('PMx%.2f', perceivedVA40/realVA), '.', 'p');
filenamePNG = fullfile(ResultsDir, [basename '_' task '_' num2str(nsubjects) 'visualize_40deg_' pmSuffix40 '.png']);
[~,~] = visualizePM(realVA,perceivedVA40,distance_mm,saveLME,filenamePNG);

fprintf(1,'%s task, moon visual angle: %.2f, perceived size at horizon: %.2f, perceived size at 2.5 degrees: %.2f, perceived size at 40 degrees: %.2f\n', ...
    task, realVA, perceivedVAH, perceivedVA, perceivedVA40);

lme_by_logRatio_by_ElevationD90 = plottedLogModel;
end
