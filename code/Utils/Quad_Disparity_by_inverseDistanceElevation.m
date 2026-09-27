function [lme_Parallax_by_InverseDistance, lme_Parallax_by_Elevation, ...
    lme_Parallax_by_InverseDistanceNElevation, ...
    lme_Parallax_by_InverseDistancePlusElevation] = ...
    Quad_Disparity_by_inverseDistanceElevation(tbl, tblName, ResultsDir, ...
    saveLME, mycolormap, sorted_idx, modelTransform, degreeFlag, ...
    fullUniqueID, secondYAxisColor, colorConfig)

% QUAD_DISPARITY_BY_INVERSEDISTANCEELEVATION
% Fit linear perceived-parallax inverse-distance/elevation RI models.

if nargin < 8 || isempty(degreeFlag)
    degreeFlag = 1; %#ok<NASGU>
end
if nargin < 7 || isempty(modelTransform)
    modelTransform = 2;
end
if nargin < 9 || isempty(fullUniqueID)
    fullUniqueID = [];
end

if nargin < 10 || isempty(secondYAxisColor)
    secondYAxisColor = 'w';
end
if nargin < 11
    colorConfig = [];
end

if ~ismember('Distance', tbl.Properties.VariableNames)
    error('Quad_Disparity_by_inverseDistanceElevation:MissingDistance', ...
        'Input table must contain a Distance column.');
end
sourceCsv = local_source_file_label(tbl, tblName);
rawElevation = local_recover_raw_elevation(tbl, modelTransform);
tbl.RawLinearElevation = rawElevation;
tbl = Quad_prepare_perceived_disparity_table(tbl, modelTransform);
% Quad_prepare_perceived_disparity_table standardizes Distance to meters.
% Compute inverse distance afterward so its units are m^{-1}.
tbl.inverseDistance = 1 ./ tbl.Distance;
tbl.log2inverseDistance = log2(tbl.inverseDistance);
tbl.Elevation = tbl.RawLinearElevation;
tbl.MeanParallax = tbl.MeanDisparity;
linearElevationSource = 'raw signed Elevation';

% Linear random-intercept models.  The interaction model includes both
% main effects, so it is nested with each corresponding single-factor model.
inverseDistanceFormula = 'MeanParallax ~ inverseDistance + (1|ID)';
elevationFormula = 'MeanParallax ~ Elevation + (1|ID)';
linearDistancePlusElevationFormula = ...
    'MeanParallax ~ inverseDistance + Elevation + (1|ID)';
linearDistanceElevationFormula = 'MeanParallax ~ inverseDistance * Elevation + (1|ID)';

lme_Parallax_by_InverseDistance = local_try_fitlme(tbl, inverseDistanceFormula);
lme_Parallax_by_Elevation = local_try_fitlme(tbl, elevationFormula);
lme_Parallax_by_InverseDistanceNElevation = local_try_fitlme(tbl, linearDistanceElevationFormula);
lme_Parallax_by_InverseDistancePlusElevation = ...
    local_try_fitlme(tbl, linearDistancePlusElevationFormula);

if saveLME
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    savelmefile = fullfile(ResultsDir, ...
        [tblName '_inverseDistance_elevation_RI_models.txt']);
    local_write_model_report(savelmefile, tbl, tblName, sourceCsv, ...
        modelTransform, linearElevationSource, ...
        {...
        lme_Parallax_by_InverseDistance,...
        lme_Parallax_by_Elevation,...
        lme_Parallax_by_InverseDistanceNElevation, ...
        lme_Parallax_by_InverseDistancePlusElevation}, ...
        {inverseDistanceFormula, elevationFormula, ...
        linearDistanceElevationFormula, ...
        linearDistancePlusElevationFormula});
end

subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID);
minParallax = max(0.01, min(tbl.MeanParallax));
maxParallax = max(tbl.MeanParallax);
nIDs = numel(categories(removecats(tbl.ID)));

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end


%% plot linear single factor models
figFull = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .92 .80], ...
    'Name', [tblName '_inverseDistance_E_RI'], ...
    'Visible', 'off');
tFull = tiledlayout(1,2,'Padding','compact','TileSpacing','loose');
tFull.Position = [0.09 0.18 0.70 0.68];
titleHandle = title(tFull, 'Linear single-factor RI models');
titleHandle.FontName = 'Avenir';
titleHandle.FontSize = 11;
titleHandle.FontWeight = 'bold';
titleHandle.Interpreter = 'tex';
axFullD = nexttile;
local_plot_linear_model_panel(axFullD, tbl, subjectcolor, ...
    lme_Parallax_by_InverseDistance, 'D', minParallax, maxParallax, ...
    modelTransform, true);
axFullE = nexttile;
local_plot_linear_model_panel(axFullE, tbl, subjectcolor, ...
    lme_Parallax_by_Elevation, 'E', minParallax, maxParallax, ...
    modelTransform, false, 'w');
local_add_subject_colorbar(figFull, mycolormap, nIDs, ...
    local_colorbar_label(colorConfig), colorConfig, axFullE);
exportgraphics(figFull, fullfile(ResultsDir, ...
    [tblName '_inverseDistance_E_RI.png']), ...
    'Resolution', 600);


local_plot_linear_interaction_surfaces( ...
    lme_Parallax_by_InverseDistanceNElevation, tbl, tblName, ...
    ResultsDir, nIDs, 'Elevation');

end

function local_plot_linear_interaction_surfaces(lme, tbl, tblName, ...
    ResultsDir, nIDs, elevationVariable)
if isempty(lme)
    fprintf('Skipping linear interaction surfaces: model is unavailable.\n');
    return;
end

distanceValues = linspace(10, 100, 100);
elevationValues = linspace(min(tbl.Elevation), max(tbl.Elevation), 100);
[distanceGrid, elevationGrid] = meshgrid(distanceValues, elevationValues);
nGrid = numel(distanceGrid);

predictionTbl = tbl(ones(nGrid, 1), :);
predictionTbl.Distance = distanceGrid(:);
predictionTbl.inverseDistance = 1 ./ predictionTbl.Distance;
predictionTbl.(elevationVariable) = elevationGrid(:);
predictedParallax = predict(lme, predictionTbl, 'Conditional', false);
parallaxGrid = reshape(predictedParallax, size(distanceGrid));

distanceMap = turbo(256);
elevationMap = earthColormap(256, 'Apply', false);
figSurface = figure('Color', 'w', 'Units', 'normalized', ...
    'Position', [0.05 0.04 0.90 0.90], ...
    'Name', [tblName '_inverseDistance_x_Elevation_surfaces'], ...
    'Visible', 'off');
tSurface = tiledlayout(figSurface, 2, 2, ...
    'Padding', 'compact', 'TileSpacing', 'compact');

elevationAxisLabel = 'Elevation [deg]';
elevationTitleLabel = 'E';
panelSpecs = { ...
    distanceGrid, elevationGrid, distanceGrid, distanceMap, ...
        'D [m]', elevationAxisLabel, ['D x ' elevationTitleLabel ', color: D'], 'D [m]'; ...
    elevationGrid, distanceGrid, distanceGrid, distanceMap, ...
        elevationAxisLabel, 'D [m]', [elevationTitleLabel ' x D, color: D'], 'D [m]'; ...
    distanceGrid, elevationGrid, elevationGrid, elevationMap, ...
        'D [m]', elevationAxisLabel, ['D x ' elevationTitleLabel ', color: ' elevationTitleLabel], elevationAxisLabel; ...
    elevationGrid, distanceGrid, elevationGrid, elevationMap, ...
        elevationAxisLabel, 'D [m]', [elevationTitleLabel ' x D, color: ' elevationTitleLabel], elevationAxisLabel};

for iPanel = 1:size(panelSpecs, 1)
    ax = nexttile(tSurface);
    surfaceHandle = surf(ax, panelSpecs{iPanel, 1}, panelSpecs{iPanel, 2}, ...
        parallaxGrid, panelSpecs{iPanel, 3}, ...
        'FaceColor', 'interp', 'EdgeColor', [0.35 0.35 0.35], ...
        'EdgeAlpha', 0.28);
    surfaceHandle.MeshStyle = 'both';
    colormap(ax, panelSpecs{iPanel, 4});
    cb = colorbar(ax, 'eastoutside');
    cb.Label.String = panelSpecs{iPanel, 8};
    cb.Label.FontName = 'Avenir';
    cb.Label.FontSize = 11;
    cb.FontName = 'Avenir';
    cb.FontSize = 9;
    xlabel(ax, panelSpecs{iPanel, 5}, 'FontSize', 12);
    ylabel(ax, panelSpecs{iPanel, 6}, 'FontSize', 12);
    if iPanel == 1
        zlabel(ax, 'Predicted parallax [deg]', 'FontSize', 12);
    end
    title(ax, panelSpecs{iPanel, 7}, 'FontSize', 12, ...
        'FontWeight', 'normal');
    set(ax, 'FontName', 'Avenir', 'FontSize', 9);
    view(ax, 40, 28);
    grid(ax, 'on');
    box(ax, 'off');
end

modelTitleLines = local_linear_interaction_title(lme, nIDs, elevationVariable);
titleHandle = title(tSurface, strjoin(modelTitleLines, newline), ...
    'FontName', 'Avenir', 'FontSize', 11, 'FontWeight', 'bold', ...
    'Interpreter', 'tex');
titleHandle.HorizontalAlignment = 'center';

exportgraphics(figSurface, fullfile(ResultsDir, ...
    [tblName '_inverseDistance_x_Elevation_surfaces.png']), ...
    'Resolution', 600);
savefig(figSurface, fullfile(ResultsDir, ...
    [tblName '_inverseDistance_x_Elevation_surfaces.fig']));
close(figSurface);

end

function local_write_model_report(reportFile, tbl, tblName, sourceCsv, ...
    modelTransform, linearElevationSource, models, formulas)
modelLabels = cellfun(@(f) ['Model: ' f], formulas, 'UniformOutput', false);
validModel = ~cellfun(@isempty, models);
if ~any(validModel)
    local_write_empty_report(reportFile, tblName, sourceCsv, formulas);
    return;
end

[comparisons, comparisonLabels] = local_model_comparisons(models, formulas);

reportOpts = struct();
reportOpts.ReportTitle = sprintf('Quad Horizontal Binocular Parallax inverseDistance/Elevation LME Report: %s', ...
    char(string(tblName)));
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = sourceCsv;
reportOpts.ModelLabel = ['Quad Horizontal Binocular Parallax predicted by ' ...
    'inverse distance and elevation'];
reportOpts.SummaryLines = { ...
    sprintf('Experiment: Quad'), ...
    sprintf('Rows in model table: %d', height(tbl)), ...
    sprintf('Participants in model table: %d', numel(categories(removecats(tbl.ID)))), ...
    sprintf('Legacy log-model elevation transform input: %s (not used by these linear models)', local_transform_label(modelTransform)), ...
    sprintf('Linear-model Elevation source: %s', linearElevationSource), ...
    sprintf('Fit method: ML'), ...
    sprintf('All formulas are fit with random intercepts by participant.'), ...
    sprintf('Elevation models use raw signed Elevation in degrees.'), ...
    sprintf('No elevation transform or +1 regularization is used by any model in this report.')};
reportOpts.Models = models(validModel);
reportOpts.ModelLabels = modelLabels(validModel);
reportOpts.Comparisons = comparisons;
reportOpts.ComparisonLabels = comparisonLabels;
reportOpts.RemoveGroupError = false;
write_lme_stats_report(models{find(validModel, 1, 'first')}, reportFile, reportOpts);
end

function [comparisons, comparisonLabels] = local_model_comparisons(models, formulas)
comparisons = {};
comparisonLabels = {};

[comparisonTbl, ok] = local_try_compare(models{1}, models{3});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{1}, formulas{3});
end

[comparisonTbl, ok] = local_try_compare(models{2}, models{3});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{2}, formulas{3});
end

[comparisonTbl, ok] = local_try_compare(models{4}, models{3});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf( ...
        'Additive vs interaction comparison: %s vs %s', ...
        formulas{4}, formulas{3});
end
[fitStatsTbl, ok] = local_fit_stat_table( ...
    models, formulas, ...
    ["Linear: 1/Distance"; "Linear: Elevation"; ...
    "Linear: 1/Distance*Elevation"; ...
    "Linear: 1/Distance + Elevation"], ...
    repmat("MeanParallax", 4, 1));
if ok
    comparisons{end + 1} = fitStatsTbl;
    comparisonLabels{end + 1} = ...
        'AIC/BIC summary: linear 1/Distance/elevation models';
end
end

function [comparisonTbl, ok] = local_try_compare(lme1, lme2)
comparisonTbl = [];
ok = false;
if isempty(lme1) || isempty(lme2)
    return;
end

try
    comparisonTbl = compare(lme1, lme2);
    ok = true;
catch ME
    fprintf('Skipping model comparison: %s\n', ME.message);
end
end

function [fitStatsTbl, ok] = local_fit_stat_table(models, formulas, labels, responseScales)
valid = ~cellfun(@isempty, models);
models = models(valid);
formulas = formulas(valid);
labels = labels(valid);
responseScales = responseScales(valid);
ok = ~isempty(models);

if ~ok
    fitStatsTbl = table();
    return;
end

nModels = numel(models);
nObs = nan(nModels, 1);
logLikelihood = nan(nModels, 1);
aic = nan(nModels, 1);
bic = nan(nModels, 1);
deviance = nan(nModels, 1);

for iModel = 1:nModels
    nObs(iModel) = models{iModel}.NumObservations;
    logLikelihood(iModel) = models{iModel}.LogLikelihood;
    aic(iModel) = models{iModel}.ModelCriterion.AIC;
    bic(iModel) = models{iModel}.ModelCriterion.BIC;
    deviance(iModel) = -2 * models{iModel}.LogLikelihood;
end

fitStatsTbl = table(labels(:), string(formulas(:)), responseScales(:), ...
    nObs, logLikelihood, aic, bic, deviance, ...
    'VariableNames', {'Model','Formula','Response','N','LogLikelihood','AIC','BIC','Deviance'});
end

function local_write_empty_report(reportFile, tblName, sourceCsv, formulas)
[reportDir, ~, ~] = fileparts(reportFile);
if ~isempty(reportDir) && ~exist(reportDir, 'dir')
    mkdir(reportDir);
end
[fid, msg] = fopen(reportFile, 'w');
if fid == -1
    error('Could not open report file %s: %s', reportFile, msg);
end
cleanupObj = onCleanup(@() fclose(fid));

reportTitle = sprintf('Quad Perceived Parallax 1/Distance/Elevation LME Report: %s', ...
    char(string(tblName)));
fprintf(fid, '%s\n', reportTitle);
fprintf(fid, '%s\n\n', repmat('=', 1, numel(reportTitle)));
fprintf(fid, 'Generated: %s\n', char(string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"))));
fprintf(fid, 'Generated by: %s\n', mfilename);
fprintf(fid, 'Source CSV: %s\n\n', sourceCsv);
fprintf(fid, 'No models were fit successfully.\n\n');
fprintf(fid, 'Attempted formulas:\n');
for iFormula = 1:numel(formulas)
    fprintf(fid, '    %s\n', formulas{iFormula});
end
end

function sourceCsv = local_source_file_label(tbl, tblName)
sourceCsv = char(string(tblName));
try
    if isstruct(tbl.Properties.UserData) && isfield(tbl.Properties.UserData, 'SourceFile')
        sourceCsv = char(string(tbl.Properties.UserData.SourceFile));
    end
catch
end

if ~endsWith(string(sourceCsv), ".csv", "IgnoreCase", true)
    sourceCsv = sprintf('%s.csv (inferred from tblName; function input is a table)', sourceCsv);
end
end

function rawElevation = local_recover_raw_elevation(tbl, modelTransform)
currentElevation = double(tbl.Elevation);
candidates = {'RawElevation', 'Observer_Elevation', 'Ground_Elevation'};
for iCandidate = 1:numel(candidates)
    varName = candidates{iCandidate};
    if ~ismember(varName, tbl.Properties.VariableNames)
        continue;
    end
    candidate = double(tbl.(varName));
    transformedCandidate = local_apply_elevation_transform(candidate, modelTransform);
    finiteRows = isfinite(currentElevation) & isfinite(transformedCandidate);
    if any(finiteRows) && max(abs(currentElevation(finiteRows) - ...
            transformedCandidate(finiteRows))) < 1e-8
        rawElevation = candidate;
        return;
    end
end

if any(modelTransform == [2 4 6])
    error('Quad_Disparity_by_inverseDistanceElevation:MissingRawElevation', ...
        ['Signed elevation cannot be recovered from an absolute-elevation input. ' ...
        'Retain Observer_Elevation, Ground_Elevation, or RawElevation in the table.']);
end
rawElevation = currentElevation;
end

function transformedElevation = local_apply_elevation_transform(elevation, modelTransform)
switch modelTransform
    case 1
        transformedElevation = elevation;
    case 2
        transformedElevation = abs(elevation);
    case 3
        transformedElevation = pi * elevation / 180;
    case 4
        transformedElevation = pi * abs(elevation) / 180;
    case 5
        transformedElevation = elevation / 90;
    case 6
        transformedElevation = abs(elevation / 90);
    otherwise
        transformedElevation = elevation;
end
end

function transformLabel = local_transform_label(modelTransform)
switch modelTransform
    case 1
        transformLabel = 'Elevation';
    case 2
        transformLabel = 'absElevation';
    case 5
        transformLabel = 'ElevationD90';
    case 6
        transformLabel = 'absElevationD90';
    otherwise
        transformLabel = sprintf('modelTransform %d', modelTransform);
end
end

function titleLines = local_full_model_title(lme, modelTransform, includeVisualAngle, nIDs)
if nargin < 3
    includeVisualAngle = false;
end
if nargin < 4
    nIDs = nan;
end
if isempty(lme)
    titleLines = {'Full RI model', 'Model unavailable'};
    return;
end

b0 = local_coef_estimate(lme, '(Intercept)');
bD = local_coef_estimate(lme, 'log2inverseDistance');
bE = local_coef_estimate(lme, 'log2elevation');
p0 = local_coef_pvalue(lme, '(Intercept)');
pD = local_coef_pvalue(lme, 'log2inverseDistance');
pE = local_coef_pvalue(lme, 'log2elevation');
scale = 2.^b0;
elevationTerm = local_elevation_equation_term(modelTransform);
elevationLogTerm = local_elevation_log_formula_term(modelTransform);
nText = local_format_count(nIDs);

if includeVisualAngle
    bVA = local_coef_estimate(lme, 'log2real_visual_angle');
    pVA = local_coef_pvalue(lme, 'log2real_visual_angle');
    modelLine = sprintf(['Full RI model: log_2(Perceived Parallax) = b_0 + ' ...
        'b_{VA} log_2(VA) + b_D ' ...
        'log_2(Distance) + b_E %s + (1|ID)'], ...
        elevationLogTerm);
    equationLine = sprintf(['Perceived Parallax = %s VA^{%s} ' ...
        'Distance^{%s} %s^{%s}'], ...
        local_format_title_number(scale), local_format_title_number(bVA), ...
        local_format_title_number(-bD), elevationTerm, local_format_title_number(bE));
    statsLine = sprintf('p_{VA}=%s, p_D=%s, p_E=%s', ...
        local_format_pvalue(pVA), local_format_pvalue(pD), ...
        local_format_pvalue(pE));
    interceptLine = sprintf('p_0=%s, n=%s', local_format_pvalue(p0), nText);
else
    modelLine = sprintf(['Full RI model: log_2(Perceived Parallax) = b_0 + ' ...
        'b_D log_2(Distance) + b_E %s + (1|ID)'], ...
        elevationLogTerm);
    equationLine = sprintf('Perceived Parallax = %s Distance^{%s} %s^{%s}', ...
        local_format_title_number(scale), local_format_title_number(-bD), ...
        elevationTerm, local_format_title_number(bE));
    statsLine = sprintf('p_D=%s, p_E=%s', ...
        local_format_pvalue(pD), local_format_pvalue(pE));
    interceptLine = sprintf('p_0=%s, n=%s', local_format_pvalue(p0), nText);
end

titleLines = {modelLine, equationLine, statsLine, interceptLine};
end

function estimate = local_coef_estimate(lme, coefName)
estimate = nan;
coefNames = string(lme.Coefficients.Name);
idx = find(coefNames == string(coefName), 1, 'first');
if ~isempty(idx)
    estimate = lme.Coefficients.Estimate(idx);
end
end

function pval = local_coef_pvalue(lme, coefName)
pval = nan;
coefNames = string(lme.Coefficients.Name);
idx = find(coefNames == string(coefName), 1, 'first');
if ~isempty(idx)
    pval = lme.Coefficients.pValue(idx);
end
end

function elevationTerm = local_elevation_equation_term(modelTransform)
switch modelTransform
    case 2
        elevationTerm = '(1+|E|)';
    case 6
        elevationTerm = '(1+|E|/90)';
    otherwise
        elevationTerm = '(1+E/90)';
end
end

function elevationLogTerm = local_elevation_log_formula_term(modelTransform)
switch modelTransform
    case 2
        elevationLogTerm = 'log_2(1+|E|)';
    case 6
        elevationLogTerm = 'log_2(1+|E|/90)';
    otherwise
        elevationLogTerm = 'log_2(1+E/90)';
end
end

function numberText = local_format_title_number(value)
if ~isfinite(value)
    numberText = 'n/a';
elseif abs(value) >= 100
    numberText = sprintf('%.1f', value);
else
    numberText = sprintf('%.2f', value);
end
end

function countText = local_format_count(value)
if ~isfinite(value)
    countText = 'n/a';
else
    countText = sprintf('%d', round(value));
end
end

function subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID)
if isempty(fullUniqueID)
    uniqueID = categories(removecats(tbl.ID));
else
    uniqueID = string(fullUniqueID(:));
end
subjectcolor = zeros(height(tbl), 3);
for c = 1:height(tbl)
    cindex = find(strcmp(uniqueID, char(string(tbl.ID(c)))), 1, 'first');
    colorRow = local_lookup_color_row(sorted_idx, cindex, numel(uniqueID), size(mycolormap, 1));
    subjectcolor(c,:) = mycolormap(colorRow,:);
end
end

function colorRow = local_lookup_color_row(sorted_idx, cindex, nSubjects, nColors)
if isempty(cindex) || ~isfinite(cindex)
    colorRow = 1;
    return;
end

if local_uses_direct_color_rows(sorted_idx, nSubjects) && cindex <= numel(sorted_idx)
    colorRow = round(sorted_idx(cindex));
else
    colorRow = find(sorted_idx == cindex, 1, 'first');
    if isempty(colorRow)
        colorRow = cindex;
    end
end

colorRow = max(1, min(nColors, colorRow));
end

function tf = local_uses_direct_color_rows(sorted_idx, nSubjects)
if isempty(sorted_idx) || numel(sorted_idx) ~= nSubjects
    tf = false;
    return;
end

idx = round(sorted_idx(:));
tf = ~(all(isfinite(idx)) && isequal(sort(idx)', 1:nSubjects));
end

function labelText = local_colorbar_label(colorConfig)
labelText = 'Participant color order';
if ~isstruct(colorConfig) || ~isfield(colorConfig, 'Mode')
    return;
end

switch string(colorConfig.Mode)
    case "stereoscore"
        labelText = 'Normed stereo score';
    case "clinicalnotes"
        labelText = 'Clinical notes';
    case "id"
        labelText = 'Participant ID';
end
end

function local_add_subject_colorbar(figHandle, mycolormap, nIDs, ...
    labelText, colorConfig, legendAxes)
if nargin < 4 || isempty(labelText)
    labelText = 'Participant color order';
end
if nargin < 5
    colorConfig = [];
end
if nargin < 6 || isempty(legendAxes)
    legendAxes = findobj(figHandle, 'Type', 'axes', '-not', 'Tag', 'Colorbar');
    legendAxes = legendAxes(1);
end

if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        string(colorConfig.Mode) == "clinicalnotes"
    legendHandle = Quad_add_clinical_notes_legend(legendAxes, colorConfig);
    legendHandle.FontSize = 11;
    return;
end

if isempty(mycolormap)
    return;
end

labelLower = lower(string(labelText));
isNormedStereoBar = contains(labelLower, 'normed stereo score') || ...
    contains(labelLower, 'normedscore') || ...
    contains(labelLower, 'normedstereoscore');
if isNormedStereoBar
    plotAxes = findall(figHandle, 'Type', 'axes');
    plotAxes = plotAxes(~arrayfun(@(ax) isa(ax, 'matlab.graphics.illustration.ColorBar'), plotAxes));
    if ~isempty(plotAxes)
        apply_stereo_score_colormap(plotAxes);
    end
    cb = add_stereo_score_colorbar(figHandle, labelText, [0.885 0.22 0.012 0.52]);
    cb.FontName = 'Avenir';
    cb.FontSize = 18;
    cb.Label.FontName = 'Avenir';
    cb.Label.FontSize = 20;
    return;
end

nColorLevels = min(size(mycolormap, 1), max(1, nIDs));
displayCmap = mycolormap(1:nColorLevels, :);
cbAx = axes('Parent', figHandle, 'Position', [0.86 0.22 0.010 0.52]);
set(cbAx, 'Visible', 'off', 'YDir', 'normal', 'CLim', [1 nColorLevels], ...
    'Color', 'none', 'XColor', 'none', 'YColor', 'none');
colormap(cbAx, displayCmap);

cb = colorbar(cbAx, 'Position', [0.885 0.22 0.012 0.52]);
cb.FontName = 'Avenir';
cb.FontSize = 12;
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        string(colorConfig.Mode) == "id" && ...
        isfield(colorConfig, 'ColorbarTicks') && ...
        isfield(colorConfig, 'ColorbarTickLabels') && ...
        ~isempty(colorConfig.ColorbarTicks)
    cb.Ticks = max(1, min(nColorLevels, colorConfig.ColorbarTicks(:)'));
    cb.TickLabels = string(colorConfig.ColorbarTickLabels(:)');
else
    cb.Ticks = unique(max(1, min(nColorLevels, [1 nColorLevels])));
    cb.TickLabels = string(cb.Ticks);
end
cb.Label.String = labelText;
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 14;
end

function local_plot_linear_model_panel(ax, tbl, subjectcolor, lme, modeChar, ...
    minParallax, maxParallax, modelTransform, showYLabel, hiddenYAxisColor)
if nargin < 9 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 10 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end

hold(ax, 'on');
[x, xlabelText, predictorName, predictorLabel] = ...
    local_linear_axis_setup(tbl, modeChar, modelTransform);
y = tbl.MeanParallax;

if ~isempty(lme)
    pval = local_fixed_effect_pvalue(lme, predictorName);
    if isfinite(pval) && pval < 0.05
        xGrid = linspace(min(x), max(x), 200)';
        newTbl = tbl(ones(numel(xGrid), 1), :);
        newTbl.(predictorName) = xGrid;
        try
            [yFit, yCI] = predict(lme, newTbl, 'Conditional', false);
            fill(ax, [xGrid; flipud(xGrid)], ...
                [yCI(:,1); flipud(yCI(:,2))], 'k', ...
                'EdgeColor', 'none', 'FaceAlpha', 0.20);
            plot(ax, xGrid, yFit, 'k-', 'LineWidth', 5);
        catch ME
            fprintf('Skipping linear fixed-effect plot: %s\n', ME.message);
        end
    end
else
    pval = nan;
end

scatter_by_measurement(ax, x, y, subjectcolor, tbl.Measurement);
local_finish_linear_axes(ax, x, xlabelText, minParallax, maxParallax, modeChar, ...
    showYLabel, hiddenYAxisColor);
titleText = local_linear_single_factor_title(lme, modeChar, ...
    predictorLabel, pval, numel(categories(removecats(tbl.ID))));
title(ax, titleText, ...
    'FontSize', 15, 'FontWeight', 'normal');
end

function local_plot_linear_interaction_panel(ax, tbl, lme, modeChar, ...
    minParallax, maxParallax, showYLabel)
hold(ax, 'on');
markerSize = 32;

if modeChar == 'D'
    x = tbl.inverseDistance;
    scatterModerator = tbl.Elevation;
    xName = 'inverseDistance';
    moderatorName = 'Elevation';
    moderatorDisplayName = 'Elevation';
    % LampBulb7 disk elevations from Supplemental Table 3. This analysis
    % uses absolute elevation, so the negative value enters as |E|.
    representativeValues = sort(abs([...
        -0.87375, 1.84810262, 2.84908696]));
    representativeDisplayValues = representativeValues;
    xlabelText = '1/Distance [m^{-1}]';
    colorbarText = '|Elevation| [deg]';
    panelMap = earthColormap(256, 'Apply', false);
else
    x = tbl.Elevation;
    scatterModerator = tbl.Distance;
    xName = 'Elevation';
    moderatorName = 'inverseDistance';
    moderatorDisplayName = 'Distance [m]';
    % Approximate mean distance of the Lamp5 disks.
    representativeDisplayValues = 12.6;
    representativeValues = 1 ./ representativeDisplayValues;
    xlabelText = '|Elevation| [deg]';
    colorbarText = 'Distance [m]';
    panelMap = plasma(256);
end
colorLimits = [min(scatterModerator) max(scatterModerator)];
lineMap = local_colors_from_colormap(panelMap, colorLimits, ...
    representativeDisplayValues);

scatter(ax, x, tbl.MeanParallax, markerSize, scatterModerator, 'filled', ...
    'MarkerFaceAlpha', 0.45, 'MarkerEdgeColor', 'none', ...
    'HandleVisibility', 'off');
colormap(ax, panelMap);
if colorLimits(1) < colorLimits(2)
    clim(ax, colorLimits);
end
cb = colorbar(ax, 'eastoutside');
cb.Label.String = colorbarText;
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 14;
cb.FontName = 'Avenir';
cb.FontSize = 12;

xGrid = linspace(min(x), max(x), 200)';
for iValue = 1:numel(representativeValues)
    newTbl = tbl(ones(numel(xGrid), 1), :);
    newTbl.(xName) = xGrid;
    newTbl.(moderatorName) = repmat(representativeValues(iValue), ...
        numel(xGrid), 1);
    try
        yFit = predict(lme, newTbl, 'Conditional', false);
        plot(ax, xGrid, yFit, '-', 'Color', lineMap(iValue,:), ...
            'LineWidth', 4, 'DisplayName', ...
            sprintf('%s = %.3g', moderatorDisplayName, ...
            representativeDisplayValues(iValue)));
    catch ME
        fprintf('Skipping interaction prediction line: %s\n', ME.message);
    end
end

xlabel(ax, xlabelText, 'FontName', 'Avenir', 'FontSize', 18);
if showYLabel
    ylabel(ax, 'Perceived Parallax [deg]', 'FontName', 'Avenir', 'FontSize', 18);
else
    ylabel(ax, '');
    ax.YColor = 'w';
end
set(ax, 'FontName', 'Avenir', 'FontSize', 14);
if modeChar == 'D'
    [xLimits, xTicks] = local_inverse_distance_axis(x);
    xlim(ax, xLimits);
    xticks(ax, xTicks);
else
    xlim(ax, local_expand_linear_limits(x, false));
end
ylim(ax, local_expand_linear_limits([minParallax maxParallax], false));
box(ax, 'off');
grid(ax, 'off');
legend(ax, 'Location', 'best', 'Box', 'off', 'FontSize', 11);
end

function colors = local_colors_from_colormap(colorMap, colorLimits, values)
values = double(values(:));
if colorLimits(1) == colorLimits(2)
    colors = repmat(colorMap(round(end / 2), :), numel(values), 1);
    return;
end

mapPositions = linspace(colorLimits(1), colorLimits(2), size(colorMap, 1));
clippedValues = min(max(values, colorLimits(1)), colorLimits(2));
colors = interp1(mapPositions, colorMap, clippedValues, 'linear');
end

function titleLines = local_linear_interaction_title(lme, nIDs, elevationVariable)
if isempty(lme)
    titleLines = {'Linear interaction RI model', 'Model unavailable'};
    return;
end
b0 = local_coef_estimate(lme, '(Intercept)');
bD = local_coef_estimate(lme, 'inverseDistance');
bE = local_coef_estimate(lme, elevationVariable);
bDE = local_coef_estimate_any(lme, ...
    {['inverseDistance:' elevationVariable], [elevationVariable ':inverseDistance']});
pD = local_coef_pvalue(lme, 'inverseDistance');
pE = local_coef_pvalue(lme, elevationVariable);
pDE = local_coef_pvalue_any(lme, ...
    {['inverseDistance:' elevationVariable], [elevationVariable ':inverseDistance']});
eSymbol = 'E';
titleLines = { ...
    sprintf('Linear interaction RI model: Perceived Parallax = b_0 + b_D/D + b_E%s + b_{DE}%s/D + (1|ID)', eSymbol, eSymbol), ...
    sprintf('Perceived Parallax = %s %s/D %s%s %s%s/D', ...
    local_format_title_number(b0), local_format_signed_term(bD), ...
    local_format_signed_term(bE), eSymbol, local_format_signed_term(bDE), eSymbol), ...
    sprintf('p_D=%s, p_E=%s, p_{D x E}=%s, n=%d', ...
    local_format_pvalue(pD), local_format_pvalue(pE), ...
    local_format_pvalue(pDE), nIDs)};
end

function estimate = local_coef_estimate_any(lme, candidateNames)
estimate = nan;
for iName = 1:numel(candidateNames)
    estimate = local_coef_estimate(lme, candidateNames{iName});
    if isfinite(estimate)
        return;
    end
end
end

function pval = local_coef_pvalue_any(lme, candidateNames)
pval = nan;
for iName = 1:numel(candidateNames)
    pval = local_coef_pvalue(lme, candidateNames{iName});
    if isfinite(pval)
        return;
    end
end
end

function termText = local_format_signed_term(value)
if value < 0
    termText = sprintf('- %.3g', abs(value));
else
    termText = sprintf('+ %.3g', value);
end
end

function [x, xlabelText, predictorName, predictorLabel] = ...
    local_linear_axis_setup(tbl, modeChar, modelTransform)
if modeChar == 'D'
    x = tbl.inverseDistance;
    xlabelText = '1/Distance [m^{-1}]';
    predictorName = 'inverseDistance';
    predictorLabel = 'Perceived Parallax by 1/Distance';
elseif modeChar == 'E'
    x = tbl.Elevation;
    predictorName = 'Elevation';
    predictorLabel = 'Perceived Parallax by elevation';
    xlabelText = 'Elevation [deg]';
else
    error('Unsupported linear plotting mode "%s".', modeChar);
end
end

function titleText = local_linear_single_factor_title(lme, modeChar, ...
    predictorLabel, pval, nIDs)
if isempty(lme) || ~isfinite(pval) || pval >= 0.05
    titleText = sprintf('%s, p=%s\nn=%d', predictorLabel, ...
        local_format_pvalue(pval), nIDs);
    return;
end

b0 = local_coef_estimate(lme, '(Intercept)');
if modeChar == 'D'
    b1 = local_coef_estimate(lme, 'inverseDistance');
    equationText = sprintf('Perceived Parallax = %s %s/D', ...
        local_format_title_number(b0), local_format_signed_term(b1));
else
    if modeChar == 'E'
        predictorName = 'Elevation';
        predictorSymbol = 'E';
    else
        error('Unsupported linear plotting mode "%s".', modeChar);
    end
    b1 = local_coef_estimate(lme, predictorName);
    equationText = sprintf('Perceived Parallax = %s %s%s', ...
        local_format_title_number(b0), local_format_signed_term(b1), ...
        predictorSymbol);
end
titleText = sprintf('%s\np=%s, n=%d', equationText, ...
    local_format_pvalue(pval), nIDs);
end

function local_finish_linear_axes(ax, x, xlabelText, minParallax, maxParallax, ...
    modeChar, showYLabel, hiddenYAxisColor)
set(ax, 'FontName', 'Avenir', 'FontSize', 14);
xlabel(ax, xlabelText, 'FontSize', 18);
if showYLabel
    ylabel(ax, {'Perceived Parallax [deg]','linear scale'}, 'FontSize', 18);
else
    ylabel(ax, '');
    ax.YColor = hiddenYAxisColor;
end
if modeChar == 'D'
    [xLimits, xTicks] = local_inverse_distance_axis(x);
    xlim(ax, xLimits);
    xticks(ax, xTicks);
else
    xlim(ax, local_expand_linear_limits(x, false));
end
ylim(ax, local_expand_linear_limits([minParallax maxParallax], false));
box(ax, 'off');
grid(ax, 'off');
end

function [limits, ticks] = local_inverse_distance_axis(x)
x = double(x(:));
x = x(isfinite(x) & x >= 0);
if isempty(x) || max(x) <= 0
    limits = [0 1];
    ticks = 0:0.2:1;
    return;
end
targetStep = max(x) / 4;
scale = 10.^floor(log10(targetStep));
candidates = [1 2 2.5 5 10] * scale;
niceStep = candidates(find(candidates >= targetStep, 1, 'first'));
upperLimit = ceil(max(x) / niceStep) * niceStep;
limits = [0 upperLimit];
ticks = 0:niceStep:upperLimit;
end

function limits = local_expand_linear_limits(x, includeZero)
if nargin < 2
    includeZero = false;
end
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
    limits = [0 1];
    return;
end
xmin = min(x);
xmax = max(x);
span = xmax - xmin;
pad = max(0.04 * span, eps(max(abs([xmin xmax]))));
limits = [xmin - pad xmax + pad];
if includeZero
    limits(1) = min(0, limits(1));
end
end

function local_plot_full_model_panel(ax, tbl, subjectcolor, lme, modeChar, ...
    minParallax, maxParallax, modelTransform, showYLabel, hiddenYAxisColor)
if nargin < 9 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 10 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end

hold(ax, 'on');
[x, xlog, xlabelText, tickVals, predictorName, ~] = ...
    local_log_axis_setup(tbl, modeChar, modelTransform);
y = tbl.log2mean_parallax;

if isempty(lme)
    scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
    local_finish_log_axes(ax, tickVals, xlabelText, minParallax, maxParallax, x, ...
        showYLabel, hiddenYAxisColor);
    return;
end

pval = local_fixed_effect_pvalue(lme, predictorName);
if isfinite(pval) && pval < 0.05
    xlinerange = linspace(min(xlog), max(xlog), 200)';
    [yFit, yCI, ok] = local_full_model_prediction(lme, tbl, modeChar, xlinerange);
    if ok
        fill(ax, [xlinerange; flipud(xlinerange)], ...
            [yCI(:,1); flipud(yCI(:,2))], 'k', ...
            'EdgeColor', 'none', 'FaceAlpha', 0.22);
        plot(ax, xlinerange, yFit, 'k-', 'LineWidth', 5);
    end
end

scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
local_finish_log_axes(ax, tickVals, xlabelText, minParallax, maxParallax, x, ...
    showYLabel, hiddenYAxisColor);
end

function [yFit, yCI, ok] = local_full_model_prediction(lme, tbl, modeChar, xlinerange)
ok = false;
yFit = [];
yCI = [];
nGrid = numel(xlinerange);
newTbl = tbl(ones(nGrid, 1), :);

if ismember('log2real_visual_angle', newTbl.Properties.VariableNames)
    newTbl.log2real_visual_angle = repmat(mean(tbl.log2real_visual_angle, 'omitnan'), nGrid, 1);
end
if ismember('log2inverseDistance', newTbl.Properties.VariableNames)
    newTbl.log2inverseDistance = repmat(mean(tbl.log2inverseDistance, 'omitnan'), nGrid, 1);
end
if ismember('log2elevation', newTbl.Properties.VariableNames)
    newTbl.log2elevation = repmat(mean(tbl.log2elevation, 'omitnan'), nGrid, 1);
end

switch modeChar
    case 'A'
        newTbl.log2real_visual_angle = xlinerange;
    case 'D'
        newTbl.log2inverseDistance = xlinerange;
    otherwise
        newTbl.log2elevation = xlinerange;
end

try
    [yFit, yCI] = predict(lme, newTbl, 'Conditional', false);
    ok = true;
catch ME
    fprintf('Skipping full-model prediction plot: %s\n', ME.message);
end
end

function pval = local_fixed_effect_pvalue(lme, predictorName)
pval = nan;
if isempty(lme)
    return;
end

coefNames = string(lme.Coefficients.Name);
idx = find(coefNames == string(predictorName), 1, 'first');
if ~isempty(idx)
    pval = lme.Coefficients.pValue(idx);
end
end

function [x, xlog, xlabelText, tickVals, predictorName, predictorLabel] = ...
    local_log_axis_setup(tbl, modeChar, modelTransform)
switch modeChar
    case 'A'
        x = tbl.Real_Visual_Angle;
        xlog = tbl.log2real_visual_angle;
        xlabelText = 'Real VA [deg, log scale]';
        tickVals = local_visual_angle_ticks(min(x), max(x));
        predictorName = "log2real_visual_angle";
        predictorLabel = "VA";
    case 'D'
        x = tbl.inverseDistance;
        xlog = tbl.log2inverseDistance;
        xlabelText = '1/Distance [m^{-1}, log scale]';
        tickVals = local_log_ticks(min(x), max(x), false);
        predictorName = "log2inverseDistance";
        predictorLabel = "1/Distance";
    otherwise
        x = tbl.ElevationModel;
        xlog = tbl.log2elevation;
        predictorName = "log2elevation";
        predictorLabel = "Elevation";
        if modelTransform == 2
            xlabelText = '|Elevation| [deg, log scale]';
        elseif modelTransform == 6
            xlabelText = '|Elevation| [deg, log scale]';
        else
            xlabelText = 'Elevation [deg, log scale]';
        end
        tickVals = local_log_ticks(min(x), max(x), true, modelTransform);
end
end

function local_finish_log_axes(ax, tickVals, xlabelText, minParallax, maxParallax, x, showYLabel, hiddenYAxisColor)
set(ax, 'XTick', tickVals.positions, 'XTickLabel', tickVals.labels, ...
    'YTick', floor(log2(minParallax)):ceil(log2(maxParallax)), ...
    'YTickLabel', string(2.^(floor(log2(minParallax)):ceil(log2(maxParallax)))), ...
    'FontName', 'Avenir', 'FontSize', 12);
xlabel(ax, xlabelText, 'FontSize', 15);
if showYLabel
    ylabel(ax, {'Perceived Parallax [deg]','log scale'}, 'FontSize', 16);
else
    ylabel(ax, '');
    ax.YColor = hiddenYAxisColor;
end
ax.XTickLabelRotation = 0;
xlim(ax, local_expand_log_limits(x));
ylim(ax, [floor(log2(minParallax)) ceil(log2(maxParallax))]);
box(ax, 'off');
grid(ax, 'off');
end

function pStr = local_format_pvalue(pval)
if isnan(pval)
    pStr = 'n/a';
    return;
end
if pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end

function lme = local_try_fitlme(tbl, formulaStr)
try
    % Fixed-effect likelihood-ratio tests require models fitted by ML,
    % rather than the default REML fit.
    lme = fitlme(tbl, formulaStr, 'FitMethod', 'ML');
catch ME
    fprintf('Skipping model: %s\nReason: %s\n', formulaStr, ME.message);
    lme = [];
end
end

function tickStruct = local_visual_angle_ticks(minVal, maxVal)
candidateVals = [0.025 0.05 0.1 0.2 0.5 1 1.5 2 3 5 8 10 15];
tickVals = candidateVals(candidateVals >= minVal * 0.95 & candidateVals <= maxVal * 1.02);

if numel(tickVals) < 3
    tickVals = unique(round(logspace(log10(minVal), log10(maxVal), 4), 2));
end

tickStruct = local_finalize_ticks(tickVals(:), log2(tickVals(:)), 0.45);
end

function tickStruct = local_log_ticks(minVal, maxVal, isElevation, modelTransform)
if nargin < 3
    isElevation = false;
end
if nargin < 4
    modelTransform = [];
end

if ~isElevation
    tickVals = unique(round(logspace(log10(minVal), log10(maxVal), 4), 2));
    tickVals = unique([minVal; tickVals(:); maxVal]);
    tickStruct = local_finalize_ticks(tickVals, log2(tickVals));
    return;
end

if modelTransform == 2
    nativeVals = unique(max(0, round(linspace(max(0, minVal - 1), max(0, maxVal - 1), 4), 1)));
    nativeVals = unique([max(0, minVal - 1); nativeVals(:); max(0, maxVal - 1)]);
    tickStruct = local_finalize_ticks(nativeVals, log2(nativeVals + 1));
else
    nativeVals = [-45 -30 -15 -5 0 5 15 30 45 60];
    tickPos = log2(1 + nativeVals/90);
    valid = isfinite(tickPos) & (1 + nativeVals/90) > 0;
    nativeVals = nativeVals(valid);
    dataMinNative = 90 * (minVal - 1);
    dataMaxNative = 90 * (maxVal - 1);
    inRange = nativeVals >= dataMinNative & nativeVals <= dataMaxNative;
    nativeVals = nativeVals(inRange);
    nativeVals = unique([round(dataMinNative, 1) nativeVals round(dataMaxNative, 1)], 'stable');
    tickStruct = local_finalize_ticks(nativeVals, log2(1 + nativeVals/90));
end
end

function lims = local_expand_log_limits(x)
x = x(isfinite(x) & x > 0);
if isempty(x)
    lims = [0 1];
    return;
end

logX = log2(x);
xmin = min(logX);
xmax = max(logX);
span = xmax - xmin;
pad = max(0.06 * span, 0.12);
lims = [xmin - pad xmax + pad];
end

function tickStruct = local_finalize_ticks(labelVals, positions, minSep)
if nargin < 3 || isempty(minSep)
    minSep = 0.18;
end

labelVals = labelVals(:);
positions = positions(:);
valid = isfinite(labelVals) & isfinite(positions);
labelVals = labelVals(valid);
positions = positions(valid);

if isempty(labelVals)
    tickStruct.positions = [];
    tickStruct.labels = strings(0, 1);
    return;
end

[positions, order] = sort(positions);
labelVals = labelVals(order);
roundedVals = round(labelVals, 2);
[~, uniqueIdx] = unique(roundedVals, 'stable');
positions = positions(uniqueIdx);
labelVals = labelVals(uniqueIdx);

if numel(labelVals) <= 2
    tickStruct.positions = positions;
    tickStruct.labels = string(round(labelVals, 2));
    return;
end

keep = true(size(positions));
for i = 2:numel(positions)-1
    if abs(positions(i) - positions(i-1)) < minSep || abs(positions(i+1) - positions(i)) < minSep
        keep(i) = false;
    end
end

positions = positions(keep);
labelVals = labelVals(keep);

if numel(labelVals) < 2
    positions = [positions(1); positions(end)];
    labelVals = [labelVals(1); labelVals(end)];
end

tickStruct.positions = positions;
tickStruct.labels = string(round(labelVals, 2));
end
