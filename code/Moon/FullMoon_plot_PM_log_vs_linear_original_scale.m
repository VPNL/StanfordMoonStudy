function figHandle = FullMoon_plot_PM_log_vs_linear_original_scale( ...
    tbl, lmeLogRI, lmeLinearRI, subjectColor, task, resultsDir, ...
    baseName, nSubjects)
% Compare RI log-log and linear PM models on the original measurement scale.

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

xMin = min(tbl.Elevation);
xMax = max(tbl.Elevation);
yMax = max(tbl.Ratio_Visual_Angle);
xGrid = linspace(xMin, xMax, 300)';

[logFit, logLower, logUpper] = local_fixed_effect_curve( ...
    lmeLogRI, log2(1 + xGrid), true);
[linearFit, linearLower, linearUpper] = local_fixed_effect_curve( ...
    lmeLinearRI, xGrid, false);

[logAdjustedR2, logRMSE] = local_original_scale_metrics( ...
    lmeLogRI, tbl.Ratio_Visual_Angle, true);
[linearAdjustedR2, linearRMSE] = local_original_scale_metrics( ...
    lmeLinearRI, tbl.Ratio_Visual_Angle, false);

figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .8 .6], ...
    'Name', [baseName ' log-log versus linear RI models on original scale']);

subplot(1,2,1);
local_plot_panel(tbl, subjectColor, xGrid, logFit, logLower, logUpper, ...
    xMax, yMax, task, 'Log-log RI model on original scale', ...
    logAdjustedR2, logRMSE, false);

subplot(1,2,2);
local_plot_panel(tbl, subjectColor, xGrid, linearFit, linearLower, linearUpper, ...
    xMax, yMax, task, 'Linear RI model on original scale', ...
    linearAdjustedR2, linearRMSE, false);

filename = fullfile(resultsDir, sprintf( ...
    'Supplemental_Fig_LogVsLin_%s_%s_%d.png', ...
    baseName, task, nSubjects));
exportgraphics(figHandle, filename, 'Resolution', 600);
end

function [fitOriginal, lowerOriginal, upperOriginal] = ...
    local_fixed_effect_curve(lme, xModel, backTransformLog2)
beta = fixedEffects(lme);
design = [ones(numel(xModel),1), xModel];
fitModel = design * beta;

coefficientCovariance = lme.CoefficientCovariance;
predictionVariance = sum((design * coefficientCovariance) .* design, 2);
predictionSE = sqrt(max(predictionVariance, 0));
criticalValue = 1.96;
lowerModel = fitModel - criticalValue * predictionSE;
upperModel = fitModel + criticalValue * predictionSE;

if backTransformLog2
    fitOriginal = 2.^fitModel;
    lowerOriginal = 2.^lowerModel;
    upperOriginal = 2.^upperModel;
else
    fitOriginal = fitModel;
    lowerOriginal = lowerModel;
    upperOriginal = upperModel;
end
end

function [adjustedR2, rmse] = local_original_scale_metrics(lme, yActual, backTransformLog2)
yPredicted = predict(lme);
if backTransformLog2
    yPredicted = 2.^yPredicted;
end

valid = isfinite(yActual) & isfinite(yPredicted);
yActual = yActual(valid);
yPredicted = yPredicted(valid);
rSquared = corr(yActual, yPredicted).^2;
n = numel(yActual);
p = max(0, numel(fixedEffects(lme)) - 1) + numel(randomEffects(lme));
if n > p + 1
    adjustedR2 = 1 - (1 - rSquared) * (n - 1) / (n - p - 1);
else
    adjustedR2 = NaN;
end
rmse = sqrt(mean((yActual - yPredicted).^2));
end

function local_plot_panel(tbl, subjectColor, xGrid, yFit, yLower, yUpper, ...
    xMax, yMax, task, modelTitle, adjustedR2, rmse, hideYAxis)
hold on;
fill([xGrid; flipud(xGrid)], [yLower; flipud(yUpper)], [0.85 0.85 0.85], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.75);
plot(xGrid, yFit, 'k-', 'LineWidth', 3);
scatter(tbl.Elevation, tbl.Ratio_Visual_Angle, 36, subjectColor, 'filled');
plot([0 xMax], [1 1], 'Color', [0.8 0.8 0.8], 'LineWidth', 3);

xlim([0 xMax]);
ylim([0 yMax]);
set(gca, 'YTick', 0:1:yMax, 'FontSize', 20, 'FontName', 'Avenir');
xlabel('Moon Elevation (degrees)');
if hideYAxis
    set(gca, 'YColor', 'w');
else
    ylabel('Perceptual Magnification');
end
title(sprintf('%s Matching\n%s\nAdjusted R^2=%.3f, RMSE=%.3f', ...
    task, modelTitle, adjustedR2, rmse), ...
    'FontSize', 14, 'FontName', 'Avenir', 'FontWeight', 'normal');
end
