function [statsTblP,statsTblA,fh] = PM_plot_meanLMEcoeffsI_bothtasks(perceptual_summaryTbl,adjusted_summaryTbl,saveFilename,coefVars,verboseFlag)
% [outTbl,fh] = PM_plot_meanLMEcoeffs(summaryTbl,Tblname,saveFilename,verboseFlag)
% gets a summary table of 7 LME model estimates across iterations
% calculates the mean and standard deviation of model slopes across iterations
% plots model slopes in form of a bar graph
% is saveFilename is given then exports the figure in the file name and
% format specificied in saveFilename
if nargin< 2
    disp('error: there need to be 2 tables (perceptual/adjusted) as inputs')
    return
end
if exist('saveFilename','var')
    saveFlag=1;
end
if ~exist('verboseFlag')
    verboseFlag=0
end
if ~exist('coefVars','var')
    coefVars = {'Intercept','VAe','De','Ee'};
end
%% Coefficients of interest
[modelListP,muP,sigP,statsTblP]=organize_table(perceptual_summaryTbl, coefVars);
[modelListA,muA,sigA,statsTblA]=organize_table(adjusted_summaryTbl, coefVars);

%% Plot: grouped bar with error bars
fh=figure('Color','w', 'Units','normalized','Position',[0 0 1 .8]);



% lets make shorter labels for plot
[modelLabel] = modelList2modelLabel(modelListP);

subplot(1,2,1)
b = bar(muP, 'grouped');  % one bar object per coefficient
b(1).FaceColor = [0.70 0.70 0.70];   % Intercept
b(2).FaceColor = [0.30 0.70 0.30];   % De
b(3).FaceColor = [0.40 0.50 .9];   % Ee
b(4).FaceColor = [0.70 0.30 0.60];   % VAe


axP = gca;
axP.XTick=1:numel(modelLabel);
axP.XTickLabel = modelLabel;
axP.XTickLabelRotation = 90;
axP.TickLabelInterpreter = 'none';

% Add error bars at the correct x-positions for grouped bars
hold on;
for k = 1:numel(b)
    x = b(k).XEndPoints;                 % x positions of bars in group
    errorbar(x, muP(:,k), sigP(:,k), 'k', ...
        'LineStyle','none', 'CapSize', 8, 'LineWidth', 1);
end
hold off;box off

set(gca,'FontName','Avenir','Fontsize',20)
legend(coefVars(1:4), 'Interpreter','none', 'Location','bestoutside','box','off','FontSize',20);
title('Perceptual','FontSize',24);
ylabel('Coefficient estimate','FontSize',24);
xlabel('Model','FontSize',24);

subplot(1,2,2)

b = bar(muA, 'grouped');  % one bar object per coefficient
b(1).FaceColor = [0.70 0.70 0.70];   % Intercept
b(2).FaceColor = [0.30 0.70 0.30];   % De
b(3).FaceColor = [0.40 0.50 .9];   % Ee
b(4).FaceColor = [0.70 0.30 0.60];   % VAe

axA = gca;
axA.XTick=1:numel(modelLabel);
axA.XTickLabel = modelLabel;
axA.XTickLabelRotation = 90;
axA.TickLabelInterpreter = 'none';

% let's set the Ylim range so it will be the same across plots
yLimMin=min([axA.YLim(1) axP.YLim(1)]);
yLimMax=max([axA.YLim(2) axP.YLim(2)]);
axP.YLim=[yLimMin yLimMax]; axA.YLim=[yLimMin yLimMax];
% Add error bars at the correct x-positions for grouped bars
hold on;
for k = 1:numel(b)
    x = b(k).XEndPoints;                 % x positions of bars in group
    errorbar(x, muA(:,k), sigA(:,k), 'k', ...
        'LineStyle','none', 'CapSize', 8, 'LineWidth', 1);
end
hold off;box off

set(gca,'FontName','Avenir','Fontsize',20)
legend(coefVars(1:4), 'Interpreter','none', 'Location','bestoutside','box','off','FontSize',20);
title('Adjusted','FontSize',24);
ylabel('Coefficient estimate','FontSize',24);
xlabel('Model','FontSize',24);

if saveFlag
    exportgraphics(fh,saveFilename , 'Resolution', 600);
end

%% %% Plot: grouped bar with error bars
fh=figure('Color','w', 'Name', 'Both Intercepts', 'Units','normalized','Position',[0 0 .25 .8]);
%coefVars = {'Intercept','De','Ee','VAe'};

s1=subplot(1,2,1)
b = bar(muP(:,1));
b(1).FaceColor = [0.70 0.70 0.70];   % Intercept
% Add error bars at the correct x-positions for grouped bars
hold on;
for k = 1:numel(b)
    x = b(k).XEndPoints;                 % x positions of bars in group
    errorbar(x, muP(:,k), sigP(:,k), 'k', ...
        'LineStyle','none', 'CapSize', 8, 'LineWidth', 1);
end
hold off;box off
axs1 = gca;
axs1.XTick=1:numel(modelLabel);
axs1.XTickLabel = modelLabel;
axs1.XTickLabelRotation = 90;
axs1.TickLabelInterpreter = 'none';

set(gca,'FontName','Avenir','Fontsize',10)
title('Perceptual','FontSize',20);
ylabel('Intercept','FontSize',20);
xlabel('Model','FontSize',20);


s3=subplot(1,2,2)
b = bar(muA(:,1));
b(1).FaceColor = [0.70 0.70 0.70];   % Intercept
% Add error bars at the correct x-positions for grouped bars
hold on;
for k = 1:numel(b)
    x = b(k).XEndPoints;                 % x positions of bars in group
    errorbar(x, muA(:,k), sigA(:,k), 'k', ...
        'LineStyle','none', 'CapSize', 8, 'LineWidth', 1);
end
hold off;box off

axs2 = gca;
axs2.XTick=1:numel(modelLabel);
axs2.XTickLabel = modelLabel;
axs2.XTickLabelRotation = 90;
axs2.TickLabelInterpreter = 'none';
axs2.YColor = 'w'
set(gca,'FontName','Avenir','Fontsize',10)
title('Adjusted','FontSize',20);
ylabel('Intercept','FontSize',20);
xlabel('Model','FontSize',20);

yLimMin1=min([axs1.YLim(1) axs2.YLim(1)]);
yLimMax1=max([axs1.YLim(2) axs2.YLim(2)]);
axs1.YLim=[yLimMin1 yLimMax1]; axs2.YLim=[yLimMin1 yLimMax1];

s1 = erase(saveFilename, '.png');
 if saveFlag
     exportgraphics(fh,[ s1 '_intercepts.png'], 'Resolution', 600);
 end

%%
fh=figure('Color','w', 'Name', 'Both Exponents', 'Units','normalized','Position',[0 0 1 .8]);

% Exponents (slopes only): 
coefExp   = {'VAe','De','Ee'};
coefCols  = 2:4; % columns in muP/muA corresponding to coefExp (based on coefVars above)
colorsExp = [ ...
    0.30 0.70 0.30;  % 1st coeff
    0.40 0.50 0.90;  % 2nd coeff
    0.70 0.30 0.60]; % 3rd coeff

subplot(1,2,1)
plotPackedBars(muP(:,coefCols), sigP(:,coefCols), modelLabel, coefExp, colorsExp);
title('Perceptual','FontSize',20);
ylabel('Exponent','FontSize',20);

subplot(1,2,2)
plotPackedBars(muA(:,coefCols), sigA(:,coefCols), modelLabel, coefExp, colorsExp);
title('Adjusted','FontSize',20);
ylabel('Exponent','FontSize',20);

% Match y-limits across subplots
axs = findall(fh,'Type','axes');
if numel(axs) >= 2
    yLimMin = min(cellfun(@(a)a(1), {axs.YLim}));
    yLimMax = max(cellfun(@(a)a(2), {axs.YLim}));
    for iAx = 1:numel(axs)
        axs(iAx).YLim = [yLimMin yLimMax];
    end
end

s2 = erase(saveFilename, '.png');
if saveFlag
    exportgraphics(fh,[ s2 '_exponents.png'] , 'Resolution', 600);
end


end % end main function

function plotPackedBars(mu, sig, modelList, coefNames, coefColors)
% Plot per-model bars with fixed thin width; pack 1/2/3 coefficients without gaps.

nModels = size(mu,1);
barW    = 0.25;            % fixed thin width (as if always 3 coefficients)
slotDelta = barW * 1.18;   % fixed slot spacing; avoids overlap

hold on;
for iM = 1:nModels
    present = ~isnan(mu(iM,:));
    idx = find(present);
    nBars = numel(idx);
    if nBars==0
        continue
    end

    offsets = ((1:nBars) - (nBars+1)/2) * slotDelta; % generic: 1..N bars

    for j = 1:nBars
        c = idx(j);
        xPos = iM + offsets(j);

        bar(xPos, mu(iM,c), barW, 'FaceColor', coefColors(c,:), 'EdgeColor','none');
        errorbar(xPos, mu(iM,c), sig(iM,c), 'k', 'LineStyle','none', 'CapSize', 8, 'LineWidth', 1,'HandleVisibility','off');
    end
end
hold off; box off;

ax = gca;
ax.XTick = 1:numel(modelList);
ax.XTickLabel = modelList;
ax.XTickLabelRotation = 90;
ax.TickLabelInterpreter = 'none';
set(ax,'FontName','Avenir','FontSize',20);


l=legend(coefNames, 'Interpreter','none', 'Location','bestoutside', 'box','off', 'FontSize',20);
end
function [modelList,mu,sig,statsTbl]=organize_table(summaryTbl, coefVars)

%Ensure coefficient columns are numeric doubles (robust to string/cell)
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

% Group by modelName (across iterations)
g = findgroups(summaryTbl.modelName);
modelList = splitapply(@(x)x(1), string(summaryTbl.modelName), g);  % one per group

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

% Enforce a specific model order on the x-axis (and in outTbl)
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
mu        = mu(ordIdx, :);
sig       = sig(ordIdx, :);
statsTbl  = statsTbl(ordIdx, :);
end % end organize_table
