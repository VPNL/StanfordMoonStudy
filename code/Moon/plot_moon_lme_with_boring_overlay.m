function [figureHandle, sortedMoonIDs] = ...
    plot_moon_lme_with_boring_overlay(taskAnalysis, boringData, ...
    moonTask, boringTaskLabel, outputStem, sortedMoonIDs)
% PLOT_MOON_LME_WITH_BORING_OVERLAY Plot a saved Moon LME with Boring data.
% The supplied Moon RI/RS models are used without refitting. Boring data are
% scatter overlays only and do not contribute to either Moon model.

if nargin < 6
    sortedMoonIDs = [];
end

moonData = taskAnalysis.Data;
moonRILME = taskAnalysis.RILME;
moonRSLME = taskAnalysis.RSLME;
[fixedEffectsRI, ~, fixedStatsRI] = fixedEffects(moonRILME);
[randomEffectsRS, randomNamesRS] = randomEffects(moonRSLME);

moonIDs = unique(moonData.ID);
nMoonParticipants = numel(moonIDs);
participantIntercept = nan(nMoonParticipants, 1);
participantSlope = nan(nMoonParticipants, 1);
for participantIdx = 1:nMoonParticipants
    randomRows = find(strcmp(string(randomNamesRS.Level), ...
        string(moonIDs(participantIdx))));
    if numel(randomRows) >= 2
        participantIntercept(participantIdx) = ...
            fixedEffectsRI(1) + randomEffectsRS(randomRows(1));
        participantSlope(participantIdx) = ...
            fixedEffectsRI(2) + randomEffectsRS(randomRows(2));
    end
end

if isempty(sortedMoonIDs)
    [~, sortedIdx] = sort(participantIntercept);
    sortedMoonIDs = moonIDs(sortedIdx);
else
    [foundIDs, sortedIdx] = ismember(sortedMoonIDs, moonIDs);
    sortedIdx = sortedIdx(foundIDs & sortedIdx > 0);
    remainingIdx = setdiff((1:nMoonParticipants)', sortedIdx, 'stable');
    sortedIdx = [sortedIdx; remainingIdx];
    sortedMoonIDs = moonIDs(sortedIdx);
end

moonCmap = jet(nMoonParticipants);
moonRowColors = nan(height(moonData), 3);
for sortedRank = 1:nMoonParticipants
    participantIdx = sortedIdx(sortedRank);
    participantRows = moonData.ID == moonIDs(participantIdx);
    moonRowColors(participantRows, :) = repmat(moonCmap(sortedRank, :), ...
        sum(participantRows), 1);
end

boringIDs = unique(boringData.ID);
nBoringParticipants = numel(boringIDs);
markerSymbols = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};
if nBoringParticipants > numel(markerSymbols)
    error('BoringOverlay:NotEnoughMarkers', ...
        'Add marker symbols for all %d Boring participants.', ...
        nBoringParticipants);
end

intercept = fixedEffectsRI(1);
slope = fixedEffectsRI(2);
pValue = fixedStatsRI.pValue(2);
lowerSlope = fixedStatsRI.Lower(2);
upperSlope = fixedStatsRI.Upper(2);
markerScale = 36;

figureHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0.02 0.05 0.96 0.72], ...
    'Name', sprintf('%s Moon model with Boring %s data', ...
    moonTask, boringTaskLabel));
tiledlayout(figureHandle, 1, 2, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

%% Linear elevation and PM panel
linearAxes = nexttile(1);
hold(linearAxes, 'on');
scatter(linearAxes, moonData.Elevation, moonData.Ratio_Visual_Angle, ...
    markerScale, moonRowColors, 'o', 'filled', 'HandleVisibility', 'off');

maxElevation = max([double(moonData.Elevation); double(boringData.Elevation)]);
xLinear = linspace(1, maxElevation);
yLinear = 2^intercept .* xLinear.^slope;
lowerY = 2^intercept .* xLinear.^lowerSlope;
xLinearDescending = sort(xLinear, 'descend');
upperY = 2^intercept .* xLinearDescending.^upperSlope;
fill(linearAxes, [xLinear xLinearDescending], [lowerY upperY], 1, ...
    'FaceColor', 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.1, ...
    'HandleVisibility', 'off');
moonFitHandle = plot(linearAxes, xLinear, yLinear, 'k-', ...
    'LineWidth', 3, 'DisplayName', 'Moon fixed-effect fit');

boringHandles = gobjects(nBoringParticipants, 1);
for participantIdx = 1:nBoringParticipants
    participantRows = boringData.ID == boringIDs(participantIdx);
    boringHandles(participantIdx) = scatter(linearAxes, ...
        boringData.Elevation(participantRows), ...
        boringData.Ratio_Visual_Angle(participantRows), markerScale + 10, ...
        'k', markerSymbols{participantIdx}, 'filled', ...
        'DisplayName', sprintf('Boring participant %s', ...
        string(boringIDs(participantIdx))));
end
plot(linearAxes, [0 maxElevation], [1 1], 'Color', [0.8 0.8 0.8], ...
    'LineWidth', 3, 'HandleVisibility', 'off');
xlabel(linearAxes, 'Moon Elevation (degrees)');
ylabel(linearAxes, 'Perceptual Magnification');
maxRatio = max([double(moonData.Ratio_Visual_Angle); ...
    double(boringData.Ratio_Visual_Angle)]);
ylim(linearAxes, [0 ceil(maxRatio)]);
set(linearAxes, 'FontSize', 20, 'FontName', 'Avenir');

if pValue < 0.001
    pText = sprintf('%5.2e', pValue);
else
    pText = sprintf('%.4f', pValue);
end
title(linearAxes, sprintf(['%s Matching + Boring %s data\n' ...
    'Moon PM=%.1f(1+Elevation)^{%.2f}, p=%s, n=%d'], ...
    moonTask, boringTaskLabel, round(2^intercept, 1), slope, pText, ...
    nMoonParticipants), 'FontSize', 16, 'FontName', 'Avenir');
legend(linearAxes, [moonFitHandle; boringHandles], ...
    'Location', 'eastoutside', 'FontSize', 11);

%% Log2 elevation and PM panel
logAxes = nexttile(2);
hold(logAxes, 'on');
xLog = linspace(min(moonData.logElevation), max(moonData.logElevation));
if pValue < 0.05
    for sortedRank = 1:nMoonParticipants
        participantIdx = sortedIdx(sortedRank);
        if isfinite(participantIntercept(participantIdx)) && ...
                isfinite(participantSlope(participantIdx))
            yParticipant = participantIntercept(participantIdx) + ...
                participantSlope(participantIdx) .* xLog;
            plot(logAxes, xLog, yParticipant, ':', ...
                'Color', moonCmap(sortedRank, :), 'LineWidth', 1, ...
                'HandleVisibility', 'off');
        end
    end
end
scatter(logAxes, moonData.logElevation, moonData.logRatio, markerScale, ...
    moonRowColors, 'o', 'filled', 'HandleVisibility', 'off');
for participantIdx = 1:nBoringParticipants
    participantRows = boringData.ID == boringIDs(participantIdx);
    scatter(logAxes, boringData.logElevation(participantRows), ...
        boringData.logRatio(participantRows), markerScale + 10, 'k', ...
        markerSymbols{participantIdx}, 'filled', 'HandleVisibility', 'off');
end
plot(logAxes, [0 max([moonData.logElevation; boringData.logElevation])], ...
    [0 0], 'Color', [0.8 0.8 0.8], 'LineWidth', 3, ...
    'HandleVisibility', 'off');
xlabel(logAxes, 'Moon Elevation (degrees), log_2 scale');
ylabel(logAxes, 'Perceptual Magnification, log_2 scale');
set(logAxes, 'FontSize', 20, 'FontName', 'Avenir');
logXTicks = get(logAxes, 'XTick');
set(logAxes, 'XTickLabel', round(2.^logXTicks, 1));
logYTicks = get(logAxes, 'YTick');
set(logAxes, 'YTickLabel', round(2.^logYTicks, 1));
title(logAxes, sprintf(['%s Moon log model + Boring %s data\n' ...
    'intercept=%.2f, slope=%.3f, p=%s, Moon n=%d'], ...
    moonTask, boringTaskLabel, 2^intercept, slope, pText, ...
    nMoonParticipants), 'FontSize', 16, 'FontName', 'Avenir');

exportgraphics(figureHandle, [outputStem '.png'], 'Resolution', 600);
print(figureHandle, [outputStem '.eps'], '-depsc', '-r600');
save([outputStem '_models.mat'], 'moonRILME', 'moonRSLME', ...
    'moonData', 'boringData', 'boringIDs', 'markerSymbols', ...
    'sortedMoonIDs', 'moonTask', 'boringTaskLabel');
end
