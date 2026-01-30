
function [meanErr,sdErr]=PM_Models_MSE(T,saveFilename,figName)
% function [meanErr,sdErr]=PM_Models_MSE(T)
% gets the testing data table T and calculates the MSE for perceptual magnification +/- SD for each model
%
if ~exist('T','var')
    disp('error, no table')
    return
end
if exist('saveFilename','var')
    saveFlag=1;
else
    saveFlag=0
end
if ~exist('figName','var')
    figName='';
end

% --------- Locate actual (ground-truth) column ----------
actualName = "";
if ismember("Ratio_Visual_Angle", T.Properties.VariableNames)
    actualName = "Ratio_Visual_Angle";
else
    % fallback: try to find something like "*ratio*visual*angle*"
    v = lower(string(T.Properties.VariableNames));
    idx = find(contains(v,"ratio") & contains(v,"visual") & contains(v,"angle"), 1, "first");
    if ~isempty(idx)
        actualName = string(T.Properties.VariableNames{idx});
    else
        error("Could not find actual column 'Ration_Visual_Angle' (or close match) in table.");
    end
end
y= T.(actualName); % reported PM

% --------- Locate iteration column ----------
if ~ismember("Iteration", T.Properties.VariableNames)
    error("Could not find required column 'Iteration' in the data table.");
end
itr = T.Iteration;

% Ensure iteration is a simple grouping vector
if iscell(itr)
    itr = string(itr);
elseif iscategorical(itr)
    itr = string(itr);
end

% Unique iteration levels (stable order)
itrLevels = unique(itr, 'stable');

% --------- Find predicted columns (contain 'predicted') ----------
vnames = string(T.Properties.VariableNames);
predCols = vnames(contains(lower(vnames), "predicted"));

if isempty(predCols)
    error("No columns containing 'predicted' were found in the data table.");
end

% --------- Compute iteration-level pMSE for each model ----------
nModels = numel(predCols);
nItr    = numel(itrLevels);

errByItr = nan(nItr, nModels);   % rows: iteration, cols: model

for m = 1:nModels
    yhat_all = T.(predCols(m));

    for k = 1:nItr
        sel = (itr == itrLevels(k));

        yk    = y(sel);
        yhatk = yhat_all(sel);

        % Guard: require positive/finite y to avoid divide-by-zero or nonsense
        valid = isfinite(yk) & isfinite(yhatk) & (yk ~= 0);

        if any(valid)
            pmse = 100 * mean( ((yhatk(valid) - yk(valid)) ./ yk(valid)).^2 , 'omitnan' );
            errByItr(k,m) = pmse;
        end
    end
end

% --------- Mean + SD across iterations (per model) ----------
meanErr = mean(errByItr, 1, 'omitnan');
sdErr   = std(errByItr,  0, 1, 'omitnan');   % SD across iterations

% --------- Make labels nicer (optional) ----------
modelLabels = predCols;
% If you want to strip a suffix like "_predicted" or "predicted_"
modelLabels = replace(modelLabels, "_predicted", "");
modelLabels = replace(modelLabels, "predicted_", "");
modelLabels = replace(modelLabels, "Predicted_", "");
modelLabels = replace(modelLabels, "_Predicted", "");

%% --------- Plot bar + error bars ----------
fh=figure('Color','w','Name',figName,'Units','Norm','Position',[ 0 0 .5 1]); 
b = bar(meanErr);
hold on;
b(1).FaceColor = [0.70 0.70 0.70]; 
x = 1:nModels;
errorbar(x, meanErr, sdErr, 'k', 'LineStyle','none', 'LineWidth',1);

ax = gca;
ax.XTick = x;
ax.XTickLabel = cellstr(modelLabels);
ax.TickLabelInterpreter = 'none';   % prevents underscores from becoming subscripts
ax.XTickLabelRotation = 90;

ylabel('Mean percent MSE across iterations');
grid off;box off
hold off;
set(gca,'FontName','Avenir','FontSize',12)
% --------- Optional: show the computed table in workspace ----------
ErrorSummary = table(modelLabels(:), meanErr(:), sdErr(:), ...
    'VariableNames', {'Model','Mean_pMSE','SD_pMSE'});
disp(ErrorSummary);

 if saveFlag % export figure
      exportgraphics(fh,saveFilename , 'Resolution', 600);
 end
end