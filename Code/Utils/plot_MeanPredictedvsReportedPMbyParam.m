function [SummaryItrParam, SummaryParam, fh] = plot_MeanPredictedvsReportedPMbyParam(T, Param, saveFilename, figName, errType)
%% Plot mean predicted vs mean reported PM by Param level (aggregated across iterations)
%
% Sister function to plot_PredictedvsReportedPMbyParam.m
%
% For each Param level:
%   - Computes per-iteration means of reported PM (Ratio_Visual_Angle / close match)
%     and predicted PM for each model (columns containing 'predicted_PM').
%   - Then computes, across iterations, the mean and SD (or SEM) of those per-iteration means.
%   - Plots mean(predicted) vs mean(reported) with BOTH x- and y-error bars.
%     Points are colored by Param level.
%
% Inputs
%   T            : table
%   Param        : string/char name of the parameter column (e.g., 'Distance', 'Elevation')
%   saveFilename : optional (if provided, exports figure)
%   figName      : optional figure name
%   errType      : optional, 'sd' (default) or 'sem'
%
% Outputs
%   SummaryItrParam : table with one row per (Iteration, Param) containing means
%   SummaryParam    : table with one row per Param containing across-iteration mean and SD/SEM
%   fh              : figure handle

if ~exist('T','var') || isempty(T) || ~istable(T)
    error('Input T must be a non-empty table.');
end

if nargin < 2 || isempty(Param)
    error('You must provide Param as the name of a column in T.');
end
Param = string(Param);

saveFlag = (nargin >= 3) && exist('saveFilename','var') && ~isempty(saveFilename);
if nargin < 4 || ~exist('figName','var'); figName = []; end
if nargin < 5 || ~exist('errType','var') || isempty(errType); errType = 'sd'; end
errType = lower(string(errType));
if ~ismember(errType, ["sd" "sem"])
    error("errType must be 'sd' or 'sem'.");
end

% Normalize Param input
Param = string(Param);
if numel(Param) ~= 1 || strlength(Param) == 0
    error("Param must be a nonempty scalar string/char specifying a column name in T.");
end


%% ---- Identify required columns ----
% Iteration
if ~ismember("Iteration", string(T.Properties.VariableNames))
    error("Missing required column: Iteration");
end

% Param
if ~ismember(Param, string(T.Properties.VariableNames))
    error("Missing required param column: %s", Param);
end

% Actual (Ratio_Visual_Angle) with fallback if spelled differently
actualName = "";
if ismember("Ratio_Visual_Angle", string(T.Properties.VariableNames))
    actualName = "Ratio_Visual_Angle";
elseif ismember("Ration_Visual_Angle", string(T.Properties.VariableNames))
    actualName = "Ration_Visual_Angle";
else
    v = lower(string(T.Properties.VariableNames));
    idx = find(contains(v,"ratio") & contains(v,"visual") & contains(v,"angle"), 1, "first");
    if ~isempty(idx)
        actualName = string(T.Properties.VariableNames{idx});
    else
        error("Could not find Ratio_Visual_Angle (or close match) in the table.");
    end
end

% Predicted columns: prefer those containing 'predicted_PM'
vnames = string(T.Properties.VariableNames);
predCols = vnames(contains(lower(vnames), "predicted_pm"));
if isempty(predCols)
    % fallback to any predicted
    predCols = vnames(contains(lower(vnames), "predicted"));
end
if isempty(predCols)
    error("No columns containing 'predicted_PM' (or 'predicted') were found.");
end

%% ---- Normalize grouping keys ----
itr = T.Iteration;
if iscell(itr) || isstring(itr)
    itr = string(itr);
elseif iscategorical(itr)
    itr = string(itr);
end

paramCol = T.(Param);

% Sorted unique Param levels (preserve numeric ordering when possible)
if isnumeric(paramCol)
    uParam = unique(paramCol);
    uParam = sort(uParam(:));
elseif iscategorical(paramCol)
    uParam = categories(paramCol);
    uParam = string(uParam(:));
    uParam = sort(uParam);
else
    uParam = unique(string(paramCol));
    uParam = sort(uParam(:));
end

%% ---- Step 1: per (Iteration x Param) mean reported + mean predicted (each model) ----
[G1, itrLevels, paramLevels] = findgroups(itr, paramCol);

xReported = T.(actualName);
meanReported = splitapply(@(x) mean(x, 'omitnan'), xReported, G1);

nModels = numel(predCols);
meanPred = nan(numel(meanReported), nModels);
for m = 1:nModels
    yhat = T.(predCols(m));
    meanPred(:,m) = splitapply(@(x) mean(x, 'omitnan'), yhat, G1);
end

% Summary table at Iteration x Param granularity
varNames1 = ["Iteration", Param, "MeanReported"];
SummaryItrParam = table(itrLevels, paramLevels, meanReported, 'VariableNames', varNames1);
for m = 1:nModels
    nm = predCols(m) + "_MeanByItrParam";
    nm = matlab.lang.makeValidName(nm);
    SummaryItrParam.(nm) = meanPred(:,m);
end

%% ---- Step 2: across-iteration mean + SD (or SEM) for each Param (and each model) ----
[G2, uParamLevels] = findgroups(paramLevels);

xMean = splitapply(@(x) mean(x, 'omitnan'), meanReported, G2);
xStd  = splitapply(@(x) std(x,  'omitnan'), meanReported, G2);
xN    = splitapply(@(x) sum(isfinite(x)), meanReported, G2);

if errType == "sem"
    xErr = xStd ./ sqrt(max(xN,1));
else
    xErr = xStd;
end

yMean = nan(numel(uParamLevels), nModels);
yStd  = nan(numel(uParamLevels), nModels);
yN    = nan(numel(uParamLevels), nModels);
yErr  = nan(numel(uParamLevels), nModels);

for m = 1:nModels
    ym = meanPred(:,m);
    yMean(:,m) = splitapply(@(x) mean(x, 'omitnan'), ym, G2);
    yStd(:,m)  = splitapply(@(x) std(x,  'omitnan'), ym, G2);
    yN(:,m)    = splitapply(@(x) sum(isfinite(x)), ym, G2);
    if errType == "sem"
        yErr(:,m) = yStd(:,m) ./ sqrt(max(yN(:,m),1));
    else
        yErr(:,m) = yStd(:,m);
    end
end

% Param order + mapping to colormap
% Align uParamLevels ordering to sorted uParam when possible
if isnumeric(paramCol)
    % uParamLevels should be numeric
    [uParamSorted, ord] = sort(uParamLevels);
    xMean = xMean(ord); xErr = xErr(ord);
    yMean = yMean(ord,:); yErr = yErr(ord,:);
    uParamLevels = uParamSorted;
else
    uParamLevelsStr = string(uParamLevels);
    [uParamSortedStr, ord] = sort(uParamLevelsStr);
    xMean = xMean(ord); xErr = xErr(ord);
    yMean = yMean(ord,:); yErr = yErr(ord,:);
    uParamLevels = uParamSortedStr;
end

% Build SummaryParam table (one row per Param)
varNames2 = [Param, "MeanReported_AcrossItr", "StdReported_AcrossItr", "NItr_WithData"];
SummaryParam = table(uParamLevels, xMean, xStd, xN, 'VariableNames', varNames2);
for m = 1:nModels
    base = matlab.lang.makeValidName(predCols(m));
    SummaryParam.(base + "_MeanAcrossItr") = yMean(:,m);
    SummaryParam.(base + "_StdAcrossItr")  = yStd(:,m);
    SummaryParam.(base + "_NItrWithData")  = yN(:,m);
end

%% ---- Plot: one panel per model; one point per Param level with x/y error bars ----
% Colormap and color indexing by Param level
nParam = numel(uParamLevels);
cmap = jet(max(nParam, 2));
markerSize=15;
% Axis limits based on means +/- errors
allMin = +inf; allMax = -inf;
for m = 1:nModels
    vx = xMean - xErr;
    wx = xMean + xErr;
    vy = yMean(:,m) - yErr(:,m);
    wy = yMean(:,m) + yErr(:,m);
    allMin = min([allMin; vx(:); vy(:)], [], 'omitnan');
    allMax = max([allMax; wx(:); wy(:)], [], 'omitnan');
end
if ~isfinite(allMin) || ~isfinite(allMax) || allMin == allMax
    allMin = 0; allMax = 1;
end
pad = 0.05 * (allMax - allMin);
minX = allMin - pad;
maxX = allMax + pad;

fh = figure('Color','w','Name',figName,'Units','normalized','Position',[0 0 1 .5]);
tiledlayout(1, nModels, 'TileSpacing','compact');

for m = 1:nModels
    nexttile; hold on;

    % Reference line
    plot([minX maxX], [minX maxX], 'k:');

    % Error-bar cap size
    cap = 0.01 * (maxX - minX);

    % Draw per-point x/y errorbars in the Param's color
    for p = 1:nParam
        xp = xMean(p);  yp = yMean(p,m);
        dx = xErr(p);   dy = yErr(p,m);
        if ~isfinite(xp) || ~isfinite(yp)
            continue
        end

        colr = cmap(p,:);

        % Horizontal error bar (x)
        if isfinite(dx) && dx > 0
            plot([xp-dx xp+dx], [yp yp], 'Color', colr, 'LineWidth', 1);
            plot([xp-dx xp-dx], [yp-cap yp+cap], 'Color', colr, 'LineWidth', 1);
            plot([xp+dx xp+dx], [yp-cap yp+cap], 'Color', colr, 'LineWidth', 1);
        end

        % Vertical error bar (y)
        if isfinite(dy) && dy > 0
            plot([xp xp], [yp-dy yp+dy], 'Color', colr, 'LineWidth', 1);
            plot([xp-cap xp+cap], [yp-dy yp-dy], 'Color', colr, 'LineWidth', 1);
            plot([xp-cap xp+cap], [yp+dy yp+dy], 'Color', colr, 'LineWidth', 1);
        end
    end

    % Scatter points colored by Param index
    scatter(xMean, yMean(:,m), markerSize, (1:nParam)', 'filled');
    colormap(cmap);
    caxis([1 nParam]);

    xlabel('Mean reported PM');
    ylabel('Mean predicted PM');

    ax = gca;
    ax.XLim = [minX maxX];
    ax.YLim = [minX maxX];
    ax.FontName = 'Avenir';
    ax.FontSize = 10;
    grid off; box off; axis square;
    ax.XTick=ax.YTick;

    % Title: model name from predicted column
    ttl = predCols(m);
    ttl = erase(ttl, 'predicted_PM_logPM_by_log');
    title(strrep(ttl, "_", "\_"), 'Interpreter','tex','FontSize',10);
end

% Shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = Param;
cb.Label.FontSize =10;
stepsize=4;
cb.Ticks = 1:stepsize:nParam;

% Tick labels
if isnumeric(uParamLevels)
    uParamLevels=round(uParamLevels(1:stepsize:nParam),1);
    cb.TickLabels=uParamLevels;
else
    cb.TickLabels = cellstr(string(uParamLevels));
end
cb.FontName = 'Avenir';
cb.FontSize = 8;


if saveFlag
    exportgraphics(fh, saveFilename, 'Resolution', 600);
end

end