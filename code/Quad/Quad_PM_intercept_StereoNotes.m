function interceptTbl = Quad_PM_intercept_StereoNotes(tblStereo, lmePerceptual, lmeAdjusted, QuadBasename, ResultsDir, setaxesLim, val)
% QUAD_PM_INTERCEPT_STEREONOTES
% Build a per-subject table of PM intercepts from the perceptual and
% adjusted 3-factor LMEs together with normed stereo score and notes.

if nargin < 5 || isempty(ResultsDir)
    ResultsDir = pwd;
end

if nargin < 6 || isempty(setaxesLim)
    setaxesLim = false;
end

if nargin < 7
    val = [];
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

scoreVar = local_find_first_var(tblStereo, {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
hasStereo = ~isempty(scoreVar);

if ~iscategorical(tblStereo.ID)
    ids = categorical(tblStereo.ID);
else
    ids = tblStereo.ID;
end

uniqueID = categories(removecats(ids));
normedScore = nan(numel(uniqueID), 1);
notes = strings(numel(uniqueID), 1);
for i = 1:numel(uniqueID)
    rowMask = ids == categorical(uniqueID(i));
    if hasStereo
        normedScore(i) = mean(double(tblStereo.(scoreVar)(rowMask)), 'omitnan');
    end
    notes(i) = local_collect_notes(tblStereo(rowMask, :));
end

perceptualIntercept = local_extract_subject_intercepts(lmePerceptual, uniqueID);
adjustedIntercept = local_extract_subject_intercepts(lmeAdjusted, uniqueID);
interceptDifference = adjustedIntercept - perceptualIntercept;
powerLawInterceptPerceptual = 2 .^ perceptualIntercept;
powerLawInterceptAdjusted = 2 .^ adjustedIntercept;
powerLawInterceptDifference = powerLawInterceptAdjusted - powerLawInterceptPerceptual;

interceptTbl = table(string(uniqueID), perceptualIntercept, adjustedIntercept, interceptDifference, ...
    powerLawInterceptPerceptual, powerLawInterceptAdjusted, powerLawInterceptDifference, normedScore, notes, ...
    'VariableNames', {'ID', 'Intercept_Perceptual', 'Intercept_Adjusted', 'Intercept_Difference', ...
    'PowerLawIntercept_Perceptual', 'PowerLawIntercept_Adjusted', 'PowerLawIntercept_Difference', ...
    'NormedStereoScore', 'Notes'});

interceptTbl = sortrows(interceptTbl, 'PowerLawIntercept_Perceptual', 'descend');
outFile = fullfile(ResultsDir, [QuadBasename '_PM_intercept_StereoNotes.csv']);
writetable(interceptTbl, outFile);
local_plot_intercept_scatter(interceptTbl, QuadBasename, ResultsDir, hasStereo, setaxesLim, val);
end

function subjectIntercept = local_extract_subject_intercepts(lmeFull, uniqueID)
[reEfx, reNames] = randomEffects(lmeFull);
levels = string(reNames.Level);
names = string(reNames.Name);
coefNames = string(lmeFull.Coefficients.Name);
fixedInterceptIdx = find(strcmp(coefNames, '(Intercept)'), 1, 'first');

if isempty(fixedInterceptIdx)
    error('Quad_PM_intercept_StereoNotes:MissingIntercept', ...
        'The supplied LME does not contain a fixed intercept.');
end

fixedIntercept = lmeFull.Coefficients.Estimate(fixedInterceptIdx);
subjectIntercept = nan(numel(uniqueID), 1);

for i = 1:numel(uniqueID)
    idxIntercept = find(strcmp(levels, string(uniqueID(i))) & strcmp(names, '(Intercept)'), 1, 'first');
    if ~isempty(idxIntercept)
        subjectIntercept(i) = fixedIntercept + reEfx(idxIntercept);
    else
        subjectIntercept(i) = fixedIntercept;
    end
end
end

function varName = local_find_first_var(tbl, candidates)
for i = 1:numel(candidates)
    if ismember(candidates{i}, tbl.Properties.VariableNames)
        varName = candidates{i};
        return;
    end
end
varName = '';
end

function noteText = local_collect_notes(tblSubject)
noteVar = '';
if ismember('Notes', tblSubject.Properties.VariableNames)
    noteVar = 'Notes';
elseif ismember('Note', tblSubject.Properties.VariableNames)
    noteVar = 'Note';
end

if isempty(noteVar)
    noteText = "";
    return;
end

rawNotes = string(tblSubject.(noteVar));
rawNotes = strtrim(rawNotes);
invalidMask = ismissing(rawNotes) | rawNotes == "" | lower(rawNotes) == "nan";
rawNotes = rawNotes(~invalidMask);

if isempty(rawNotes)
    noteText = "";
    return;
end

uniqueNotes = unique(rawNotes, 'stable');
noteText = strjoin(uniqueNotes, " | ");
end

function local_plot_intercept_scatter(interceptTbl, QuadBasename, ResultsDir, hasStereo, setaxesLim, val)
validMask = ~isnan(interceptTbl.PowerLawIntercept_Perceptual) & ~isnan(interceptTbl.PowerLawIntercept_Adjusted);
if hasStereo
    validMask = validMask & ~isnan(interceptTbl.NormedStereoScore);
end
plotTbl = interceptTbl(validMask, :);

if isempty(plotTbl)
    return;
end

if hasStereo
    [~, plotOrder] = sort(plotTbl.NormedStereoScore, 'descend', 'MissingPlacement', 'last');
    plotTbl = plotTbl(plotOrder, :);
end

figH = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0.18 0.18 0.8 0.8], ...
    'Name', [QuadBasename '_PM_intercept_StereoNotes'], 'Visible', 'off');
ax = axes(figH, 'Position', [0.13 0.14 0.68 0.72]);
hold(ax, 'on');

if hasStereo
     scatter(ax, plotTbl.PowerLawIntercept_Adjusted, plotTbl.PowerLawIntercept_Perceptual, 120, ...
        plotTbl.NormedStereoScore, 'filled', 'MarkerEdgeColor', 'none');
    apply_stereo_score_colormap(ax);
    cb = add_stereo_score_colorbar(ax, 'Normed stereo score');
    cb.FontSize = 24;
    cb.Label.FontSize = 24;
else
    scatter(ax, plotTbl.PowerLawIntercept_Adjusted, plotTbl.PowerLawIntercept_Perceptual, 120, ...
        [.5 .5  .5], 'filled', 'MarkerEdgeColor', 'none');
end

[lims, tickVals] = local_equal_axes_lims_and_ticks(plotTbl.PowerLawIntercept_Adjusted, plotTbl.PowerLawIntercept_Perceptual);
if setaxesLim
    lims = local_validate_axes_lims(val);
    tickVals = local_tick_vals_for_lims(lims);
end
plot(ax, [0 0], lims, 'k-', 'LineWidth', 1);
plot(ax, lims, [0 0], 'k-', 'LineWidth', 1);
plot(ax, lims, lims, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 2);

set(ax, 'FontName', 'Avenir', 'FontSize', 24, ...
    'XTick', tickVals, 'YTick', tickVals);
xlim(ax, lims);
ylim(ax, lims);
xlabel(ax, 'Power-law intercept Monocular', 'FontSize', 24);
ylabel(ax, 'Power-law intercept Binocular', 'FontSize', 24);
box(ax, 'on');
grid(ax, 'off');
axis(ax, 'square');
title(ax, sprintf('n=%d', height(plotTbl)), ...
    'FontSize', 18, 'FontWeight', 'normal');

exportgraphics(figH, fullfile(ResultsDir, [QuadBasename '_PM_intercept_StereoNotes.png']), 'Resolution', 600);
close(figH);
end

function [lims, tickVals] = local_equal_axes_lims_and_ticks(xVals, yVals)
allVals = [xVals(:); yVals(:)];
allVals = allVals(~isnan(allVals));

if isempty(allVals)
    lims = [0 1];
    tickVals = 0:0.25:1;
    return;
end

minVal = min(allVals);
maxVal = max(allVals);
span = maxVal - minVal;
if span <= 0
    span = max(abs(maxVal), 1);
end

targetSteps = [0.1 0.2 0.25 0.5 1 2 5 10];
roughStep = span / 5;
stepIdx = find(targetSteps >= roughStep, 1, 'first');
if isempty(stepIdx)
    tickStep = 10^floor(log10(roughStep));
else
    tickStep = targetSteps(stepIdx);
end

minTick = tickStep * floor(minVal / tickStep);
maxTick = tickStep * ceil(maxVal / tickStep);
if minTick == maxTick
    maxTick = minTick + tickStep;
end

lims = [minTick maxTick];
tickVals = minTick:tickStep:maxTick;
end

function lims = local_validate_axes_lims(val)
if isempty(val) || ~isnumeric(val) || numel(val) ~= 2 || any(~isfinite(val(:)))
    error('Quad_PM_intercept_StereoNotes:InvalidAxesLim', ...
        'When setaxesLim is true, val must be a numeric two-element axis range such as [0 4].');
end

lims = double(val(:))';
if lims(1) >= lims(2)
    error('Quad_PM_intercept_StereoNotes:InvalidAxesLim', ...
        'Axis range val must be increasing, such as [0 4].');
end
end

function tickVals = local_tick_vals_for_lims(lims)
span = lims(2) - lims(1);
targetSteps = [0.1 0.2 0.25 0.5 1 2 5 10];
roughStep = span / 5;
stepIdx = find(targetSteps >= roughStep, 1, 'first');
if isempty(stepIdx)
    tickStep = 10^floor(log10(roughStep));
else
    tickStep = targetSteps(stepIdx);
end

firstTick = tickStep * ceil(lims(1) / tickStep);
lastTick = tickStep * floor(lims(2) / tickStep);
tickVals = firstTick:tickStep:lastTick;
if isempty(tickVals)
    tickVals = lims;
end
end
