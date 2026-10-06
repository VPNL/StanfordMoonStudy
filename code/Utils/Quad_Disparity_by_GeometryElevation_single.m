function [lmeParallaxByGeometry, lmeParallaxByElevation, ...
    lmeParallaxByGeometryRS, lmeParallaxByElevationRS, ...
    lmeParallaxByGeometryElevation, ...
    lmeParallaxByGeometryElevationRS, ...
    lmeAdjustedParallaxByElevation, ...
    lmeAdjustedParallaxByElevationRS, ...
    lmeCaliperDistanceByElevation, lmeCaliperDistanceByDistance, ...
    lmeInfinityAdjustedParallaxByElevation, ...
    lmeInfinityAdjustedParallaxByElevationRS, ...
    lmeCaliperDistanceByElevationDistance, ...
    lmeCaliperDistanceByElevationDistanceRS] = ...
    Quad_Disparity_by_GeometryElevation_single(tbl, tblName, ResultsDir, ...
    saveLME, mycolormap, sortedIdx, fullUniqueID, colorbarLabel, ...
    plotFixedEffectsRS, plotRI, colorConfig)
% QUAD_DISPARITY_BY_GEOMETRYELEVATION_SINGLE
% Fit raw-scale perceived-parallax models by geometric parallax and elevation.
%
% GeometricParallax is calculated in degrees using Eq. 8:
%   phi = (360/pi) * atan(tan(pi*VA/360) + b/2*(1/z - 1/D)) - VA
% where b = 6.5 cm, z is the mean of the two caliper distances (cm), D is
% the raw distance (cm), and VA is the raw real visual angle (degrees).
% No distance or elevation transform is applied in this function.

if nargin < 7 || isempty(fullUniqueID); fullUniqueID = []; end
if nargin < 8 || isempty(colorbarLabel); colorbarLabel = 'Participant color order'; end
if nargin < 9 || isempty(plotFixedEffectsRS); plotFixedEffectsRS = false; end
if nargin < 10 || isempty(plotRI); plotRI = false; end
if nargin < 11; colorConfig = []; end
if ~exist(ResultsDir, 'dir'); mkdir(ResultsDir); end

tbl = local_prepare_table(tbl);
formulas = { ...
    'MeanParallax ~ 1 + GeometricParallax + (1|ID)', ...
    'MeanParallax ~ 1 + Elevation + (1|ID)', ...
    'MeanParallax ~ 1 + GeometricParallax + (GeometricParallax|ID)', ...
    'MeanParallax ~ 1 + Elevation + (Elevation|ID)', ...
    'MeanParallax ~ 1 + GeometricParallax + Elevation + (1|ID)', ...
    'MeanParallax ~ 1 + GeometricParallax + Elevation + (Elevation|ID)', ...
    'AdjustedParallax ~ 1 + Elevation + (1|ID)', ...
    'AdjustedParallax ~ 1 + Elevation + (Elevation|ID)', ...
    'CaliperDistance ~ 1 + Elevation + (1|ID)', ...
    'CaliperDistance ~ 1 + Distance + (1|ID)', ...
    'InfinityAdjustedParallax ~ 1 + Elevation + (1|ID)', ...
    'InfinityAdjustedParallax ~ 1 + Elevation + (Elevation|ID)', ...
    'CaliperDistance ~ 1 + Elevation + Distance + (1|ID)', ...
    ['CaliperDistance ~ 1 + Elevation + Distance + ' ...
     '(Elevation + Distance|ID)']};

lmeParallaxByGeometry = local_try_fitlme(tbl, formulas{1});
lmeParallaxByElevation = local_try_fitlme(tbl, formulas{2});
lmeParallaxByGeometryRS = local_try_fitlme(tbl, formulas{3});
lmeParallaxByElevationRS = local_try_fitlme(tbl, formulas{4});
lmeParallaxByGeometryElevation = local_try_fitlme(tbl, formulas{5});
lmeParallaxByGeometryElevationRS = local_try_fitlme(tbl, formulas{6});
lmeAdjustedParallaxByElevation = local_try_fitlme(tbl, formulas{7});
lmeAdjustedParallaxByElevationRS = local_try_fitlme(tbl, formulas{8});
lmeCaliperDistanceByElevation = local_try_fitlme(tbl, formulas{9});
lmeCaliperDistanceByDistance = local_try_fitlme(tbl, formulas{10});
lmeInfinityAdjustedParallaxByElevation = local_try_fitlme(tbl, formulas{11});
lmeInfinityAdjustedParallaxByElevationRS = local_try_fitlme(tbl, formulas{12});
lmeCaliperDistanceByElevationDistance = local_try_fitlme(tbl, formulas{13});
lmeCaliperDistanceByElevationDistanceRS = local_try_fitlme(tbl, formulas{14});

models = {lmeParallaxByGeometry, lmeParallaxByElevation, ...
    lmeParallaxByGeometryRS, lmeParallaxByElevationRS, ...
    lmeParallaxByGeometryElevation, lmeParallaxByGeometryElevationRS, ...
    lmeAdjustedParallaxByElevation, lmeAdjustedParallaxByElevationRS, ...
    lmeCaliperDistanceByElevation, lmeCaliperDistanceByDistance, ...
    lmeInfinityAdjustedParallaxByElevation, ...
    lmeInfinityAdjustedParallaxByElevationRS, ...
    lmeCaliperDistanceByElevationDistance, ...
    lmeCaliperDistanceByElevationDistanceRS};
if saveLME
    local_write_report(fullfile(ResultsDir, [tblName '_geometry_elevation_single_RI_RS.txt']), ...
        tbl, models, formulas);
    write_lme_fixed_effects_summary_csv(tblName, formulas, models, ...
        fullfile(ResultsDir, [tblName '_geometry_elevation_model_coefficients.csv']));
end

colors = local_subject_colors(tbl, mycolormap, sortedIdx, fullUniqueID, colorConfig);
local_plot_models(tbl, models(3:4), colors, ResultsDir, tblName, ...
    colorbarLabel, plotFixedEffectsRS, false, colorConfig);
if plotRI
    local_plot_models(tbl, models(1:2), colors, ResultsDir, tblName, ...
        colorbarLabel, true, true, colorConfig);
end
local_plot_additive_model(tbl, lmeParallaxByGeometryElevation, colors, ...
    ResultsDir, tblName, colorbarLabel, true, colorConfig);
local_plot_additive_model(tbl, lmeParallaxByGeometryElevationRS, colors, ...
    ResultsDir, tblName, colorbarLabel, false, colorConfig);
local_plot_elevation_ri_rs(tbl, lmeAdjustedParallaxByElevation, ...
    lmeAdjustedParallaxByElevationRS, colors, ResultsDir, tblName, ...
    colorbarLabel, colorConfig, 'AdjustedParallax', ...
    {'Adjusted Parallax [deg]', 'Perceived - Geometric'}, ...
    'Adjusted Parallax = Perceived Parallax - Geometric Parallax', ...
    'adjusted_parallax_by_elevation_RI_RS');
local_plot_caliper_sanity(tbl, lmeCaliperDistanceByElevation, ...
    lmeCaliperDistanceByDistance, colors, ResultsDir, tblName, ...
    colorbarLabel, colorConfig);
local_plot_joint_caliper_models(tbl, ...
    lmeCaliperDistanceByElevationDistance, ...
    lmeCaliperDistanceByElevationDistanceRS, colors, ResultsDir, ...
    tblName, colorbarLabel, colorConfig);
local_plot_elevation_ri_rs(tbl, lmeInfinityAdjustedParallaxByElevation, ...
    lmeInfinityAdjustedParallaxByElevationRS, colors, ResultsDir, tblName, ...
    colorbarLabel, colorConfig, 'InfinityAdjustedParallax', ...
    {'Infinity-adjusted Parallax [deg]', 'Perceived - participant P_{infinity}'}, ...
    ['Infinity-adjusted Parallax using each participant''s ' ...
    'mean caliper distance'], ...
    'infinity_adjusted_parallax_by_elevation_RI_RS');
end

function tbl = local_prepare_table(tbl)
required = {'ID', 'Distance', 'Elevation', 'Real_Visual_Angle', ...
    'Caliper1_Distance', 'Caliper2_Distance'};
missing = required(~ismember(required, tbl.Properties.VariableNames));
if ~isempty(missing)
    error('Quad_Disparity_by_GeometryElevation_single:MissingVariables', ...
        'Missing required raw variable(s): %s.', strjoin(missing, ', '));
end
if all(ismember({'Disparity1','Disparity2'}, tbl.Properties.VariableNames))
    disparity = mean([double(tbl.Disparity1), double(tbl.Disparity2)], 2, 'omitnan');
elseif ismember('Disparity', tbl.Properties.VariableNames)
    disparity = double(tbl.Disparity);
elseif ismember('MeanDisparity', tbl.Properties.VariableNames)
    disparity = double(tbl.MeanDisparity);
else
    error('Quad_Disparity_by_GeometryElevation_single:MissingDisparity', ...
        'Need Disparity1/Disparity2, Disparity, or MeanDisparity.');
end

distance = double(tbl.Distance);
caliper1 = double(tbl.Caliper1_Distance);
caliper2 = double(tbl.Caliper2_Distance);
visualAngle = double(tbl.Real_Visual_Angle);
elevation = double(tbl.Elevation);
caliperDistance = mean([caliper1 caliper2], 2, 'omitnan');
% All distances are intentionally left in their source units (cm).
geometricParallax = (360 / pi) .* atan( ...
    tan(pi .* visualAngle ./ 360) + 6.5 ./ 2 .* ...
    (1 ./ caliperDistance - 1 ./ distance)) - visualAngle;

valid = isfinite(disparity) & isfinite(geometricParallax) & ...
    isfinite(elevation) & distance > 0 & caliperDistance > 0 & ...
    ~ismissing(string(tbl.ID));
tbl = tbl(valid, :);
tbl.ID = categorical(tbl.ID);
tbl.MeanParallax = disparity(valid);
tbl.GeometricParallax = geometricParallax(valid);
tbl.AdjustedParallax = tbl.MeanParallax - tbl.GeometricParallax;
tbl.CaliperDistance = caliperDistance(valid);
tbl.Elevation = elevation(valid); % Preserve raw signed elevation.
tbl.Distance = distance(valid);

% Participant-specific geometric baseline for VA=0 and D approaching
% infinity. Distances and the 6.5-cm interocular baseline share cm units.
tbl.ParticipantMeanCaliperDistance = nan(height(tbl), 1);
tbl.InfinityParallax = nan(height(tbl), 1);
ids = categories(tbl.ID);
for iID = 1:numel(ids)
    rows = tbl.ID == ids{iID};
    meanCaliperDistance = mean(tbl.CaliperDistance(rows), 'omitnan');
    infinityParallax = (360 / pi) * atan(6.5 / (2 * meanCaliperDistance));
    tbl.ParticipantMeanCaliperDistance(rows) = meanCaliperDistance;
    tbl.InfinityParallax(rows) = infinityParallax;
end
tbl.InfinityAdjustedParallax = tbl.MeanParallax - tbl.InfinityParallax;
end

function lme = local_try_fitlme(tbl, formula)
try
    lme = fitlme(tbl, formula, 'FitMethod', 'ML');
catch ME
    warning('Quad_Disparity_by_GeometryElevation_single:FitFailed', ...
        'Could not fit %s: %s', formula, ME.message);
    lme = [];
end
end

function local_write_report(reportFile, tbl, models, formulas)
fid = fopen(reportFile, 'w');
if fid < 0; error('Could not write %s.', reportFile); end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'Quad raw geometric-parallax/elevation LME report\n');
fprintf(fid, 'Rows: %d\nParticipants: %d\n\n', height(tbl), numel(categories(tbl.ID)));
fprintf(fid, 'GeometricParallax = (360/pi)*atan(tan(pi*VA/360) + 6.5/2*(1/z - 1/D)) - VA\n');
fprintf(fid, 'b = 6.5 cm; z = mean(Caliper1_Distance, Caliper2_Distance); D = raw Distance.\n');
fprintf(fid, ['InfinityParallax_ID = (360/pi)*atan(6.5/' ...
    '(2*meanCaliperDistance_ID)) for VA=0 and D approaching infinity.\n']);
fprintf(fid, ['InfinityAdjustedParallax = MeanParallax - ' ...
    'InfinityParallax_ID.\n']);
fprintf(fid, 'No distance or elevation transform was applied.\n\n');
for i = 1:numel(models)
    fprintf(fid, 'Model: %s\n', formulas{i});
    if isempty(models{i})
        fprintf(fid, 'Fit failed. See MATLAB warning.\n\n');
    else
        fprintf(fid, '%s\n\n', evalc('disp(models{i})'));
    end
end
if ~isempty(models{1}) && ~isempty(models{3})
    fprintf(fid, 'RI versus RS geometric-parallax comparison\n%s\n', evalc('disp(compare(models{1}, models{3}))'));
end
if ~isempty(models{2}) && ~isempty(models{4})
    fprintf(fid, 'RI versus RS elevation comparison\n%s\n', evalc('disp(compare(models{2}, models{4}))'));
end
if ~isempty(models{1}) && ~isempty(models{5})
    fprintf(fid, ['Geometry-only RI versus geometry-plus-elevation RI comparison\n' ...
        '%s\n'], evalc('disp(compare(models{1}, models{5}))'));
end
if ~isempty(models{5}) && ~isempty(models{6})
    fprintf(fid, ['Geometry-plus-elevation RI versus elevation-RS comparison\n' ...
        '%s\n'], evalc('disp(compare(models{5}, models{6}))'));
end
if ~isempty(models{7}) && ~isempty(models{8})
    fprintf(fid, ['Adjusted-parallax elevation RI versus RS comparison\n' ...
        '%s\n'], evalc('disp(compare(models{7}, models{8}))'));
end
if ~isempty(models{11}) && ~isempty(models{12})
    fprintf(fid, ['Infinity-adjusted parallax elevation RI versus RS comparison\n' ...
        '%s\n'], evalc('disp(compare(models{11}, models{12}))'));
end
if ~isempty(models{13}) && ~isempty(models{14})
    fprintf(fid, ['Joint caliper-distance RI versus RS comparison\n' ...
        '%s\n'], evalc('disp(compare(models{13}, models{14}))'));
end
end

function local_plot_elevation_ri_rs(tbl, riModel, rsModel, colors, ...
    ResultsDir, tblName, colorbarLabel, colorConfig, responseName, ...
    yLabelText, figureTitle, outputSuffix)
if isempty(riModel) || isempty(rsModel), return; end
fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'normalized', ...
    'Position', [0.1 0.15 0.78 0.58]);
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    t.OuterPosition = [0 0 0.87 1];
end
models = {riModel, rsModel};
panelNames = {'RI model', 'Elevation RS model'};
x = tbl.Elevation;
xGrid = linspace(min(x), max(x), 150)';
for iPanel = 1:2
    ax = nexttile(t); hold(ax, 'on');
    scatter(ax, x, tbl.(responseName), 26, colors, 'filled', ...
        'MarkerFaceAlpha', 0.8);
    predTbl = tbl(ones(numel(xGrid), 1), :);
    predTbl.Elevation = xGrid;
    [yHat, yCI] = predict(models{iPanel}, predTbl, 'Conditional', false);
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
        [0.65 0.65 0.65], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(ax, xGrid, yHat, 'k-', 'LineWidth', 2.2);
    if iPanel == 2
        local_plot_subject_lines(ax, tbl, models{iPanel}, 'Elevation', colors);
    end
    yline(ax, 0, ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
    xlabel(ax, 'Elevation [deg]');
    if iPanel == 1
        ylabel(ax, yLabelText);
    end
    title(ax, sprintf('%s\n%s', panelNames{iPanel}, ...
        local_model_title(models{iPanel}, 'Elevation')), ...
        'Interpreter', 'none', 'FontSize', 10);
    if strcmp(responseName, 'InfinityAdjustedParallax')
        local_set_ylim_ignoring_single_extreme(ax, tbl.(responseName));
    end
    set(ax, 'FontName', 'Avenir', 'FontSize', 10, 'Box', 'off');
end
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    add_stereo_score_colorbar(fig, colorbarLabel, [0.91 0.20 0.014 0.60]);
else
    cb = colorbar(nexttile(t, 2));
    cb.Label.String = colorbarLabel;
end
title(t, figureTitle, 'FontWeight', 'bold', 'Interpreter', 'none');
exportgraphics(fig, fullfile(ResultsDir, ...
    [tblName '_' outputSuffix '.png']), ...
    'Resolution', 600);
close(fig);
end

function local_set_ylim_ignoring_single_extreme(ax, y)
% Keep every observation in the model and plot, but prevent one extreme
% point from determining the visible range.
y = y(isfinite(y));
if numel(y) < 4, return; end
center = median(y);
robustScale = 1.4826 * median(abs(y - center));
if robustScale <= 0, return; end
[largestDeviation, extremeIndex] = max(abs(y - center));
if largestDeviation <= 6 * robustScale, return; end
yForLimits = y;
yForLimits(extremeIndex) = [];
yMin = min(yForLimits);
yMax = max(yForLimits);
padding = 0.06 * max(yMax - yMin, eps);
ylim(ax, [yMin - padding, yMax + padding]);
end

function local_plot_caliper_sanity(tbl, elevationModel, distanceModel, ...
    colors, ResultsDir, tblName, colorbarLabel, colorConfig)
if isempty(elevationModel) || isempty(distanceModel), return; end
fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'normalized', ...
    'Position', [0.1 0.15 0.78 0.58]);
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    t.OuterPosition = [0 0 0.87 1];
end
models = {elevationModel, distanceModel};
predictors = {'Elevation', 'Distance'};
xLabels = {'Elevation [deg]', 'Observer Distance [cm]'};
for iPanel = 1:2
    ax = nexttile(t); hold(ax, 'on');
    predictor = predictors{iPanel};
    x = tbl.(predictor);
    scatter(ax, x, tbl.CaliperDistance, 26, colors, 'filled', ...
        'MarkerFaceAlpha', 0.8);
    xGrid = linspace(min(x), max(x), 150)';
    predTbl = tbl(ones(numel(xGrid), 1), :);
    predTbl.(predictor) = xGrid;
    [yHat, yCI] = predict(models{iPanel}, predTbl, 'Conditional', false);
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
        [0.65 0.65 0.65], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(ax, xGrid, yHat, 'k-', 'LineWidth', 2.2);
    xlabel(ax, xLabels{iPanel});
    if iPanel == 1, ylabel(ax, 'Caliper Distance [cm]'); end
    title(ax, local_model_title(models{iPanel}, predictor), ...
        'Interpreter', 'none', 'FontSize', 10);
    set(ax, 'FontName', 'Avenir', 'FontSize', 10, 'Box', 'off');
end
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    add_stereo_score_colorbar(fig, colorbarLabel, [0.91 0.20 0.014 0.60]);
else
    cb = colorbar(nexttile(t, 2));
    cb.Label.String = colorbarLabel;
end
title(t, 'Caliper-distance sanity checks', 'FontWeight', 'bold');
exportgraphics(fig, fullfile(ResultsDir, ...
    [tblName '_caliper_distance_by_elevation_and_distance.png']), ...
    'Resolution', 600);
close(fig);
end

function local_plot_joint_caliper_models(tbl, riModel, rsModel, colors, ...
    ResultsDir, tblName, colorbarLabel, colorConfig)
if isempty(riModel) || isempty(rsModel), return; end
fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'normalized', ...
    'Position', [0.06 0.08 0.84 0.78]);
t = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    t.OuterPosition = [0 0 0.80 1];
end
models = {riModel, riModel; rsModel, rsModel};
predictors = {'Elevation', 'Distance'};
xLabels = {'Elevation [deg]', 'Observer Distance [cm]'};
rowLabels = {'Joint RI', 'Joint RS'};
for iRow = 1:2
    for iColumn = 1:2
        ax = nexttile(t); hold(ax, 'on');
        predictor = predictors{iColumn};
        otherPredictor = predictors{3 - iColumn};
        x = tbl.(predictor);
        scatter(ax, x, tbl.CaliperDistance, 24, colors, 'filled', ...
            'MarkerFaceAlpha', 0.75);
        xGrid = linspace(min(x), max(x), 150)';
        predTbl = tbl(ones(numel(xGrid), 1), :);
        predTbl.(predictor) = xGrid;
        heldValue = mean(tbl.(otherPredictor), 'omitnan');
        predTbl.(otherPredictor) = repmat(heldValue, numel(xGrid), 1);
        [yHat, yCI] = predict(models{iRow, iColumn}, predTbl, ...
            'Conditional', false);
        fill(ax, [xGrid; flipud(xGrid)], ...
            [yCI(:,1); flipud(yCI(:,2))], [0.65 0.65 0.65], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.3);
        plot(ax, xGrid, yHat, 'k-', 'LineWidth', 2.2);
        if iRow == 2
            local_plot_joint_caliper_subject_lines(ax, tbl, rsModel, ...
                predictor, otherPredictor, colors);
        end
        xlabel(ax, xLabels{iColumn});
        if iColumn == 1, ylabel(ax, 'Caliper Distance [cm]'); end
        title(ax, sprintf('%s: %s', rowLabels{iRow}, ...
            local_model_title(models{iRow, iColumn}, predictor)), ...
            'Interpreter', 'none', 'FontSize', 10);
        set(ax, 'FontName', 'Avenir', 'FontSize', 10, 'Box', 'off');
    end
end
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    add_stereo_score_colorbar(fig, colorbarLabel, [0.92 0.20 0.014 0.60]);
else
    cb = colorbar(nexttile(t, 4));
    cb.Label.String = colorbarLabel;
end
title(t, ['Joint caliper-distance models' newline ...
    'Adjusted predictions hold the other predictor at its mean'], ...
    'FontWeight', 'bold');
exportgraphics(fig, fullfile(ResultsDir, ...
    [tblName '_caliper_distance_joint_elevation_distance_RI_RS.png']), ...
    'Resolution', 600);
close(fig);
end

function local_plot_joint_caliper_subject_lines(ax, tbl, lme, predictor, ...
    otherPredictor, colors)
[re, names] = randomEffects(lme);
if istable(re), re = re.Estimate; end
fe = fixedEffects(lme);
coefNames = string(lme.CoefficientNames(:));
i0 = find(coefNames == "(Intercept)", 1);
iPredictor = find(coefNames == string(predictor), 1);
iOther = find(coefNames == string(otherPredictor), 1);
effectNames = string(names.Name);
effectLevels = string(names.Level);
ids = categories(tbl.ID);
for i = 1:numel(ids)
    participantRows = tbl.ID == ids{i};
    participantX = tbl.(predictor)(participantRows);
    if numel(unique(participantX)) < 2, continue; end
    interceptRow = find(effectLevels == string(ids{i}) & ...
        effectNames == "(Intercept)", 1);
    slopeRow = find(effectLevels == string(ids{i}) & ...
        effectNames == string(predictor), 1);
    otherSlopeRow = find(effectLevels == string(ids{i}) & ...
        effectNames == string(otherPredictor), 1);
    if isempty(interceptRow) || isempty(slopeRow) || isempty(otherSlopeRow)
        continue;
    end
    xGrid = linspace(min(participantX), max(participantX), 50)';
    heldValue = mean(tbl.(otherPredictor)(participantRows), 'omitnan');
    intercept = fe(i0) + re(interceptRow);
    slope = fe(iPredictor) + re(slopeRow);
    heldSlope = fe(iOther) + re(otherSlopeRow);
    y = intercept + slope .* xGrid + heldSlope .* heldValue;
    row = find(participantRows, 1, 'first');
    plot(ax, xGrid, y, '-', 'Color', colors(row,:), 'LineWidth', 1.0);
end
end

function local_plot_additive_model(tbl, lme, colors, ResultsDir, tblName, ...
    colorbarLabel, isRI, colorConfig)
if isempty(lme), return; end
suffix = 'RS'; if isRI, suffix = 'RI'; end
fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'normalized', ...
    'Position', [0.1 0.15 0.78 0.58]);
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    t.OuterPosition = [0 0 0.87 1];
end
predictors = {'GeometricParallax', 'Elevation'};
labels = {'Geometric Parallax [deg]', 'Elevation [deg]'};
for iPredictor = 1:2
    ax = nexttile(t); hold(ax, 'on');
    predictor = predictors{iPredictor};
    otherPredictor = predictors{3 - iPredictor};
    x = tbl.(predictor);
    scatter(ax, x, tbl.MeanParallax, 26, colors, 'filled', ...
        'MarkerFaceAlpha', 0.8);
    xGrid = linspace(min(x), max(x), 150)';
    predTbl = tbl(ones(numel(xGrid), 1), :);
    predTbl.(predictor) = xGrid;
    heldValue = mean(tbl.(otherPredictor), 'omitnan');
    predTbl.(otherPredictor) = repmat(heldValue, numel(xGrid), 1);
    [yHat, yCI] = predict(lme, predTbl, 'Conditional', false);
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
        [0.65 0.65 0.65], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(ax, xGrid, yHat, 'k-', 'LineWidth', 2.2);
    if ~isRI
        local_plot_additive_subject_lines(ax, tbl, lme, predictor, colors);
    end
    xlabel(ax, labels{iPredictor});
    if iPredictor == 1
        ylabel(ax, 'Perceived Parallax [deg]');
    end
    title(ax, local_model_title(lme, predictor), ...
        'Interpreter', 'none', 'FontSize', 10);
    set(ax, 'FontName', 'Avenir', 'FontSize', 10, 'Box', 'off');
end
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    add_stereo_score_colorbar(fig, colorbarLabel, [0.91 0.20 0.014 0.60]);
else
    cb = colorbar(nexttile(t, 2));
    cb.Label.String = colorbarLabel;
end
title(t, sprintf(['Additive geometry + elevation %s model\n' ...
    'Adjusted predictions hold the other predictor at its mean'], suffix), ...
    'FontWeight', 'bold');
exportgraphics(fig, fullfile(ResultsDir, ...
    [tblName '_geometry_plus_elevation_' suffix '.png']), 'Resolution', 600);
close(fig);
end

function local_plot_additive_subject_lines(ax, tbl, lme, predictor, colors)
[re, names] = randomEffects(lme);
if istable(re), re = re.Estimate; end
fe = fixedEffects(lme);
coefNames = string(lme.CoefficientNames(:));
i0 = find(coefNames == "(Intercept)", 1);
iGeometry = find(coefNames == "GeometricParallax", 1);
iElevation = find(coefNames == "Elevation", 1);
effectNames = string(names.Name);
effectLevels = string(names.Level);
ids = categories(tbl.ID);
for i = 1:numel(ids)
    participantRows = tbl.ID == ids{i};
    participantX = tbl.(predictor)(participantRows);
    if numel(unique(participantX)) < 2, continue; end
    interceptRow = find(effectLevels == string(ids{i}) & ...
        effectNames == "(Intercept)", 1);
    slopeRow = find(effectLevels == string(ids{i}) & ...
        effectNames == "Elevation", 1);
    if isempty(interceptRow) || isempty(slopeRow), continue; end
    xGrid = linspace(min(participantX), max(participantX), 50)';
    meanGeometry = mean(tbl.GeometricParallax(participantRows), 'omitnan');
    meanElevation = mean(tbl.Elevation(participantRows), 'omitnan');
    intercept = fe(i0) + re(interceptRow);
    elevationSlope = fe(iElevation) + re(slopeRow);
    if strcmp(predictor, 'GeometricParallax')
        y = intercept + fe(iGeometry) .* xGrid + ...
            elevationSlope .* meanElevation;
    else
        y = intercept + fe(iGeometry) .* meanGeometry + ...
            elevationSlope .* xGrid;
    end
    row = find(participantRows, 1, 'first');
    plot(ax, xGrid, y, '-', 'Color', colors(row, :), 'LineWidth', 1.1);
end
end

function local_plot_models(tbl, models, colors, ResultsDir, tblName, colorbarLabel, plotFixed, isRI, colorConfig)
suffix = 'RS'; if isRI; suffix = 'RI'; end
fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'normalized', ...
    'Position', [0.1 0.15 0.78 0.58]);
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    t.OuterPosition = [0 0 0.87 1];
end
predictors = {'GeometricParallax', 'Elevation'};
labels = {'Geometric Parallax [deg]', 'Elevation [deg]'};
for i = 1:2
    ax = nexttile(t); hold(ax, 'on');
    x = tbl.(predictors{i});
    scatter(ax, x, tbl.MeanParallax, 26, colors, 'filled', 'MarkerFaceAlpha', 0.8);
    if ~isempty(models{i})
        xGrid = linspace(min(x), max(x), 150)';
        predTbl = tbl(ones(numel(xGrid), 1), :);
        predTbl.(predictors{i}) = xGrid;
        [yHat, yCI] = predict(models{i}, predTbl, 'Conditional', false);
        fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
            [0.65 0.65 0.65], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
        plot(ax, xGrid, yHat, 'k-', 'LineWidth', 2.2);
        if ~isRI
            local_plot_subject_lines(ax, tbl, models{i}, predictors{i}, colors);
        end
        if plotFixed
            title(ax, local_model_title(models{i}, predictors{i}), 'Interpreter', 'none', 'FontSize', 10);
        end
    end
    xlabel(ax, labels{i});
    if i == 1; ylabel(ax, 'Perceived Parallax [deg]'); end
    set(ax, 'FontName', 'Avenir', 'FontSize', 10); box(ax, 'off');
end
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        strcmpi(string(colorConfig.Mode), "stereoscore")
    add_stereo_score_colorbar(fig, colorbarLabel, [0.91 0.20 0.014 0.60]);
else
    cb = colorbar(nexttile(t, 2));
    cb.Label.String = colorbarLabel;
end
title(t, sprintf('Raw-scale %s models', suffix), 'FontWeight', 'bold');
exportgraphics(fig, fullfile(ResultsDir, [tblName '_geometry_elevation_' suffix '.png']), 'Resolution', 600);
close(fig);
end

function local_plot_subject_lines(ax, tbl, lme, predictor, colors)
[re, names] = randomEffects(lme);
if istable(re)
    re = re.Estimate;
end
fe = fixedEffects(lme);
ids = categories(tbl.ID);
effectNames = string(names.Name);
effectLevels = string(names.Level);
for i = 1:numel(ids)
    idRows = effectLevels == string(ids{i});
    interceptRow = find(idRows & effectNames == "(Intercept)", 1);
    slopeRow = find(idRows & effectNames == string(predictor), 1);
    if isempty(interceptRow) || isempty(slopeRow)
        continue;
    end
    participantRows = tbl.ID == ids{i};
    participantX = tbl.(predictor)(participantRows);
    if numel(unique(participantX)) < 2
        continue;
    end
    participantGrid = linspace(min(participantX), max(participantX), 50)';
    y = (fe(1) + re(interceptRow)) + ...
        (fe(2) + re(slopeRow)) .* participantGrid;
    row = find(participantRows, 1, 'first');
    plot(ax, participantGrid, y, '-', 'Color', colors(row,:), 'LineWidth', 1.1);
end
end

function titleText = local_model_title(lme, predictor)
coef = lme.Coefficients;
row = strcmp(string(coef.Name), predictor);
if any(row)
    titleText = sprintf('slope = %.3g, p = %.3g', coef.Estimate(row), coef.pValue(row));
else
    titleText = '';
end
end

function colors = local_subject_colors(tbl, cmap, sortedIdx, fullUniqueID, colorConfig)
ids = categories(tbl.ID);
n = numel(ids);
if isstruct(colorConfig) && isfield(colorConfig, 'ID') && ...
        isfield(colorConfig, 'Color')
    colors = zeros(height(tbl), 3);
    [found, configRows] = ismember(string(ids), string(colorConfig.ID));
    for i = 1:n
        rows = tbl.ID == ids{i};
        if found(i)
            rgb = colorConfig.Color(configRows(i), :);
        else
            rgb = [0.82 0.82 0.82];
        end
        colors(rows, :) = repmat(rgb, nnz(rows), 1);
    end
    return;
end
if isempty(cmap); cmap = parula(max(n, 2)); end
if size(cmap, 1) < n; cmap = interp1(linspace(0,1,size(cmap,1)), cmap, linspace(0,1,n)); end
order = (1:n)';
if ~isempty(fullUniqueID)
    orderedIDs = string(fullUniqueID(:));
    if ~isempty(sortedIdx) && numel(sortedIdx) == numel(orderedIDs)
        orderedIDs = orderedIDs(sortedIdx);
    end
    [found, location] = ismember(string(ids), orderedIDs);
    order(found) = location(found);
elseif ~isempty(sortedIdx) && numel(sortedIdx) == n
    order(sortedIdx) = 1:n;
end
colors = zeros(height(tbl), 3);
for i = 1:n
    rows = tbl.ID == ids{i};
    rgb = cmap(mod(order(i)-1, size(cmap,1))+1, :);
    colors(rows, :) = repmat(rgb, nnz(rows), 1);
end
end
