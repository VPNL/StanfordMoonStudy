function [lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logAngle_RS, lme_logPM_by_logDistance_RS, lme_logPM_by_logElevation_RS] = ...
    Quad_PM_by_task_single(tbl, tblName, ResultsDir, saveLME, cmap, sorted_idx, ElevationTransform, plotFixedEffectsRS)
% QUAD_PM_BY_TASK_SINGLE
% Fit single-factor PM models with random intercepts and random slopes.

if nargin < 7 || isempty(ElevationTransform)
    ElevationTransform = 1;
end
if nargin < 8 || isempty(plotFixedEffectsRS)
    plotFixedEffectsRS = false;
end
ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'standard');

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

[tbl, nsubjects, subjectcolor, uniqueID] = local_prepare_table(tbl, cmap, sorted_idx, ElevationTransform);

lme_logPM_by_logAngle = fitlme(tbl, 'log2ratio_visual_angle ~ log2real_visual_angle + (1|ID)');
lme_logPM_by_logDistance = fitlme(tbl, 'log2ratio_visual_angle ~ log2distance + (1|ID)');
lme_logPM_by_logElevation = fitlme(tbl, 'log2ratio_visual_angle ~ log2elevation + (1|ID)');

lme_logPM_by_logAngle_RS = fitlme(tbl, 'log2ratio_visual_angle ~ log2real_visual_angle + (log2real_visual_angle|ID)');
lme_logPM_by_logDistance_RS = fitlme(tbl, 'log2ratio_visual_angle ~ log2distance + (log2distance|ID)');
lme_logPM_by_logElevation_RS = fitlme(tbl, 'log2ratio_visual_angle ~ log2elevation + (log2elevation|ID)');

if saveLME
    savelmefile = fullfile(ResultsDir, [tblName '_single.txt']);
    sourceCsv = char(string(tblName));
    try
        if isstruct(tbl.Properties.UserData) && isfield(tbl.Properties.UserData, 'SourceFile')
            sourceCsv = char(string(tbl.Properties.UserData.SourceFile));
        end
    catch
    end
    if ~endsWith(string(sourceCsv), ".csv", "IgnoreCase", true)
        sourceCsv = sprintf('%s.csv (inferred from tblName; function input is a table)', sourceCsv);
    end

    reportOpts = struct();
    reportOpts.ReportTitle = sprintf('Quad PM Single-Factor LME Report: %s', char(string(tblName)));
    reportOpts.GeneratedBy = mfilename;
    reportOpts.SourceFile = sourceCsv;
    reportOpts.ModelLabel = 'Log perceptual magnification predicted by one log physical factor';
    reportOpts.SummaryLines = { ...
        sprintf('Experiment: Quad'), ...
        sprintf('Rows in model table: %d', height(tbl)), ...
        sprintf('Participants in model table: %d', nsubjects), ...
        sprintf('Elevation transform: %s', char(string(ElevationTransform)))};
    reportOpts.Models = { ...
        lme_logPM_by_logAngle, ...
        lme_logPM_by_logAngle_RS, ...
        lme_logPM_by_logDistance, ...
        lme_logPM_by_logDistance_RS, ...
        lme_logPM_by_logElevation, ...
        lme_logPM_by_logElevation_RS};
    reportOpts.ModelLabels = { ...
        'Model: log2ratio_visual_angle ~ log2real_visual_angle + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2real_visual_angle + (log2real_visual_angle|ID)', ...
        'Model: log2ratio_visual_angle ~ log2distance + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2distance + (log2distance|ID)', ...
        'Model: log2ratio_visual_angle ~ log2elevation + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2elevation + (log2elevation|ID)'};
    reportOpts.Comparisons = { ...
        compare(lme_logPM_by_logAngle, lme_logPM_by_logAngle_RS), ...
        compare(lme_logPM_by_logDistance, lme_logPM_by_logDistance_RS), ...
        compare(lme_logPM_by_logElevation, lme_logPM_by_logElevation_RS)};
    reportOpts.ComparisonLabels = { ...
        'Model comparison: visual angle RI vs RS', ...
        'Model comparison: distance RI vs RS', ...
        'Model comparison: elevation RI vs RS'};
    reportOpts.RemoveGroupError = false;
    write_lme_stats_report(lme_logPM_by_logAngle, savelmefile, reportOpts);
end

minRatio = min(tbl.Ratio_Visual_Angle);
maxRatio = max(tbl.Ratio_Visual_Angle);
maxPMLim = max(16, maxRatio);
minPMLim = min(0.25, minRatio);

figRI = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 1 .7], ...
    'Name', [tblName '_single_RI'], 'Visible', 'off');
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
local_plot_pm_panel(nexttile, tbl, subjectcolor, lme_logPM_by_logAngle, 'A', ElevationTransform, nsubjects, uniqueID, cmap, sorted_idx, false, minPMLim, maxPMLim, plotFixedEffectsRS);
local_plot_pm_panel(nexttile, tbl, subjectcolor, lme_logPM_by_logDistance, 'D', ElevationTransform, nsubjects, uniqueID, cmap, sorted_idx, false, minPMLim, maxPMLim, plotFixedEffectsRS);
local_plot_pm_panel(nexttile, tbl, subjectcolor, lme_logPM_by_logElevation, 'E', ElevationTransform, nsubjects, uniqueID, cmap, sorted_idx, false, minPMLim, maxPMLim, plotFixedEffectsRS);
exportgraphics(figRI, fullfile(ResultsDir, [tblName '_single_RI.png']), 'Resolution', 600);
close(figRI);

figRS = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 1 .7], ...
    'Name', [tblName '_single_RS'], 'Visible', 'off');
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
local_plot_pm_panel(nexttile, tbl, subjectcolor, lme_logPM_by_logAngle_RS, 'A', ElevationTransform, nsubjects, uniqueID, cmap, sorted_idx, true, minPMLim, maxPMLim, plotFixedEffectsRS);
local_plot_pm_panel(nexttile, tbl, subjectcolor, lme_logPM_by_logDistance_RS, 'D', ElevationTransform, nsubjects, uniqueID, cmap, sorted_idx, true, minPMLim, maxPMLim, plotFixedEffectsRS);
local_plot_pm_panel(nexttile, tbl, subjectcolor, lme_logPM_by_logElevation_RS, 'E', ElevationTransform, nsubjects, uniqueID, cmap, sorted_idx, true, minPMLim, maxPMLim, plotFixedEffectsRS);
local_export_png(figRS, fullfile(ResultsDir, [tblName '_single_RS.png']), 600);
close(figRS);
end

function [tbl, nsubjects, subjectcolor, uniqueID] = local_prepare_table(tbl, cmap, sorted_idx, ElevationTransform)
tbl.log2real_visual_angle = log2(tbl.Real_Visual_Angle);
tbl.log2ratio_visual_angle = log2(tbl.Ratio_Visual_Angle);
tbl.log2distance = log2(tbl.Distance);

switch ElevationTransform
    case 1
        tbl.log2elevation = log2(tbl.Elevation + 1);
        tbl.ElevationModel = tbl.Elevation + 1;
    case 2
        tbl.log2elevation = log2(abs(tbl.Elevation) + 1);
        tbl.ElevationModel = abs(tbl.Elevation) + 1;
    case 5
        tbl.log2elevation = log2(tbl.Elevation / 90 + 1);
        tbl.ElevationModel = tbl.Elevation / 90 + 1;
    case 6
        tbl.log2elevation = log2(abs(tbl.Elevation) / 90 + 1);
        tbl.ElevationModel = abs(tbl.Elevation) / 90 + 1;
    otherwise
        error('Invalid elevation transform value');
end

uniqueID = unique(tbl.ID);
nsubjects = numel(uniqueID);
subjectcolor = zeros(height(tbl), 3);
for c = 1:height(tbl)
    cindex = find(uniqueID == tbl.ID(c), 1, 'first');
    sorted_cindex = find(sorted_idx == cindex, 1, 'first');
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    subjectcolor(c, :) = cmap(sorted_cindex, :);
end
end

function local_plot_pm_panel(ax, tbl, subjectcolor, lme, modeChar, ElevationTransform, nsubjects, uniqueID, cmap, sorted_idx, addSubjectLines, minPMLim, maxPMLim, plotFixedEffectsRS)
hold(ax, 'on');
markerSize = 50;
[~, xLog, xlabelText, titleTemplate, xTickVals, xTickLabels, xLimits] = local_axis_info(tbl, modeChar, ElevationTransform);
if addSubjectLines
    plot(ax, xLimits, [0 0], 'k:', 'LineWidth', 3);
else
    plot(ax, xLimits, [0 0], 'k:', 'LineWidth', 1);
end

if addSubjectLines
    local_plot_subject_lines(ax, tbl, lme, modeChar, uniqueID, cmap, sorted_idx);
end

b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);
ciL0 = lme.Coefficients.Lower(1);
ciL1 = lme.Coefficients.Lower(2);
ciU0 = lme.Coefficients.Upper(1);
ciU1 = lme.Coefficients.Upper(2);
lineRange = linspace(xLimits(1), xLimits(2), 200);
if ~addSubjectLines || plotFixedEffectsRS
    plot(ax, lineRange, b0 + b1 * lineRange, 'k-', 'LineWidth', 3);
end
if ~addSubjectLines % add confidence interval if we don't have invidual subject lines otherwise too crowded
    fill(ax, [lineRange fliplr(lineRange)], ...
        [ciL0 + ciL1 * lineRange fliplr(ciU0 + ciU1 * lineRange)], ...
     'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);
end
scatter_pm_by_measurement(ax, xLog, tbl.log2ratio_visual_angle, subjectcolor, tbl.Measurement, markerSize);

set(ax, 'XTick', xTickVals, 'XTickLabel', xTickLabels, ...
    'YTick', log2(minPMLim):1:ceil(log2(maxPMLim)), ...
    'YTickLabel', string(2.^(log2(minPMLim):1:ceil(log2(maxPMLim)))), ...
    'FontName', 'Avenir', 'FontSize', 20);
set(ax, 'YTick', floor(log2(minPMLim)):1:ceil(log2(maxPMLim)), ...
    'YTickLabel', string(2.^(floor(log2(minPMLim)):1:ceil(log2(maxPMLim)))));
set(ax, 'XLim', xLimits, 'YLim', [floor(log2(minPMLim)) ceil(log2(maxPMLim))]);
box(ax, 'off');
grid(ax, 'off');
xlabel(ax, xlabelText, 'FontSize', 24);
if modeChar == 'A'
    ylabel(ax, {'Perceptual Magnification','log scale'}, 'FontSize', 24);
else
    ylabel(ax, '');
end
title(ax, sprintf(titleTemplate, 2.^b0, b1, local_format_pvalue(lme.Coefficients.pValue(2)), nsubjects), ...
    'FontSize', 18, 'FontWeight', 'normal');
end

function [xRaw, xLog, xlabelText, titleTemplate, xTickVals, xTickLabels, xLimits] = local_axis_info(tbl, modeChar, ElevationTransform)
switch modeChar
    case 'A'
        xRaw = tbl.Real_Visual_Angle;
        xLog = tbl.log2real_visual_angle;
        xlabelText = {'Visual Angle [degree]','log scale'};
        titleTemplate = 'PM=%.2fVA^{%.2f}\n p=%s \n n=%d';
    case 'D'
        xRaw = tbl.Distance;
        xLog = tbl.log2distance;
        xlabelText = {'Distance [m]','log scale'};
        titleTemplate = 'PM=%.2fD^{%.2f}\n p=%s \n n=%d';
    otherwise
        xRaw = tbl.ElevationModel;
        xLog = tbl.log2elevation;
        switch ElevationTransform
            case 1
                xlabelText = {'Elevation [degree]','log scale'};
                titleTemplate = 'PM=%.2f(1+E)^{%.2f}\n p=%s \n n=%d';
            case 2
                xlabelText = {'|Elevation| [degree]','log scale'};
                titleTemplate = 'PM=%.2f(1+|E|)^{%.2f}\n p=%s \n n=%d';
            case 5
                xlabelText = {'Elevation [degree]','log scale'};
                titleTemplate = 'PM=%.2f(1+E/90)^{%.2f}\n p=%s \n n=%d';
            otherwise
                xlabelText = {'|Elevation| [degree]','log scale'};
                titleTemplate = 'PM=%.2f(1+|E|/90)^{%.2f}\n p=%s \n n=%d';
        end
end

if modeChar == 'E'
    [xTickVals, xTickLabels, xLimits] = local_elevation_ticks_and_limits(xRaw, ElevationTransform);
else
    [xTickVals, xTickLabels] = local_oldstyle_ticks(xRaw, modeChar, ElevationTransform);
    xLimits = [log2(min(xRaw) * 0.95) log2(max(xRaw) * 1.05)];
end
end

function local_plot_subject_lines(ax, tbl, lme, modeChar, uniqueID, cmap, sorted_idx)
[reEfx, reNames] = randomEffects(lme);
levels = string(reNames.Level);
names = string(reNames.Name);

switch modeChar
    case 'A'
        slopeName = "log2real_visual_angle";
        xAll = tbl.log2real_visual_angle;
    case 'D'
        slopeName = "log2distance";
        xAll = tbl.log2distance;
    otherwise
        slopeName = "log2elevation";
        xAll = tbl.log2elevation;
end

for i = 1:numel(uniqueID)
    subj = string(uniqueID(i));
    rowMask = string(tbl.ID) == subj;
    if ~any(rowMask)
        continue;
    end

    cindex = find(string(uniqueID) == subj, 1, 'first');
    sorted_cindex = find(sorted_idx == cindex, 1, 'first');
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    thisColor = cmap(sorted_cindex, :);

    idxIntercept = find(levels == subj & names == "(Intercept)", 1, 'first');
    idxSlope = find(levels == subj & names == slopeName, 1, 'first');
    reIntercept = 0;
    reSlope = 0;
    if ~isempty(idxIntercept), reIntercept = reEfx(idxIntercept); end
    if ~isempty(idxSlope), reSlope = reEfx(idxSlope); end

    xSub = xAll(rowMask);
    xGrid = linspace(min(xSub), max(xSub), 50);
    yFit = (lme.Coefficients.Estimate(1) + reIntercept) + (lme.Coefficients.Estimate(2) + reSlope) * xGrid;
    plot(ax, xGrid, yFit, '-', 'Color', thisColor, 'LineWidth', 3);
end
end

function local_export_png(figHandle, outFile, dpi)
if nargin < 3 || isempty(dpi)
    dpi = 600;
end
set(figHandle, 'PaperPositionMode', 'auto');
print(figHandle, outFile, '-dpng', sprintf('-r%d', dpi));
end

function [xTickVals, xTickLabels] = local_oldstyle_ticks(xRaw, modeChar, ElevationTransform)
minVal = min(xRaw);
maxVal = max(xRaw);

[xTickVals, nativeVals] = local_adaptive_log_ticks(minVal, maxVal);

if modeChar == 'E' && any(ElevationTransform == [5 6])
    nativeVals = round(90 * (nativeVals - 1), 1);
elseif modeChar ~= 'E'
    nativeVals = round(nativeVals, 1);
end
xTickLabels = local_format_tick_labels(nativeVals);
end

function [xTickVals, xTickLabels, xLimits] = local_elevation_ticks_and_limits(xRaw, ElevationTransform)
xmin = min(xRaw);
xmax = max(xRaw);
xTickVals = log2([xmin xmax]);

if any(ElevationTransform == [5 6])
    nativeVals = round(90 * (2.^xTickVals - 1), 1);
else
    nativeVals = round(2.^xTickVals - 1, 1);
end
xTickLabels = local_format_tick_labels(nativeVals);

span = xmax - xmin;
margin = max(0.05 * span, 0.02);
plotMin = max(eps, xmin - margin);
plotMax = xmax + margin;
xLimits = log2([plotMin plotMax]);
end

function pStr = local_format_pvalue(pval)
if ~isfinite(pval)
    pStr = 'n/a';
elseif pval > 0.001
    pStr = sprintf('%.3f', pval);
elseif pval == 0
    pStr = sprintf('<%.2e', realmin);
else
    pStr = sprintf('%.2e', pval);
end
end

function labels = local_format_tick_labels(vals)
labels = strings(size(vals));
for i = 1:numel(vals)
    if abs(vals(i)) > 1000
        labels(i) = sprintf('%.1e', vals(i));
    else
        labels(i) = string(vals(i));
    end
end
end

function [tickPos, nativeVals] = local_adaptive_log_ticks(minVal, maxVal)
if ~isfinite(minVal) || ~isfinite(maxVal) || minVal <= 0 || maxVal <= 0
    tickPos = [];
    nativeVals = [];
    return
end

if maxVal < minVal
    tmp = minVal;
    minVal = maxVal;
    maxVal = tmp;
end

if minVal == maxVal
    nativeVals = minVal;
else
    logMin = log2(minVal);
    logMax = log2(maxVal);
    logSpan = logMax - logMin;

    if logSpan < 1
        nTicks = 2;
    elseif logSpan < 2.5
        nTicks = 3;
    elseif logSpan < 4.5
        nTicks = 4;
    else
        nTicks = 2;
    end

    nativeVals = 2.^linspace(logMin, logMax, nTicks);
    nativeVals(1) = minVal;
    nativeVals(end) = maxVal;
end

nativeVals = unique(nativeVals, 'stable');
tickPos = log2(nativeVals);
end
