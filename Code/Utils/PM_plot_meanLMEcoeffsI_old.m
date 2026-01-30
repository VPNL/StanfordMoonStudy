function [outTbl,fh] = PM_plot_meanLMEcoeffsI(summaryTbl,Tblname,saveFilename,verboseFlag)
% [outTbl,fh] = PM_plot_meanLMEcoeffs(summaryTbl,Tblname,saveFilename,verboseFlag)
% gets a summary table of 7 LME model estimates across iterations
% calculates the mean and standard deviation of model slopes across iterations
% plots model slopes in form of a bar graph
% is saveFilename is given then exports the figure in the file name and
% format specificied in saveFilename

if ~exist('summaryTbl','var')
    disp('error: no table is given as input')
    return
end
if ~exist('Tblname','var')
    Tblname=[];
    return
end
if exist('saveFilename','var')
    saveFlag=1;
end
if ~exist('verboseFlag')
    verboseFlag=0;
end
    

%% Coefficients of interest
coefVars = {'Intercept','De','Ee','VAe'};

%% Ensure coefficient columns are numeric doubles (robust to string/cell)
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
fh=figure('Color','w','Name',Tblname,'Units','normalized','Position',[0 0 0.5 ,8]);
b = bar(mu, 'grouped');  % one bar object per coefficient
%coefVars = {'Intercept','De','Ee','VAe'};
b(1).FaceColor = [0.70 0.70 0.70];   % Intercept
b(2).FaceColor = [0.30 0.70 0.30];   % De
b(3).FaceColor = [0.40 0.50 .9];   % Ee
b(4).FaceColor = [0.70 0.30 0.60];   % VAe

modelList=erase(modelList, "logPM_by_");
ax = gca;
ax.XTick = 1:numel(modelList);
ax.XTickLabel = modelList;
ax.XTickLabelRotation = 90;
ax.TickLabelInterpreter = 'none';

% Add error bars at the correct x-positions for grouped bars
hold on;
for k = 1:numel(b)
    x = b(k).XEndPoints;                 % x positions of bars in group
    errorbar(x, mu(:,k), sig(:,k), 'k', ...
        'LineStyle','none', 'CapSize', 8, 'LineWidth', 1);
end
hold off;box off

set(gca,'FontName','Avenir','Fontsize',16)
legend(coefVars(1:4), 'Interpreter','none', 'Location','bestoutside','box','off','FontSize',16);
title('Mean ± SD of coefficients across iterations','FontSize',16);
ylabel('Coefficient estimate','FontSize',20);
xlabel('Model','FontSize',20);

%% Optional: view the computed means/stds as a tidy table
% Expand statsTbl into separate columns (readable)
outTbl = table(modelList,modelFormula, ...
    mu(:,1), sig(:,1), mu(:,2), sig(:,2), mu(:,3), sig(:,3), mu(:,4), sig(:,4), ...
    'VariableNames', {'modelName', 'FormulaStr',...
    'Intercept_mean','Intercept_std','De_mean','De_std','Ee_mean','Ee_std','VAe_mean','VAe_std'});
if verboseFlag
    disp(outTbl);
end
if saveFlag
    exportgraphics(fh,saveFilename , 'Resolution', 600);
end
