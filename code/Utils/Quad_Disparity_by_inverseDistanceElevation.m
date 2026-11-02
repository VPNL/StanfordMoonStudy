function [lme_Parallax_by_InverseDistance, lme_Parallax_by_Elevation, ...
    lme_Parallax_by_InverseDistanceNElevation, ...
    lme_Parallax_by_InverseDistancePlusElevation, ...
    lme_Parallax_by_InverseDistancePlusElevationXStereoGroup] = ...
    Quad_Disparity_by_inverseDistanceElevation(tbl, tblName, ResultsDir, ...
    saveLME, mycolormap, sorted_idx, degreeFlag, ...
    fullUniqueID, secondYAxisColor, colorConfig, plotFlag)

% QUAD_DISPARITY_BY_INVERSEDISTANCEELEVATION
% Fit linear perceived-parallax inverse-distance/elevation RI models.

if nargin < 7 || isempty(degreeFlag)
    degreeFlag = 1; %#ok<NASGU>
end
if nargin < 8 || isempty(fullUniqueID)
    fullUniqueID = [];
end

if nargin < 9 || isempty(secondYAxisColor)
    secondYAxisColor = 'w';
end
if nargin < 10
    colorConfig = [];
end

if nargin < 11
    plotFlag = true;
end
if ~ismember('Distance', tbl.Properties.VariableNames)
    error('Quad_Disparity_by_inverseDistanceElevation:MissingDistance', ...
        'Input table must contain a Distance column.');
end
sourceCsv = Quad_source_file_label(tbl, tblName);
% Quad_prepare_perceived_disparity_table standardizes Distance to meters.
% Compute inverse distance afterward so its units are m^{-1}.

tbl = Quad_prepare_perceived_disparity_table(tbl);
tbl.inverseDistance = 1 ./ tbl.Distance;
tbl.MeanParallax = tbl.MeanDisparity;
linearElevationSource = 'raw Observer Elevation';

% Linear random-intercept models.  The interaction model includes both
% main effects, so it is nested with each corresponding single-factor model.
inverseDistanceFormula = 'MeanParallax ~ inverseDistance + (1|ID)';
elevationFormula = 'MeanParallax ~ Elevation + (1|ID)';
linearDistancePlusElevationFormula = ...
    'MeanParallax ~ inverseDistance + Elevation + (1|ID)';
linearDistanceElevationFormula = 'MeanParallax ~ inverseDistance * Elevation + (1|ID)';
linearDistancePlusElevationStereoFormula = ...
    'MeanParallax ~ (inverseDistance + Elevation)*StereoGroup + (1|ID)';

lme_Parallax_by_InverseDistance = local_try_fitlme(tbl, inverseDistanceFormula);
lme_Parallax_by_Elevation = local_try_fitlme(tbl, elevationFormula);
lme_Parallax_by_InverseDistanceNElevation = local_try_fitlme(tbl, linearDistanceElevationFormula);
lme_Parallax_by_InverseDistancePlusElevation = ...
    local_try_fitlme(tbl, linearDistancePlusElevationFormula);
[stereoTbl, stereoSummaryLines] = local_prepare_stereo_group_table(tbl);
lme_Parallax_by_InverseDistancePlusElevationXStereoGroup = [];
if ~isempty(stereoTbl)
    lme_Parallax_by_InverseDistancePlusElevationXStereoGroup = ...
        local_try_fitlme(stereoTbl, linearDistancePlusElevationStereoFormula);
    stereoSummaryLines = [stereoSummaryLines, ...
        local_stereo_interaction_test_lines( ...
        lme_Parallax_by_InverseDistancePlusElevationXStereoGroup)];
end

if saveLME
    if ~exist(ResultsDir, 'dir')
        mkdir(ResultsDir);
    end
    savelmefile = fullfile(ResultsDir, ...
        [tblName '_inverseDistance_elevation_RI_models.txt']);
    local_write_model_report(savelmefile, tbl, tblName, sourceCsv, ...
        linearElevationSource, stereoSummaryLines, ...
        {...
        lme_Parallax_by_InverseDistance,...
        lme_Parallax_by_Elevation,...
        lme_Parallax_by_InverseDistancePlusElevation, ...
        lme_Parallax_by_InverseDistanceNElevation, ...
        lme_Parallax_by_InverseDistancePlusElevationXStereoGroup}, ...
        {inverseDistanceFormula, ...
        elevationFormula, ...
        linearDistancePlusElevationFormula, ...
        linearDistanceElevationFormula, ...
        linearDistancePlusElevationStereoFormula});
end

subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID);
minParallax = max(0.01, min(tbl.MeanParallax));
maxParallax = max(tbl.MeanParallax);
nIDs = numel(categories(removecats(tbl.ID)));

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end


%% plot linear single factor models
if plotFlag
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
        true);
    axFullE = nexttile;
    local_plot_linear_model_panel(axFullE, tbl, subjectcolor, ...
        lme_Parallax_by_Elevation, 'E', minParallax, maxParallax, ...
        false, 'w');
    Quad_add_participant_colorbar(figFull, mycolormap, nIDs, ...
        local_colorbar_label(colorConfig), colorConfig, axFullE);
    exportgraphics(figFull, fullfile(ResultsDir, ...
        [tblName '_inverseDistance_E_RI.png']), ...
        'Resolution', 600);


    local_plot_linear_additive_model( ...
        lme_Parallax_by_InverseDistancePlusElevation, tbl, subjectcolor, ...
        tblName, ResultsDir, mycolormap, nIDs, colorConfig, ...
        minParallax, maxParallax);

    local_plot_linear_additive_surfaces( ...
        lme_Parallax_by_InverseDistancePlusElevation, tbl, tblName, ...
        ResultsDir, nIDs, 'Elevation');
end
end

function local_plot_linear_additive_surfaces(lme, tbl, tblName, ...
    ResultsDir, nIDs, elevationVariable)
if isempty(lme)
    fprintf('Skipping linear additive surfaces: model is unavailable.\n');
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
    'Position', [0.12 0.04 0.48 0.90], ...
    'Name', [tblName '_inverseDistance_plus_Elevation_surfaces'], ...
    'Visible', 'off');
tSurface = tiledlayout(figSurface, 2, 1, ...
    'Padding', 'compact', 'TileSpacing', 'compact');

elevationAxisLabel = 'Elevation [deg]';
elevationTitleLabel = 'E';
panelSpecs = { ...
    distanceGrid, elevationGrid, distanceGrid, distanceMap, ...
        'D [m]', elevationAxisLabel, [ ], 'D [m]'};

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
    cb.Label.FontSize = 14;
    cb.FontName = 'Avenir';
    cb.FontSize = 9;
    xlabel(ax, panelSpecs{iPanel, 5}, 'FontSize', 18);
    ylabel(ax, panelSpecs{iPanel, 6}, 'FontSize', 18);
    if iPanel == 1
        zlabel(ax, 'Predicted parallax [deg]', 'FontSize', 18);
    end
    title(ax, panelSpecs{iPanel, 7}, 'FontSize', 12, ...
        'FontWeight', 'normal');
    set(ax, 'FontName', 'Avenir', 'FontSize', 12);
    view(ax, 40, 28);
    grid(ax, 'on');
    box(ax, 'off');
end

modelTitleLines = local_linear_additive_title(lme, nIDs, elevationVariable);
titleHandle = title(tSurface, strjoin(modelTitleLines, newline), ...
    'FontName', 'Avenir', 'FontSize', 11, 'FontWeight', 'bold', ...
    'Interpreter', 'tex');
titleHandle.HorizontalAlignment = 'center';

exportgraphics(figSurface, fullfile(ResultsDir, ...
    [tblName '_inverseDistance_plus_Elevation_surfaces.png']), ...
    'Resolution', 600);
close(figSurface);

end

function local_plot_linear_additive_model(lme, tbl, subjectcolor, ...
    tblName, ResultsDir, mycolormap, nIDs, colorConfig, ...
    minParallax, maxParallax)
if isempty(lme)
    fprintf('Skipping linear additive-model plot: model is unavailable.\n');
    return;
end

fig = figure('Color', 'w', 'Units', 'normalized', ...
    'Position', [0 0 .92 .80], ...
    'Name', [tblName '_inverseDistance_plus_E_RI'], ...
    'Visible', 'off');
t = tiledlayout(fig, 1, 2, 'Padding', 'compact', ...
    'TileSpacing', 'loose');
t.Position = [0.09 0.18 0.70 0.68];

axD = nexttile(t);
local_plot_additive_effect_panel(axD, tbl, subjectcolor, lme, 'D', ...
    minParallax, maxParallax, true);
axE = nexttile(t);
local_plot_additive_effect_panel(axE, tbl, subjectcolor, lme, 'E', ...
    minParallax, maxParallax, false, 'w');

title(t, strjoin(local_linear_additive_title(lme, nIDs, 'Elevation'), ...
    newline), 'FontName', 'Avenir', 'FontSize', 11, ...
    'FontWeight', 'bold', 'Interpreter', 'tex');
Quad_add_participant_colorbar(fig, mycolormap, nIDs, ...
    local_colorbar_label(colorConfig), colorConfig, axE);
exportgraphics(fig, fullfile(ResultsDir, ...
    [tblName '_inverseDistance_plus_E_RI.png']), 'Resolution', 600);
close(fig);
end

function local_plot_additive_effect_panel(ax, tbl, subjectcolor, lme, ...
    modeChar, minParallax, maxParallax, showYLabel, ...
    hiddenYAxisColor)
if nargin < 10 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
hold(ax, 'on');
[x, xlabelText, predictorName] = ...
    local_linear_axis_setup(tbl, modeChar);
xGrid = linspace(min(x), max(x), 200)';
newTbl = tbl(ones(numel(xGrid), 1), :);
newTbl.(predictorName) = xGrid;
if modeChar == 'D'
    newTbl.Elevation(:) = 0;
else
    meanInverseDistance = mean(tbl.inverseDistance, 'omitnan');
    newTbl.inverseDistance(:) = meanInverseDistance;
    newTbl.Distance(:) = 1 ./ meanInverseDistance;
end
[yFit, yCI] = predict(lme, newTbl, 'Conditional', false);
fill(ax, [xGrid; flipud(xGrid)], [yCI(:, 1); flipud(yCI(:, 2))], ...
    [0.72 0.72 0.72], 'EdgeColor', 'none', 'FaceAlpha', 0.35);
plot(ax, xGrid, yFit, 'k-', 'LineWidth', 5);
scatter_by_measurement(ax, x, tbl.MeanParallax, subjectcolor, ...
    tbl.Measurement);
local_finish_linear_axes(ax, x, xlabelText, minParallax, maxParallax, ...
    modeChar, showYLabel, hiddenYAxisColor);
if modeChar == 'D'
    title(ax, 'Effect of 1/Distance at E = 0 deg', 'FontSize', 14, ...
        'FontWeight', 'normal');
else
    title(ax, sprintf('Effect of elevation at mean Distance = %.2f m', ...
        1 ./ mean(tbl.inverseDistance, 'omitnan')), 'FontSize', 14, ...
        'FontWeight', 'normal');
end
end

function [stereoTbl, summaryLines] = local_prepare_stereo_group_table(tbl)
summaryLines = {'StereoGroup two-factor model: skipped (StereoGroup variable not found).'};
stereoTbl = table();
if ~ismember('StereoGroup', tbl.Properties.VariableNames)
    return;
end

stereoTbl = tbl;
stereoTbl.StereoGroup = Quad_stereo_group_categorical(stereoTbl.StereoGroup);
stereoTbl = stereoTbl(~isundefined(stereoTbl.StereoGroup), :);
stereoTbl.StereoGroup = removecats(stereoTbl.StereoGroup);
groupNames = string(categories(stereoTbl.StereoGroup));
if numel(groupNames) < 2
    summaryLines = { ...
        'StereoGroup two-factor model: skipped (fewer than two valid groups).'};
    stereoTbl = table();
    return;
end

summaryLines = [{sprintf( ...
    'StereoGroup two-factor model: %d rows, %d participants, %d groups.', ...
    height(stereoTbl), numel(categories(removecats(stereoTbl.ID))), ...
    numel(groupNames))}, Quad_stereo_group_summary_lines(stereoTbl)];
end

function summaryLines = local_stereo_interaction_test_lines(lme)
if isempty(lme)
    summaryLines = {'StereoGroup joint parameter tests: unavailable (model was not fit).'};
    return;
end

coefficientNames = string(lme.Coefficients.Name);
isStereoTerm = contains(coefficientNames, "StereoGroup");
isInteraction = contains(coefficientNames, ":");
mainGroupTerms = isStereoTerm & ~isInteraction;
distanceGroupTerms = isStereoTerm & isInteraction & ...
    contains(coefficientNames, "inverseDistance");
elevationGroupTerms = isStereoTerm & isInteraction & ...
    contains(coefficientNames, "Elevation");
allSlopeTerms = distanceGroupTerms | elevationGroupTerms;
allGroupTerms = mainGroupTerms | allSlopeTerms;

summaryLines = { ...
    'Joint Wald tests for the two-factor StereoGroup model:', ...
    local_joint_test_line(lme, allGroupTerms, ...
        'Any model parameter differs across StereoGroups'), ...
    local_joint_test_line(lme, mainGroupTerms, ...
        'Intercept differs across StereoGroups'), ...
    local_joint_test_line(lme, distanceGroupTerms, ...
        '1/Distance slope differs across StereoGroups'), ...
    local_joint_test_line(lme, elevationGroupTerms, ...
        'Elevation slope differs across StereoGroups'), ...
    local_joint_test_line(lme, allSlopeTerms, ...
        'Either 1/Distance or Elevation slope differs across StereoGroups')};
end

function summaryLine = local_joint_test_line(lme, termMask, labelText)
termIndex = find(termMask);
if isempty(termIndex)
    summaryLine = sprintf('  %s: unavailable (terms not found).', labelText);
    return;
end

hypothesisMatrix = zeros(numel(termIndex), height(lme.Coefficients));
for iTerm = 1:numel(termIndex)
    hypothesisMatrix(iTerm, termIndex(iTerm)) = 1;
end

try
    [pValue, fStatistic, numeratorDF, denominatorDF] = ...
        coefTest(lme, hypothesisMatrix);
    summaryLine = sprintf('  %s: F(%g,%g)=%.4g, p=%s.', ...
        labelText, numeratorDF, denominatorDF, fStatistic, ...
        Quad_format_pvalue(pValue));
catch ME
    summaryLine = sprintf('  %s: test failed (%s).', labelText, ME.message);
end
end

function local_write_model_report(reportFile, tbl, tblName, sourceCsv, ...
    linearElevationSource, stereoSummaryLines, models, formulas)
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
reportOpts.SummaryLines = [{ ...
    sprintf('Experiment: Quad'), ...
    sprintf('Rows in model table: %d', height(tbl)), ...
    sprintf('Participants in model table: %d', numel(categories(removecats(tbl.ID)))), ...
    sprintf('Linear-model Elevation source: %s', linearElevationSource), ...
    sprintf('Fit method: ML'), ...
    sprintf('All formulas are fit with random intercepts by participant.'), ...
    sprintf('Elevation models use raw signed Elevation in degrees.'), ...
    sprintf('No elevation transform or +1 regularization is used by any model in this report.')}, ...
    stereoSummaryLines];
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

[comparisonTbl, ok] = Quad_try_compare_lme(models{1}, models{3});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{1}, formulas{3});
end

[comparisonTbl, ok] = Quad_try_compare_lme(models{2}, models{3});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{2}, formulas{3});
end

[comparisonTbl, ok] = Quad_try_compare_lme(models{3}, models{4});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf( ...
        'Additive vs interaction comparison: %s vs %s', ...
        formulas{3}, formulas{4});
end
fitStatLabels = ["Linear: 1/Distance"; ...
    "Linear: Elevation"; ...
    "Linear: 1/Distance + Elevation"; ...
    "Linear: 1/Distance*Elevation"];
responseScales = repmat("MeanParallax", 4, 1);
[fitStatsTbl, ok] = Quad_lme_fit_stat_table( ...
    models(1:4), formulas(1:4), fitStatLabels, responseScales);
if ok
    comparisons{end + 1} = fitStatsTbl;
    comparisonLabels{end + 1} = ...
        'AIC/BIC summary: linear 1/Distance/elevation models';
end
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

function numberText = local_format_title_number(value)
if ~isfinite(value)
    numberText = 'n/a';
elseif abs(value) >= 100
    numberText = sprintf('%.1f', value);
else
    numberText = sprintf('%.2f', value);
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

function local_plot_linear_model_panel(ax, tbl, subjectcolor, lme, modeChar, ...
    minParallax, maxParallax, showYLabel, hiddenYAxisColor)
if nargin < 9 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 10 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end

hold(ax, 'on');
[x, xlabelText, predictorName, predictorLabel] = ...
    local_linear_axis_setup(tbl, modeChar);
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

function titleLines = local_linear_additive_title(lme, nIDs, elevationVariable)
if isempty(lme)
    titleLines = {'Linear additive RI model', 'Model unavailable'};
    return;
end
b0 = local_coef_estimate(lme, '(Intercept)');
bD = local_coef_estimate(lme, 'inverseDistance');
bE = local_coef_estimate(lme, elevationVariable);
pD = local_coef_pvalue(lme, 'inverseDistance');
pE = local_coef_pvalue(lme, elevationVariable);
titleLines = { ...
    'Linear additive RI model: Perceived Parallax = b_0 + b_D/D + b_EE + (1|ID)', ...
    sprintf('Perceived Parallax = %s %s/D %sE', ...
    local_format_title_number(b0), local_format_signed_term(bD), ...
    local_format_signed_term(bE)), ...
    sprintf('p_D=%s, p_E=%s, n=%d', ...
    local_format_pvalue(pD), local_format_pvalue(pE), nIDs)};
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
    local_linear_axis_setup(tbl, modeChar)
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
    ylabel(ax, {'Perceived Parallax [deg]'}, 'FontSize', 18);
else
    ylabel(ax, '');
    ax.YColor = hiddenYAxisColor;
end
if modeChar == 'D'
    [xLimits, xTicks] = Quad_inverse_distance_axis(x);
    xlim(ax, xLimits);
    xticks(ax, xTicks);
else
    xlim(ax, Quad_expand_linear_limits(x, false));
end
ylim(ax, Quad_expand_linear_limits([minParallax maxParallax], false));
box(ax, 'off');
grid(ax, 'off');
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
