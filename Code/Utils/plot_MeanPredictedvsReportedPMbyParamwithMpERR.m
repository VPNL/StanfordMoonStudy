function [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(T, Param, saveFilename, figName, errType)
%% Plot mean predicted vs mean reported PM by Param level (aggregated across iterations)
%
% For each Param level:
%   - Computes per-iteration means of reported PM (Ratio_Visual_Angle)
%     and predicted PM for each model (columns containing 'predicted_PM').
%   - Then computes, across iterations, the mean and SD (or SEM) of those per-iteration means.
%   - Plots mean(predicted) vs mean(reported) with BOTH x- and y-error bars.
%     Points are colored by Param level.
%
% Additional error summaries:
%   - Mean squared error (MSE) between per-(Iteration x Param) mean predicted and mean reported.
%   - Mean percentage error between per-(Iteration x Param) mean predicted and mean reported.
%   - Summaries per iteration across Param levels (mean across Param levels per iteration).
%   - Violin plot of the per-iteration mean MSEs for all models.
%   - Bar+dot plot of mean percentage error across iterations for each model, with per-iteration dots.
%
% Inputs
%   T            : table
%   Param        : string/char name of the parameter column (e.g., 'Distance', 'Elevation')
%   saveFilename : optional (if provided, exports main figure; violin uses suffix '_violin')
%   figName      : optional figure name
%   errType      : optional, 'sd' (default) or 'sem'
%  violinplot    : optional if violinplot=1; adds a violin plot of the
%                  error; default=0
% 
%
%
% Outputs
%   SummaryItrParam  : table with one row per (Iteration, Param) containing means and error metrics
%   SummaryParam     : table with one row per Param containing across-iteration mean and SD/SEM
%   MSE_ItrParam     : long-format table with one row per (Iteration, Param, Model) containing MSE
%   MSE_Itr          : table with one row per Iteration containing mean MSE across Param levels (per model)
%   fh               : figure handle (mean predicted vs mean reported panels)
%   fh_violin        : figure handle (violin plot of mean MSE across iterations)
%   PctErr_ItrParam  : long-format table with one row per (Iteration, Param, Model) containing mean % error
%   PctErr_Itr       : table with one row per Iteration containing mean % error across Param levels (per model)
%   fh_pctbar        : figure handle (bar+dot plot of mean % error across iterations)

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

if ~exist('violinplot','var')
    violinplot=0;
end

% Normalize Param input
if numel(Param) ~= 1 || strlength(Param) == 0
    error("Param must be a nonempty scalar string/char specifying a column name in T.");
end

% Initialize additional outputs
MSE_ItrParam    = table();
MSE_Itr         = table();
PctErr_ItrParam = table();
PctErr_Itr      = table();
fh              = [];
fh_violin       = [];
fh_pctbar       = [];

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

% Optional: reorder models if we can match a canonical 7-model order
desiredOrder = ["logPM_by_logAngle", ...
                "logPM_by_logDistance", ...
                "logPM_by_logElevation", ...
                "logPM_by_logAngleNDistance", ...
                "logPM_by_logAngleNElevation", ...
                "logPM_by_logDistanceNElevation", ...
                "logPM_by_logAngleNDistanceNElevation"];
[predCols, ~] = local_reorderPredCols(predCols, desiredOrder);

%% ---- Normalize grouping keys ----
itr = T.Iteration;
if iscell(itr) || isstring(itr)
    itr = str2double(string(itr));
elseif iscategorical(itr)
    itr = str2double(string(itr));
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
    nm = matlab.lang.makeValidName(predCols(m) + "_MeanByItrParam");
    SummaryItrParam.(nm) = meanPred(:,m);
end

%% ---- Step 1b: error metrics at (Iteration x Param) level ----
% Mean squared error (MSE)
mseMat = (meanPred - meanReported).^2; % nGroups x nModels

% Mean percentage error
% Default: absolute percentage error to avoid cancellation across Param levels
% pctErr = 100 * abs(pred - reported) / abs(reported)
% If reported == 0, set to NaN
absDen = abs(meanReported);
absDen(absDen == 0) = NaN;
pctErrMat = 100 * abs(meanPred - meanReported) ./ absDen;

% Add wide MSE and %error columns to SummaryItrParam
for m = 1:nModels
    nmMSE = matlab.lang.makeValidName(predCols(m) + "_MSEByItrParam");
    nmPE  = matlab.lang.makeValidName(predCols(m) + "_MeanPctErrByItrParam");
    SummaryItrParam.(nmMSE) = mseMat(:,m);
    SummaryItrParam.(nmPE)  = pctErrMat(:,m);
end

% Long-format MSE table
nGroups = numel(meanReported);
IterationLong = repmat(itrLevels, nModels, 1);
ParamLong     = repmat(paramLevels, nModels, 1);
ModelLong     = repelem(predCols(:), nGroups, 1);
MSELong       = reshape(mseMat, [], 1);
MSE_ItrParam  = table(IterationLong, ParamLong, ModelLong, MSELong, ...
    'VariableNames', ["Iteration", Param, "Model", "MeanSqError"]);

% Long-format mean % error table
PctErrLong      = reshape(pctErrMat, [], 1);
PctErr_ItrParam = table(IterationLong, ParamLong, ModelLong, PctErrLong, ...
    'VariableNames', ["Iteration", Param, "Model", "MeanPctError"]);

%% ---- Step 1c: summarize per iteration across Param levels (per model) ----
Gitr = findgroups(itrLevels);
uItrLevels = splitapply(@(x) x(1), itrLevels, Gitr);

% Per-iteration mean MSE across Param levels
mseItrMean = nan(numel(uItrLevels), nModels);
for m = 1:nModels
    mm = mseMat(:,m);
    mseItrMean(:,m) = splitapply(@(x) mean(x, 'omitnan'), mm, Gitr);
end

MSE_Itr = table(uItrLevels, 'VariableNames', "Iteration");
for m = 1:nModels
    base = matlab.lang.makeValidName(predCols(m));
    MSE_Itr.(base + "_MeanMSE_AcrossParam") = mseItrMean(:,m);
end

% Per-iteration mean % error across Param levels
pctErrItrMean = nan(numel(uItrLevels), nModels);
for m = 1:nModels
    pp = pctErrMat(:,m);
    pctErrItrMean(:,m) = splitapply(@(x) mean(x, 'omitnan'), pp, Gitr);
end

PctErr_Itr = table(uItrLevels, 'VariableNames', "Iteration");
for m = 1:nModels
    base = matlab.lang.makeValidName(predCols(m));
    PctErr_Itr.(base + "_MeanPctErr_AcrossParam") = pctErrItrMean(:,m);
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

% Align uParamLevels ordering to sorted uParam when possible
if isnumeric(paramCol)
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

if strcmp(Param,'Distance')
     cmap=brighten(flipud(colormap(turbo(nParam))),0.4);
elseif strcmp(Param,'Elevation') 
     cmap = brighten(earthColormap(nParam),.2);
elseif strcmp(Param,'Real_Visual_Angle')
    cmap = flipud(purpleVioletBlueTurquoiseGreenColorMap(ceil(nParam)));
else
    cmap = jet(max(nParam, 2));
end


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
markerSize = 20;
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

    xlabel('Mean participant PM');
    ylabel('Mean predicted PM');

    ax = gca;
    ax.XLim = [minX maxX];
    ax.YLim = [minX maxX];
    ax.FontName = 'Avenir';
    ax.FontSize = 10;
    grid off; box off; axis square;

    % Title: model name from predicted column
    ttl = predCols(m);
    ttl = erase(ttl, "predicted_PM_logPM_by_");
    title(strrep(ttl, "_", "\_"), 'Interpreter','tex','FontSize',10);
end

% % Shared colorbar
% cb = colorbar;
% cb.Layout.Tile = 'east';
% cb.Label.String = Param;
% cb.Label.Interpreter='none'
% stepsize = 4;
% cb.Ticks = 1:stepsize:nParam;
% 
% % Tick labels
% if isnumeric(uParamLevels)
%     cb.TickLabels = string(round(uParamLevels(1:stepsize:nParam), 3));
% else
%     cb.TickLabels = cellstr(string(uParamLevels(1:stepsize:nParam)));
% end
% cb.FontName = 'Avenir';
% cb.FontSize = 8;
% 

% Shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = Param;
cb.Label.Interpreter = 'none';

% Derive an adaptive step size from nParam
% Target total number of ticks (including first & last). Adjust if you prefer.
nTicksTarget = min(8, max(3, ceil(nParam/5)));  % heuristic: ~1 tick per ~5 bins, capped at 8
stepsize = max(1, round((nParam - 1) / (nTicksTarget - 1)));

% Always include first and last bin, plus evenly stepped ticks in the middle
tickBins = 1:stepsize:nParam;
tickBins = unique([1 tickBins nParam], 'stable');

cb.Ticks = tickBins;

% Tick labels
if isnumeric(uParamLevels)
    cb.TickLabels = string(round(uParamLevels(tickBins), 2));
else
    cb.TickLabels = cellstr(string(uParamLevels(tickBins)));
end

cb.FontName = 'Avenir';
cb.FontSize = 8;

if saveFlag
    exportgraphics(fh, saveFilename, 'Resolution', 600);
end

%% plot errors
% Labels for x-axis
modelLabels = predCols;
modelLabels = erase(modelLabels, "predicted_PM_logPM_by_");
modelLabels = strrep(modelLabels, "_", " ");
modelLabels = string(modelLabels);

%% ---- Violin plot of mean squared errors across iterations (one violin per model) ----
if violinplot
    % Use per-iteration mean MSE (averaged across Param levels)
    figNameStr = string(figName);
    if strlength(figNameStr)==0
        violinFigName = "MSE Violin";
    else
        violinFigName = figNameStr + " — MSE Violin";
    end
    fh_violin = figure('Color','w','Name',violinFigName, 'Units','normalized','Position',[0.1 0.1 0.25 0.6]);
    axv = axes(fh_violin);
    hold(axv, 'on');
    
    
    % Plot violins
    width = 0.35;
    for m = 1:nModels
        d = mseItrMean(:,m);
        d = d(isfinite(d));
        if isempty(d)
            continue
        end
        local_violin(axv, d, m, width);
        % overlay median tick
        med = median(d, 'omitnan');
        plot(axv, [m-0.12 m+0.12], [med med], 'k-', 'LineWidth', 1.5);
    end
    
    xlim(axv, [0.5 nModels+0.5]);
    axv.XTick = 1:nModels;
    axv.XTickLabel = cellstr(modelLabels);
    axv.XTickLabelRotation = 90;
    axv.FontName = 'Avenir';
    axv.FontSize = 13;
    ylabel(axv, "Mean squared error (over " + Param + ")",'Interpreter','none');
    grid(axv, 'off'); box(axv, 'off');
    
    if saveFlag
        % Save violin plot with suffix
        [p,f,e] = fileparts(char(saveFilename));
        save2 = fullfile(p, f + "_violin" + e);
        exportgraphics(fh_violin, save2, 'Resolution', 600);
    end
end

%% ---- Bar + dot plot of mean percentage error across iterations (per model) ----
% Bars: mean across iterations of per-iteration mean % error (already averaged across Param levels)
figNameStr = string(figName);
meanPctErrAcrossItr = mean(pctErrItrMean, 1, 'omitnan');

if strlength(figNameStr)==0
    pctFigName = "Mean % Error Bar";
else
    pctFigName = figNameStr + " — Mean % Error";
end
fh_pctbar = figure('Color','w','Name',pctFigName, 'Units','normalized','Position',[0.5 0.1 0.25 0.6]);
axb = axes(fh_pctbar);
hold(axb, 'on');

b=bar(axb, 1:nModels, meanPctErrAcrossItr);
b(1).FaceColor = [0.75 0.75 0.75]; 
b(1).EdgeColor='none';

% Overlay per-iteration dots (gray), one dot per iteration per model
for m = 1:nModels
    y = pctErrItrMean(:,m);
    y = y(isfinite(y));
    if isempty(y)
        continue
    end
    try
        jitter = (rand(size(y)) - 0.5) * 0.18;
        scatter(axb, m + jitter, y, 18, [0.5 0.5 0.5], 'filled', 'MarkerFaceAlpha', 0.65, 'MarkerEdgeAlpha', 0.65);
    catch
        jitter = (rand(size(y)) - 0.5) * 0.18;
        scatter(axb, m + jitter, y, 18, [0.5 0.65 0.5], 'filled');
    end
end

axb.XLim = [0.5 nModels+0.5];
axb.YLim = [0.5 max([40  max(max(pctErrItrMean))])];
axb.XTick = 1:nModels;
axb.XTickLabel = cellstr(modelLabels);
axb.XTickLabelRotation = 90;
axb.FontName = 'Avenir';
axb.FontSize = 16;
ylabel(axb, "Mean % error (over " + Param + ")",'Interpreter','none');
grid(axb, 'off'); box(axb, 'off');

if saveFlag
    [p,f,e] = fileparts(char(saveFilename));
    save3 = fullfile(p, f + "_pctError" + e);
    exportgraphics(fh_pctbar, save3, 'Resolution', 600);
end

end

%% ===== Local helper functions =====
function [predColsOut, applied] = local_reorderPredCols(predColsIn, desiredOrder)
% Reorder predicted columns if we can match all desiredOrder substrings.
predColsOut = predColsIn;
applied = false;

predLower = lower(string(predColsIn));
wantLower = lower(string(desiredOrder));

idx = nan(size(wantLower));
for k = 1:numel(wantLower)
    hit = find(contains(predLower, wantLower(k)), 1, "first");
    if isempty(hit)
        idx = [];
        break
    end
    idx(k) = hit;
end

if ~isempty(idx) && numel(unique(idx)) == numel(idx)
    predColsOut = predColsIn(idx);
    applied = true;
end
end

function local_violin(ax, data, x0, width)
% Minimal violin plot using kernel density (falls back to histogram if ksdensity unavailable).
data = data(:);
data = data(isfinite(data));
if isempty(data)
    return
end

% Compute density
try
    [f, xi] = ksdensity(data);
catch
    % Fallback: histogram-based "density"
    nb = max(10, min(50, round(sqrt(numel(data)))));
    [cnt, edges] = histcounts(data, nb, 'Normalization', 'pdf');
    xi = (edges(1:end-1) + edges(2:end)) / 2;
    f = cnt;
end

if all(f == 0) || isempty(f) || isempty(xi)
    return
end

f = f / max(f);          % normalize to [0,1]
f = f * width;           % scale to desired half-width

xL = x0 - f;
xR = x0 + f;
X = [xL(:); flipud(xR(:))];
Y = [xi(:); flipud(xi(:))];

% Violin patch (light gray)
patch(ax, X, Y, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.35);

% Optional: jittered points
try
    jitter = (rand(size(data)) - 0.5) * 0.12;
    scatter(ax, x0 + jitter, data, 8, 'k', 'filled', 'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.15);
catch
    jitter = (rand(size(data)) - 0.5) * 0.12;
    scatter(ax, x0 + jitter, data, 8, 'k', 'filled');
end
end
