function [lme_logPM_by_logAngle,lme_logPM_by_logDistance,lme_logPM_by_logElevation,...
    lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation,...
    lme_logPM_by_logAngleNDistanceNElevation] = ...
    Quad_PerceivedDisparity_by_task(tbl, tblName, ResultsDir, saveLME, mycolormap, sorted_idx, modelTransform, degreeFlag, fullUniqueID, removeOutlierParticipants)
% QUAD_PERCEIVEDDISPARITY_BY_TASK
% Mirror of Quad_PM_by_task for mean perceived disparity.

if nargin < 8 || isempty(degreeFlag)
    degreeFlag = 1; %#ok<NASGU>
end
if nargin < 7 || isempty(modelTransform)
    modelTransform = 2;
end
if nargin < 9 || isempty(fullUniqueID)
    fullUniqueID = [];
end
if nargin < 10 || isempty(removeOutlierParticipants)
    removeOutlierParticipants = false;
end

tbl = Quad_prepare_perceived_disparity_table(tbl, modelTransform, removeOutlierParticipants);

lme_logPM_by_logAngle = local_try_fitlme(tbl,'log2mean_disparity ~ log2real_visual_angle + (1|ID)');
lme_logPM_by_logDistance = local_try_fitlme(tbl,'log2mean_disparity ~ log2distance + (1|ID)');
lme_logPM_by_logElevation = local_try_fitlme(tbl,'log2mean_disparity ~ log2elevation + (1|ID)');

lme_logPM_by_logAngleNDistance = local_try_fitlme(tbl,'log2mean_disparity ~ log2real_visual_angle + log2distance + (1|ID)');
lme_logPM_by_logAngleNElevation = local_try_fitlme(tbl,'log2mean_disparity ~ log2real_visual_angle + log2elevation + (1|ID)');
lme_logPM_by_logDistanceNElevation = local_try_fitlme(tbl,'log2mean_disparity ~ log2distance + log2elevation + (1|ID)');
lme_logPM_by_logAngleNDistanceNElevation = local_try_fitlme(tbl,'log2mean_disparity ~ log2real_visual_angle + log2distance + log2elevation + (1|ID)');

if saveLME
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    savelmefile = fullfile(ResultsDir, [tblName '.txt']);
    diary(savelmefile);
    local_log_model('log2mean_disparity ~ log2real_visual_angle + (1|ID)', lme_logPM_by_logAngle)
    local_log_model('log2mean_disparity ~ log2distance + (1|ID)', lme_logPM_by_logDistance)
    local_log_model('log2mean_disparity ~ log2elevation + (1|ID)', lme_logPM_by_logElevation)
    local_log_model('log2mean_disparity ~ log2real_visual_angle + log2distance + (1|ID)', lme_logPM_by_logAngleNDistance)
    local_log_model('log2mean_disparity ~ log2real_visual_angle + log2elevation + (1|ID)', lme_logPM_by_logAngleNElevation)
    local_log_model('log2mean_disparity ~ log2distance + log2elevation + (1|ID)', lme_logPM_by_logDistanceNElevation)
    local_log_model('log2mean_disparity ~ log2real_visual_angle + log2distance + log2elevation + (1|ID)', lme_logPM_by_logAngleNDistanceNElevation)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2real_visual_angle + (1|ID)', lme_logPM_by_logAngle, ...
        'log2mean_disparity ~ log2real_visual_angle + log2distance + (1|ID)', lme_logPM_by_logAngleNDistance)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2real_visual_angle + (1|ID)', lme_logPM_by_logAngle, ...
        'log2mean_disparity ~ log2real_visual_angle + log2elevation + (1|ID)', lme_logPM_by_logAngleNElevation)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2distance + (1|ID)', lme_logPM_by_logDistance, ...
        'log2mean_disparity ~ log2real_visual_angle + log2distance + (1|ID)', lme_logPM_by_logAngleNDistance)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2distance + (1|ID)', lme_logPM_by_logDistance, ...
        'log2mean_disparity ~ log2distance + log2elevation + (1|ID)', lme_logPM_by_logDistanceNElevation)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2elevation + (1|ID)', lme_logPM_by_logElevation, ...
        'log2mean_disparity ~ log2real_visual_angle + log2elevation + (1|ID)', lme_logPM_by_logAngleNElevation)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2elevation + (1|ID)', lme_logPM_by_logElevation, ...
        'log2mean_disparity ~ log2distance + log2elevation + (1|ID)', lme_logPM_by_logDistanceNElevation)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2real_visual_angle + log2distance + (1|ID)', lme_logPM_by_logAngleNDistance, ...
        'log2mean_disparity ~ log2real_visual_angle + log2distance + log2elevation + (1|ID)', lme_logPM_by_logAngleNDistanceNElevation)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2real_visual_angle + log2elevation + (1|ID)', lme_logPM_by_logAngleNElevation, ...
        'log2mean_disparity ~ log2real_visual_angle + log2distance + log2elevation + (1|ID)', lme_logPM_by_logAngleNDistanceNElevation)
    local_compare_if_available( ...
        'log2mean_disparity ~ log2distance + log2elevation + (1|ID)', lme_logPM_by_logDistanceNElevation, ...
        'log2mean_disparity ~ log2real_visual_angle + log2distance + log2elevation + (1|ID)', lme_logPM_by_logAngleNDistanceNElevation)
    diary off
end

subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID);
minDisp = max(0.01, min(tbl.MeanDisparity));
maxDisp = max(tbl.MeanDisparity);

figh = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 1 .6], 'Name', tblName, 'Visible', 'off');
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
nIDs = numel(categories(removecats(tbl.ID)));

local_plot_single_model(nexttile, tbl, subjectcolor, lme_logPM_by_logAngle, 'VA', minDisp, maxDisp, modelTransform, nIDs);
local_plot_single_model(nexttile, tbl, subjectcolor, lme_logPM_by_logDistance, 'D', minDisp, maxDisp, modelTransform, nIDs);
local_plot_single_model(nexttile, tbl, subjectcolor, lme_logPM_by_logElevation, 'E', minDisp, maxDisp, modelTransform, nIDs);

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end
exportgraphics(figh, fullfile(ResultsDir, [tblName '.png']), 'Resolution', 600);
close(figh);
end

function subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID)
if isempty(fullUniqueID)
    uniqueID = categories(removecats(tbl.ID));
else
    uniqueID = string(fullUniqueID(:));
end
subjectcolor = zeros(height(tbl), 3);
for c = 1:height(tbl)
    cindex = find(strcmp(uniqueID, char(string(tbl.ID(c)))), 1, 'first');
    sorted_cindex = find(sorted_idx == cindex, 1, 'first');
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    subjectcolor(c,:) = mycolormap(sorted_cindex,:);
end
end

function local_plot_single_model(ax, tbl, subjectcolor, lme, modeChar, minDisp, maxDisp, modelTransform, nIDs)
hold(ax, 'on');

switch modeChar
    case 'VA'
        x = tbl.Real_Visual_Angle;
        xlog = tbl.log2real_visual_angle;
        xlabelText = {'Visual Angle [deg]','log scale'};
        tickVals = local_log_ticks(min(x), max(x), false);
    case 'D'
        x = tbl.Distance;
        xlog = tbl.log2distance;
        xlabelText = {'Distance [m]','log scale'};
        tickVals = local_log_ticks(min(x), max(x), false);
    otherwise
        x = tbl.ElevationModel;
        xlog = tbl.log2elevation;
        if modelTransform == 2
            xlabelText = {'|Elevation| [deg]','log scale'};
            predictorToken = '|E|';
        elseif modelTransform == 6
            xlabelText = {'|Elevation| [deg]','log scale'};
            predictorToken = '|E|/90';
        else
            xlabelText = {'Elevation [deg]','log scale'};
            predictorToken = 'E/90';
        end
        tickVals = local_log_ticks(min(x), max(x), true, modelTransform);
end

if strcmp(modeChar, 'VA')
    titleFormula = 'Disparity=%.2f(VA)^{%.2f}\np=%s\nn=%d';
elseif strcmp(modeChar, 'D')
    titleFormula = 'Disparity=%.2f(D)^{%.2f}\np=%s\nn=%d';
elseif modelTransform == 2
    titleFormula = 'Disparity=%.2f(1+|E|)^{%.2f}\np=%s\nn=%d';
elseif modelTransform == 6
    titleFormula = 'Disparity=%.2f(1+|E|/90)^{%.2f}\np=%s\nn=%d';
else
    titleFormula = 'Disparity=%.2f(1+E/90)^{%.2f}\np=%s\nn=%d';
end

    y = tbl.log2mean_disparity;

    xlinerange = linspace(min(xlog), max(xlog), 200);
    if isempty(lme)
        title(ax, {'Model unavailable','rank-deficient or singular'}, 'FontSize', 16, 'FontWeight', 'normal');
        return;
    end

    b0 = lme.Coefficients.Estimate(1);
    b1 = lme.Coefficients.Estimate(2);
    ciL0 = lme.Coefficients.Lower(1);
    ciL1 = lme.Coefficients.Lower(2);
    ciU0 = lme.Coefficients.Upper(1);
    ciU1 = lme.Coefficients.Upper(2);

    yFit = b0 + b1 * xlinerange;
    xvector = [xlinerange fliplr(xlinerange)];
    yvector = [ciL0 + ciL1 * xlinerange fliplr(ciU0 + ciU1 * xlinerange)];
    fill(ax, xvector, yvector, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);
    plot(ax, xlinerange, yFit, 'k-', 'LineWidth', 3);
    scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);

    set(ax, 'XTick', tickVals.positions, 'XTickLabel', tickVals.labels, ...
        'YTick', floor(log2(minDisp)):ceil(log2(maxDisp)), ...
        'YTickLabel', string(2.^(floor(log2(minDisp)):ceil(log2(maxDisp)))), ...
        'FontName', 'Avenir', 'FontSize', 18);
    xlabel(ax, xlabelText, 'FontSize', 22);
    ylabel(ax, {'Perceived Disparity [deg]','log scale'}, 'FontSize', 22);
    xlim(ax, local_expand_log_limits(x));
    ylim(ax, [floor(log2(minDisp)) ceil(log2(maxDisp))]);
    box(ax, 'off');
    grid(ax, 'off');

    b0 = lme.Coefficients.Estimate(1);
    b1 = lme.Coefficients.Estimate(2);
    pval = lme.Coefficients.pValue(2);
    titleStr = sprintf(titleFormula, 2.^b0, b1, local_format_pvalue(pval), nIDs);
    title(ax, titleStr, 'FontSize', 16, 'FontWeight', 'normal');
end

function pStr = local_format_pvalue(pval)
if pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end

function lme = local_try_fitlme(tbl, formulaStr)
try
    lme = fitlme(tbl, formulaStr);
catch ME
    fprintf('Skipping model: %s\nReason: %s\n', formulaStr, ME.message);
    lme = [];
end
end

function local_log_model(formulaStr, lme)
fprintf('Model: %s\n', formulaStr);
if isempty(lme)
    fprintf('Skipped: rank-deficient or singular design.\n\n');
else
    disp(lme);
end
end

function local_compare_if_available(formula1, lme1, formula2, lme2)
if isempty(lme1) || isempty(lme2)
    fprintf('Comparison skipped:\n');
    fprintf('  %s\n', formula1);
    fprintf('  %s\n', formula2);
    fprintf('Reason: one or both models were unavailable.\n\n');
else
    fprintf('Model comparison:\n');
    fprintf('  %s\n', formula1);
    fprintf('  %s\n', formula2);
    cmpTbl = compare(lme1, lme2);
    try
        cmpTbl.Model = string({formula1; formula2});
    catch
    end
    disp(cmpTbl)
end
end

function tickStruct = local_log_ticks(minVal, maxVal, isElevation, modelTransform)
if nargin < 3
    isElevation = false;
end

if nargin < 4
    modelTransform = [];
end

if ~isElevation
    tickVals = unique(round(logspace(log10(minVal), log10(maxVal), 4), 2));
    tickVals = unique([minVal; tickVals(:); maxVal]);
    tickStruct = local_finalize_ticks(tickVals, log2(tickVals));
    return;
end

if modelTransform == 2
    nativeVals = unique(max(0, round(linspace(max(0, minVal - 1), max(0, maxVal - 1), 4), 1)));
    nativeVals = unique([max(0, minVal - 1); nativeVals(:); max(0, maxVal - 1)]);
    tickStruct = local_finalize_ticks(nativeVals, log2(nativeVals + 1));
else
    nativeVals = [-45 -30 -15 -5 0 5 15 30 45 60];
    tickPos = log2(1 + nativeVals/90);
    valid = isfinite(tickPos) & (1 + nativeVals/90) > 0;
    nativeVals = nativeVals(valid);
    tickPos = tickPos(valid);
    dataMinNative = 90 * (minVal - 1);
    dataMaxNative = 90 * (maxVal - 1);
    inRange = nativeVals >= dataMinNative & nativeVals <= dataMaxNative;
    nativeVals = nativeVals(inRange);
    tickPos = tickPos(inRange);
    nativeVals = unique([round(dataMinNative, 1) nativeVals round(dataMaxNative, 1)], 'stable');
    tickStruct = local_finalize_ticks(nativeVals, log2(1 + nativeVals/90));
end
end

function lims = local_expand_log_limits(x)
xmin = min(x);
xmax = max(x);
span = xmax - xmin;
if span <= 0
    pad = max(0.01 * max(abs(xmin), 1), 0.01);
else
    pad = max(0.05 * span, 0.005 * max(abs([xmin xmax])));
end
xlow = max(eps, xmin - pad);
xhigh = xmax + pad;
lims = log2([xlow xhigh]);
end

function tickStruct = local_finalize_ticks(labelVals, positions)
labelVals = labelVals(:);
positions = positions(:);
valid = isfinite(labelVals) & isfinite(positions);
labelVals = labelVals(valid);
positions = positions(valid);

if numel(labelVals) <= 2
    tickStruct.positions = positions;
    tickStruct.labels = string(round(labelVals, 2));
    return;
end

keep = true(size(positions));
minSep = 0.18;
for i = 2:numel(positions)-1
    if abs(positions(i) - positions(i-1)) < minSep || abs(positions(i+1) - positions(i)) < minSep
        keep(i) = false;
    end
end

positions = positions(keep);
labelVals = labelVals(keep);

if numel(labelVals) < 2
    positions = [positions(1); positions(end)];
    labelVals = [labelVals(1); labelVals(end)];
end

tickStruct.positions = positions;
tickStruct.labels = string(round(labelVals, 2));
end
