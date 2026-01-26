function plot_PredictedvsReportedPMbyParam(T,Param,saveFilename,figName)
%% Summarize predicted values by Distance across iterations, then plot model panels
% Assumes:
%   T - Table contains: Iteration, Distance, Ratio_Visual_Angle (or close match),
%     and predicted columns containing 'predicted' in the variable name.

% dataFile = "FinalQuadProcessedData109_withPredictedLog2PM.csv";  % <-- EDIT if needed
% T = readtable(dataFile);

if ~exist('T','var')
    disp('error there is no table')
    return
end
if ~exist('saveFilename','var')
    saveFlag=0; 
else
    saveFlag = 1; % Set saveFlag to indicate that a filename is provided   
end
if ~exist('figName','var')
    figName=[];
end
    % ---- Identify required columns ----
% Iteration
if ~ismember("Iteration", T.Properties.VariableNames)
    error("Missing required column: Iteration");
end

% Param
if ~ismember(string(Param), T.Properties.VariableNames)
    error("Missing required param:");
end

% Actual (Ratio_Visual_Angle) with fallback if spelled differently
actualName = "";
if ismember("Ratio_Visual_Angle", T.Properties.VariableNames)
    actualName = "Ratio_Visual_Angle";
elseif ismember("Ration_Visual_Angle", T.Properties.VariableNames)
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

% Predicted columns
vnames  = string(T.Properties.VariableNames);
predCols = vnames(contains(lower(vnames), "predicted"));
if isempty(predCols)
    error("No columns containing 'predicted' were found.");
end

%% ---- Prepare grouping keys ----
itr = T.Iteration;
if iscell(itr) || isstring(itr)
    itr = string(itr);
elseif iscategorical(itr)
    itr = string(itr);
end

if ismember(Param, T.Properties.VariableNames)
    col = T.(Param);
else
    error("Column not found: %s", colName);
end


% Sorted unique distances and a distance-index for coloring
uCol = unique(col);
uCol = sort(uCol(:));                     % sorted unique distances
[~, distIdxAll] = ismember(col, uCol);    % 1..nDist per row

% ---- Group by Iteration x Column variable; summarize actual + each predicted ----
[G, itrLevels, paramLevels] = findgroups(itr, col);

% Mean actual per (Iteration, Distance)
y = T.(actualName);
meanActual = splitapply(@(x) mean(x, 'omitnan'), y, G);

% Mean predicted per model per (Iteration, Distance)
nModels = numel(predCols);
meanPred = nan(numel(meanActual), nModels);

for m = 1:nModels
    yhat = T.(predCols(m));
    meanPred(:,m) = splitapply(@(x) mean(x, 'omitnan'), yhat, G);
end

% Distance index for each grouped point (Iteration,Distance)
[~, distIdxGroup] = ismember(paramLevels, uCol);

% Optional: summary table you can inspect/export
Summary = table(itrLevels, paramLevels, meanActual, 'VariableNames', ...
    {'Iteration',Param,'MeanActual'});
for m = 1:nModels
    nm = predCols(m) + "_MeanByItrDist";
    nm = matlab.lang.makeValidName(nm);
    Summary.(nm) = meanPred(:,m);
end
% writetable(Summary, "PredictedSummary_ByIterationDistance.csv");

%% ---- Plot: one panel per model (mean predicted vs mean actual), colored by Distance ----
nCol = numel(uCol);
cmap  = jet(max(nCol, 2));  % sorted colormap; distance order maps to colormap order


% Choose a tile layout close to square
nCols = nModels;
nRows = 1;
%maxX=max([max(T.Reported_Visual_Angle) max(yhat)]);
maxX=2.5*max(yhat);
minX=min([min(T.Reported_Visual_Angle) min(yhat)]);

fh=figure('Color','w','Name',figName,'Units','normalized','Position',[ 0 0 1 .5]);
tiledlayout(nRows, nCols, 'TileSpacing','compact');

for m = 1:nModels
    nexttile;
    hold on
    x = meanActual;          % mean actual (by itr x dist)
    y = meanPred(:,m);       % mean predicted (by itr x dist)
  
    valid = isfinite(x) & isfinite(y) & (distIdxGroup > 0);

    scatter(x(valid), y(valid), 18, distIdxGroup(valid), 'filled');
    plot([minX maxX],[minX maxX],'k:');
    colormap(cmap);
    caxis([1 nCol]);

    xlabel('Reported PM');
    ylabel('Predicted PM');
    ax = gca;
    ax.XLim=[minX maxX];
    ax.YLim=[minX maxX];
    ax.FontName='Avenir'
    ax.FontSize=10;
    % Title = model name from predicted column (leave verbatim)
    ttl = predCols(m);
    ttl = erase(ttl,'predicted_PM_') ;
    title(strrep(ttl, "_", "\_"), 'Interpreter','tex','FontSize',6);  % show underscores nicely

    grid off;
    box off;
    axis('square');
    
    
end


% Shared colorbar (distance mapping)
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = Param;
cb.Ticks = 1:nCol;

% For many distances, labeling every tick can get cluttered; this is the faithful version:
cb.TickLabels = compose('%g', uCol);
cb.FontName='Avenir'
cb.FontSize=6;

if saveFlag % export figure
      exportgraphics(fh,saveFilename , 'Resolution', 600);
end
% If there are too many unique distances, you can thin labels like this:
% if nDist > 12
%     keep = round(linspace(1, nDist, 8));
%     cb.Ticks = keep;
%     cb.TickLabels = compose('%g', uDist(keep));
% end
