function [lme_by_logRatio_by_ElevationD90] = FullMoon_PM_by_task_logD90v2(dataDir,datafile,ResultsDir,task,recomputeSort,saveLME)
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
lme_ratio_by_Elevation = fitlme(all_data,'Ratio_Visual_Angle ~ Elevation + (1|ID)');
lme_by_logRatio_by_Elevation = fitlme(all_data,'logRatio ~ logElevation + (1|ID)');
lme_by_logRatio_by_ElevationD90 = fitlme(all_data,'logRatio ~ logElevationD90 + (1|ID)');
model_complog = compare(lme_by_logRatio_by_Elevation,lme_by_logRatio_by_ElevationD90);

if saveLME
    savelmefile = fullfile('.',ResultsDir,[basename '_' task '_lme_moon_logRatio_by_Elevation.txt']);
    diary(savelmefile)
    fprintf(1,'task %s median matched size %5.2f; mean matched size %5.2f stdev %5.2f \n', ...
        task, median(all_data.Reported_Visual_Angle), mean(all_data.Reported_Visual_Angle), std(all_data.Ratio_Visual_Angle));
    lme_by_logRatio_by_Elevation
    lme_by_logRatio_by_ElevationD90
    fprintf(1,'log(1+E) vs log(1+E/90) model comparison \n')
    model_complog
    diary off
end

% fixed/random effects from the D90 model
[reEfx_log,reNames_log,~] = randomEffects(lme_by_logRatio_by_ElevationD90);
[feEfx_log,~,festats_log] = fixedEffects(lme_by_logRatio_by_ElevationD90);
coefCov_log = lme_by_logRatio_by_ElevationD90.CoefficientCovariance;

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
reLevels = string(reNames_log.Level);
for i = 1:nsubjects
    subjectRows = find(reLevels == string(uniqueID(i)));
    if isempty(subjectRows)
        error('Could not find random effect for subject ID %s.', string(uniqueID(i)));
    end
    individualIntercepts_log(i) = interceptL + reEfx_log(subjectRows(1));
end

% sort subjects by random intercept (used only for coloring)
sortfile = fullfile('.', ResultsDir, [basename '_sortedidx.mat']);
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

% Panel 1: both axes in log space using the D90 transform
subplot(1,3,1); hold on
scatter(all_data.logElevationD90, all_data.logRatio, markerScale, subjectcolor, 'o', 'filled');
fill([xFitD90; flipud(xFitD90)], [yLow_log; flipud(yHigh_log)], 1, ...
    'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot(xFitD90, yFit_log, 'k-', 'LineWidth', 5);
plot([min(all_data.logElevationD90) max(all_data.logElevationD90)], [0 0], 'Color',[.8 .8 .8], 'LineWidth', 3)

if pvalL < 0.001
    titlestr = sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%5.2e\n n=%d', ...
        task, interceptL, slopeL, pvalL, nsubjects);
else
    titlestr = sprintf('%s Matching\n intercept=%3.2f slope=%5.3f \n p=%.4f\n n=%d', ...
        task, interceptL, slopeL, pvalL, nsubjects);
end

title(titlestr)
xlabel('Moon Elevation (degrees), log scale')
ylabel('Perceptual Magnification, log scale')
set(gca,'FontSize',20,'FontName','Avenir')
xlim([min(all_data.logElevationD90) max(all_data.logElevationD90)])

xticks_raw = [0 2.5 5 10 20 40 60 90];
xticks_raw = xticks_raw(xticks_raw <= maxElevation);
if isempty(xticks_raw) || xticks_raw(1) ~= 0
    xticks_raw = [0 xticks_raw];
end
xticks_log = log2(xticks_raw/90 + 1);
set(gca,'XTick',xticks_log,'XTickLabel',xticks_raw);

yticks = get(gca,'YTick');
set(gca,'YTickLabel', round(2.^yticks,2));

% Panel 2: ratio vs elevation with D90-model fit transformed back to ratio units
subplot(1,3,2); hold on
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
title(titlestr)

% ----------------------
% linear model in ratio space for comparison (random intercept only)
% ----------------------

[feEfx_ratio,~,festats_ratio] = fixedEffects(lme_ratio_by_Elevation);
coefCov_ratio = lme_ratio_by_Elevation.CoefficientCovariance;

interceptR = feEfx_ratio(1);
slopeR = feEfx_ratio(2);
pvalR = festats_ratio.pValue(2);

xFit_lin = linspace(0,maxElevation,200)';
Xlin = [ones(size(xFit_lin)) xFit_lin];
yFit_ratio = Xlin * feEfx_ratio;
seFit_ratio = sqrt(sum((Xlin * coefCov_ratio) .* Xlin, 2));
tCrit_ratio = tinv(0.975, min(festats_ratio.DF));
yLow_ratio = yFit_ratio - tCrit_ratio * seFit_ratio;
yHigh_ratio = yFit_ratio + tCrit_ratio * seFit_ratio;

subplot(1,3,3); hold on
scatter(all_data.Elevation, all_data.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
plot([0 maxElevation], [1 1], 'Color',[.8 .8 .8], 'LineWidth', 3)

if pvalR < 0.05
    plot(xFit_lin, yFit_ratio, 'k-', 'LineWidth', 3);
    fill([xFit_lin; flipud(xFit_lin)], [yLow_ratio; flipud(yHigh_ratio)], 1, ...
        'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
    if pvalR < 0.001
        titlestr = sprintf('%s Matching\n PM=%3.2f + (%3.3f)*Elevation\n p=%5.2e\n n=%d', ...
            task, interceptR, slopeR, pvalR, nsubjects);
    else
        titlestr = sprintf('%s Matching\n PM=%3.2f + (%3.3f)*Elevation\n p=%.4f\n n=%d', ...
            task, interceptR, slopeR, pvalR, nsubjects);
    end
else
    titlestr = sprintf('%s Matching\n p=%.4f\n n=%d', task, pvalR, nsubjects);
end

xlabel('Moon Elevation (degrees)')
ylabel('Perceptual Magnification')
ylim([0 maxRatio])
set(gca,'YTick',0:1:maxRatio,'YTickLabel',0:1:maxRatio,'FontSize',20,'FontName','Avenir')
title(titlestr)

% save 3-panel figure
filenamePNG = fullfile('.', ResultsDir, ['SuppFigModelComps_' basename '_' task '_' num2str(nsubjects) '.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);

if saveLME
    savelmefile = fullfile('.',ResultsDir,[basename '_' task '_lme_moon_ratio_by_Elevation.txt']);
    diary(savelmefile)
    fprintf(1,'task %s median PM %5.2f mean PM %5.2f stdev %5.2f \n', ...
        task, median(all_data.Ratio_Visual_Angle), mean(all_data.Ratio_Visual_Angle), std(all_data.Ratio_Visual_Angle));
    lme_ratio_by_Elevation
    diary off
end

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
title(titlestr,'FontSize',20,'FontName','Avenir')

filenamePNG = fullfile('.', ResultsDir, ['SuppFig1_' basename '_' task '_' num2str(nsubjects) '.png']);
exportgraphics(fig1h,filenamePNG,'Resolution',600);

% ----------------------
% save analysis workspace summary
% ----------------------
savefile = fullfile('.', ResultsDir, [basename '_' task '_analysed.mat']);
save(savefile, ...
    'all_data', ...
    'lme_by_logRatio_by_Elevation', ...
    'lme_by_logRatio_by_ElevationD90', ...
    'lme_ratio_by_Elevation', ...
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
filenamePNG = fullfile('.', ResultsDir, [basename '_' task '_' num2str(nsubjects) 'visualize_horizon.png']);
[~,~] = visualizePM(realVA,perceivedVAH,distance_mm,saveLME,filenamePNG);

elevation = 2.5; % lowest elevation measured
perceivedVA = (2^interceptL) * ((1 + elevation/90)^slopeL) * realVA;
filenamePNG = fullfile('.', ResultsDir, [basename '_' task '_' num2str(nsubjects) 'visualize_2p5deg.png']);
[~,~] = visualizePM(realVA,perceivedVA,distance_mm,saveLME,filenamePNG);

elevation = 40; % highest elevation measured
perceivedVA40 = (2^interceptL) * ((1 + elevation/90)^slopeL) * realVA;
filenamePNG = fullfile('.', ResultsDir, [basename '_' task '_' num2str(nsubjects) 'visualize_40deg.png']);
[~,~] = visualizePM(realVA,perceivedVA40,distance_mm,saveLME,filenamePNG);

fprintf(1,'%s task, moon visual angle: %.2f, perceived size at horizon: %.2f, perceived size at 2.5 degrees: %.2f, perceived size at 40 degrees: %.2f\n', ...
    task, realVA, perceivedVAH, perceivedVA, perceivedVA40);

end
