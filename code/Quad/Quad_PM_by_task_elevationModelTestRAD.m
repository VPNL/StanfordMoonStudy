function [lme_PM_by_Elevation, lme_PM_by_AbsElevation, lme_logPM_by_logabsElevation,lme_logPM_by_logElevationRAD,lme_logPM_by_logabsElevationRAD,lme_logPM_by_logElevationD90,lme_logPM_by_logabsElevationD90] = ...
    Quad_PM_by_task_elevationModelTestRAD(tbl, tblName, ResultsDir, saveLME, cmap, sorted_idx)
% Quad_PM_by_task_elevationModelTest
%
% Fits 7 LME models:
% Shared transform coding in the PM codebase:
%   1 = Elevation
%   2 = absElevation
%   3 = ElevationRAD
%   4 = absElevationRAD
%   5 = ElevationD90
%   6 = absElevationD90
%
%   1) Ratio_Visual_Angle ~ Elevation + (1|ID)
%   2) Ratio_Visual_Angle ~ AbsElevation + (1|ID)
%   3) Log2_Ratio_Visual_Angle ~ Log2_1plusAbsElevation + (1|ID)
%   4) Log2_Ratio_Visual_Angle ~ Log2_1plusElevationRAD + (1|ID)
%   5) Log2_Ratio_Visual_Angle ~ Log2_1plusabsElevationRAD + (1|ID)
%   6) Log2_Ratio_Visual_Angle ~ Log2_1plusElevationD90 + (1|ID)
%   7) Log2_Ratio_Visual_Angle ~ Log2_1plusabsElevationD90 + (1|ID)
%
% Writes model summaries to text and plots one figure with 7 panels.
%
% INPUTS
%   tbl        : data table, must contain:
%                Ratio_Visual_Angle, Elevation, ID
%   tblName    : string used for file naming
%   ResultsDir : output directory
%   saveLME    : 1 save text/figure, 0 don't save
%   cmap       : colormap for subjects
%   sorted_idx : sort order for subject colors
%
% OUTPUTS
%   lme_PM_by_Elevation
%   lme_PM_by_AbsElevation
%   lme_logPM_by_logabsElevation
%   lme_logPM_by_logElevationRAD
%   lme_logPM_by_logabsElevationRAD
%   lme_logPM_by_logElevationD90
%   lme_logPM_by_logabsElevationD90
% KGS Nov 2025, rewritten

%% checks
requiredVars = {'Ratio_Visual_Angle','Elevation','ID'};
for i = 1:numel(requiredVars)
    if ~ismember(requiredVars{i}, tbl.Properties.VariableNames)
        error('Missing required variable: %s', requiredVars{i});
    end
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

% keep valid rows only
good = ~isnan(tbl.Ratio_Visual_Angle) & ~isnan(tbl.Elevation);
tbl = tbl(good,:);

% ID as categorical
if ~iscategorical(tbl.ID)
    tbl.ID = categorical(tbl.ID);
end

% derived variables
tbl.AbsElevation = abs(tbl.Elevation);
if any(tbl.Ratio_Visual_Angle <= 0)
    error('Ratio_Visual_Angle must be positive for the log2 model.');
end
tbl.Log2_Ratio_Visual_Angle = log2(tbl.Ratio_Visual_Angle);
tbl.Log2_1plusAbsElevation = log2(1 + abs(tbl.Elevation));
tbl.Log2_1plusElevationRAD = log2(1 + pi*(tbl.Elevation)/180);
tbl.Log2_1plusabsElevationRAD = log2(1 + pi*(abs(tbl.Elevation))/180);
tbl.Log2_1plusElevationD90 = log2(1 + (tbl.Elevation)/90);
tbl.Log2_1plusabsElevationD90 = log2(1 + abs(tbl.Elevation)/90);
minElevGlobal = min(tbl.Elevation);
maxElevGlobal = max(tbl.Elevation);
minPM=min(tbl.Ratio_Visual_Angle);
maxPM=max(tbl.Ratio_Visual_Angle);
ymin_log = (log2(minPM));
ymax_log = (log2(maxPM));

%% summary values
uniqueID = unique(tbl.ID);
nsubjects = numel(uniqueID);

maxRatio = max(tbl.Ratio_Visual_Angle);
minRatio = min(tbl.Ratio_Visual_Angle);
minElevation = min(tbl.Elevation);
maxElevation = max(tbl.Elevation);
minAbsElevation = min(tbl.AbsElevation);
maxAbsElevation = max(tbl.AbsElevation);
minLogAbsElevation = min(tbl.Log2_1plusAbsElevation);
maxLogAbsElevation = max(tbl.Log2_1plusAbsElevation);

minLogAbsElevationRAD = min(tbl.Log2_1plusabsElevationRAD);
maxLogAbsElevationRAD = max(tbl.Log2_1plusabsElevationRAD);
minLogRatio = min(tbl.Log2_Ratio_Visual_Angle);
maxLogRatio = max(tbl.Log2_Ratio_Visual_Angle);

maxPMLim = 16;
minPMLim = 0.25;

if maxRatio > maxPMLim
    fprintf(1,'Warning: max Ratio %.2f exceeds Ylim max %.2f\n', maxRatio, maxPMLim);
end
if minRatio < minPMLim
    fprintf(1,'Warning: min Ratio %.2f is less than Ylim min %.2f\n', minRatio, minPMLim);
end

%% fit models
lme_PM_by_Elevation = fitlme(tbl, ...
    'Ratio_Visual_Angle ~ Elevation + (1|ID)');

lme_PM_by_AbsElevation = fitlme(tbl, ...
    'Ratio_Visual_Angle ~ AbsElevation + (1|ID)');

lme_logPM_by_logabsElevation = fitlme(tbl, ...
    'Log2_Ratio_Visual_Angle ~ Log2_1plusAbsElevation + (1|ID)');


lme_logPM_by_logElevationRAD=fitlme(tbl, ...
    'Log2_Ratio_Visual_Angle ~ Log2_1plusElevationRAD + (1|ID)');

lme_logPM_by_logabsElevationRAD=fitlme(tbl, ...
    'Log2_Ratio_Visual_Angle ~ Log2_1plusabsElevationRAD + (1|ID)');

lme_logPM_by_logElevationD90=fitlme(tbl, ...
    'Log2_Ratio_Visual_Angle ~ Log2_1plusElevationD90 + (1|ID)');

lme_logPM_by_logabsElevationD90=fitlme(tbl, ...
    'Log2_Ratio_Visual_Angle ~ Log2_1plusabsElevationD90 + (1|ID)');

%% write text report
if saveLME
    savelmefile = fullfile(ResultsDir, [tblName '_ElevationModels.txt']);
    fid = fopen(savelmefile,'w');
    if fid == -1
        error('Cannot open %s for writing.', savelmefile);
    end

    fprintf(fid, '%s\n', tblName);
    fprintf(fid, 'Seven elevation-related LME models\n\n');
    fprintf(fid, 'N subjects: %d\n', nsubjects);
    fprintf(fid, 'N observations: %d\n\n', height(tbl));

    writeModelToFile(fid, 'Model 1: PM ~ Elevation + (1|ID)', lme_PM_by_Elevation);
    writeModelToFile(fid, 'Model 2: PM ~ abs(Elevation) + (1|ID)', lme_PM_by_AbsElevation);
    writeModelToFile(fid, 'Model 3: log2(PM) ~ log2(1+abs(Elevation)) + (1|ID)', lme_logPM_by_logabsElevation);
    writeModelToFile(fid, 'Model 4: log2(PM) ~ log2(1+Elevation_RAD) + (1|ID)', lme_logPM_by_logElevationRAD);
    writeModelToFile(fid, 'Model 5: log2(PM) ~ log2(1+abs(Elevation_RAD)) + (1|ID)', lme_logPM_by_logabsElevationRAD);
    writeModelToFile(fid, 'Model 6: log2(PM) ~ log2(1+Elevation_D90) + (1|ID)', lme_logPM_by_logElevationD90);
    writeModelToFile(fid, 'Model 7: log2(PM) ~ log2(1+abs(Elevation_D90)) + (1|ID)', lme_logPM_by_logabsElevationD90);

    fprintf(fid, 'Model comparisons\n');
    fprintf(fid, '=================\n\n');

    fprintf(fid, 'Model 1 vs Model 2\n');
    fprintf(fid, '%s\n', evalc('compare(lme_PM_by_Elevation, lme_PM_by_AbsElevation)'));

    fprintf(fid, 'Model 2 vs Model 3\n');
    fprintf(fid, '%s\n', evalc('compare(lme_PM_by_AbsElevation,lme_logPM_by_logabsElevation)'));
    
    fprintf(fid, 'Model 3 vs Model 4\n');
    fprintf(fid, '%s\n', evalc('compare(lme_logPM_by_logabsElevation,lme_logPM_by_logElevationRAD)'));

    fprintf(fid, 'Model 4 vs Model 5\n');
    fprintf(fid, '%s\n', evalc('compare(lme_logPM_by_logElevationRAD,lme_logPM_by_logabsElevationRAD)'));
    
    fprintf(fid, 'Model 6 vs Model 7\n');
    fprintf(fid, '%s\n', evalc('compare(lme_logPM_by_logElevationD90,lme_logPM_by_logabsElevationD90)'));

    fclose(fid);
end

%% subject colors
ID = tbl.ID;
subjectcolor = zeros(length(ID),3);
for c = 1:length(ID)
    cindex = find(uniqueID == ID(c), 1);
    sorted_cindex = find(sorted_idx == cindex, 1);
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    subjectcolor(c,:) = cmap(sorted_cindex,:);
end

%% plot
figh = figure('Color',[1 1 1], 'Units','normalized', ...
    'Position',[0 0 1 .45], 'Name',[tblName '_ElevationModels']);

markerSize = 50;

% ---------- Panel 1: PM by Elevation ----------
subplot(1,7,1);
hold on;

scatter(tbl.Elevation, tbl.Ratio_Visual_Angle, markerSize, subjectcolor, 'filled');

b0 = lme_PM_by_Elevation.Coefficients.Estimate(1);
b1 = lme_PM_by_Elevation.Coefficients.Estimate(2);
p1 = lme_PM_by_Elevation.Coefficients.pValue(2);
t1 = lme_PM_by_Elevation.Coefficients.tStat(2);

xline1 = linspace(minElevation, maxElevation, 200);
yfit1 = b0 + b1*xline1;

[b0L,b0U,b1L,b1U] = getCoefBounds(lme_PM_by_Elevation);
xU = xline1;
xD = fliplr(xline1);
y1L = b0L + b1L*xU;
y1U = b0U + b1U*xD;

plot(xline1, zeros(size(xline1)), 'k:', 'LineWidth', 1);
fill([xU xD], [y1L y1U], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.18);
plot(xline1, yfit1, 'k-', 'LineWidth', 3);

xlim([minElevation*1.05 - 0.05*max(abs([minElevation maxElevation])), ...
      maxElevation*1.05]);
ylim([minPMLim ceil(maxPMLim)]);
%ylim([2^ymin_log 2^ymax_log]);
set(gca,'FontName','Avenir','FontSize',9);
xlabel('Elevation [deg]','FontSize',9);
ylabel('Perceptual Magnification','FontSize',9);
title(sprintf('PM = %.2f + %.3fE_{deg}\n p=%.2e, n=%d', ...
    b0, b1, p1, nsubjects), 'FontSize',9,'FontWeight','normal');

% ---------- Panel 2: PM by abs(Elevation) ----------
subplot(1,7,2);
hold on;

scatter(tbl.AbsElevation, tbl.Ratio_Visual_Angle, markerSize, subjectcolor, 'filled');

b0 = lme_PM_by_AbsElevation.Coefficients.Estimate(1);
b1 = lme_PM_by_AbsElevation.Coefficients.Estimate(2);
p2 = lme_PM_by_AbsElevation.Coefficients.pValue(2);
t2 = lme_PM_by_AbsElevation.Coefficients.tStat(2);

xline2 = linspace(minAbsElevation, maxAbsElevation, 200);
yfit2 = b0 + b1*xline2;

[b0L,b0U,b1L,b1U] = getCoefBounds(lme_PM_by_AbsElevation);
xU = xline2;
xD = fliplr(xline2);
y2L = b0L + b1L*xU;
y2U = b0U + b1U*xD;

plot(xline2, zeros(size(xline2)), 'k:', 'LineWidth', 1);
fill([xU xD], [y2L y2U], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.18);
plot(xline2, yfit2, 'k-', 'LineWidth', 3);

xlim([.8*minAbsElevation maxAbsElevation*1.05 + eps]);
ylim([minPMLim ceil(maxPMLim)]);
%ylim([2^ymin_log 2^ymax_log]);

set(gca,'FontName','Avenir','FontSize',9);
xlabel('|Elevation| [deg]','FontSize',9);
ylabel('Perceptual Magnification','FontSize',9);
title(sprintf('PM = %.2f + %.3f|E_{deg}|\n p=%.2e, n=%d', ...
    b0, b1, p2, nsubjects), 'FontSize',9,'FontWeight','normal');

% ---------- Panel 3: log2(PM) by log2(1+abs(Elevation)) ----------
subplot(1,7,3);
hold on;

scatter(tbl.Log2_1plusAbsElevation, tbl.Log2_Ratio_Visual_Angle, ...
    markerSize, subjectcolor, 'filled');

b0 = lme_logPM_by_logabsElevation.Coefficients.Estimate(1);
b1 = lme_logPM_by_logabsElevation.Coefficients.Estimate(2);
p3 = lme_logPM_by_logabsElevation.Coefficients.pValue(2);
t3 = lme_logPM_by_logabsElevation.Coefficients.tStat(2);

xline3 = linspace(minLogAbsElevation, maxLogAbsElevation, 200);
yfit3 = b0 + b1*xline3;

[b0L,b0U,b1L,b1U] = getCoefBounds(lme_logPM_by_logabsElevation);
xU = xline3;
xD = fliplr(xline3);
y3L = b0L + b1L*xU;
y3U = b0U + b1U*xD;

plot(xline3, zeros(size(xline3)), 'k:', 'LineWidth', 1);
fill([xU xD], [y3L y3U], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.18);
plot(xline3, yfit3, 'k-', 'LineWidth', 3);

xlim([0.8*minLogAbsElevation maxLogAbsElevation*1.05 + eps]);
ylim([floor(minLogRatio) ceil(maxLogRatio)]);
%ylim([2^ymin_log 2^ymax_log]);
set(gca,'FontName','Avenir','FontSize',9);
xlabel('1 + |Elevation|, degree log scale','FontSize',9);
ylabel('Perceptual Magnification, log scale','FontSize',9);
% --------- KEY CHANGE: relabel ticks as 2^(value) ---------

% X ticks
xticks_vals = get(gca, 'XTick');
xticklabels_vals = arrayfun(@(x) sprintf('%.2g', 2.^x), xticks_vals, 'UniformOutput', false);
set(gca, 'XTickLabel', xticklabels_vals);

% Y ticks
yticks_vals = get(gca, 'YTick');
yticklabels_vals = arrayfun(@(y) sprintf('%.2g', 2.^y), yticks_vals, 'UniformOutput', false);
set(gca, 'YTickLabel', yticklabels_vals);

% --------------------------------------------------------


title(sprintf('PM = %.2flog_2(1+|E_{deg}|)^{%.3f}\n p=%.2e, n=%d', ...
     2^b0, b1, p3, nsubjects), 'FontSize',9,'FontWeight','normal');

% ---------- Panel 4: log2(PM) by log2(1+Elevation_RAD) ----------
subplot(1,7,4);
hold on;

scatter(tbl.Log2_1plusElevationRAD, tbl.Log2_Ratio_Visual_Angle, ...
    markerSize, subjectcolor, 'filled');

b0 = lme_logPM_by_logElevationRAD.Coefficients.Estimate(1);
b1 = lme_logPM_by_logElevationRAD.Coefficients.Estimate(2);
p3 = lme_logPM_by_logElevationRAD.Coefficients.pValue(2);
t3 = lme_logPM_by_logElevationRAD.Coefficients.tStat(2);

xline3 = linspace(min(tbl.Log2_1plusElevationRAD), max(tbl.Log2_1plusElevationRAD), 200);
yfit3 = b0 + b1*xline3;

[b0L,b0U,b1L,b1U] = getCoefBounds(lme_logPM_by_logElevationRAD);
xU = xline3;
xD = fliplr(xline3);
y3L = b0L + b1L*xU;
y3U = b0U + b1U*xD;

plot(xline3, zeros(size(xline3)), 'k:', 'LineWidth', 1);
fill([xU xD], [y3L y3U], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.18);
plot(xline3, yfit3, 'k-', 'LineWidth', 3);
% 
% xlim([minLogAbsElevationRAD minLogAbsElevationRAD*1.05 + eps]);

ylim([floor(minLogRatio) ceil(maxLogRatio)]);
set(gca,'FontName','Avenir','FontSize',9);
xlabel('Elevation [RAD], log scale','FontSize',9);
ylabel('Perceptual Magnification, log scale','FontSize',9);
% --------- KEY CHANGE: relabel ticks as 2^(value) ---------

% X ticks
xticks_vals = get(gca, 'XTick');
xticklabels_vals = arrayfun(@(x) sprintf('%.2g', (2.^x-1)), xticks_vals, 'UniformOutput', false);
set(gca, 'XTickLabel', xticklabels_vals);

% Y ticks
yticks_vals = get(gca, 'YTick');
yticklabels_vals = arrayfun(@(y) sprintf('%.2g', 2.^y), yticks_vals, 'UniformOutput', false);
set(gca, 'YTickLabel', yticklabels_vals);

% --------------------------------------------------------



title(sprintf('PM = %.2flog_2(1+E_{rad})^{%.3f}\n p=%.2e, n=%d', ...
     2^b0, b1, p3, nsubjects), 'FontSize',9,'FontWeight','normal');


% ---------- Panel 5: log2(PM) by log2(1+abs(Elevation_RAD)) ----------
subplot(1,7,5);
hold on;

scatter(tbl.Log2_1plusabsElevationRAD, tbl.Log2_Ratio_Visual_Angle, ...
    markerSize, subjectcolor, 'filled');

b0 = lme_logPM_by_logabsElevationRAD.Coefficients.Estimate(1);
b1 = lme_logPM_by_logabsElevationRAD.Coefficients.Estimate(2);
p3 = lme_logPM_by_logabsElevationRAD.Coefficients.pValue(2);
t3 = lme_logPM_by_logabsElevationRAD.Coefficients.tStat(2);

xline3 = linspace(min(tbl.Log2_1plusabsElevationRAD), max(tbl.Log2_1plusabsElevationRAD), 200);
yfit3 = b0 + b1*xline3;

[b0L,b0U,b1L,b1U] = getCoefBounds(lme_logPM_by_logabsElevationRAD);
xU = xline3;
xD = fliplr(xline3);
y3L = b0L + b1L*xU;
y3U = b0U + b1U*xD;

plot(xline3, zeros(size(xline3)), 'k:', 'LineWidth', 1);
fill([xU xD], [y3L y3U], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.18);
plot(xline3, yfit3, 'k-', 'LineWidth', 3);

% xlim([minLogAbsElevationRAD minLogAbsElevationRAD*1.05 + eps]);
ylim([floor(minLogRatio) ceil(maxLogRatio)]);
%ylim([2^ymin_log 2^ymax_log]);
set(gca,'FontName','Avenir','FontSize',9);
xlabel('Elevation [RAD], log scale','FontSize',9);
ylabel('Perceptual Magnification, log scale','FontSize',9);


% X ticks
xticks_vals = get(gca, 'XTick');
xticklabels_vals = arrayfun(@(x) sprintf('%.2g', (2.^x-1)), xticks_vals, 'UniformOutput', false); % this may need to be changed
set(gca, 'XTickLabel', xticklabels_vals);

% Y ticks
yticks_vals = get(gca, 'YTick');
yticklabels_vals = arrayfun(@(y) sprintf('%.2g', 2.^y), yticks_vals, 'UniformOutput', false);
set(gca, 'YTickLabel', yticklabels_vals);




title(sprintf('PM = %.2flog_2(1+abs(E_{RAD}))^{%.3f}\n p=%.2e, n=%d', ...
     2^b0, b1, p3, nsubjects), 'FontSize',9,'FontWeight','normal');

% ---------- Panel 6: log2(PM) by log2(1+Elevation/90) ----------
subplot(1,7,6);
hold on;

scatter(tbl.Log2_1plusElevationD90, tbl.Log2_Ratio_Visual_Angle, ...
    markerSize, subjectcolor, 'filled');

b0 = lme_logPM_by_logElevationD90.Coefficients.Estimate(1);
b1 = lme_logPM_by_logElevationD90.Coefficients.Estimate(2);
p3 = lme_logPM_by_logElevationD90.Coefficients.pValue(2);
t3 = lme_logPM_by_logElevationD90.Coefficients.tStat(2);

xline3 = linspace(min(tbl.Log2_1plusElevationD90), max(tbl.Log2_1plusElevationD90), 200);
yfit3 = b0 + b1*xline3;

[b0L,b0U,b1L,b1U] = getCoefBounds(lme_logPM_by_logElevationD90);
xU = xline3;
xD = fliplr(xline3);
y3L = b0L + b1L*xU;
y3U = b0U + b1U*xD;

plot(xline3, zeros(size(xline3)), 'k:', 'LineWidth', 1);
fill([xU xD], [y3L y3U], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.18);
plot(xline3, yfit3, 'k-', 'LineWidth', 3);

ylim([floor(minLogRatio) ceil(maxLogRatio)]);
set(gca,'FontName','Avenir','FontSize',9);
xlabel('Elevation/90, log scale','FontSize',9);
ylabel('Perceptual Magnification, log scale','FontSize',9);

xticks_vals = get(gca, 'XTick');
xticklabels_vals = arrayfun(@(x) sprintf('%.2g', (2.^x - 1)), xticks_vals, 'UniformOutput', false);
set(gca, 'XTickLabel', xticklabels_vals);

yticks_vals = get(gca, 'YTick');
yticklabels_vals = arrayfun(@(y) sprintf('%.2g', 2.^y), yticks_vals, 'UniformOutput', false);
set(gca, 'YTickLabel', yticklabels_vals);

title(sprintf('PM = %.2flog_2(1+E/90)^{%.3f}\n p=%.2e, n=%d', ...
     2^b0, b1, p3, nsubjects), 'FontSize',9,'FontWeight','normal');

% ---------- Panel 7: log2(PM) by log2(1+abs(Elevation)/90) ----------
subplot(1,7,7);
hold on;

scatter(tbl.Log2_1plusabsElevationD90, tbl.Log2_Ratio_Visual_Angle, ...
    markerSize, subjectcolor, 'filled');

b0 = lme_logPM_by_logabsElevationD90.Coefficients.Estimate(1);
b1 = lme_logPM_by_logabsElevationD90.Coefficients.Estimate(2);
p3 = lme_logPM_by_logabsElevationD90.Coefficients.pValue(2);
t3 = lme_logPM_by_logabsElevationD90.Coefficients.tStat(2);

xline3 = linspace(min(tbl.Log2_1plusabsElevationD90), max(tbl.Log2_1plusabsElevationD90), 200);
yfit3 = b0 + b1*xline3;

[b0L,b0U,b1L,b1U] = getCoefBounds(lme_logPM_by_logabsElevationD90);
xU = xline3;
xD = fliplr(xline3);
y3L = b0L + b1L*xU;
y3U = b0U + b1U*xD;

plot(xline3, zeros(size(xline3)), 'k:', 'LineWidth', 1);
fill([xU xD], [y3L y3U], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.18);
plot(xline3, yfit3, 'k-', 'LineWidth', 3);

ylim([floor(minLogRatio) ceil(maxLogRatio)]);
set(gca,'FontName','Avenir','FontSize',9);
xlabel('|Elevation|/90, log scale','FontSize',9);
ylabel('Perceptual Magnification, log scale','FontSize',9);

xticks_vals = get(gca, 'XTick');
xticklabels_vals = arrayfun(@(x) sprintf('%.2g', (2.^x - 1)), xticks_vals, 'UniformOutput', false);
set(gca, 'XTickLabel', xticklabels_vals);

yticks_vals = get(gca, 'YTick');
yticklabels_vals = arrayfun(@(y) sprintf('%.2g', 2.^y), yticks_vals, 'UniformOutput', false);
set(gca, 'YTickLabel', yticklabels_vals);

title(sprintf('PM = %.2flog_2(1+|E|/90)^{%.3f}\n p=%.2e, n=%d', ...
     2^b0, b1, p3, nsubjects), 'FontSize',9,'FontWeight','normal');





%% save figure
if saveLME
    filenamePNG = fullfile(ResultsDir, [tblName '_ElevationModels.png']);
    exportgraphics(figh, filenamePNG, 'Resolution', 600);
end

end

% ========================= helpers =========================

function writeModelToFile(fid, modelLabel, lme)
fprintf(fid, '%s\n', modelLabel);
fprintf(fid, '%s\n', repmat('=',1,length(modelLabel)));
fprintf(fid, 'Formula: %s\n\n', lme.Formula.char);

fprintf(fid, 'Coefficients:\n');
coefTbl = lme.Coefficients;
for i = 1:height(coefTbl)
    fprintf(fid, '%-24s Estimate=%10.5f  SE=%10.5f  t=%10.5f  p=%10.5g', ...
        coefTbl.Name{i}, coefTbl.Estimate(i), coefTbl.SE(i), ...
        coefTbl.tStat(i), coefTbl.pValue(i));
    % if ismember('Lower', coefTbl.Properties.VarNames) && ismember('Upper', coefTbl.Properties.VarNames)
    %     fprintf(fid, '  CI=[%10.5f %10.5f]', coefTbl.Lower(i), coefTbl.Upper(i));
    % end
    fprintf(fid, '\n');
end
fprintf(fid, '\n');

fprintf(fid, 'Model fit:\n');
if isprop(lme,'LogLikelihood')
    fprintf(fid, 'LogLikelihood: %.6f\n', lme.LogLikelihood);
end
if isprop(lme,'ModelCriterion')
    fprintf(fid, 'AIC: %.6f\n', lme.ModelCriterion.AIC);
    fprintf(fid, 'BIC: %.6f\n', lme.ModelCriterion.BIC);
end
fprintf(fid, '\nANOVA:\n%s\n', evalc('anova(lme)'));
fprintf(fid, '\n');
end

function [b0L,b0U,b1L,b1U] = getCoefBounds(lme)
coefTbl = lme.Coefficients;
if ismember('Lower', coefTbl.Properties.VarNames) && ismember('Upper', coefTbl.Properties.VarNames)
    b0L = coefTbl.Lower(1);
    b0U = coefTbl.Upper(1);
    b1L = coefTbl.Lower(2);
    b1U = coefTbl.Upper(2);
else
    % fallback if Lower/Upper are unavailable
    b0 = coefTbl.Estimate(1);
    b1 = coefTbl.Estimate(2);
    se0 = coefTbl.SE(1);
    se1 = coefTbl.SE(2);
    z = 1.96;
    b0L = b0 - z*se0;
    b0U = b0 + z*se0;
    b1L = b1 - z*se1;
    b1U = b1 + z*se1;
end
end
