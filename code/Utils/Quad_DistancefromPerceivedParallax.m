function [lmeRI, lmeRS, lmeElevationRI, lmeElevationRS] = ...
    Quad_DistancefromPerceivedParallax( ...
    tbl, tblName, ResultsDir, saveLME, cmap, sortedIdx, fullUniqueID, ...
    colorbarLabel, colorConfig, aggregationMode)
% QUAD_DISTANCEFROMPERCEIVEDPARALLAX Estimate fixation distance from parallax.
%
% The row-wise fixation distance is calculated in cm as
%
%   FD = b*z / (b - 2*z*(tan(pi*(alpha+VA)/360) ...
%                        - tan(pi*VA/360)))
%
% where b=6.5 cm, z is the caliper distance in cm, VA is real visual angle
% in degrees, and alpha is its paired perceived-parallax measurement. Each
% source row contributes up to two observations: (Disparity1,
% Caliper1_Distance) and (Disparity2, Caliper2_Distance).
% Estimates are retained only when the formula denominator is positive and
% its relative cancellation ratio is at least 1e-3:
%
%   abs(denominator)/(abs(b) + abs(2*z*deltaTangent)) >= 1e-3.
%
% The models use the source centimeter units. Values are converted to
% meters only for plotting.
%
% Fits exactly two maximum-likelihood models:
%   FixationDistance ~ Distance + (1|ID)
%   FixationDistance ~ Distance + (Distance|ID)
% and compares the nested RI and RS models with a likelihood-ratio test.

if nargin < 5 || isempty(cmap), cmap = parula(64); end
if nargin < 6, sortedIdx = []; end
if nargin < 7, fullUniqueID = []; end
if nargin < 8 || isempty(colorbarLabel)
    colorbarLabel = 'Participant color order';
end
if nargin < 9, colorConfig = []; end
if nargin < 10 || isempty(aggregationMode)
    aggregationMode = "paired";
else
    aggregationMode = lower(string(aggregationMode));
end
if ~ismember(aggregationMode, ["paired", "mean"])
    error('Quad_DistancefromPerceivedParallax:InvalidAggregationMode', ...
        'aggregationMode must be "paired" or "mean".');
end
if ~exist(ResultsDir, 'dir'), mkdir(ResultsDir); end

[modelTbl, preparation] = local_prepare_table(tbl, aggregationMode);
riFormula = 'FixationDistance ~ 1 + Distance + (1|ID)';
rsFormula = 'FixationDistance ~ 1 + Distance + (Distance|ID)';
elevationRIFormula = 'FixationDistance ~ 1 + Elevation + (1|ID)';
elevationRSFormula = ...
    'FixationDistance ~ 1 + Elevation + (Elevation|ID)';
distanceElevationFormula = ...
    'FixationDistance ~ 1 + Distance*Elevation + (1|ID)';

lmeRI = fitlme(modelTbl, riFormula, 'FitMethod', 'ML');
lmeRS = fitlme(modelTbl, rsFormula, 'FitMethod', 'ML');
riVsRs = compare(lmeRI, lmeRS);
lmeElevationRI = fitlme(modelTbl, elevationRIFormula, 'FitMethod', 'ML');
lmeElevationRS = fitlme(modelTbl, elevationRSFormula, 'FitMethod', 'ML');
elevationRIvsRS = compare(lmeElevationRI, lmeElevationRS);
lmeDistanceByElevation = fitlme(modelTbl, distanceElevationFormula, ...
    'FitMethod', 'ML');

colors = local_subject_colors(modelTbl, cmap, sortedIdx, ...
    fullUniqueID, colorConfig);
if aggregationMode == "mean"
    outputStem = [tblName '_distance_from_mean_perceived_parallax'];
    figureTitle = ...
        'Fixation Distance from Mean Perceived Parallax and Mean Caliper Distance';
    reportTitle = ...
        'Quad Fixation Distance from Mean Perceived Parallax and Mean Caliper Distance';
    generatedBy = 'Quad_DistancefromMeanPerceivedParallax';
else
    outputStem = [tblName '_distance_from_perceived_parallax'];
    figureTitle = 'Fixation Distance Estimated from Perceived Parallax';
    reportTitle = 'Quad Fixation Distance Estimated from Perceived Parallax';
    generatedBy = 'Quad_DistancefromPerceivedParallax';
end
local_plot_models(modelTbl, lmeRI, lmeRS, riVsRs, colors, ...
    ResultsDir, outputStem, figureTitle, colorbarLabel, colorConfig, ...
    'Distance', 100, 'Observer Distance [m]', 'D', '');
local_plot_models(modelTbl, lmeElevationRI, lmeElevationRS, ...
    elevationRIvsRS, colors, ResultsDir, outputStem, ...
    [figureTitle ' by Elevation'], colorbarLabel, colorConfig, ...
    'Elevation', 1, 'Elevation [deg]', 'E', '_by_elevation');

if saveLME
    formulas = {riFormula, rsFormula, elevationRIFormula, ...
        elevationRSFormula, distanceElevationFormula};
    models = {lmeRI, lmeRS, lmeElevationRI, lmeElevationRS, ...
        lmeDistanceByElevation};
    reportFile = fullfile(ResultsDir, ...
        [outputStem '_RI_RS_models.txt']);
    opts = struct();
    opts.ReportTitle = reportTitle;
    opts.GeneratedBy = generatedBy;
    opts.SourceFile = tblName;
    opts.SummaryLines = {
        sprintf('Input table rows: %d', preparation.InputRows)
        sprintf('Potential analysis observations: %d', preparation.PotentialObservations)
        sprintf('Analysed observations: %d', height(modelTbl))
        sprintf('Excluded analysis observations: %d', preparation.ExcludedObservations)
        sprintf('Excluded for a nonpositive FD denominator: %d', ...
            preparation.NonpositiveDenominatorObservations)
        sprintf(['Excluded for unstable relative cancellation: %d ' ...
            '(threshold = %.1e)'], ...
            preparation.UnstableCancellationObservations, ...
            preparation.CancellationThreshold)
        sprintf('Participants: %d', numel(categories(modelTbl.ID)))
        sprintf('Measurement aggregation: %s', preparation.AggregationDescription)
        ['FD = b*z/(b - 2*z*(tan(pi*(alpha+VA)/360) - ' ...
         'tan(pi*VA/360)))']
        preparation.MeasurementDetail
        ['FD and observer Distance were fitted in cm and converted to ' ...
         'meters only for plotting. FD estimates require a positive ' ...
         'denominator and the stated relative cancellation threshold.']
        };
    opts.Models = models;
    opts.ModelLabels = formulas;
    opts.Comparisons = {riVsRs, elevationRIvsRS};
    opts.ComparisonLabels = { ...
        'Fixation-distance by Distance: RI versus RS', ...
        'Fixation-distance by Elevation: RI versus RS'};
    opts.RemoveGroupError = false;
    write_lme_stats_report(lmeRI, reportFile, opts);
    write_lme_fixed_effects_summary_csv(tblName, formulas, models, ...
        fullfile(ResultsDir, ...
        [outputStem '_coefficients.csv']));
end
end

function [tbl, preparation] = local_prepare_table(tbl, aggregationMode)
required = {'ID', 'Distance', 'Elevation', 'Real_Visual_Angle', 'Disparity1', ...
    'Disparity2', 'Caliper1_Distance', 'Caliper2_Distance'};
missing = required(~ismember(required, tbl.Properties.VariableNames));
if ~isempty(missing)
    error('Quad_DistancefromPerceivedParallax:MissingVariables', ...
        'Missing required variable(s): %s.', strjoin(missing, ', '));
end

b = 6.5; % cm
cancellationThreshold = 1e-3;
inputRows = height(tbl);
retainedInputRows = height(tbl);
if aggregationMode == "mean"
    longTbl = tbl;
    longTbl.ParallaxMeasurement = zeros(retainedInputRows, 1);
    perceivedParallax = mean( ...
        [double(tbl.Disparity1), double(tbl.Disparity2)], 2, 'omitnan');
    caliperDistanceCm = mean( ...
        [double(tbl.Caliper1_Distance), ...
         double(tbl.Caliper2_Distance)], 2, 'omitnan');
    potentialObservations = retainedInputRows;
    aggregationDescription = ...
        'row mean of Disparity1/Disparity2 paired with row mean of Caliper1/Caliper2';
    measurementDetail = ['b=6.5 cm; alpha=mean(Disparity1, Disparity2); ' ...
        'z=mean(Caliper1_Distance, Caliper2_Distance).'];
else
    longTbl = [tbl; tbl];
    longTbl.ParallaxMeasurement = [ones(retainedInputRows, 1); ...
        2 .* ones(retainedInputRows, 1)];
    perceivedParallax = [double(tbl.Disparity1); double(tbl.Disparity2)];
    caliperDistanceCm = [double(tbl.Caliper1_Distance); ...
        double(tbl.Caliper2_Distance)];
    potentialObservations = 2 * retainedInputRows;
    aggregationDescription = ...
        'paired Disparity1/Caliper1 and Disparity2/Caliper2 observations';
    measurementDetail = ['b=6.5 cm. Disparity1 is paired with ' ...
        'Caliper1_Distance and Disparity2 is paired with ' ...
        'Caliper2_Distance; no averaging is used.'];
end
observerDistanceCm = double(longTbl.Distance);
elevationDeg = double(longTbl.Elevation);
visualAngle = double(longTbl.Real_Visual_Angle);
angleSum = perceivedParallax + visualAngle;
tangentDifference = tan(pi .* angleSum ./ 360) - ...
    tan(pi .* visualAngle ./ 360);
geometricTerm = 2 .* caliperDistanceCm .* tangentDifference;
denominator = b - geometricTerm;
fixationDistanceCm = b .* caliperDistanceCm ./ denominator;

principalRange = angleSum > -180 & angleSum < 180;
validInputs = isfinite(perceivedParallax) & isfinite(visualAngle) & ...
    isfinite(caliperDistanceCm) & caliperDistanceCm > 0 & ...
    isfinite(observerDistanceCm) & observerDistanceCm > 0 & ...
    isfinite(elevationDeg) & ...
    principalRange & ...
    ~ismissing(string(longTbl.ID));
positiveDenominator = isfinite(denominator) & denominator > 0;
cancellationRatio = abs(denominator) ./ ...
    (abs(b) + abs(geometricTerm));
stableCancellation = isfinite(cancellationRatio) & ...
    cancellationRatio >= cancellationThreshold;
keep = validInputs & positiveDenominator & stableCancellation & ...
    isfinite(fixationDistanceCm);

preparation.InputRows = inputRows;
preparation.PotentialObservations = potentialObservations;
preparation.ExcludedObservations = nnz(~keep);
preparation.NonpositiveDenominatorObservations = ...
    nnz(validInputs & ~positiveDenominator);
preparation.UnstableCancellationObservations = ...
    nnz(validInputs & positiveDenominator & ~stableCancellation);
preparation.CancellationThreshold = cancellationThreshold;
preparation.AggregationDescription = aggregationDescription;
preparation.MeasurementDetail = measurementDetail;
tbl = longTbl(keep, :);
tbl.ID = removecats(categorical(tbl.ID));
tbl.PerceivedParallax = perceivedParallax(keep);
tbl.CaliperDistance = caliperDistanceCm(keep);
tbl.FixationDistance = fixationDistanceCm(keep);
tbl.FDDenominator = denominator(keep);
tbl.FDCancellationRatio = cancellationRatio(keep);
tbl.Distance = observerDistanceCm(keep);
tbl.Elevation = elevationDeg(keep);
end

function local_plot_models(tbl, riModel, rsModel, comparison, colors, ...
    ResultsDir, outputStem, figureTitle, colorbarLabel, colorConfig, ...
    predictorName, xScale, xLabel, predictorSymbol, fileSuffix)
fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'normalized', ...
    'Position', [0.08 0.14 0.82 0.60]);
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', ...
    'TileSpacing', 'compact');
if local_uses_stereo_colors(colorConfig)
    t.OuterPosition = [0 0 0.87 1];
end

models = {riModel, rsModel};
panelNames = {'Random-intercept model', 'Random-slope model'};
predictor = tbl.(predictorName);
for iPanel = 1:2
    ax = nexttile(t); hold(ax, 'on');
    scatter(ax, predictor ./ xScale, tbl.FixationDistance ./ 100, ...
        28, colors, ...
        'filled', 'MarkerFaceAlpha', 0.78);

    xGrid = linspace(min(predictor), max(predictor), 160)';
    predictionTbl = tbl(ones(numel(xGrid), 1), :);
    predictionTbl.(predictorName) = xGrid;
    [yHat, yCI] = predict(models{iPanel}, predictionTbl, ...
        'Conditional', false);

    if iPanel == 1
        fill(ax, [xGrid; flipud(xGrid)] ./ 100, ...
            [yCI(:, 1); flipud(yCI(:, 2))] ./ 100, ...
            [0.72 0.72 0.72], ...
            'EdgeColor', 'none', 'FaceAlpha', 0.35);
    else
        local_plot_subject_lines(ax, tbl, rsModel, colors, ...
            predictorName, xScale);
    end
    plot(ax, xGrid ./ xScale, yHat ./ 100, 'k-', 'LineWidth', 2.8);

    xlabel(ax, xLabel);
    if iPanel == 1
        ylabel(ax, 'Fixation Distance Estimated from Parallax [m]');
    else
        ax.YColor = 'w';
    end
    title(ax, local_model_title(models{iPanel}, panelNames{iPanel}, ...
        predictorName, predictorSymbol), ...
        'Interpreter', 'none');
    set(ax, 'FontName', 'Avenir', 'FontSize', 15);
    box(ax, 'off');
end

pComparison = comparison.pValue(end);
title(t, sprintf([figureTitle '\n' ...
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
    [outputStem fileSuffix '_RI_RS.png']), ...
    'Resolution', 600);
close(fig);
end

function local_plot_subject_lines(ax, tbl, lme, colors, ...
    predictorName, xScale)
[randomValues, randomNames] = randomEffects(lme);
if istable(randomValues), randomValues = randomValues.Estimate; end
fixedValues = fixedEffects(lme);
ids = categories(tbl.ID);
effectNames = string(randomNames.Name);
effectLevels = string(randomNames.Level);
for iID = 1:numel(ids)
    idRows = effectLevels == string(ids{iID});
    interceptRow = find(idRows & effectNames == "(Intercept)", 1);
    slopeRow = find(idRows & effectNames == predictorName, 1);
    participantRows = tbl.ID == ids{iID};
    participantX = tbl.(predictorName)(participantRows);
    if isempty(interceptRow) || isempty(slopeRow) || ...
            numel(unique(participantX)) < 2
        continue;
    end
    xGrid = linspace(min(participantX), max(participantX), 50)';
    y = fixedValues(1) + randomValues(interceptRow) + ...
        (fixedValues(2) + randomValues(slopeRow)) .* xGrid;
    colorRow = find(participantRows, 1, 'first');
    plot(ax, xGrid ./ xScale, y ./ 100, '-', ...
        'Color', colors(colorRow, :), ...
        'LineWidth', 1.1);
end
end

function titleText = local_model_title(lme, heading, ...
    predictorName, predictorSymbol)
coef = lme.Coefficients;
slopeRow = strcmp(string(coef.Name), predictorName);
if predictorName == "Distance"
    slopeForTitle = coef.Estimate(slopeRow);
else
    slopeForTitle = coef.Estimate(slopeRow) ./ 100;
end
titleText = sprintf('%s\nFD=%.3g %+.3g%s, p=%s, n=%d', heading, ...
    coef.Estimate(1) ./ 100, slopeForTitle, predictorSymbol, ...
    local_p_text(coef.pValue(slopeRow)), ...
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
if p == 0
    value = '<1e-300';
elseif p < 0.001
    value = sprintf('%.2e', p);
else
    value = sprintf('%.3f', p);
end
end
