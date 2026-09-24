function [pairedTbl, lmeRI, lmeRS, cmpTbl] = PerceptualVsAdjusted_ReportedVisualAngle(tbl, Basename, ResultsDir, colorBy)
% PERCEPTUALVSADJUSTED_REPORTEDVISUALANGLE
%
% Compare Perceptual and Adjusted reported visual angles while including
% normed stereo score as a fixed effect.
%
% Inputs
%   tbl        - table containing both Perceptual and Adjusted task rows
%   Basename   - base label used for exported files
%   ResultsDir - directory for figures and text output
%   colorBy    - participant coloring: 'stereoscore' (default),
%                'clinicalnotes', or 'none'. This affects plots only;
%                stereo score remains in the statistical model when present.
%
% Outputs
%   pairedTbl  - paired Perceptual/Adjusted table used for fitting
%   lmeRI      - random-intercept model
%   lmeRS      - random-slope model
%   cmpTbl     - compare(lmeRI, lmeRS) output

if nargin < 1 || isempty(tbl)
    error('Input table tbl is required.');
end
if nargin < 2 || isempty(Basename)
    Basename = 'PerceptualVsAdjusted_ReportedVisualAngle';
end
if nargin < 3 || isempty(ResultsDir)
    ResultsDir = pwd;
end
if nargin < 4 || isempty(colorBy)
    colorBy = 'stereoscore';
end
colorBy = local_normalize_color_mode(colorBy);

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

pairedTbl = local_build_paired_table(tbl);
hasStereo = ismember('NormedStereoScore', pairedTbl.Properties.VariableNames);
validMask = ~isnan(pairedTbl.Perceptual_Reported_Visual_Angle) & ...
    ~isnan(pairedTbl.Adjusted_Reported_Visual_Angle);
if hasStereo
    validMask = validMask & ~isnan(pairedTbl.NormedStereoScore);
end
pairedTbl = pairedTbl(validMask, :);

if isempty(pairedTbl)
    error('No paired Perceptual/Adjusted rows were found after filtering.');
end

if ~iscategorical(pairedTbl.ID)
    pairedTbl.ID = categorical(pairedTbl.ID);
end

if hasStereo
    formulaRI = 'Perceptual_Reported_Visual_Angle ~ -1 + Adjusted_Reported_Visual_Angle + NormedStereoScore + (-1|ID)';
    formulaRS = 'Perceptual_Reported_Visual_Angle ~ -1 + Adjusted_Reported_Visual_Angle + NormedStereoScore + (Adjusted_Reported_Visual_Angle-1|ID)';
else
    formulaRI = 'Perceptual_Reported_Visual_Angle ~ -1 + Adjusted_Reported_Visual_Angle + (-1|ID)';
    formulaRS = 'Perceptual_Reported_Visual_Angle ~ -1 + Adjusted_Reported_Visual_Angle + (Adjusted_Reported_Visual_Angle-1|ID)';
end

lmeRI = fitlme(pairedTbl, formulaRI);
lmeRS = fitlme(pairedTbl, formulaRS);
cmpTbl = compare(lmeRI, lmeRS);

colorSpec = local_build_color_spec(tbl, Basename, ResultsDir, colorBy);
local_write_report(pairedTbl, lmeRI, lmeRS, cmpTbl, Basename, ResultsDir, formulaRI, formulaRS, hasStereo, colorBy);
local_plot_ri_figure(pairedTbl, lmeRI, Basename, ResultsDir, hasStereo, colorSpec);
local_plot_rs_figure(pairedTbl, lmeRS, Basename, ResultsDir, hasStereo, colorSpec);
end

function pairedTbl = local_build_paired_table(tbl)
requiredVars = {'ID','Task','Measurement','Reported_Visual_Angle'};
for iVar = 1:numel(requiredVars)
    if ~ismember(requiredVars{iVar}, tbl.Properties.VariableNames)
        error('Input table is missing required variable "%s".', requiredVars{iVar});
    end
end

scoreVar = local_find_score_var(tbl);

tbl = tbl(~ismissing(tbl.Task) & ~ismissing(tbl.Measurement), :);
tbl.MeasurementBase = regexprep(string(tbl.Measurement), '_(Perceptual|Adjusted)_VA$', '', 'ignorecase');

joinCandidates = {'ID','Date','Time','Version','MeasurementBase','Object', ...
    'Ground_Distance','Real_Visual_Angle','Ground_Elevation', ...
    'Observer_Distance','Observer_Elevation','Width'};
joinKeys = joinCandidates(ismember(joinCandidates, tbl.Properties.VariableNames));

tblPerceptual = tbl(strcmpi(string(tbl.Task), 'Perceptual'), :);
tblAdjusted = tbl(strcmpi(string(tbl.Task), 'Adjusted'), :);

keepPerceptual = unique([joinKeys, {'Reported_Visual_Angle'}], 'stable');
if ~isempty(scoreVar)
    keepPerceptual = unique([keepPerceptual, {scoreVar}], 'stable');
end
keepAdjusted = unique([joinKeys, {'Reported_Visual_Angle'}], 'stable');

tblPerceptual = tblPerceptual(:, keepPerceptual);
tblAdjusted = tblAdjusted(:, keepAdjusted);

if ~isempty(scoreVar)
    tblPerceptual = renamevars(tblPerceptual, ...
        {scoreVar, 'Reported_Visual_Angle'}, ...
        {'NormedStereoScore', 'Perceptual_Reported_Visual_Angle'});
else
    tblPerceptual = renamevars(tblPerceptual, 'Reported_Visual_Angle', 'Perceptual_Reported_Visual_Angle');
end
tblAdjusted = renamevars(tblAdjusted, ...
    'Reported_Visual_Angle', 'Adjusted_Reported_Visual_Angle');

pairedTbl = innerjoin(tblPerceptual, tblAdjusted, 'Keys', joinKeys);
end

function scoreVar = local_find_score_var(tbl)
candidates = {'NormedStereoScore','NormedScore','NormScore','StereoScore'};
for i = 1:numel(candidates)
    if ismember(candidates{i}, tbl.Properties.VariableNames)
        scoreVar = candidates{i};
        return;
    end
end
scoreVar = '';
end

function local_write_report(pairedTbl, lmeRI, lmeRS, cmpTbl, Basename, ResultsDir, formulaRI, formulaRS, hasStereo, colorBy)
reportFile = fullfile(ResultsDir, [Basename '_PerceptualVsAdjusted_ReportedVisualAngle.txt']);
fid = fopen(reportFile, 'w');
if fid == -1
    error('Could not open report file for writing: %s', reportFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Perceptual Vs Adjusted Reported Visual Angle\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));
fprintf(fid, 'Rows paired: %d\n', height(pairedTbl));
fprintf(fid, 'Unique participants: %d\n\n', numel(categories(removecats(pairedTbl.ID))));

fprintf(fid, 'Stereo predictor included: %s\n\n', string(hasStereo));
fprintf(fid, 'Participant color mode: %s\n\n', colorBy);
fprintf(fid, 'Model: %s\n', formulaRI);
fprintf(fid, '%s\n\n', evalc('disp(lmeRI)'));

fprintf(fid, 'Model: %s\n', formulaRS);
fprintf(fid, '%s\n\n', evalc('disp(lmeRS)'));

fprintf(fid, 'Model comparison\n');
fprintf(fid, '%s\n', evalc('disp(cmpTbl)'));
end

function local_plot_ri_figure(pairedTbl, lmeRI, Basename, ResultsDir, hasStereo, colorSpec)
[plotTbl, scoreVals] = local_sorted_plot_table(pairedTbl, hasStereo, colorSpec.Mode);

figH = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0.18 0.18 0.56 0.62], ...
    'Name', [Basename '_PerceptualVsAdjusted_RI'], 'Visible', 'off');
ax = axes(figH, 'Position', [0.13 0.14 0.68 0.72]);
hold(ax, 'on');


pAdj = local_get_coef_pvalue(lmeRI, 'Adjusted_Reported_Visual_Angle');
pStereo = local_get_coef_pvalue(lmeRI, 'NormedStereoScore');

if ~isnan(pAdj) && pAdj < 0.05
    xGrid = linspace(min(plotTbl.Adjusted_Reported_Visual_Angle), max(plotTbl.Adjusted_Reported_Visual_Angle), 200)';
    meanStereo = local_mean_stereo(plotTbl, hasStereo);
    [yFit, yLow, yHigh] = local_fixed_line_with_ci(lmeRI, xGrid, meanStereo, 'Adjusted_Reported_Visual_Angle');
    fill(ax, [xGrid; flipud(xGrid)], [yLow; flipud(yHigh)], [0.85 0.85 0.85], ...
        'EdgeColor', 'none', 'FaceAlpha', .3);
    plot(ax, xGrid, yFit, 'k-', 'LineWidth', 3);
end
if colorSpec.Mode == "clinicalnotes"
    pointColors = local_colors_for_ids(plotTbl.ID, colorSpec);
    scatter(ax, plotTbl.Adjusted_Reported_Visual_Angle, plotTbl.Perceptual_Reported_Visual_Angle, ...
        50, pointColors, 'filled', 'MarkerEdgeColor', 'none');
    local_add_clinical_legend(ax, colorSpec);
elseif colorSpec.Mode == "stereoscore" && hasStereo
    scatter(ax, plotTbl.Adjusted_Reported_Visual_Angle, plotTbl.Perceptual_Reported_Visual_Angle, ...
        50, scoreVals, 'filled', 'MarkerEdgeColor', 'none');
    apply_stereo_score_colormap(ax);
    cb = add_stereo_score_colorbar(ax, 'Normed stereo score');
    cb.FontName = 'Avenir';
    cb.FontSize = 9;
    cb.Label.FontName = 'Avenir';
    cb.Label.FontSize =9;
else
    scatter(ax, plotTbl.Adjusted_Reported_Visual_Angle, plotTbl.Perceptual_Reported_Visual_Angle, ...
        50, 'k', 'filled', 'MarkerEdgeColor', 'none');
end

nSubjects = numel(categories(removecats(plotTbl.ID)));
lims = local_finish_axes(ax, plotTbl);
plot(ax, lims, lims, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 2);
title(ax, local_ri_title(lmeRI, pAdj, pStereo, nSubjects), ...
    'FontSize', 12, 'FontWeight', 'normal');
exportgraphics(figH, fullfile(ResultsDir, [Basename '_PerceptualVsAdjusted_RI.png']), 'Resolution', 600);
close(figH);
end

function local_plot_rs_figure(pairedTbl, lmeRS, Basename, ResultsDir, hasStereo, colorSpec)
[plotTbl, scoreVals] = local_sorted_plot_table(pairedTbl, hasStereo, colorSpec.Mode);

figH = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0.18 0.18 0.56 0.62], ...
    'Name', [Basename '_PerceptualVsAdjusted_RS'], 'Visible', 'off');
ax = axes(figH, 'Position', [0.13 0.14 0.68 0.72]);
hold(ax, 'on');

local_plot_subject_lines(ax, plotTbl, lmeRS, hasStereo, colorSpec);

if colorSpec.Mode == "clinicalnotes"
    pointColors = local_colors_for_ids(plotTbl.ID, colorSpec);
    scatter(ax, plotTbl.Adjusted_Reported_Visual_Angle, plotTbl.Perceptual_Reported_Visual_Angle, ...
        50, pointColors, 'filled', 'MarkerEdgeColor', 'none');
    local_add_clinical_legend(ax, colorSpec);
elseif colorSpec.Mode == "stereoscore" && hasStereo
    scatter(ax, plotTbl.Adjusted_Reported_Visual_Angle, plotTbl.Perceptual_Reported_Visual_Angle, ...
        50, scoreVals, 'filled', 'MarkerEdgeColor', 'none');
    apply_stereo_score_colormap(ax);
    cb = add_stereo_score_colorbar(ax, 'Normed stereo score');
    cb.FontName = 'Avenir';
    cb.FontSize = 9;
    cb.Label.FontName = 'Avenir';
    cb.Label.FontSize = 9;
else
    scatter(ax, plotTbl.Adjusted_Reported_Visual_Angle, plotTbl.Perceptual_Reported_Visual_Angle, ...
        50, 'k', 'filled', 'MarkerEdgeColor', 'none');
end

pAdj = local_get_coef_pvalue(lmeRS, 'Adjusted_Reported_Visual_Angle');
pStereo = local_get_coef_pvalue(lmeRS, 'NormedStereoScore');
nSubjects = numel(categories(removecats(plotTbl.ID)));

lims = local_finish_axes(ax, plotTbl);
plot(ax, lims, lims, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 2);
title(ax, local_rs_title(lmeRS, pAdj, pStereo, nSubjects), ...
    'FontSize', 12, 'FontWeight', 'normal');

exportgraphics(figH, fullfile(ResultsDir, [Basename '_PerceptualVsAdjusted_RS.png']), 'Resolution', 600);
close(figH);
end

function [plotTbl, scoreVals] = local_sorted_plot_table(pairedTbl, hasStereo, colorMode)
if colorMode == "stereoscore" && hasStereo
    plotTbl = sortrows(pairedTbl, 'NormedStereoScore', 'descend');
    scoreVals = plotTbl.NormedStereoScore;
elseif colorMode == "clinicalnotes"
    plotTbl = sortrows(pairedTbl, 'ID');
    scoreVals = [];
else
    plotTbl = pairedTbl;
    scoreVals = [];
end
end

function local_plot_subject_lines(ax, pairedTbl, lmeRS, hasStereo, colorSpec)
[reEfx, reNames] = randomEffects(lmeRS);
levels = string(reNames.Level);
names = string(reNames.Name);

coefTbl = lmeRS.Coefficients;
coefNames = string(coefTbl.Name);
idxAdjustedFixed = find(coefNames == "Adjusted_Reported_Visual_Angle", 1, 'first');

fixedAdjusted = coefTbl.Estimate(idxAdjustedFixed);
idxStereoFixed = find(coefNames == "NormedStereoScore", 1, 'first');
if ~isempty(idxStereoFixed)
    fixedStereo = coefTbl.Estimate(idxStereoFixed);
else
    fixedStereo = 0;
end

uniqueID = categories(removecats(pairedTbl.ID));
subjectScores = nan(numel(uniqueID), 1);
for i = 1:numel(uniqueID)
    rowMask = pairedTbl.ID == categorical(uniqueID(i));
    if hasStereo
        subjectScores(i) = mean(pairedTbl.NormedStereoScore(rowMask), 'omitnan');
    else
        subjectScores(i) = NaN;
    end
end

if hasStereo
    [~, order] = sort(subjectScores, 'descend', 'MissingPlacement', 'last');
    baseCmap = StereoScores(256);
else
    order = 1:numel(uniqueID);
end

for k = 1:numel(order)
    i = order(k);
    subj = string(uniqueID{i});
    rowMask = pairedTbl.ID == categorical(uniqueID(i));
    if ~any(rowMask)
        continue;
    end

    subjScore = 0;
    if hasStereo
        subjScore = subjectScores(i);
    end
    if colorSpec.Mode == "clinicalnotes"
        thisColor = local_colors_for_ids(pairedTbl.ID(find(rowMask, 1, 'first')), colorSpec);
    elseif colorSpec.Mode == "stereoscore" && hasStereo
        colorRow = local_score_to_color_row(subjScore, size(baseCmap, 1));
        thisColor = baseCmap(colorRow, :);
    else
        thisColor = [0 0 0];
    end

    idxSlope = find(levels == subj & names == "Adjusted_Reported_Visual_Angle", 1, 'first');
    reSlope = 0;
    if ~isempty(idxSlope)
        reSlope = reEfx(idxSlope);
    end

    xSub = pairedTbl.Adjusted_Reported_Visual_Angle(rowMask);
    xGrid = linspace(min(xSub), max(xSub), 50);
    ySub = (fixedAdjusted + reSlope) .* xGrid + ...
        fixedStereo .* subjScore;
    plot(ax, xGrid, ySub, '-', 'Color', thisColor, 'LineWidth', 1);
end
end

function colorBy = local_normalize_color_mode(colorBy)
colorBy = lower(strtrim(string(colorBy)));
switch colorBy
    case {"stereoscore", "stereo", "normed", "normedstereoscore"}
        colorBy = "stereoscore";
    case {"clinicalnotes", "clinical"}
        colorBy = "clinicalnotes";
    case {"none", "black"}
        colorBy = "none";
    otherwise
        error('PerceptualVsAdjusted:InvalidColorMode', ...
            'Unsupported colorBy value "%s". Use "stereoscore", "clinicalnotes", or "none".', colorBy);
end
end

function colorSpec = local_build_color_spec(tbl, Basename, ResultsDir, colorBy)
colorSpec = struct('Mode', colorBy, 'ID', strings(0, 1), ...
    'Category', strings(0, 1), 'Cmap', zeros(0, 3));

if colorBy ~= "clinicalnotes"
    return;
end

[~, categoryByID, uniqueID, cmap] = ...
    Quad_compute_clinical_notes_color_idx(tbl, ResultsDir, Basename, true);
colorSpec.ID = string(uniqueID);
colorSpec.Category = categoryByID;
colorSpec.Cmap = cmap;
end

function colors = local_colors_for_ids(ids, colorSpec)
idStrings = string(ids);
[isKnown, colorRows] = ismember(idStrings, colorSpec.ID);
colors = repmat([0.5, 0.5, 0.5], numel(idStrings), 1);
colors(isKnown, :) = colorSpec.Cmap(colorRows(isKnown), :);
end

function local_add_clinical_legend(ax, colorSpec)
lgd = Quad_add_clinical_notes_legend(ax, colorSpec);
lgd.FontSize = 9;
end

function [yFit, yLow, yHigh] = local_fixed_line_with_ci(lme, xGrid, stereoVal, adjustedVarName)
coefTbl = lme.Coefficients;
coefNames = string(coefTbl.Name);

idxAdjusted = find(coefNames == adjustedVarName, 1, 'first');
idxStereo = find(coefNames == "NormedStereoScore", 1, 'first');

b1 = coefTbl.Estimate(idxAdjusted);
l1 = coefTbl.Lower(idxAdjusted);
u1 = coefTbl.Upper(idxAdjusted);
if ~isempty(idxStereo)
    b2 = coefTbl.Estimate(idxStereo);
    l2 = coefTbl.Lower(idxStereo);
    u2 = coefTbl.Upper(idxStereo);
else
    b2 = 0;
    l2 = 0;
    u2 = 0;
end

yFit = (b2 * stereoVal) + b1 * xGrid;
yLow = (l2 * stereoVal) + l1 * xGrid;
yHigh = (u2 * stereoVal) + u1 * xGrid;
end

function pval = local_get_coef_pvalue(lme, coefName)
coefTbl = lme.Coefficients;
coefNames = string(coefTbl.Name);
idx = find(coefNames == string(coefName), 1, 'first');
if isempty(idx)
    pval = NaN;
else
    pval = coefTbl.pValue(idx);
end
end

function txt = local_ri_title(lme, pAdj, pStereo, nRows)
coefTbl = lme.Coefficients;
coefNames = string(coefTbl.Name);
bAdj = coefTbl.Estimate(find(coefNames == "Adjusted_Reported_Visual_Angle", 1, 'first'));
idxStereo = find(coefNames == "NormedStereoScore", 1, 'first');
if isempty(idxStereo)
    txt = sprintf('Perceptual=%sAdjusted\\newlinep_{Adjusted}=%s\\newlinen=%d', ...
        local_format_number(bAdj), local_format_pvalue(pAdj), nRows);
else
    bStereo = coefTbl.Estimate(idxStereo);
    txt = sprintf('Perceptual=%sAdjusted+%sStereo\\newlinep_{Adjusted}=%s, p_{Stereo}=%s\\newlinen=%d', ...
        local_format_number(bAdj), local_format_number(bStereo), ...
        local_format_pvalue(pAdj), local_format_pvalue(pStereo), nRows);
end
end

function txt = local_rs_title(lme, pAdj, pStereo, nRows)
coefTbl = lme.Coefficients;
coefNames = string(coefTbl.Name);
bAdj = coefTbl.Estimate(find(coefNames == "Adjusted_Reported_Visual_Angle", 1, 'first'));
idxStereo = find(coefNames == "NormedStereoScore", 1, 'first');
if isempty(idxStereo)
    txt = sprintf('Perceptual=%sAdjusted\\newlineRS model: p_{Adjusted}=%s\\newlinen=%d', ...
        local_format_number(bAdj), local_format_pvalue(pAdj), nRows);
else
    bStereo = coefTbl.Estimate(idxStereo);
    txt = sprintf('Perceptual=%sAdjusted+%sStereo\\newlineRS model: p_{Adjusted}=%s, p_{Stereo}=%s\\newlinen=%d', ...
        local_format_number(bAdj), local_format_number(bStereo), ...
        local_format_pvalue(pAdj), local_format_pvalue(pStereo), nRows);
end
end

function lims = local_finish_axes(ax, plotTbl)
allVals = [plotTbl.Adjusted_Reported_Visual_Angle; plotTbl.Perceptual_Reported_Visual_Angle];
allVals = allVals(~isnan(allVals));

if isempty(allVals)
    lims = [0 5];
    tickVals = 0:5:5;
else
    minAxis = min(allVals);
    maxAxis = max(allVals);
    minAxis = min(0, minAxis);
    maxAxis = max(0, maxAxis);

    tickStep = 5;
    lims = [tickStep * floor(minAxis / tickStep), tickStep * ceil(maxAxis / tickStep)];
    if lims(1) == lims(2)
        lims(2) = lims(1) + tickStep;
    end
    tickVals = lims(1):tickStep:lims(2);
end

set(ax, 'FontName', 'Avenir', 'FontSize', 18, ...
    'XTick', tickVals, 'YTick', tickVals);
xlim(ax, lims);
ylim(ax, lims);
xlabel(ax, 'Perceived VA Adjusted, Monocular (degrees)', 'FontSize', 14);
ylabel(ax, 'Perceived VA Binocular (degrees)', 'FontSize', 14);
box(ax, 'off');
grid(ax, 'off');
axis(ax, 'square');
end

function colorRow = local_score_to_color_row(scoreVal, nColors)
if isnan(scoreVal)
    colorRow = 1;
    return;
end
scoreScaled = (min(max(scoreVal, 0), 100)) / 100;
colorRow = 1 + round(scoreScaled * (nColors - 1));
colorRow = max(1, min(nColors, colorRow));
end

function meanStereo = local_mean_stereo(plotTbl, hasStereo)
if hasStereo
    meanStereo = mean(plotTbl.NormedStereoScore, 'omitnan');
else
    meanStereo = 0;
end
end

function pStr = local_format_pvalue(pval)
if isnan(pval)
    pStr = 'NaN';
elseif pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end

function numStr = local_format_number(val)
if val ~= 0 && abs(val) < 0.01
    numStr = sprintf('%.2e', val);
else
    numStr = sprintf('%.2f', val);
end
end
