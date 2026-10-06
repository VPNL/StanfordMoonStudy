function [lmePvG_RI, lmePvG_RS] = Quad_Parallax_by_Geometry( ...
    tbl, tblName, ResultsDir, saveLME, cmap, sortedIdx, fullUniqueID, ...
    colorbarLabel, colorConfig)
% QUAD_PARALLAX_BY_GEOMETRY Validate perceived against geometric parallax.
%
% Fits exactly two maximum-likelihood models:
%   MeanParallax ~ GeometricParallax + (1|ID)
%   MeanParallax ~ GeometricParallax + (GeometricParallax|ID)
% and compares the nested RI and RS models with a likelihood-ratio test.

% Geometric parallax is calculated in degrees using:
%   (360/pi)*atan(tan(pi*VA/360) + b/2*(1/z - 1/D)) - VA
% where b=6.5 cm, z is mean caliper distance, and D is observer distance.

% The function does not fit elevation or StereoGroup models. Stereo-score
% information, when supplied through colorConfig, is used only for color.

% Outputs
%   lmePvG_RI  random-intercept model
%   lmePvG_RS  random-intercept/random-slope model


if nargin < 5 || isempty(cmap), cmap = parula(64); end
if nargin < 6, sortedIdx = []; end
if nargin < 7, fullUniqueID = []; end
if nargin < 8 || isempty(colorbarLabel)
    colorbarLabel = 'Participant color order';
end
if nargin < 9, colorConfig = []; end
if ~exist(ResultsDir, 'dir'), mkdir(ResultsDir); end

modelTbl = local_prepare_table(tbl);
riFormula = 'MeanParallax ~ 1 + GeometricParallax + (1|ID)';
rsFormula = ['MeanParallax ~ 1 + GeometricParallax + ' ...
    '(GeometricParallax|ID)'];

lmePvG_RI = fitlme(modelTbl, riFormula, 'FitMethod', 'ML');
lmePvG_RS = fitlme(modelTbl, rsFormula, 'FitMethod', 'ML');
riVsRs = compare(lmePvG_RI, lmePvG_RS);

colors = local_subject_colors(modelTbl, cmap, sortedIdx, ...
    fullUniqueID, colorConfig);
local_plot_models(modelTbl, lmePvG_RI, lmePvG_RS, riVsRs, colors, ...
    ResultsDir, tblName, colorbarLabel, colorConfig);

if saveLME
    formulas = {riFormula, rsFormula};
    models = {lmePvG_RI, lmePvG_RS};
    reportFile = fullfile(ResultsDir, ...
        [tblName '_parallax_by_geometry_RI_RS_models.txt']);
    opts = struct();
    opts.ReportTitle = 'Quad Perceived Parallax by Geometric Parallax';
    opts.GeneratedBy = 'Quad_Parallax_by_Geometry';
    opts.SourceFile = tblName;
    opts.SummaryLines = {
        sprintf('Rows: %d', height(modelTbl))
        sprintf('Participants: %d', numel(categories(modelTbl.ID)))
        ['GeometricParallax = (360/pi)*atan(tan(pi*VA/360) + ' ...
         '6.5/2*(1/z - 1/D)) - VA']
        ['b=6.5 cm; z=mean caliper distance; D=observer distance. ' ...
         'No elevation or StereoGroup model is fitted.']
        };
    opts.Models = models;
    opts.ModelLabels = formulas;
    opts.Comparisons = {riVsRs};
    opts.ComparisonLabels = {'Geometric-parallax RI versus RS'};
    opts.RemoveGroupError = false;
    write_lme_stats_report(lmePvG_RI, reportFile, opts);
    write_lme_fixed_effects_summary_csv(tblName, formulas, models, ...
        fullfile(ResultsDir, ...
        [tblName '_parallax_by_geometry_model_coefficients.csv']));
end
end

function tbl = local_prepare_table(tbl)
required = {'ID', 'Distance', 'Real_Visual_Angle', ...
    'Caliper1_Distance', 'Caliper2_Distance'};
missing = required(~ismember(required, tbl.Properties.VariableNames));
if ~isempty(missing)
    error('Quad_Parallax_by_Geometry:MissingVariables', ...
        'Missing required variable(s): %s.', strjoin(missing, ', '));
end

if all(ismember({'Disparity1', 'Disparity2'}, tbl.Properties.VariableNames))
    perceivedParallax = mean( ...
        [double(tbl.Disparity1), double(tbl.Disparity2)], 2, 'omitnan');
elseif ismember('Disparity', tbl.Properties.VariableNames)
    perceivedParallax = double(tbl.Disparity);
elseif ismember('MeanDisparity', tbl.Properties.VariableNames)
    perceivedParallax = double(tbl.MeanDisparity);
else
    error('Quad_Parallax_by_Geometry:MissingParallax', ...
        'Need Disparity1/Disparity2, Disparity, or MeanDisparity.');
end

distance = double(tbl.Distance);
visualAngle = double(tbl.Real_Visual_Angle);
caliperDistance = mean([double(tbl.Caliper1_Distance), ...
    double(tbl.Caliper2_Distance)], 2, 'omitnan');
geometricParallax = (360 / pi) .* atan( ...
    tan(pi .* visualAngle ./ 360) + 6.5 ./ 2 .* ...
    (1 ./ caliperDistance - 1 ./ distance)) - visualAngle;

keep = isfinite(perceivedParallax) & isfinite(geometricParallax) & ...
    isfinite(distance) & distance > 0 & isfinite(caliperDistance) & ...
    caliperDistance > 0 & ~ismissing(string(tbl.ID));
tbl = tbl(keep, :);
tbl.ID = categorical(tbl.ID);
tbl.MeanParallax = perceivedParallax(keep);
tbl.GeometricParallax = geometricParallax(keep);
end

function local_plot_models(tbl, riModel, rsModel, comparison, colors, ...
    ResultsDir, tblName, colorbarLabel, colorConfig)
fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'normalized', ...
    'Position', [0.08 0.14 0.82 0.60]);
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', ...
    'TileSpacing', 'compact');
if local_uses_stereo_colors(colorConfig)
    t.OuterPosition = [0 0 0.87 1];
end

models = {riModel, rsModel};
panelNames = {'Random-intercept model', 'Random-slope model'};
for iPanel = 1:2
    ax = nexttile(t); hold(ax, 'on');
    scatter(ax, tbl.GeometricParallax, tbl.MeanParallax, 28, colors, ...
        'filled', 'MarkerFaceAlpha', 0.78);
    xGrid = linspace(min(tbl.GeometricParallax), ...
        max(tbl.GeometricParallax), 160)';
    predictionTbl = tbl(ones(numel(xGrid), 1), :);
    predictionTbl.GeometricParallax = xGrid;
    [yHat, yCI] = predict(models{iPanel}, predictionTbl, ...
        'Conditional', false);
    fill(ax, [xGrid; flipud(xGrid)], ...
        [yCI(:, 1); flipud(yCI(:, 2))], [0.72 0.72 0.72], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.35);
    plot(ax, xGrid, yHat, 'k-', 'LineWidth', 2.6);
    if iPanel == 2
        local_plot_subject_lines(ax, tbl, rsModel, colors);
    end
    xlabel(ax, 'Geometric Parallax [deg]');
    if iPanel == 1
        ylabel(ax, 'Perceived Parallax [deg]');
    else
        ax.YColor = 'w';
    end
    title(ax, local_model_title(models{iPanel}, panelNames{iPanel}), ...
        'Interpreter', 'none');
    set(ax, 'FontName', 'Avenir', 'FontSize', 15);
    box(ax, 'off');
end

pComparison = comparison.pValue(end);
title(t, sprintf(['Perceived Parallax by Geometric Parallax\n' ...
    'RI versus RS likelihood-ratio test: p=%s'], ...
    local_p_text(pComparison)), 'FontWeight', 'bold');
if local_uses_stereo_colors(colorConfig)
    add_stereo_score_colorbar(fig, colorbarLabel, ...
        [0.91 0.20 0.014 0.60]);
else
    cb = colorbar(nexttile(t, 2));
    cb.Label.String = colorbarLabel;
end
exportgraphics(fig, fullfile(ResultsDir, ...
    [tblName '_parallax_by_geometry_RI_RS.png']), 'Resolution', 600);
close(fig);
end

function local_plot_subject_lines(ax, tbl, lme, colors)
[randomValues, randomNames] = randomEffects(lme);
if istable(randomValues), randomValues = randomValues.Estimate; end
fixedValues = fixedEffects(lme);
ids = categories(tbl.ID);
effectNames = string(randomNames.Name);
effectLevels = string(randomNames.Level);
for iID = 1:numel(ids)
    idRows = effectLevels == string(ids{iID});
    interceptRow = find(idRows & effectNames == "(Intercept)", 1);
    slopeRow = find(idRows & effectNames == "GeometricParallax", 1);
    participantRows = tbl.ID == ids{iID};
    participantX = tbl.GeometricParallax(participantRows);
    if isempty(interceptRow) || isempty(slopeRow) || ...
            numel(unique(participantX)) < 2
        continue;
    end
    xGrid = linspace(min(participantX), max(participantX), 50)';
    y = fixedValues(1) + randomValues(interceptRow) + ...
        (fixedValues(2) + randomValues(slopeRow)) .* xGrid;
    colorRow = find(participantRows, 1, 'first');
    plot(ax, xGrid, y, '-', 'Color', colors(colorRow, :), ...
        'LineWidth', 1.1);
end
end

function titleText = local_model_title(lme, heading)
coef = lme.Coefficients;
slopeRow = strcmp(string(coef.Name), 'GeometricParallax');
titleText = sprintf('%s\nslope=%.3g, p=%s, n=%d', heading, ...
    coef.Estimate(slopeRow), local_p_text(coef.pValue(slopeRow)), ...
    numel(categories(lme.Variables.ID)));
end

function colors = local_subject_colors(tbl, cmap, sortedIdx, ...
    fullUniqueID, colorConfig)
ids = categories(tbl.ID);
colors = zeros(height(tbl), 3);
if isstruct(colorConfig) && isfield(colorConfig, 'ID') && ...
        isfield(colorConfig, 'Color')
    [found, configRows] = ismember(string(ids), string(colorConfig.ID));
    for iID = 1:numel(ids)
        rows = tbl.ID == ids{iID};
        if found(iID)
            rgb = colorConfig.Color(configRows(iID), :);
        else
            rgb = [0.72 0.72 0.72];
        end
        colors(rows, :) = repmat(rgb, nnz(rows), 1);
    end
    return;
end

if size(cmap, 1) < numel(ids)
    cmap = interp1(linspace(0, 1, size(cmap, 1)), cmap, ...
        linspace(0, 1, numel(ids)));
end
order = (1:numel(ids))';
if ~isempty(fullUniqueID)
    orderedIDs = string(fullUniqueID(:));
    if ~isempty(sortedIdx) && numel(sortedIdx) == numel(orderedIDs)
        orderedIDs = orderedIDs(sortedIdx);
    end
    [found, location] = ismember(string(ids), orderedIDs);
    order(found) = location(found);
elseif ~isempty(sortedIdx) && numel(sortedIdx) == numel(ids)
    order(sortedIdx) = 1:numel(ids);
end
for iID = 1:numel(ids)
    rows = tbl.ID == ids{iID};
    rgb = cmap(mod(order(iID) - 1, size(cmap, 1)) + 1, :);
    colors(rows, :) = repmat(rgb, nnz(rows), 1);
end
end

function tf = local_uses_stereo_colors(colorConfig)
tf = isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
    strcmpi(string(colorConfig.Mode), "stereoscore");
end

function value = local_p_text(p)
if p < 0.001
    value = sprintf('%.2e', p);
else
    value = sprintf('%.3f', p);
end
end
