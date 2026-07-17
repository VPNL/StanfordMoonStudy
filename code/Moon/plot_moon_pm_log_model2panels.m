function figPath = plot_moon_pm_log_model2panels(all_data, plottedLogModel, ...
    subjectcolor, cmap, sorted_idx_log, basename, task, ResultsDir, markerScale)
% plot_moon_pm_log_model2panels
%
% Create a 2-panel supplemental moon PM figure:
%   1) log PM vs log Elevation with fixed-effects fit + CI + individual RS slopes
%   2) PM vs Elevation (linear scale) with fixed-effects power-law fit + CI
% The linear-scale panel title reports the logElevation p value from:
%   logRatio ~ 1 + logElevation + (1 | ID)
%
% Inputs
%   all_data       : moon task table with Ratio_Visual_Angle, Elevation, logRatio, logElevation, ID, Session
%   plottedLogModel: LinearMixedModel, typically logRatio ~ logElevation + (Elevation|ID)
%   subjectcolor   : Nx3 colors aligned to all_data rows
%   cmap           : subject colormap
%   sorted_idx_log : subject sort order used for colors
%   basename       : basename for output file
%   task           : task label
%   ResultsDir     : output directory
%   markerScale    : scatter marker size
%
% Output
%   figPath        : saved PNG path

if nargin < 9 || isempty(markerScale)
    markerScale = 36;
end

ID = all_data.ID;
uniqueID = unique(ID);
nsubjects = numel(uniqueID);
maxRatio = max(all_data.Ratio_Visual_Angle);

[xNativeData, xLogData, xLabelLinear, xLabelLog, formulaTerm, xFitNative] = ...
    local_get_elevation_plot_spec(all_data, plottedLogModel);

[reEfx_log,reNames_log] = randomEffects(plottedLogModel);
[feEfx_log,~,festats_log] = fixedEffects(plottedLogModel);

interceptL = feEfx_log(1);
slopeL = feEfx_log(2);
pvalL = festats_log.pValue(2);
panel2Pval = local_panel2_title_pvalue(all_data);
lower_slopeL = festats_log.Lower(2);
upper_slopeL = festats_log.Upper(2);

individualIntercepts_log = zeros(nsubjects,1);
individualSlopes_log = zeros(nsubjects,1);
for i = 1:nsubjects
    subjectRows = find(strcmp(reNames_log.Level, num2str(uniqueID(i))));
    individualIntercepts_log(i) = feEfx_log(1) + reEfx_log(subjectRows(1));
    individualSlopes_log(i) = feEfx_log(2) + reEfx_log(subjectRows(2));
end

figh = figure('Color',[1 1 1], ...
    'Units','normalized', ...
    'Position',[0 0 1 .8], ...
    'Name',[basename '_' task '_SuppFigModelComps_2panel']);


% -------------------------------------------------------
% Panel 1: log PM vs log Elevation, with subject RS lines
% --------------------------------------------------------
subplot(1,2,1); hold on
xLogFit = linspace(min(xLogData), max(xLogData), 200);
yLogFit = interceptL + slopeL * xLogFit;
yLogLow = interceptL + lower_slopeL * xLogFit;
xLogFitDesc = sort(xLogFit, 'descend');
yLogHigh = interceptL + upper_slopeL * xLogFitDesc;

if pvalL < 0.05
    for s = 1:nsubjects
        sortedID = sorted_idx_log(s);
        sindex = find(uniqueID == ID(sortedID), 1, 'first');
        jj = find(all_data.ID == uniqueID(sindex));
        if numel(jj) > 1
            sdata = all_data(jj,:);
            lower = find(strcmp(sdata.Session,'Lower'));
            higher = find(strcmp(sdata.Session,'Higher'));
            xvectorS = [xLogData(jj(lower)) xLogData(jj(higher))];
            yvectorS = individualSlopes_log(sortedID) * xvectorS + individualIntercepts_log(sortedID);
            plot(xvectorS, yvectorS, ':', 'Color', cmap(s,:), 'LineWidth', 1);
        end
    end
end

fill([xLogFit xLogFitDesc], [yLogLow yLogHigh], 1, 'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot(xLogFit, yLogFit, 'k-', 'LineWidth', 5);
scatter(xLogData, all_data.logRatio, markerScale, subjectcolor, 'o', 'filled');
plot([min(xLogData) max(xLogData)], [0 0], 'Color',[.8 .8 .8], 'LineWidth', 3)
xlabel(xLabelLog)
ylabel('Perceptual Magnification, log scale')
set(gca,'FontSize',20, 'FontName','Avenir')
if pvalL < 0.001
        titleStr=sprintf('%s Matching\n intercept=%.2f slope=%.3f \n p=%.2e\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
    else
        titleStr=sprintf('%s Matching\n intercept=%.2f slope=%.3f \n p=%.3f\n n=%d',task, 2^interceptL,slopeL,festats_log.pValue(2), nsubjects);
end 

title(titleStr,'FontSize',16,'FontName','Avenir')

xticksVals = get(gca,'XTick');
set(gca,'XTickLabel', local_native_tick_labels(xticksVals, plottedLogModel));
yticksVals = get(gca,'YTick');
set(gca,'YTickLabel', round(2.^yticksVals, 1));


% ----------------------
% Panel 2: PM vs Elevation, linear scale
% ----------------------
subplot(1,2,2); hold on
xFit = xFitNative(:)';
yFit = 2^interceptL * (xFit.^slopeL);
yLow = 2^interceptL * (xFit.^lower_slopeL);
xFitDesc = sort(xFit, 'descend');
yHigh = 2^interceptL * (xFitDesc.^upper_slopeL);

scatter(xNativeData, all_data.Ratio_Visual_Angle, markerScale, subjectcolor, 'o', 'filled');
fill([xFit xFitDesc], [yLow yHigh], 1, 'facecolor','k', 'edgecolor','none', 'facealpha',0.1);
plot(xFit, yFit, 'k-', 'LineWidth', 3);
plot([0 max(xNativeData)], [1 1], 'Color',[.8 .8 .8], 'LineWidth', 3);
xlabel(xLabelLinear)
ylabel('Perceptual Magnification')
ylim([0 maxRatio])
set(gca,'YTick',0:1:maxRatio,'YTickLabel',0:1:maxRatio,'FontSize',20,'FontName','Avenir')

if panel2Pval < 0.001
    titleStr = sprintf('%s Matching\n PM=%.1f%s^{%.2f}\n p=%5.2e\n n=%d', ...
        task, round(2^interceptL,1), formulaTerm, slopeL, panel2Pval, nsubjects);
else
    titleStr = sprintf('%s Matching\n PM=%.1f%s^{%.2f}\n p=%.4f\n n=%d', ...
        task, round(2^interceptL,1), formulaTerm, slopeL, panel2Pval, nsubjects);
end
title(titleStr,'FontSize',16,'FontName','Avenir')

figPNG = fullfile(ResultsDir, ['Fig1_2panels_' basename '_' task '_' num2str(nsubjects) '.png']);
print(figh, figPNG, '-dpng', '-r600');
figEPS = fullfile(ResultsDir, ['Fig1_2panels_' basename '_' task '_' num2str(nsubjects) '.eps']);
print(figh, figEPS, '-deps', '-r600');
end

function pval = local_panel2_title_pvalue(all_data)
panel2Model = fitlme(all_data, 'logRatio ~ 1 + logElevation + (1 | ID)');
pval = local_fixed_effect_pvalue(panel2Model, "logElevation");
end

function pval = local_fixed_effect_pvalue(lme, coefficientName)
coefNames = string(lme.Coefficients.Name);
coefIdx = find(coefNames == coefficientName, 1, 'first');
if isempty(coefIdx)
    error('Coefficient "%s" not found in model coefficients.', coefficientName);
end
pval = lme.Coefficients.pValue(coefIdx);
end

function [xNativeData, xLogData, xLabelLinear, xLabelLog, formulaTerm, xFitNative] = ...
    local_get_elevation_plot_spec(all_data, plottedLogModel)
coefNames = string(plottedLogModel.Coefficients.Name);
predictorName = "";
if numel(coefNames) >= 2
    predictorName = coefNames(2);
end

switch predictorName
    case "logElevationD90"
        xNativeData = all_data.Elevation;
        xLogData = all_data.logElevationD90;
        xLabelLinear = 'Moon Elevation (degrees)';
        xLabelLog = 'Moon Elevation (degrees), log scale';
        formulaTerm = '(1+Elevation/90)';
        xFitNative = linspace(1, max(xNativeData), 200);
    otherwise
        xNativeData = all_data.Elevation;
        xLogData = all_data.logElevation;
        if ismember('ElevationRAD', all_data.Properties.VariableNames)
            xLabelLinear = 'Moon Elevation (radians)';
            xLabelLog = 'Moon Elevation (radians), log scale';
        else
            xLabelLinear = 'Moon Elevation (degrees)';
            xLabelLog = 'Moon Elevation (degree), log scale';
        end
        formulaTerm = '(1+Elevation)';
        xFitNative = linspace(1, max(xNativeData), 200);
end
end

function labels = local_native_tick_labels(xticksVals, plottedLogModel)
coefNames = string(plottedLogModel.Coefficients.Name);
predictorName = "";
if numel(coefNames) >= 2
    predictorName = coefNames(2);
end

switch predictorName
    case "logElevationD90"
        nativeVals = 90 * (2.^xticksVals - 1);
    otherwise
        nativeVals = 2.^xticksVals - 1;
end
labels = round(nativeVals, 1);
end
