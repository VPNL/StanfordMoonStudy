function [outTbl,fh] = PM_plot_meanLMEcoeffs(summaryTbl,Tblname,saveFilename,coefVars, plotCoefVars,verboseFlag)
% [outTbl,fh] = PM_plot_meanLMEcoeffs(summaryTbl,Tblname,saveFilename,verboseFlag)
% gets a summary table of 7 LME model estimates across iterations
% calculates the mean and standard deviation of model slopes across iterations
% plots model slopes in form of a bar graph
% is saveFilename is given then exports the figure in the file name and
% format specificied in saveFilename

% Notes on plotting:
% Different LMEs may have different sets of predictors (e.g., 1–3 slopes).
% This function detects which coefficients are present per model (non-NaN
% across iterations) and only plots those bars within each model group,
% while keeping coefficient colors consistent across all models.

if ~exist('summaryTbl','var')
    disp('error: no table is given as input')
    return
end

if ~exist('Tblname','var') || isempty(Tblname)
    Tblname = '';
end

saveFlag = 0;
if exist('saveFilename','var') && ~isempty(saveFilename)
    saveFlag = 1;
end
    
if ~exist('coefVars','var')
% Coefficients of interest
% We compute summary stats for the intercept + all possible slopes.
    coefVars = {'Intercept','VAe','De','Ee'};
end
if ~exist('plotCoefVars','var')
   % plotCoefVars = {'VAe', 'De','Ee'};  % slopes only
    plotCoefVars = {'Intercept', 'VAe', 'De','Ee'};  % intercepts + slopes only
end

if ~exist('verboseFlag','var') || isempty(verboseFlag)
    verboseFlag = 0;
end

% Consistent colors by coefficient name
coefColorMap = containers.Map();
coefColorMap('Intercept') = [0.70 0.70 0.70];
coefColorMap('De')        = [0.30 0.70 0.30];
coefColorMap('Ee')        = [0.40 0.50 0.90];
coefColorMap('VAe')       = [0.70 0.30 0.60];

%% Ensure coefficient columns are numeric doubles 
for k = 1:numel(coefVars)
    v = coefVars{k};
    x = summaryTbl.(v);

    if iscell(x)
        % Convert cell entries to doubles; empty -> NaN
        y = nan(height(summaryTbl),1);
        for i = 1:height(summaryTbl)
            xi = x{i};
            if isempty(xi)
                y(i) = NaN;
            elseif isnumeric(xi) && isscalar(xi)
                y(i) = double(xi);
            else
                s = strtrim(string(xi));
                s = erase(s, ["[","]","{","}"]);
                y(i) = str2double(s);
            end
        end
        summaryTbl.(v) = y;

    elseif isstring(x) || ischar(x)
        s = strtrim(string(x));
        s = erase(s, ["[","]","{","}"]);
        summaryTbl.(v) = str2double(s);

    else
        summaryTbl.(v) = double(x);
    end
end

%% Group by modelName (across iterations)
g = findgroups(summaryTbl.modelName);
modelList = splitapply(@(x)x(1), string(summaryTbl.modelName), g);  % one per group
modelFormula = splitapply(@(x)x(1), string(summaryTbl.FormulaStr), g);  % one per group

% Compute mean/std with omitnan
mu  = nan(numel(modelList), numel(coefVars));
sig = nan(numel(modelList), numel(coefVars));

for k = 1:numel(coefVars)
    v = coefVars{k};
    if k==1 % turn intercept to number from log2
        mu(:,k)  = splitapply(@(x) mean(x, 'omitnan'), 2.^summaryTbl.(v), g);
        sig(:,k) = splitapply(@(x)  std(x,  'omitnan'), 2.^summaryTbl.(v), g);
    else
        mu(:,k)  = splitapply(@(x) mean(x, 'omitnan'), summaryTbl.(v), g);
        sig(:,k) = splitapply(@(x)  std(x,  'omitnan'), summaryTbl.(v), g);
    end
end

statsTbl = table(modelList, mu, sig, 'VariableNames', {'modelName','Mean','Std'});

%% Enforce a specific model order on the x-axis (and in outTbl)
desiredOrder = [
    "logPM_by_logAngle"
    "logPM_by_logDistance"
    "logPM_by_logElevation"
    "logPM_by_logAngleNDistance"
    "logPM_by_logAngleNElevation"
    "logPM_by_logDistanceNElevation"
    "logPM_by_logAngleNDistanceNElevation" ];

% Reorder rows to match desiredOrder (then append any unexpected models)
[tf, loc] = ismember(desiredOrder, modelList);
ordIdx = loc(tf);

extraIdx = find(~ismember(modelList, desiredOrder));
ordIdx = [ordIdx; extraIdx(:)];

modelList = modelList(ordIdx);
modelFormula= modelFormula(ordIdx);
mu        = mu(ordIdx, :);
sig       = sig(ordIdx, :);
statsTbl  = statsTbl(ordIdx, :);

%% Plot: grouped bar with error bars
fh = figure('Color','w','Name',Tblname,'Units','normalized','Position',[0.0 0.0 0.5 1]);
ax = gca;
hold(ax,'on');

% Plot bars with FIXED width/spacing while positioning 1/2/3 coefficients cleanly 

nModels = numel(modelList);
barEdgeColor = 'none';

% Ensure plotting coefficient indices follow plotCoefVars order (not coefVars order)
plotCoefIdx = nan(1, numel(plotCoefVars));
for ii = 1:numel(plotCoefVars)
    plotCoefIdx(ii) = find(strcmp(coefVars, plotCoefVars{ii}), 1, 'first');
end


% These values make the bars as thin as the "3-bars" case and prevent overlap.
slotDelta = 0.18;                 % spacing between adjacent bars in the 3-bar case
barW      = 0.16;                 % constant bar width 

% Track which coefficients are present anywhere (for legend)
coefPresentAnyPlot = false(1, numel(plotCoefVars));

for iM = 1:nModels
    % Determine which of the plot coefficients are present for this model
    isPresent = false(1, numel(plotCoefVars));
    for ii = 1:numel(plotCoefVars)
        k = plotCoefIdx(ii);
        if ~isnan(mu(iM, k))
            isPresent(ii) = true;
        end
    end

    presentSlots = find(isPresent);
    nBars = numel(presentSlots);
    if nBars == 0
        continue
    end
    coefPresentAnyPlot(presentSlots) = true;

    % Choose offsets that keep the same thin bar width while avoiding gaps
    offsets = ((1:nBars) - (nBars+1)/2) * slotDelta;

    for j = 1:nBars
        slot = presentSlots(j);
        k    = plotCoefIdx(slot);          % coefficient index into coefVars/mu/sig
        cName  = coefVars{k};
        cColor = coefColorMap(cName);

        xPos = iM + offsets(j);

        bar(ax, xPos, mu(iM, k), barW, 'FaceColor', cColor, 'EdgeColor', barEdgeColor);
        errorbar(ax, xPos, mu(iM, k), sig(iM, k), 'k', ...
            'LineStyle','none', 'CapSize', 8, 'LineWidth', 1);
    end
end

modelList=erase(modelList, "logPM_by_");
ax.XTick = 1:numel(modelList);
ax.XTickLabel = modelList;
ax.XTickLabelRotation = 90;
ax.TickLabelInterpreter = 'none';

% Ensure good x-limits around groups
xlim(ax, [0.5, nModels + 0.5]);
box(ax,'off');

set(gca,'FontName','Avenir','Fontsize',16)

% Legend: show only plotted coefficients that appear in at least one model.
legendNames = plotCoefVars(coefPresentAnyPlot);

% Create dummy bars for legend so colors are consistent.
hLeg = gobjects(0);
for ii = 1:numel(legendNames)
    nm = legendNames{ii};
    hLeg(ii) = bar(nan, nan, barW, 'FaceColor', coefColorMap(nm), 'EdgeColor', barEdgeColor); %#ok<AGROW>
end
legend(hLeg, legendNames, 'Interpreter','none', 'Location','bestoutside','box','off','FontSize',16);

title('Mean ± SD of coefficients across iterations','FontSize',16);
ylabel('Coefficient estimate','FontSize',20);
xlabel('Model','FontSize',20);

hold(ax,'off');

%% Optional: view the computed means/stds as a tidy table
% Expand statsTbl into separate columns (readable)
outTbl = table(modelList,modelFormula, ...
    mu(:,1), sig(:,1), mu(:,2), sig(:,2), mu(:,3), sig(:,3), mu(:,4), sig(:,4), ...
    'VariableNames', {'modelName', 'FormulaStr',...
    'Intercept_mean','Intercept_std','VAe_mean','VAe_std','De_mean','De_std','Ee_mean','Ee_std'});
if verboseFlag
    disp(outTbl);
end
if saveFlag
    exportgraphics(fh,saveFilename , 'Resolution', 600);
end
