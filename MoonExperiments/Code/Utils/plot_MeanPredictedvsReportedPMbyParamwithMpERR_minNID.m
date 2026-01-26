function [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(T, Param, minNID, saveFilename, figName, errType,nLevels,Study);
%% Plot mean predicted vs mean reported PM by Param level (with adaptive re-binning by min #IDs)
% [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(T, Param, minNID, saveFilename, figName, errType)
%
% Inputs:
%
% Inputs
%   T            : table (must include Iteration, ID, Param, Ratio_Visual_Angle, predicted columns)
%   Param        : string/char name of the parameter column (e.g., 'Distance', 'Elevation')
%   minNID       : (optional) minimum number of unique IDs per Param bin (default 1)
%                   If any original Param level has < minNID unique IDs, Param levels are
%                   merged into adjacent bins until every bin has >= minNID unique IDs.
%   saveFilename : optional (if provided, exports main figure; violin uses suffix '_violin')
%   figName      : optional figure name
%   errType      : optional, 'sd' (default) or 'sem'       
%   violinplot    : optional if violinplot=1; adds a violin plot of the
%                  error; default=0
%   nLevels      : number of levels of colormap to plot default nParams with more than minNID
%   Study        : If Study contains 'Quad' uses earthColormap3 for
%                  elevation otherwise uses extendearthColormap3 for
%                  elevation
%  
% - Plots are generated per *new* grouping (bins).
% Output
% Summary tables includes:
%       NewParamGroup          : integer bin ID
%       NewParamMeanValue      : mean Param value within bin
%       NewParamMinValue       : min Param value within bin
%       NewParamMaxValue       : max Param value within bin
%   
%
% 
% 
% Outputs
%   SummaryItrParam  : table with one row per (Iteration, Param) containing means and error metrics
%   SummaryParam     : table with one row per Param containing across-iteration mean and SD/SEM 
%                    : also has mean values and ranges of binned Param
%                    values
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
if ~exist('Study','var')
    Study='QuadStudy'
end

% ---- Backward-compatible argument shifting (if minNID was omitted) ----
if nargin >= 3 && (ischar(minNID) || isstring(minNID))
    errType = figName;
    figName = saveFilename;
    saveFilename = minNID;
    minNID = 1;
end
if nargin < 3 || isempty(minNID)
    minNID = 1;
end
validateattributes(minNID, {'numeric'}, {'scalar','integer','>=',1});

saveFlag = (nargin >= 4) && exist('saveFilename','var') && ~isempty(saveFilename);
if nargin < 5 || ~exist('figName','var'); figName = []; end
if nargin < 6 || ~exist('errType','var') || isempty(errType); errType = 'sd'; end
errType = lower(string(errType));
if ~ismember(errType, ["sd" "sem"])
    error("errType must be 'sd' or 'sem'.");
end

if ~exist('violinplot','var')
    violinplot=0;
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
vnames = string(T.Properties.VariableNames);

% Iteration
if ~ismember("Iteration", vnames)
    error("Missing required column: Iteration");
end

% ID
idName = local_findIDVarName(vnames);
if strlength(idName)==0
    error("Missing required subject identifier column. Expected a column named 'ID' (case-insensitive), or a close match like 'Subject', 'Subj', 'Participant'.");
end

% Param
if ~ismember(Param, vnames)
    error("Missing required param column: %s", Param);
end

% Actual (Ratio_Visual_Angle) with fallback if spelled differently
actualName = "";
if ismember("Ratio_Visual_Angle", vnames)
    actualName = "Ratio_Visual_Angle";
elseif ismember("Ration_Visual_Angle", vnames)
    actualName = "Ration_Visual_Angle";
else
    vlow = lower(vnames);
    idx = find(contains(vlow,"ratio") & contains(vlow,"visual") & contains(vlow,"angle"), 1, "first");
    if ~isempty(idx)
        actualName = vnames(idx);
    else
        error("Could not find Ratio_Visual_Angle (or close match) in the table.");
    end
end

% Predicted columns: prefer those containing 'predicted_PM'
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

%% ---- Normalize keys ----
itr = T.Iteration;
if iscell(itr) || isstring(itr)
    itr = str2double(string(itr));
elseif iscategorical(itr)
    itr = str2double(string(itr));
end

paramCol = T.(Param);
idCol = T.(idName);

% Convert IDs to string for robust uniqueness
if isnumeric(idCol)
    idStr = string(idCol);
elseif iscategorical(idCol)
    idStr = string(idCol);
elseif iscell(idCol)
    idStr = string(idCol);
else
    idStr = string(idCol);
end

% ---- Create adaptive bins (or 1:1 bins if already sufficient) ----
[paramBin, binStats, didRebin] = local_makeParamBins(paramCol, idStr, minNID);

%% ---- Step 1: per (Iteration x NewParamGroup) mean reported + mean predicted ----
[G1, itrLevels, binLevels] = findgroups(itr, paramBin);

xReported = T.(actualName);
meanReported = splitapply(@(x) mean(x, 'omitnan'), xReported, G1);

nModels = numel(predCols);
meanPred = nan(numel(meanReported), nModels);
for m = 1:nModels
    yhat = T.(predCols(m));
    meanPred(:,m) = splitapply(@(x) mean(x, 'omitnan'), yhat, G1);
end

% Build Summary table at Iteration x Bin granularity
SummaryItrParam = table(itrLevels, binLevels, meanReported, ...
    'VariableNames', ["Iteration", "New"+Param+"Group", "MeanReported"]);

% Add per-bin summary columns (mean/min/max Param values for each bin)
% binStats is ordered by NewParamGroup = 1..nBins
SummaryItrParam.NewParamMeanValue = binStats.NewParamMeanValue(SummaryItrParam.NewParamGroup);
SummaryItrParam.NewParamMinValue  = binStats.NewParamMinValue(SummaryItrParam.NewParamGroup);
SummaryItrParam.NewParamMaxValue  = binStats.NewParamMaxValue(SummaryItrParam.NewParamGroup);

for m = 1:nModels
    nm = matlab.lang.makeValidName(predCols(m) + "_MeanByItrParam");
    SummaryItrParam.(nm) = meanPred(:,m);
end

%% ---- Step 1b: error metrics at (Iteration x Bin) level ----
% Mean squared error (MSE)
mseMat = (meanPred - meanReported).^2; % nGroups x nModels

% Mean percentage error (absolute percentage error)
absDen = abs(meanReported);
absDen(absDen == 0) = NaN;
pctErrMat = 100 * abs(meanPred - meanReported) ./ absDen;

for m = 1:nModels
    nmMSE = matlab.lang.makeValidName(predCols(m) + "_MSEByItrParam");
    nmPE  = matlab.lang.makeValidName(predCols(m) + "_MeanPctErrByItrParam");
    SummaryItrParam.(nmMSE) = mseMat(:,m);
    SummaryItrParam.(nmPE)  = pctErrMat(:,m);
end

% Long-format MSE table
nGroups = numel(meanReported);
IterationLong = repmat(itrLevels, nModels, 1);
BinLong       = repmat(binLevels, nModels, 1);
ModelLong     = repelem(predCols(:), nGroups, 1);
MSELong       = reshape(mseMat, [], 1);
MSE_ItrParam  = table(IterationLong, BinLong, ModelLong, MSELong, ...
    'VariableNames', ["Iteration", "NewParamGroup", "Model", "MeanSqError"]);

% Long-format mean % error table
PctErrLong      = reshape(pctErrMat, [], 1);
PctErr_ItrParam = table(IterationLong, BinLong, ModelLong, PctErrLong, ...
    'VariableNames', ["Iteration", "NewParamGroup", "Model", "MeanPctError"]);

%% ---- Step 1c: summarize per iteration across bins (per model) ----
Gitr = findgroups(itrLevels);
uItrLevels = splitapply(@(x) x(1), itrLevels, Gitr);

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

%% ---- Step 2: across-iteration mean + SD/SEM for each bin ----
[G2, uBins] = findgroups(binLevels);

xMean = splitapply(@(x) mean(x, 'omitnan'), meanReported, G2);
xStd  = splitapply(@(x) std(x,  'omitnan'), meanReported, G2);
xN    = splitapply(@(x) sum(isfinite(x)), meanReported, G2);
if errType == "sem"
    xErr = xStd ./ sqrt(max(xN,1));
else
    xErr = xStd;
end

yMean = nan(numel(uBins), nModels);
yStd  = nan(numel(uBins), nModels);
yN    = nan(numel(uBins), nModels);
yErr  = nan(numel(uBins), nModels);
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

% Ensure bins are ordered 1..nBins
[uBins, ord] = sort(uBins);
xMean = xMean(ord); xStd = xStd(ord); xN = xN(ord); xErr = xErr(ord);
yMean = yMean(ord,:); yStd = yStd(ord,:); yN = yN(ord,:); yErr = yErr(ord,:);

SummaryParam = table(uBins, ...
    binStats.NewParamMeanValue(uBins), ...
    binStats.NewParamMinValue(uBins), ...
    binStats.NewParamMaxValue(uBins), ...
    binStats.NewParamNID(uBins),...
    xMean, xStd, xN, ...
    'VariableNames', ["NewParamGroup", "NewParamMeanValue", "NewParamMinValue", "NewParamMaxValue", "NewParamNID","MeanReported_AcrossItr", "StdReported_AcrossItr", "NItr_WithData"]);

for m = 1:nModels
    base = matlab.lang.makeValidName(predCols(m));
    SummaryParam.(base + "_MeanAcrossItr") = yMean(:,m);
    SummaryParam.(base + "_StdAcrossItr")  = yStd(:,m);
    SummaryParam.(base + "_NItrWithData")  = yN(:,m);
end

%% ---- Plot: one panel per model; one point per bin with x/y error bars ----
nParam = numel(uBins);
% if user does not specify the number of levels use the calculated number

% Colormap (kept consistent with original function)
if strcmp(Param,'Distance')
    cmap=brighten(flipud(colormap(turbo(nParam))),0.4);
elseif strcmp(Param,'Elevation') 
    if contains(lower(Study),'quad') 
        cmap = brighten(earthColormap3(nParam),.2);
    else
        cmap = brighten(earthColormapExtended3(nParam),0.2);
    end
elseif strcmp(Param,'Real_Visual_Angle')
    cmap = flipud(purpleVioletBlueTurquoiseGreenColorMap(ceil(nParam)));
else
    cmap = jet(max(nParam, 2));
end

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

if didRebin
    figNameUse = string(figName);
    if strlength(figNameUse)==0
        figNameUse = "Binned by minNID=" + string(minNID);
    else
        figNameUse = figNameUse + " (binned; minNID=" + string(minNID) + ")";
    end
else
    figNameUse = figName;
end

fh = figure('Color','w','Name',figNameUse,'Units','normalized','Position',[0 0 1 .5]);
tiledlayout(1, nModels, 'TileSpacing','compact');
markerSize = 15;
for m = 1:nModels
    nexttile; hold on;

    % Reference line
    plot([minX maxX], [minX maxX], 'k:');

    cap = 0.01 * (maxX - minX);
    for p = 1:nParam
        xp = xMean(p);  yp = yMean(p,m);
        dx = xErr(p);   dy = yErr(p,m);
        if ~isfinite(xp) || ~isfinite(yp)
            continue
        end
        colr = cmap(p,:);

        if isfinite(dx) && dx > 0
            plot([xp-dx xp+dx], [yp yp], 'Color', colr, 'LineWidth', 1);
            plot([xp-dx xp-dx], [yp-cap yp+cap], 'Color', colr, 'LineWidth', 1);
            plot([xp+dx xp+dx], [yp-cap yp+cap], 'Color', colr, 'LineWidth', 1);
        end
        if isfinite(dy) && dy > 0
            plot([xp xp], [yp-dy yp+dy], 'Color', colr, 'LineWidth', 1);
            plot([xp-cap xp+cap], [yp-dy yp-dy], 'Color', colr, 'LineWidth', 1);
            plot([xp-cap xp+cap], [yp+dy yp+dy], 'Color', colr, 'LineWidth', 1);
        end
    end

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

    ttl = predCols(m);
    ttl = erase(ttl, "predicted_PM_logPM_by_");
    title(strrep(ttl, "_", "\\_"), 'Interpreter','tex','FontSize',10);
end

% cb = colorbar;
% cb.Layout.Tile = 'east';
% if didRebin
%     cb.Label.String = Param + " (binned)";
% else
%     cb.Label.String = Param;
% end
% cb.Label.Interpreter='none';
% 
% 
% % Tick labels as [min-max] ranges
% tickBins = cb.Ticks;
% lab = strings(size(tickBins));
% for i = 1:numel(tickBins)
%     b = tickBins(i);
%     %lab(i) = sprintf('%.3g–%.3g', binStats.NewParamMinValue(b), binStats.NewParamMaxValue(b));
%      lab(i) = sprintf('%.3g', binStats.NewParamMeanValue(b));
% 
% end
% cb.TickLabels = cellstr(lab);
% cb.FontName = 'Avenir';
% cb.FontSize = 8;

cb = colorbar;
cb.Layout.Tile = 'east';

% if didRebin
%     cb.Label.String = Param + "(binned)";
% else
%     cb.Label.String = Param;
% end
if strcmp(Param,'Distance')
    cb.Label.String = Param + "[m]";
else
    cb.Label.String = Param + "[deg]"
end
cb.Label.Interpreter = 'none';

% ---- Force ticks: always include first & last bin, plus some middle bins ----
nBins = height(binStats);

% Choose total number of ticks (including endpoints)
nTicksTarget = min(6, nBins); % you can change 6 -> 5, 7, etc.

if nBins <= 1
    tickBins = 1;
elseif nBins == 2
    tickBins = [1 2];
else
    % evenly spaced bin indices, always includes 1 and nBins
    tickBins = unique(round(linspace(1, nBins, nTicksTarget)));
    tickBins(1) = 1;
    tickBins(end) = nBins;
end

cb.Ticks = tickBins;

% ---- Tick labels: endpoints show true min/max Param values; middle shows bin means (or ranges) ----
lab = strings(size(tickBins));
for k = 1:numel(tickBins)
    b = tickBins(k);

    if b == 1
        % Minimum Param value (from first bin)
        lab(k) = sprintf('%.2f', binStats.NewParamMinValue(1));
    elseif b == nBins
        % Maximum Param value (from last bin)
        lab(k) = sprintf('%.2f', binStats.NewParamMaxValue(nBins));
    else
        % Middle ticks: choose ONE of the following label styles

        % (A) Mean value of the bin:
        lab(k) = sprintf('%.2f', binStats.NewParamMeanValue(b));

        % (B) Range label (uncomment to use instead):
        % lab(k) = sprintf('%.3g–%.3g', binStats.NewParamMinValue(b), binStats.NewParamMaxValue(b));
    end
end

cb.TickLabels = cellstr(lab);
cb.FontName = 'Avenir';
cb.FontSize = 8;


if saveFlag
    exportgraphics(fh, saveFilename, 'Resolution', 600);
end

%% ---- Plot errors (same as original; but over bins) ----
modelLabels = predCols;
modelLabels = erase(modelLabels, "predicted_PM_logPM_by_");
modelLabels = strrep(modelLabels, "_", " ");
modelLabels = string(modelLabels);


%% ---- Violin plot of mean squared errors across iterations ----

if violinplot
    figNameStr = string(figNameUse);
    if strlength(figNameStr)==0
        violinFigName = "MSE Violin";
    else
        violinFigName = figNameStr + " — MSE Violin";
    end
    fh_violin = figure('Color','w','Name',violinFigName, 'Units','normalized','Position',[0.1 0.1 0.25 0.6]);
    axv = axes(fh_violin);
    hold(axv, 'on');
    
    width = 0.35;
    for m = 1:nModels
        d = mseItrMean(:,m);
        d = d(isfinite(d));
        if isempty(d)
            continue
        end
        local_violin(axv, d, m, width);
        med = median(d, 'omitnan');
        plot(axv, [m-0.12 m+0.12], [med med], 'k-', 'LineWidth', 1.5);
    end
    
    xlim(axv, [0.5 nModels+0.5]);
    axv.XTick = 1:nModels;
    axv.XTickLabel = cellstr(modelLabels);
    axv.XTickLabelRotation = 90;
    axv.FontName = 'Avenir';
    axv.FontSize = 13;
    if didRebin
        ylabel(axv, "Mean squared error (over binned " + Param + ")",'Interpreter','none');
    else
        ylabel(axv, "Mean squared error (over " + Param + ")",'Interpreter','none');
    end
    grid(axv, 'off'); box(axv, 'off');
    
    if saveFlag
        [p,f,e] = fileparts(char(saveFilename));
        save2 = fullfile(p, f + "_violin" + e);
        exportgraphics(fh_violin, save2, 'Resolution', 600);
    end
end

%% ---- Bar + dot plot of mean percentage error across iterations (per model) ----
figNameStr = string(figNameUse);
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
if didRebin
    ylabel(axb, "Mean % error (over binned " + Param + ")",'Interpreter','none');
else
    ylabel(axb, "Mean % error (over " + Param + ")",'Interpreter','none');
end
grid(axb, 'off'); box(axb, 'off');

if saveFlag
    [p,f,e] = fileparts(char(saveFilename));
    save3 = fullfile(p, f + "_pctError" + e);
    exportgraphics(fh_pctbar, save3, 'Resolution', 600);
end

end

%% ===== Local helper functions =====
function idName = local_findIDVarName(vnames)
% Find an ID column name in vnames.
idName = "";
% direct matches
direct = ["ID" "Id" "id" "Subject" "subject" "Subj" "subj" "Participant" "participant" "ParticipantID" "participant_id" "subject_id" "SubjectID"];
for k = 1:numel(direct)
    if any(strcmp(vnames, string(direct(k))))
        idName = string(direct(k));
        return
    end
end
% case-insensitive match for 'id'
idx = find(strcmpi(vnames, "ID"), 1, "first");
if ~isempty(idx)
    idName = vnames(idx);
    return
end
% fuzzy: contains 'id' but not things like 'Iteration'
vlow = lower(vnames);
cand = find(contains(vlow, "id") & ~contains(vlow, "iteration"), 1, "first");
if ~isempty(cand)
    idName = vnames(cand);
end
end

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
% 

function [paramBin, binStats, didRebin] = local_makeParamBins(paramCol, idStr, minNID)
% Create bins for Param values such that each bin contains >= minNID unique IDs.
% For non-numeric Params, bins are created per unique category level (no merging).
%
% Outputs:
%   paramBin  : bin index per row (1..nBins)
%   binStats  : table with per-bin stats:
%              NewParamGroup, NewParamMeanValue, NewParamMinValue, NewParamMaxValue, NewParamNID
%   didRebin  : true if adjacent numeric levels were merged to satisfy minNID

didRebin = false;

% Handle missing IDs
idStr = idStr(:);
if any(ismissing(idStr))
    idStr(ismissing(idStr)) = "";
end

% If Param is categorical/string: 1:1 bins
if ~isnumeric(paramCol)
    p = string(paramCol);
    [u, ~, ic] = unique(p, 'stable');
    paramBin = ic;
    nBins = numel(u);

    % Count unique IDs per bin (category level)
    binNID = nan(nBins,1);
    for b = 1:nBins
        ids = unique(idStr(paramBin==b));
        ids(ids=="") = [];
        binNID(b) = numel(ids);
    end

    % stats are placeholders (min/max/mean not well-defined for strings)
    binStats = table((1:nBins)', nan(nBins,1), nan(nBins,1), nan(nBins,1), binNID, ...
        'VariableNames', ["NewParamGroup" "NewParamMeanValue" "NewParamMinValue" "NewParamMaxValue" "NewParamNID"]);
    return
end

% Numeric Params: compute unique levels and IDs per level
p = paramCol(:);
[uLevels, ~, levelIdx] = unique(p);
[uLevels, ord] = sort(uLevels);

% remap levelIdx to sorted order
inv = zeros(size(ord));
inv(ord) = 1:numel(ord);
levelIdxSorted = inv(levelIdx);

nLevels = numel(uLevels);
idsPerLevel = cell(nLevels,1);
for i = 1:nLevels
    ids = unique(idStr(levelIdxSorted==i));
    ids(ids=="") = [];
    idsPerLevel{i} = ids;
end

% Determine if any level violates minNID
nIDByLevel = cellfun(@numel, idsPerLevel);
if minNID <= 1 || all(nIDByLevel >= minNID)
    % 1:1 bins
    didRebin = false;
    paramBin = levelIdxSorted;
    nBins = nLevels;

    % Bin stats (trivial: mean=min=max=level)
    binMean = uLevels;
    binMin  = uLevels;
    binMax  = uLevels;

    % Count unique IDs per bin (same as per level here)
    binNID = nan(nBins,1);
    for b = 1:nBins
        ids = unique(idStr(paramBin==b));
        ids(ids=="") = [];
        binNID(b) = numel(ids);
    end

    binStats = table((1:nBins)', binMean, binMin, binMax, binNID, ...
        'VariableNames', ["NewParamGroup" "NewParamMeanValue" "NewParamMinValue" "NewParamMaxValue" "NewParamNID"]);
    return
end

didRebin = true;

% Greedy merge of adjacent levels until each bin has >= minNID unique IDs
binOfLevel = zeros(nLevels,1);
binMin = [];
binMax = [];
binMean = [];

curBin = 0;
i = 1;
while i <= nLevels
    curBin = curBin + 1;
    curLevels = i;
    curIDs = idsPerLevel{i};
    j = i;
    while numel(curIDs) < minNID && j < nLevels
        j = j + 1;
        curLevels = [curLevels j]; %#ok<AGROW>
        curIDs = unique([curIDs; idsPerLevel{j}]);
    end
    binOfLevel(curLevels) = curBin;
    binMin(curBin,1) = min(uLevels(curLevels));
    binMax(curBin,1) = max(uLevels(curLevels));
    binMean(curBin,1) = mean(uLevels(curLevels), 'omitnan');
    i = j + 1;
end

% If the final bin still has < minNID unique IDs, merge it with previous bin.
if curBin > 1
    lastLevels = find(binOfLevel==curBin);
    lastIDs = unique(vertcat(idsPerLevel{lastLevels}));
    if numel(lastIDs) < minNID
        prevBin = curBin - 1;
        binOfLevel(lastLevels) = prevBin;

        prevLevels = find(binOfLevel==prevBin);
        binMin(prevBin)  = min(uLevels(prevLevels));
        binMax(prevBin)  = max(uLevels(prevLevels));
        binMean(prevBin) = mean(uLevels(prevLevels), 'omitnan');

        % drop last bin stats
        binMin(end) = [];
        binMax(end) = [];
        binMean(end) = [];
        curBin = curBin - 1;
    end
end

% Remap bins to consecutive 1..nBins (in case merging occurred)
[~,~,binOfLevel2] = unique(binOfLevel, 'stable');
nBins = max(binOfLevel2);

% Assign paramBin per row
paramBin = binOfLevel2(levelIdxSorted);

% Recompute stats per final bin
binMin2  = nan(nBins,1);
binMax2  = nan(nBins,1);
binMean2 = nan(nBins,1);
for b = 1:nBins
    lv = uLevels(binOfLevel2==b);
    binMin2(b)  = min(lv);
    binMax2(b)  = max(lv);
    binMean2(b) = mean(lv, 'omitnan');
end

% Count unique IDs per final bin (this is the requested addition)
binNID2 = nan(nBins,1);
for b = 1:nBins
    ids = unique(idStr(paramBin==b));
    ids(ids=="") = [];
    binNID2(b) = numel(ids);
end

binStats = table((1:nBins)', binMean2, binMin2, binMax2, binNID2, ...
    'VariableNames', ["NewParamGroup" "NewParamMeanValue" "NewParamMinValue" "NewParamMaxValue" "NewParamNID"]);
end

%%
function local_violin(ax, data, x0, width)
% Minimal violin plot using kernel density (falls back to histogram if ksdensity unavailable).
data = data(:);
data = data(isfinite(data));
if isempty(data)
    return
end

try
    [f, xi] = ksdensity(data);
catch
    nb = max(10, min(50, round(sqrt(numel(data)))));
    [cnt, edges] = histcounts(data, nb, 'Normalization', 'pdf');
    xi = (edges(1:end-1) + edges(2:end)) / 2;
    f = cnt;
end

if all(f == 0) || isempty(f) || isempty(xi)
    return
end

f = f / max(f);
f = f * width;

xL = x0 - f;
xR = x0 + f;
X = [xL(:); flipud(xR(:))];
Y = [xi(:); flipud(xi(:))];

patch(ax, X, Y, [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.35);

try
    jitter = (rand(size(data)) - 0.5) * 0.12;
    scatter(ax, x0 + jitter, data, 8, 'k', 'filled', 'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.15);
catch
    jitter = (rand(size(data)) - 0.5) * 0.12;
    scatter(ax, x0 + jitter, data, 8, 'k', 'filled');
end
end
