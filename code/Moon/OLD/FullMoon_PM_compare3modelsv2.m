function results = FullMoon_PM_compare3modelsv2(dataDir,datafile,ResultsDir,task,recomputeSort,saveLME)
% FullMoon_PM_compare3models
% Compare three mixed-effects models of moon perceptual magnification and
% plot their fixed-effect fits with confidence intervals on common axes.
%
% Models fit:
%   1) logRatio ~ log2(1 + Elevation/90) + (1|ID)
%   2) logRatio ~ logElevation + (1|ID)
%   3) Ratio_Visual_Angle ~ Elevation + (1|ID)
%
% All three panels are plotted in the same raw data space so they share the
% same x and y axes:
%   x = Elevation (degrees)
%   y = Ratio_Visual_Angle (Perceptual Magnification)
%
% Subject colors are kept identical across all panels and are sorted by the
% subject-specific intercepts from model 1.
%
% Output
%   results.model1, results.model2, results.model3
%   results.comparisonTable
%   results.compare12
%   results.figure_file, results.text_file, results.mat_file
%
% Notes
%   - compare(model1,model2) is attempted because those two models share the
%     same response variable.
%   - Model 3 uses a different response variable, so AIC/BIC/logLik across
%     all three are shown for reference, but should be interpreted with care.
%   - RMSE and R2 on the raw ratio scale are also reported so all three
%     models can be compared in a common plotted space.

% ----------------------
% defaults
% ----------------------
if nargin < 1 || isempty(dataDir)
    dataDir = '/Users/kalanit/Projects/PerceptualMagnification/MoonExperiments/';
end
if nargin < 2 || isempty(datafile)
    datafile = 'FullMoonDataLong.csv';
end
if nargin < 3 || isempty(ResultsDir)
    ResultsDir = 'PaperFigures';
end
if nargin < 4 || isempty(task)
    task = 'Perceptual';
end
if nargin < 5 || isempty(recomputeSort)
    recomputeSort = 1;
end
if nargin < 6 || isempty(saveLME)
    saveLME = 1;
end

basename = erase(datafile,'.csv');
taskChar = char(string(task));

startDir = pwd;
cleanupObj = onCleanup(@() cd(startDir)); %#ok<NASGU>
cd(dataDir)

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end

% ----------------------
% load and filter data
% ----------------------
all_data = readtable(datafile);
disp(all_data.Properties.VariableNames)

validRows = ~isnan(all_data.Reported_Visual_Angle) & ...
            ~isnan(all_data.Ratio_Visual_Angle) & ...
            ~isnan(all_data.Elevation) & ...
            (all_data.Ratio_Visual_Angle > 0);
all_data = all_data(validRows,:);
all_data = all_data(string(all_data.Task) == string(task),:);

if isempty(all_data)
    error('No rows found for task "%s".', taskChar);
end

% derived variables used by the requested models
all_data.logRatio = log2(all_data.Ratio_Visual_Angle);
all_data.logElevation = log2(all_data.Elevation + 1);
all_data.logElevationD90 = log2(1 + all_data.Elevation/90);

% subject bookkeeping
IDstr = string(all_data.ID);
uniqueIDstr = unique(IDstr,'stable');
nsubjects = numel(uniqueIDstr);
nobs = height(all_data);

% plotting settings
xMin = 0;
xMax = max(all_data.Elevation);
markerScale = 36;

% ----------------------
% fit the 3 requested models
% ----------------------
fitFormula1 = 'logRatio ~ logElevationD90 + (1|ID)';
fitFormula2 = 'logRatio ~ logElevation + (1|ID)';
fitFormula3 = 'Ratio_Visual_Angle ~ Elevation + (1|ID)';

displayFormula1 = 'logRatio ~ log2(1 + Elevation/90) + (1|ID)';
displayFormula2 = 'logRatio ~ logElevation + (1|ID)';
displayFormula3 = 'Ratio_Visual_Angle ~ Elevation + (1|ID)';

model1 = fitlme(all_data, fitFormula1, 'FitMethod','ML');
model2 = fitlme(all_data, fitFormula2, 'FitMethod','ML');
model3 = fitlme(all_data, fitFormula3, 'FitMethod','ML');

[fe1,~,~] = fixedEffects(model1);
[fe2,~,~] = fixedEffects(model2);
[fe3,~,~] = fixedEffects(model3);

titleFormula1 = localPowerFormula(2^fe1(1), '1 + Elevation/90', fe1(2));
titleFormula2 = localPowerFormula(2^fe2(1), '1 + Elevation', fe2(2));
titleFormula3 = localLinearFormula(fe3(1), fe3(2));

% direct compare for the two logRatio models
compare12 = [];
compare12_message = 'compare(model1,model2) failed or was not available.';
try
    compare12 = compare(model1,model2);
    compare12_message = 'compare(model1,model2) succeeded.';
catch ME
    compare12_message = ['compare(model1,model2) failed: ' ME.message];
end

% ----------------------
% subject colors sorted by intercepts from model 1
% ----------------------
[re1,reNames1,~] = randomEffects(model1);
reLevel1 = string(reNames1.Level);
reName1 = string(reNames1.Name);

subjectIntercepts1 = zeros(nsubjects,1);
for i = 1:nsubjects
    rowi = find(reLevel1 == uniqueIDstr(i) & reName1 == '(Intercept)', 1, 'first');
    if isempty(rowi)
        rowi = find(reLevel1 == uniqueIDstr(i), 1, 'first');
    end
    if isempty(rowi)
        error('Could not find a model-1 random intercept for subject %s.', uniqueIDstr(i));
    end
    subjectIntercepts1(i) = fe1(1) + re1(rowi);
end

sortfile = fullfile('.', ResultsDir, [basename '_' taskChar '_compare3models_sortedidx.mat']);
if recomputeSort || ~exist(sortfile,'file')
    [~, sorted_idx] = sort(subjectIntercepts1);
    save(sortfile,'sorted_idx','subjectIntercepts1','uniqueIDstr');
else
    S = load(sortfile,'sorted_idx');
    sorted_idx = S.sorted_idx;
end

cmap = jet(nsubjects);
subjectcolor = zeros(nobs,3);
for r = 1:nobs
    subjIndex = find(uniqueIDstr == IDstr(r), 1, 'first');
    colorIndex = find(sorted_idx == subjIndex, 1, 'first');
    if isempty(colorIndex)
        colorIndex = subjIndex;
    end
    subjectcolor(r,:) = cmap(colorIndex,:);
end

% ----------------------
% fixed-effect fits and confidence intervals in raw PM units
% ----------------------
xFit = linspace(xMin,xMax,300)';

[yFit1, yLow1, yHigh1, p1] = localPredictBand(model1, xFit, 'd90');
[yFit2, yLow2, yHigh2, p2] = localPredictBand(model2, xFit, 'logelevation');
[yFit3, yLow3, yHigh3, p3] = localPredictBand(model3, xFit, 'linear');

% predictions at observed elevations for comparison metrics on a common scale
[predObs1, ~, ~, ~] = localPredictBand(model1, all_data.Elevation, 'd90');
[predObs2, ~, ~, ~] = localPredictBand(model2, all_data.Elevation, 'logelevation');
[predObs3, ~, ~, ~] = localPredictBand(model3, all_data.Elevation, 'linear');

obsRatio = all_data.Ratio_Visual_Angle;
rmse1 = sqrt(mean((obsRatio - predObs1).^2));
rmse2 = sqrt(mean((obsRatio - predObs2).^2));
rmse3 = sqrt(mean((obsRatio - predObs3).^2));

sst = sum((obsRatio - mean(obsRatio)).^2);
r2_1 = 1 - sum((obsRatio - predObs1).^2) / sst;
r2_2 = 1 - sum((obsRatio - predObs2).^2) / sst;
r2_3 = 1 - sum((obsRatio - predObs3).^2) / sst;

% comparison table
comparisonTable = table( ...
    string({displayFormula1; displayFormula2; displayFormula3}), ...
    string({titleFormula1; titleFormula2; titleFormula3}), ...
    string({'logRatio'; 'logRatio'; 'Ratio_Visual_Angle'}), ...
    [model1.ModelCriterion.AIC; model2.ModelCriterion.AIC; model3.ModelCriterion.AIC], ...
    [model1.ModelCriterion.BIC; model2.ModelCriterion.BIC; model3.ModelCriterion.BIC], ...
    [model1.LogLikelihood; model2.LogLikelihood; model3.LogLikelihood], ...
    [p1; p2; p3], ...
    [rmse1; rmse2; rmse3], ...
    [r2_1; r2_2; r2_3], ...
    repmat(nsubjects,3,1), ...
    repmat(nobs,3,1), ...
    'VariableNames', {'Formula','FittedFormula','Response','AIC','BIC','LogLikelihood','pValue','RMSE_rawRatio','R2_rawRatio','nSubjects','nObs'});

% shared y-axis limits in raw PM units
allY = [obsRatio; yHigh1; yHigh2; yHigh3; yFit1; yFit2; yFit3];
yMin = 0;
yMax = max(allY);
if ~isfinite(yMax) || yMax <= 0
    yMax = max(obsRatio);
end
yMax = 1.05 * yMax;

% ----------------------
% plot one figure with 3 panels
% ----------------------
figh = figure('Color',[1 1 1], ...
    'Units','normalized', ...
    'Position',[0 0 1 0.52], ...
    'Name',[basename ' ' taskChar ' 3-model comparison']);

ax1 = subplot(1,3,1); hold(ax1,'on')
scatter(ax1, all_data.Elevation, obsRatio, markerScale, subjectcolor, 'o', 'filled');
fill(ax1, [xFit; flipud(xFit)], [yLow1; flipud(yHigh1)], 1, ...
    'facecolor','k', 'edgecolor','none', 'facealpha',0.12);
plot(ax1, xFit, yFit1, 'k-', 'LineWidth', 3);
plot(ax1, [xMin xMax], [1 1], 'Color',[.8 .8 .8], 'LineWidth',2);
localFormatAxis(ax1, xMin, xMax, yMin, yMax)
title(ax1, {titleFormula1, sprintf('p=%s, ns=%d', formatP(p1), nsubjects)})

ax2 = subplot(1,3,2); hold(ax2,'on')
scatter(ax2, all_data.Elevation, obsRatio, markerScale, subjectcolor, 'o', 'filled');
fill(ax2, [xFit; flipud(xFit)], [yLow2; flipud(yHigh2)], 1, ...
    'facecolor','k', 'edgecolor','none', 'facealpha',0.12);
plot(ax2, xFit, yFit2, 'k-', 'LineWidth', 3);
plot(ax2, [xMin xMax], [1 1], 'Color',[.8 .8 .8], 'LineWidth',2);
localFormatAxis(ax2, xMin, xMax, yMin, yMax)
title(ax2, {titleFormula2, sprintf('p=%s, ns=%d', formatP(p2), nsubjects)})

ax3 = subplot(1,3,3); hold(ax3,'on')
scatter(ax3, all_data.Elevation, obsRatio, markerScale, subjectcolor, 'o', 'filled');
fill(ax3, [xFit; flipud(xFit)], [yLow3; flipud(yHigh3)], 1, ...
    'facecolor','k', 'edgecolor','none', 'facealpha',0.12);
plot(ax3, xFit, yFit3, 'k-', 'LineWidth', 3);
plot(ax3, [xMin xMax], [1 1], 'Color',[.8 .8 .8], 'LineWidth',2);
localFormatAxis(ax3, xMin, xMax, yMin, yMax)
title(ax3, {titleFormula3, sprintf('p=%s, ns=%d', formatP(p3), nsubjects)}, 'Interpreter','none')

linkaxes([ax1 ax2 ax3],'xy')

% ----------------------
% save outputs
% ----------------------
filenamePNG = fullfile('.', ResultsDir, ['ModelComparison3_' basename '_' taskChar '_' num2str(nsubjects) 'subjects.png']);
filenameTXT = fullfile('.', ResultsDir, [basename '_' taskChar '_compare3models.txt']);
filenameMAT = fullfile('.', ResultsDir, [basename '_' taskChar '_compare3models.mat']);

exportgraphics(figh, filenamePNG, 'Resolution', 600);

results = struct();
results.model1 = model1;
results.model2 = model2;
results.model3 = model3;
results.comparisonTable = comparisonTable;
results.compare12 = compare12;
results.compare12_message = compare12_message;
results.sorted_idx = sorted_idx;
results.sorted_subject_ids = uniqueIDstr(sorted_idx);
results.subject_intercepts_model1 = subjectIntercepts1;
results.figure_file = filenamePNG;
results.text_file = filenameTXT;
results.mat_file = filenameMAT;
results.task = task;
results.basename = basename;
results.nSubjects = nsubjects;
results.nObs = nobs;

results_summary = struct();
results_summary.comparisonTable = comparisonTable;
results_summary.compare12_message = compare12_message;
results_summary.sorted_idx = sorted_idx;
results_summary.sorted_subject_ids = uniqueIDstr(sorted_idx);
results_summary.subject_intercepts_model1 = subjectIntercepts1;
results_summary.figure_file = filenamePNG;
results_summary.text_file = filenameTXT;
results_summary.task = task;
results_summary.basename = basename;
results_summary.nSubjects = nsubjects;
results_summary.nObs = nobs;
save(filenameMAT,'results_summary')

if saveLME
    diary(filenameTXT)
    fprintf(1,'Three-model comparison for %s task\n', taskChar);
    fprintf(1,'Data file: %s\n', datafile);
    fprintf(1,'nSubjects = %d\n', nsubjects);
    fprintf(1,'nObs = %d\n\n', nobs);

    fprintf(1,'Comparison summary table\n');
    disp(comparisonTable)
    fprintf(1,'\n')

    fprintf(1,'Model 1\n');
    disp(model1)
    fprintf(1,'\nModel 2\n');
    disp(model2)
    fprintf(1,'\nModel 3\n');
    disp(model3)
    fprintf(1,'\n')

    fprintf(1,'%s\n', compare12_message);
    if ~isempty(compare12)
        disp(compare12)
    end
    fprintf(1,'AIC/BIC/logLik are most directly comparable for models 1 and 2 because they share the same response variable.\n');
    fprintf(1,'RMSE_rawRatio and R2_rawRatio provide a common raw-scale comparison across all three models.\n');
    diary off
end

end

% =======================================================================
function [yFitRaw, yLowRaw, yHighRaw, pval] = localPredictBand(lme, xRaw, modelKind)
% Build fixed-effect prediction and confidence interval in raw PM units.

[beta,~,stats] = fixedEffects(lme);
Sigma = lme.CoefficientCovariance;
pval = stats.pValue(2);

try
    df = stats.DF;
    if numel(df) > 1
        df = min(df);
    end
    if isempty(df) || ~isfinite(df) || df <= 0
        df = lme.DFE;
    end
catch
    df = lme.DFE;
end
tCrit = tinv(0.975, df);

xRaw = xRaw(:);

switch lower(modelKind)
    case 'd90'
        xModel = log2(1 + xRaw/90);
        X = [ones(size(xModel)) xModel];
        yFitLog = X * beta;
        seFit = sqrt(sum((X * Sigma) .* X, 2));
        yLowLog = yFitLog - tCrit * seFit;
        yHighLog = yFitLog + tCrit * seFit;
        yFitRaw = 2.^yFitLog;
        yLowRaw = 2.^yLowLog;
        yHighRaw = 2.^yHighLog;

    case 'logelevation'
        xModel = log2(1 + xRaw);
        X = [ones(size(xModel)) xModel];
        yFitLog = X * beta;
        seFit = sqrt(sum((X * Sigma) .* X, 2));
        yLowLog = yFitLog - tCrit * seFit;
        yHighLog = yFitLog + tCrit * seFit;
        yFitRaw = 2.^yFitLog;
        yLowRaw = 2.^yLowLog;
        yHighRaw = 2.^yHighLog;

    case 'linear'
        X = [ones(size(xRaw)) xRaw];
        yFitRaw = X * beta;
        seFit = sqrt(sum((X * Sigma) .* X, 2));
        yLowRaw = yFitRaw - tCrit * seFit;
        yHighRaw = yFitRaw + tCrit * seFit;

    otherwise
        error('Unknown model kind: %s', modelKind);
end
end

% =======================================================================
function localFormatAxis(axh, xMin, xMax, yMin, yMax)
set(axh,'FontSize',16,'FontName','Avenir')
xlim(axh,[xMin xMax])
ylim(axh,[yMin yMax])
xlabel(axh,'Moon Elevation (degrees)')
ylabel(axh,'Perceptual Magnification')
box(axh,'off')
end

% =======================================================================
function s = localPowerFormula(scaleCoeff, baseExpr, exponentCoeff)
s = sprintf('PM = %s*(%s)^{%s}', formatCoef(scaleCoeff), baseExpr, formatCoef(exponentCoeff));
end

% =======================================================================
function s = localLinearFormula(interceptCoeff, slopeCoeff)
if slopeCoeff >= 0
    s = sprintf('PM = %s + %s*Elevation', formatCoef(interceptCoeff), formatCoef(slopeCoeff));
else
    s = sprintf('PM = %s - %s*Elevation', formatCoef(interceptCoeff), formatCoef(abs(slopeCoeff)));
end
end

% =======================================================================
function s = formatCoef(x)
if ~isfinite(x)
    s = 'NaN';
elseif abs(x) >= 1000 || (abs(x) > 0 && abs(x) < 0.001)
    s = sprintf('%.2e', x);
else
    s = sprintf('%.3f', x);
end
end

% =======================================================================
function s = formatP(p)
if ~isfinite(p)
    s = 'NaN';
elseif p < 0.001
    s = sprintf('%.2e',p);
else
    s = sprintf('%.4f',p);
end
end
