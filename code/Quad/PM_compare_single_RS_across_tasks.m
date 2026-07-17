function [resultsTbl, slopeTbl] = PM_compare_single_RS_across_tasks(tblStereo, ...
    lme_logPM_by_logAngle_RS_perceptual, lme_logPM_by_logDistance_RS_perceptual, lme_logPM_by_logElevation_RS_perceptual, ...
    lme_logPM_by_logAngle_RS_adjusted, lme_logPM_by_logDistance_RS_adjusted, lme_logPM_by_logElevation_RS_adjusted, ...
    QuadBasename, ResultsDir, setaxesLim, val)
% PM_COMPARE_SINGLE_RS_ACROSS_TASKS
% Compare subject-level random-slope estimates across perceptual and
% adjusted tasks for angle, distance, and elevation.

if nargin < 9 || isempty(ResultsDir)
    ResultsDir = pwd;
end

if nargin < 10 || isempty(setaxesLim)
    setaxesLim = false;
end

if nargin < 11
    val = [];
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

scoreVar = local_find_first_var(tblStereo, {'NormedStereoScore', 'NormedScore', 'NormScore', 'StereoScore'});
hasStereo = ~isempty(scoreVar);
factorSpecs = { ...
    struct('name', 'Angle',    'predictor', 'log2real_visual_angle', 'lmeP', lme_logPM_by_logAngle_RS_perceptual,    'lmeA', lme_logPM_by_logAngle_RS_adjusted), ...
    struct('name', 'Distance', 'predictor', 'log2distance',           'lmeP', lme_logPM_by_logDistance_RS_perceptual, 'lmeA', lme_logPM_by_logDistance_RS_adjusted), ...
    struct('name', 'Elevation','predictor', 'log2elevation',          'lmeP', lme_logPM_by_logElevation_RS_perceptual,'lmeA', lme_logPM_by_logElevation_RS_adjusted) ...
    };

slopeTblParts = cell(numel(factorSpecs), 1);
resultParts = cell(numel(factorSpecs), 1);
lmStore = cell(numel(factorSpecs), 1);

for i = 1:numel(factorSpecs)
    slopeTblParts{i} = local_build_factor_slope_table(tblStereo, scoreVar, factorSpecs{i}, hasStereo);
    if hasStereo
        lmStore{i} = fitlm(slopeTblParts{i}, 'RS_slope_perceptual ~ RS_slope_adjusted + NormedStereoScore');
    else
        lmStore{i} = fitlm(slopeTblParts{i}, 'RS_slope_perceptual ~ RS_slope_adjusted');
    end
    resultParts{i} = local_build_results_row(factorSpecs{i}.name, slopeTblParts{i}, lmStore{i}, hasStereo);
end

slopeTbl = vertcat(slopeTblParts{:});
resultsTbl = vertcat(resultParts{:});

figH = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0.05 0.10 0.90 0.55], ...
    'Name', [QuadBasename '_PM_single_RSslopes_across_tasks'], 'Visible', 'off');
tlo = tiledlayout(figH, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
axList = gobjects(numel(factorSpecs), 1);

for i = 1:numel(factorSpecs)
    ax = nexttile(tlo);
    axList(i) = ax;
    axesLim = local_get_axes_lim_for_factor(val, factorSpecs{i}.name, i, setaxesLim);
    local_plot_factor_panel(ax, slopeTblParts{i}, lmStore{i}, factorSpecs{i}.name, setaxesLim, axesLim);
end

if hasStereo
    apply_stereo_score_colormap(axList);
    cb = add_stereo_score_colorbar(axList(end), 'Normed stereo score');
    cb.FontSize = 16;
    cb.Label.FontSize = 20;
end

exportgraphics(figH, fullfile(ResultsDir, [QuadBasename '_PM_single_RSslopes_across_tasks.png']), 'Resolution', 600);
close(figH);
end

function slopeTbl = local_build_factor_slope_table(tblStereo, scoreVar, spec, hasStereo)
if ~iscategorical(tblStereo.ID)
    ids = categorical(tblStereo.ID);
else
    ids = tblStereo.ID;
end
uniqueID = categories(removecats(ids));

slopeP = local_extract_subject_slopes(spec.lmeP, spec.predictor, uniqueID);
slopeA = local_extract_subject_slopes(spec.lmeA, spec.predictor, uniqueID);
normedScore = nan(numel(uniqueID), 1);

for i = 1:numel(uniqueID)
    rowMask = ids == categorical(uniqueID(i));
    if hasStereo
        normedScore(i) = mean(double(tblStereo.(scoreVar)(rowMask)), 'omitnan');
    end
end

slopeTbl = table(repmat(string(spec.name), numel(uniqueID), 1), string(uniqueID), ...
    slopeP, slopeA, normedScore, ...
    'VariableNames', {'Factor', 'ID', 'RS_slope_perceptual', 'RS_slope_adjusted', 'NormedStereoScore'});

validMask = ~isnan(slopeTbl.RS_slope_perceptual) & ~isnan(slopeTbl.RS_slope_adjusted);
if hasStereo
    validMask = validMask & ~isnan(slopeTbl.NormedStereoScore);
end
slopeTbl = slopeTbl(validMask, :);
end

function subjectSlope = local_extract_subject_slopes(lmeObj, predictorName, uniqueID)
[reEfx, reNames] = randomEffects(lmeObj);
levels = string(reNames.Level);
names = string(reNames.Name);
coefNames = string(lmeObj.Coefficients.Name);
fixedSlopeIdx = find(strcmp(coefNames, predictorName), 1, 'first');

if isempty(fixedSlopeIdx)
    error('PM_compare_single_RS_across_tasks:MissingSlope', ...
        'Could not find predictor %s in LME coefficients.', predictorName);
end

fixedSlope = lmeObj.Coefficients.Estimate(fixedSlopeIdx);
subjectSlope = nan(numel(uniqueID), 1);

for i = 1:numel(uniqueID)
    idxSlope = find(strcmp(levels, string(uniqueID(i))) & strcmp(names, predictorName), 1, 'first');
    if ~isempty(idxSlope)
        subjectSlope(i) = fixedSlope + reEfx(idxSlope);
    else
        subjectSlope(i) = fixedSlope;
    end
end
end

function resultRow = local_build_results_row(factorName, slopeTbl, lmObj, hasStereo)
coefNames = string(lmObj.Coefficients.Properties.RowNames);
idxAdj = find(strcmp(coefNames, 'RS_slope_adjusted'), 1, 'first');
idxStereo = find(strcmp(coefNames, 'NormedStereoScore'), 1, 'first');
if hasStereo && ~isempty(idxStereo)
    stereoEstimate = lmObj.Coefficients.Estimate(idxStereo);
    stereoPValue = lmObj.Coefficients.pValue(idxStereo);
else
    stereoEstimate = NaN;
    stereoPValue = NaN;
end

resultRow = table(string(factorName), height(slopeTbl), ...
    lmObj.Coefficients.Estimate(idxAdj), lmObj.Coefficients.pValue(idxAdj), ...
    stereoEstimate, stereoPValue, ...
    lmObj.Rsquared.Ordinary, lmObj.Rsquared.Adjusted, ...
    'VariableNames', {'Factor', 'N_IDs', 'AdjustedSlopeEstimate', 'AdjustedSlopePValue', ...
    'StereoEstimate', 'StereoPValue', 'Rsq', 'RsqAdjusted'});
end

function local_plot_factor_panel(ax, slopeTbl, lmObj, factorName, setaxesLim, axesLim)
hold(ax, 'on');

hasStereo = any(~isnan(slopeTbl.NormedStereoScore));
if hasStereo
    [~, plotOrder] = sort(slopeTbl.NormedStereoScore, 'descend', 'MissingPlacement', 'last');
    plotTbl = slopeTbl(plotOrder, :);
    scatter(ax, plotTbl.RS_slope_adjusted, plotTbl.RS_slope_perceptual, 60, plotTbl.NormedStereoScore, ...
        'filled', 'MarkerEdgeColor', 'none');
else
    plotTbl = slopeTbl;
    scatter(ax, plotTbl.RS_slope_adjusted, plotTbl.RS_slope_perceptual, 60, ...
        [0.5 .5 .5], 'filled', 'MarkerEdgeColor', 'none');
end

coefNames = string(lmObj.Coefficients.Properties.RowNames);
idxAdj = find(strcmp(coefNames, 'RS_slope_adjusted'), 1, 'first');
idxStereo = find(strcmp(coefNames, 'NormedStereoScore'), 1, 'first');
pAdjusted = lmObj.Coefficients.pValue(idxAdj);
pStereo = NaN;
if hasStereo && ~isempty(idxStereo)
    pStereo = lmObj.Coefficients.pValue(idxStereo);
end
b0 = lmObj.Coefficients.Estimate(1);
b1 = lmObj.Coefficients.Estimate(idxAdj);
b2 = NaN;
if hasStereo && ~isempty(idxStereo)
    b2 = lmObj.Coefficients.Estimate(idxStereo);
end

xMin = min(plotTbl.RS_slope_adjusted);
xMax = max(plotTbl.RS_slope_adjusted);
yMin = min(plotTbl.RS_slope_perceptual);
yMax = max(plotTbl.RS_slope_perceptual);
[lims, tickVals] = local_equal_axes_lims_and_ticks([xMin; xMax], [yMin; yMax]);
if setaxesLim
    lims = axesLim;
    tickVals = local_tick_vals_for_lims(lims);
end
plot(ax, [0 0], lims, 'k-', 'LineWidth', 1);
plot(ax, lims, [0 0], 'k-', 'LineWidth', 1);
plot(ax, lims, lims, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 2);

if pAdjusted < 0.05
    xGrid = linspace(lims(1), lims(2), 200)';
    if hasStereo
        stereoMean = mean(plotTbl.NormedStereoScore, 'omitnan');
        predTbl = table(xGrid, repmat(stereoMean, numel(xGrid), 1), ...
            'VariableNames', {'RS_slope_adjusted', 'NormedStereoScore'});
        [yHat, yCI] = predict(lmObj, predTbl);
        fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
            [0.75 0.75 0.75], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        plot(ax, xGrid, yHat, 'k-', 'LineWidth', 3);
    else
        predTbl = table(xGrid, 'VariableNames', {'RS_slope_adjusted'});
        [yHat, yCI] = predict(lmObj, predTbl);
        fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
            [0.75 0.75 0.75], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        plot(ax, xGrid, yHat, 'k-', 'LineWidth', 3);
    end
    
end

set(ax, 'FontName', 'Avenir', 'FontSize', 14, ...
    'XTick', tickVals, 'YTick', tickVals);
xlim(ax, lims);
ylim(ax, lims);
xlabel(ax, sprintf('%s slope monocular', factorName), 'FontSize', 18);
ylabel(ax, sprintf('%s slope binocular', factorName), 'FontSize', 18);
box(ax, 'on');
grid(ax, 'off');
axis(ax, 'square');

if hasStereo && ~isnan(b2)
    title(ax, sprintf('%s\nPerceptual = %.2f + %.2fAdjusted + %.2fStereo\np_{Adjusted}=%s, p_{Stereo}=%s, n=%d', ...
        factorName, b0, b1, b2, local_format_pvalue(pAdjusted), local_format_pvalue(pStereo), height(plotTbl)), ...
        'FontSize', 12, 'FontWeight', 'normal');
else
    title(ax, sprintf('%s\nPerceptual = %.2f + %.2fAdjusted\np_{Adjusted}=%s, n=%d', ...
        factorName, b0, b1, local_format_pvalue(pAdjusted), height(plotTbl)), ...
        'FontSize', 12, 'FontWeight', 'normal');
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

function pStr = local_format_pvalue(pval)
if pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
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

function axesLim = local_get_axes_lim_for_factor(val, factorName, factorIndex, setaxesLim)
if ~setaxesLim
    axesLim = [];
    return;
end

if isnumeric(val)
    if isequal(size(val), [3 2])
        axesLim = val(factorIndex, :);
    elseif numel(val) == 6
        axesLims = reshape(val(:), 2, [])';
        axesLim = axesLims(factorIndex, :);
    elseif numel(val) == 2
        axesLim = val(:)';
    else
        error('PM_compare_single_RS_across_tasks:InvalidAxesLim', ...
            'When setaxesLim is true, val must be 3x2, 1x6, a three-cell array, or a struct with Angle/Distance/Elevation limits.');
    end
elseif iscell(val) && numel(val) == 3
    axesLim = val{factorIndex};
elseif isstruct(val)
    axesLim = local_get_struct_axes_lim(val, factorName);
else
    error('PM_compare_single_RS_across_tasks:InvalidAxesLim', ...
        'When setaxesLim is true, val must be 3x2, 1x6, a three-cell array, or a struct with Angle/Distance/Elevation limits.');
end

axesLim = local_validate_axes_lims(axesLim, factorName);
end

function axesLim = local_get_struct_axes_lim(val, factorName)
switch string(factorName)
    case "Angle"
        candidates = {'Angle', 'VA', 'VisualAngle', 'Visual_Angle'};
    case "Distance"
        candidates = {'Distance'};
    case "Elevation"
        candidates = {'Elevation'};
    otherwise
        candidates = {char(factorName)};
end

for i = 1:numel(candidates)
    if isfield(val, candidates{i})
        axesLim = val.(candidates{i});
        return;
    end
end

error('PM_compare_single_RS_across_tasks:InvalidAxesLim', ...
    'Missing %s axis limits in val.', factorName);
end

function lims = local_validate_axes_lims(val, factorName)
if isempty(val) || ~isnumeric(val) || numel(val) ~= 2 || any(~isfinite(val(:)))
    error('PM_compare_single_RS_across_tasks:InvalidAxesLim', ...
        '%s axis limits must be a numeric two-element range such as [-1 1].', factorName);
end

lims = double(val(:))';
if lims(1) >= lims(2)
    error('PM_compare_single_RS_across_tasks:InvalidAxesLim', ...
        '%s axis limits must be increasing, such as [-1 1].', factorName);
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
