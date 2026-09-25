function [lme_logDisparity_by_logInverseDistance, lme_logDisparity_by_logElevation, ...
    lme_logDisparity_by_logInverseDistance_RS, lme_logDisparity_by_logElevation_RS, ...
    lme_Disparity_by_InverseDistance, lme_Disparity_by_Elevation, ...
    lme_Disparity_by_InverseDistance_RS, lme_Disparity_by_Elevation_RS, ...
    lme_logDisparity_by_logInverseDistanceXStereoGroup, ...
    lme_logDisparity_by_logElevationXStereoGroup, ...
    lme_Disparity_by_InverseDistanceXStereoGroup, ...
    lme_Disparity_by_ElevationXStereoGroup] = ...
    Quad_Disparity_by_inverseDistanceElevation_single(tbl, tblName, ...
    ResultsDir, saveLME, mycolormap, sorted_idx, modelTransform, ...
    degreeFlag, fullUniqueID, colorbarLabel, ...
    secondYAxisColor, plotFixedEffectsRS, colorConfig, runStereoAnalysis)
% QUAD_DISPARITY_BY_INVERSEDISTANCEELEVATION_SINGLE
% Fit and plot single-factor inverse-distance/elevation disparity models
% with random-intercept and random-slope variants.

if nargin < 8 || isempty(degreeFlag)
    degreeFlag = 1; %#ok<NASGU>
end
if nargin < 7 || isempty(modelTransform)
    modelTransform = 2;
end
if nargin < 9 || isempty(fullUniqueID)
    fullUniqueID = [];
end
if nargin < 10 || isempty(colorbarLabel)
    colorbarLabel = 'Participant color order';
end
if nargin < 11 || isempty(secondYAxisColor)
    secondYAxisColor = 'w';
end
if nargin < 12 || isempty(plotFixedEffectsRS)
    plotFixedEffectsRS = false;
end
if nargin < 13
    colorConfig = [];
end
if nargin < 14 || isempty(runStereoAnalysis)
    runStereoAnalysis = true;
end

sourceCsv = local_source_file_label(tbl, tblName);
outputStem = [local_output_stem(tblName) '_inverseDistance'];
if ~ismember('Distance', tbl.Properties.VariableNames)
    error('Quad_Disparity_by_inverseDistanceElevation_single:MissingDistance', ...
        'Input table must contain a Distance column.');
end
tbl = Quad_prepare_perceived_disparity_table(tbl, modelTransform);
% Quad_prepare_perceived_disparity_table standardizes Distance to meters.
% Compute inverse distance afterward so its units are m^{-1}.
tbl.inverseDistance = 1 ./ tbl.Distance;
tbl.log2inverseDistance = log2(tbl.inverseDistance);
[tbl, linearElevationSource] = local_set_linear_elevation(tbl);
[tbl, stereoGroupSummaryLines, runStereoGroupInteractions] = local_prepare_stereo_group(tbl);

logInverseDistanceRIFormula = 'log2mean_disparity ~ 1 + log2inverseDistance + (1|ID)';
logElevationRIFormula = 'log2mean_disparity ~ 1 + log2elevation + (1|ID)';
logInverseDistanceRSFormula = 'log2mean_disparity ~ 1 + log2inverseDistance + (log2inverseDistance|ID)';
logElevationRSFormula = 'log2mean_disparity ~ 1 + log2elevation + (log2elevation|ID)';
linearDistanceRIFormula = 'MeanDisparity ~ 1 + inverseDistance + (1|ID)';
linearElevationRIFormula = 'MeanDisparity ~ 1 + Elevation + (1|ID)';
linearDistanceRSFormula = 'MeanDisparity ~ 1 + inverseDistance + (inverseDistance|ID)';
linearElevationRSFormula = 'MeanDisparity ~ 1 + Elevation + (Elevation|ID)';
logInverseDistanceStereoRIFormula = 'log2mean_disparity ~ 1 + log2inverseDistance*StereoGroup + (1|ID)';
logElevationStereoRIFormula = 'log2mean_disparity ~ 1 + log2elevation*StereoGroup + (1|ID)';
linearDistanceStereoRIFormula = 'MeanDisparity ~ 1 + inverseDistance*StereoGroup + (1|ID)';
linearElevationStereoRIFormula = 'MeanDisparity ~ 1 + Elevation*StereoGroup + (1|ID)';

lme_logDisparity_by_logInverseDistance = local_try_fitlme(tbl, logInverseDistanceRIFormula);
lme_logDisparity_by_logElevation = local_try_fitlme(tbl, logElevationRIFormula);
lme_logDisparity_by_logInverseDistance_RS = local_try_fitlme(tbl, logInverseDistanceRSFormula);
lme_logDisparity_by_logElevation_RS = local_try_fitlme(tbl, logElevationRSFormula);
lme_Disparity_by_InverseDistance = local_try_fitlme(tbl, linearDistanceRIFormula);
lme_Disparity_by_Elevation = local_try_fitlme(tbl, linearElevationRIFormula);
lme_Disparity_by_InverseDistance_RS = local_try_fitlme(tbl, linearDistanceRSFormula);
lme_Disparity_by_Elevation_RS = local_try_fitlme(tbl, linearElevationRSFormula);

lme_logDisparity_by_logInverseDistanceXStereoGroup = [];
lme_logDisparity_by_logElevationXStereoGroup = [];
lme_Disparity_by_InverseDistanceXStereoGroup = [];
lme_Disparity_by_ElevationXStereoGroup = [];
if runStereoGroupInteractions
    lme_logDisparity_by_logInverseDistanceXStereoGroup = local_try_fitlme(tbl, logInverseDistanceStereoRIFormula);
    lme_logDisparity_by_logElevationXStereoGroup = local_try_fitlme(tbl, logElevationStereoRIFormula);
    lme_Disparity_by_InverseDistanceXStereoGroup = local_try_fitlme(tbl, linearDistanceStereoRIFormula);
    lme_Disparity_by_ElevationXStereoGroup = local_try_fitlme(tbl, linearElevationStereoRIFormula);
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

if saveLME
    savelmefile = fullfile(ResultsDir, ...
        [outputStem '_elevation_single_RI_RS.txt']);
    local_write_model_report(savelmefile, tbl, tblName, sourceCsv, ...
        modelTransform, linearElevationSource, stereoGroupSummaryLines, ...
        runStereoAnalysis, ...
        {lme_logDisparity_by_logInverseDistance, lme_logDisparity_by_logElevation, ...
        lme_logDisparity_by_logInverseDistance_RS, lme_logDisparity_by_logElevation_RS, ...
        lme_Disparity_by_InverseDistance, lme_Disparity_by_Elevation, ...
        lme_Disparity_by_InverseDistance_RS, lme_Disparity_by_Elevation_RS, ...
        lme_logDisparity_by_logInverseDistanceXStereoGroup, ...
        lme_logDisparity_by_logElevationXStereoGroup, ...
        lme_Disparity_by_InverseDistanceXStereoGroup, ...
        lme_Disparity_by_ElevationXStereoGroup}, ...
        {logInverseDistanceRIFormula, logElevationRIFormula, ...
        logInverseDistanceRSFormula, logElevationRSFormula, ...
        linearDistanceRIFormula, linearElevationRIFormula, ...
        linearDistanceRSFormula, linearElevationRSFormula, ...
        logInverseDistanceStereoRIFormula, logElevationStereoRIFormula, ...
        linearDistanceStereoRIFormula, linearElevationStereoRIFormula});
end

subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID);
minDisp = max(0.01, min(tbl.MeanDisparity));
maxDisp = max(tbl.MeanDisparity);
nIDs = numel(categories(removecats(tbl.ID)));

figRI = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .92 .72], 'Name', [outputStem '_log_RI'], 'Visible', 'off');
tRI = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tRI.Position = [0.14 0.12 0.65 0.64];
axRI1 = nexttile;
local_plot_fixed_only(axRI1, tbl, subjectcolor, lme_logDisparity_by_logInverseDistance, ...
    'D', minDisp, maxDisp, modelTransform, nIDs, true);
axRI2 = nexttile;
local_plot_fixed_only(axRI2, tbl, subjectcolor, lme_logDisparity_by_logElevation, ...
    'E', minDisp, maxDisp, modelTransform, nIDs, false, 'w');
local_add_subject_colorbar(figRI, mycolormap, nIDs, colorbarLabel, ...
    colorConfig, axRI2);
exportgraphics(figRI, fullfile(ResultsDir, [outputStem '_log_RI.png']), 'Resolution', 600);
close(figRI);

figRS = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .92 .72], 'Name', [outputStem '_log_RS'], 'Visible', 'off');
tRS = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tRS.Position = [0.14 0.12 0.65 0.64];
axRS1 = nexttile;
local_plot_random_slopes(axRS1, tbl, subjectcolor, ...
    lme_logDisparity_by_logInverseDistance_RS, 'D', minDisp, maxDisp, modelTransform, ...
    nIDs, fullUniqueID, mycolormap, sorted_idx, true, [], plotFixedEffectsRS);
axRS2 = nexttile;
local_plot_random_slopes(axRS2, tbl, subjectcolor, ...
    lme_logDisparity_by_logElevation_RS, 'E', minDisp, maxDisp, modelTransform, ...
    nIDs, fullUniqueID, mycolormap, sorted_idx, false, ...
    'w', plotFixedEffectsRS);
local_add_subject_colorbar(figRS, mycolormap, nIDs, colorbarLabel, ...
    colorConfig, axRS2);
exportgraphics(figRS, fullfile(ResultsDir, [outputStem '_log_RS.png']), 'Resolution', 600);
close(figRS);

figLinearRI = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .92 .72], 'Name', [outputStem '_linear_RI'], 'Visible', 'off');
tLinearRI = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tLinearRI.Position = [0.14 0.12 0.65 0.64];
axLinearRI1 = nexttile;
local_plot_linear_fixed_only(axLinearRI1, tbl, subjectcolor, ...
    lme_Disparity_by_InverseDistance, 'D', minDisp, maxDisp, modelTransform, nIDs, true);
axLinearRI2 = nexttile;
local_plot_linear_fixed_only(axLinearRI2, tbl, subjectcolor, ...
    lme_Disparity_by_Elevation, 'E', minDisp, maxDisp, modelTransform, nIDs, ...
    false, 'w');
local_add_subject_colorbar(figLinearRI, mycolormap, nIDs, colorbarLabel, ...
    colorConfig, axLinearRI2);
exportgraphics(figLinearRI, fullfile(ResultsDir, [outputStem '_linear_RI.png']), 'Resolution', 600);
close(figLinearRI);

figLinearRS = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .92 .72], 'Name', [outputStem '_linear_RS'], 'Visible', 'off');
tLinearRS = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tLinearRS.Position = [0.14 0.12 0.65 0.64];
axLinearRS1 = nexttile;
local_plot_linear_random_slopes(axLinearRS1, tbl, subjectcolor, ...
    lme_Disparity_by_InverseDistance_RS, 'D', minDisp, maxDisp, modelTransform, nIDs, ...
    fullUniqueID, mycolormap, sorted_idx, true, [], plotFixedEffectsRS);
axLinearRS2 = nexttile;
local_plot_linear_random_slopes(axLinearRS2, tbl, subjectcolor, ...
    lme_Disparity_by_Elevation_RS, 'E', minDisp, maxDisp, modelTransform, nIDs, ...
    fullUniqueID, mycolormap, sorted_idx, false, 'w', ...
    plotFixedEffectsRS);
local_add_subject_colorbar(figLinearRS, mycolormap, nIDs, colorbarLabel, ...
    colorConfig, axLinearRS2);
exportgraphics(figLinearRS, fullfile(ResultsDir, [outputStem '_linear_RS.png']), 'Resolution', 600);
close(figLinearRS);

if runStereoAnalysis
    local_plot_stereo_relationship_figure(tbl, lme_logDisparity_by_logInverseDistance_RS, ResultsDir, outputStem, ...
        fullUniqueID, mycolormap, sorted_idx, colorConfig);
end
end

function local_write_model_report(reportFile, tbl, tblName, sourceCsv, ...
    modelTransform, linearElevationSource, stereoGroupSummaryLines, ...
    runStereoAnalysis, models, formulas)
modelLabels = cellfun(@(f) ['Model: ' f], formulas, 'UniformOutput', false);
validModel = ~cellfun(@isempty, models);
if ~any(validModel)
    local_write_empty_report(reportFile, tblName, sourceCsv, formulas);
    return;
end

[comparisons, comparisonLabels] = local_model_comparisons(models, formulas);
if runStereoAnalysis
    [stereoComparisons, stereoLabels] = ...
        local_stereo_relationship_models(tbl, models{3});
    comparisons = [comparisons stereoComparisons];
    comparisonLabels = [comparisonLabels stereoLabels];
end

reportOpts = struct();
reportOpts.ReportTitle = sprintf('Quad Perceived Disparity Single-Factor LME Report: %s', ...
    char(string(tblName)));
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = sourceCsv;
reportOpts.ModelLabel = ['Single-factor interocular offset models by ' ...
    'inverse distance and elevation'];
baseSummaryLines = { ...
    sprintf('Experiment: Quad'), ...
    sprintf('Rows in model table: %d', height(tbl)), ...
    sprintf('Participants in model table: %d', numel(categories(removecats(tbl.ID)))), ...
    sprintf('LMEs fit successfully: %d of %d', nnz(validModel), numel(models)), ...
    sprintf('Elevation transform: %s', local_transform_label(modelTransform)), ...
    sprintf('Linear-model Elevation source: %s', linearElevationSource), ...
    sprintf('Fit method: ML'), ...
    sprintf('Log models use transformed elevation through log2elevation.'), ...
    sprintf('Linear models use MeanDisparity, inverseDistance, and transformed Elevation without log2 or +1 regularization.'), ...
    sprintf('Log-vs-linear fit-statistic tables are descriptive only; they are not likelihood-ratio tests because the response variable differs.')};
skippedModelLines = {};
if any(~validModel)
    skippedModelLines = [{'LMEs not fit:'}, ...
        cellfun(@(formula) sprintf('    %s', formula), formulas(~validModel), ...
        'UniformOutput', false)];
end
stereoInteractionNote = {};
if ~isempty(stereoGroupSummaryLines) && strcmp(stereoGroupSummaryLines{1}, 'StereoGroup counts:')
    stereoInteractionNote = {'StereoGroup interaction models are RI models only and are not plotted.'};
end
reportOpts.SummaryLines = [ ...
    baseSummaryLines, ...
    stereoInteractionNote, ...
    skippedModelLines, ...
    stereoGroupSummaryLines];
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
hasStereoGroupModels = numel(models) >= 12 && any(~cellfun(@isempty, models(9:12)));

[comparisonTbl, ok] = local_try_compare(models{1}, models{3});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{1}, formulas{3});
end

[comparisonTbl, ok] = local_try_compare(models{2}, models{4});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{2}, formulas{4});
end

[comparisonTbl, ok] = local_try_compare(models{5}, models{7});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{5}, formulas{7});
end

[comparisonTbl, ok] = local_try_compare(models{6}, models{8});
if ok
    comparisons{end + 1} = comparisonTbl;
    comparisonLabels{end + 1} = sprintf('Model comparison: %s vs %s', ...
        formulas{6}, formulas{8});
end

if hasStereoGroupModels
    [comparisonTbl, ok] = local_try_compare(models{1}, models{9});
    if ok
        comparisons{end + 1} = comparisonTbl;
        comparisonLabels{end + 1} = sprintf('StereoGroup RI interaction comparison: %s vs %s', ...
            formulas{1}, formulas{9});
    end

    [comparisonTbl, ok] = local_try_compare(models{2}, models{10});
    if ok
        comparisons{end + 1} = comparisonTbl;
        comparisonLabels{end + 1} = sprintf('StereoGroup RI interaction comparison: %s vs %s', ...
            formulas{2}, formulas{10});
    end

    [comparisonTbl, ok] = local_try_compare(models{5}, models{11});
    if ok
        comparisons{end + 1} = comparisonTbl;
        comparisonLabels{end + 1} = sprintf('StereoGroup RI interaction comparison: %s vs %s', ...
            formulas{5}, formulas{11});
    end

    [comparisonTbl, ok] = local_try_compare(models{6}, models{12});
    if ok
        comparisons{end + 1} = comparisonTbl;
        comparisonLabels{end + 1} = sprintf('StereoGroup RI interaction comparison: %s vs %s', ...
            formulas{6}, formulas{12});
    end
end

[fitStatsTbl, ok] = local_fit_stat_table( ...
    {models{1}, models{5}, models{2}, models{6}, models{3}, models{7}, models{4}, models{8}}, ...
    {formulas{1}, formulas{5}, formulas{2}, formulas{6}, formulas{3}, formulas{7}, formulas{4}, formulas{8}}, ...
    ["Log inverse distance RI"; "Linear inverse distance RI"; ...
    "Log elevation RI"; "Linear elevation RI"; ...
    "Log inverse distance RS"; "Linear inverse distance RS"; ...
    "Log elevation RS"; "Linear elevation RS"], ...
    ["log2mean_disparity"; "MeanDisparity"; ...
    "log2mean_disparity"; "MeanDisparity"; ...
    "log2mean_disparity"; "MeanDisparity"; ...
    "log2mean_disparity"; "MeanDisparity"]);
if ok
    comparisons{end + 1} = fitStatsTbl;
    comparisonLabels{end + 1} = ...
        'Log-vs-linear fit statistics: single-factor models (descriptive; not LRT)';
end

if hasStereoGroupModels
    [fitStatsTbl, ok] = local_fit_stat_table( ...
        {models{1}, models{9}, models{2}, models{10}, models{5}, models{11}, models{6}, models{12}}, ...
        {formulas{1}, formulas{9}, formulas{2}, formulas{10}, formulas{5}, formulas{11}, formulas{6}, formulas{12}}, ...
        ["Log inverse distance RI"; "Log inverse distance x StereoGroup RI"; ...
        "Log elevation RI"; "Log elevation x StereoGroup RI"; ...
        "Linear inverse distance RI"; "Linear inverse distance x StereoGroup RI"; ...
        "Linear elevation RI"; "Linear elevation x StereoGroup RI"], ...
        ["log2mean_disparity"; "log2mean_disparity"; ...
        "log2mean_disparity"; "log2mean_disparity"; ...
        "MeanDisparity"; "MeanDisparity"; ...
        "MeanDisparity"; "MeanDisparity"]);
    if ok
        comparisons{end + 1} = fitStatsTbl;
        comparisonLabels{end + 1} = ...
            'AIC/BIC summary: RI base and StereoGroup interaction models';
    end
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

function [stereoComparisons, stereoLabels] = local_stereo_relationship_models(tbl, lmeDistanceRS)
stereoComparisons = {};
stereoLabels = {};
stereoTbl = local_subject_distance_rs_table(tbl, lmeDistanceRS, [], [], []);
if isempty(stereoTbl)
    return;
end

scoreVarLabel = stereoTbl.Properties.UserData.StereoScoreVarName;
lmInterceptContinuous = fitlm(stereoTbl, 'SubjectIntercept ~ StereoScore');
lmSlopeContinuous = fitlm(stereoTbl, 'SubjectSlope ~ StereoScore');

stereoComparisons = {lmInterceptContinuous, lmSlopeContinuous};
stereoLabels = { ...
    sprintf('Stereo score analysis: SubjectIntercept ~ %s', scoreVarLabel), ...
    sprintf('Stereo score analysis: SubjectSlope ~ %s', scoreVarLabel)};
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

reportTitle = sprintf('Quad Perceived Disparity Single-Factor LME Report: %s', ...
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

function [tbl, linearElevationSource] = local_set_linear_elevation(tbl)
linearElevationSource = 'transformed ElevationModel - 1';
if ismember('ElevationModel', tbl.Properties.VariableNames)
    tbl.Elevation = double(tbl.ElevationModel) - 1;
else
    tbl.Elevation = double(tbl.Elevation);
    linearElevationSource = 'Elevation fallback';
end
end

function [tbl, stereoGroupSummaryLines, runStereoGroupInteractions] = local_prepare_stereo_group(tbl)
stereoGroupSummaryLines = {'StereoGroup interaction models: skipped (StereoGroup variable not found).'};
runStereoGroupInteractions = false;
if ~ismember('StereoGroup', tbl.Properties.VariableNames)
    return;
end

tbl.StereoGroup = local_stereo_group_categorical(tbl.StereoGroup);
validStereoGroup = ~isundefined(tbl.StereoGroup);
if ~all(validStereoGroup)
    tbl = tbl(validStereoGroup, :);
end
tbl.StereoGroup = removecats(tbl.StereoGroup);

groupNames = string(categories(tbl.StereoGroup));
if numel(groupNames) < 2
    stereoGroupSummaryLines = {'StereoGroup interaction models: skipped (fewer than two valid groups).'};
    return;
end

stereoGroupSummaryLines = local_group_summary_lines(tbl);
runStereoGroupInteractions = true;
end

function stereoGroup = local_stereo_group_categorical(rawGroup)
if isnumeric(rawGroup) || islogical(rawGroup)
    groupValues = double(rawGroup);
    groupText = strings(size(groupValues));
    groupText(~isfinite(groupValues)) = "";
    if all(ismember(unique(groupValues(isfinite(groupValues))), [0 1 2 3]))
        groupText(groupValues == 1) = "StereoTypical";
        groupText(groupValues == 2) = "StereoDeficient";
        groupText(groupValues == 3) = "StereoBlind";
    else
        validRows = isfinite(groupValues);
        groupText(validRows) = "Group" + string(groupValues(validRows));
    end
    stereoGroup = categorical(groupText);
elseif iscategorical(rawGroup)
    stereoGroup = rawGroup;
else
    stereoGroup = categorical(strtrim(string(rawGroup)));
end
stereoGroup = local_standardize_numeric_group_labels(stereoGroup);
stereoGroup = reordercats(stereoGroup, local_order_categories(categories(stereoGroup)));
end

function stereoGroup = local_standardize_numeric_group_labels(stereoGroup)
groupText = string(stereoGroup);
validText = groupText(~ismissing(groupText) & groupText ~= "");
if ~isempty(validText) && all(ismember(validText, ["1", "2", "3"]))
    groupText(groupText == "1") = "StereoTypical";
    groupText(groupText == "2") = "StereoDeficient";
    groupText(groupText == "3") = "StereoBlind";
    stereoGroup = categorical(groupText);
end
end

function orderedCategories = local_order_categories(categoriesIn)
categoriesIn = string(categoriesIn(:));
preferred = ["StereoTypical"; "Typical"; "StereoDeficient"; "Deficient"; ...
    "StereoBlind"; "Blind"];
orderedCategories = strings(0, 1);
for iPreferred = 1:numel(preferred)
    if any(categoriesIn == preferred(iPreferred))
        orderedCategories(end + 1, 1) = preferred(iPreferred); %#ok<AGROW>
    end
end
for iCategory = 1:numel(categoriesIn)
    if ~ismember(categoriesIn(iCategory), orderedCategories)
        orderedCategories(end + 1, 1) = categoriesIn(iCategory); %#ok<AGROW>
    end
end
orderedCategories = cellstr(orderedCategories);
end

function groupSummaryLines = local_group_summary_lines(tbl)
groupNames = string(categories(tbl.StereoGroup));
groupSummaryLines = cell(1, numel(groupNames) + 1);
groupSummaryLines{1} = 'StereoGroup counts:';
for iGroup = 1:numel(groupNames)
    rowMask = string(tbl.StereoGroup) == groupNames(iGroup);
    groupSummaryLines{iGroup + 1} = sprintf('  %s: %d rows, %d participants', ...
        groupNames(iGroup), sum(rowMask), numel(unique(tbl.ID(rowMask))));
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

function local_plot_fixed_only(ax, tbl, subjectcolor, lme, modeChar, minDisp, maxDisp, modelTransform, nIDs, showYLabel, hiddenYAxisColor)
if nargin < 9 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 11 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
hold(ax, 'on');
[x, xlog, xlabelText, tickVals, titleFormula] = local_axis_setup(tbl, modeChar, modelTransform);
y = tbl.log2mean_disparity;

if isempty(lme)
    scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
    local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
    title(ax, {'Model unavailable','rank-deficient or singular'}, 'FontSize', 16, 'FontWeight', 'normal');
    return;
end

xlinerange = linspace(min(xlog), max(xlog), 200);
b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);
pval = lme.Coefficients.pValue(2);
if isfinite(pval) && pval < 0.05
    ciL0 = lme.Coefficients.Lower(1);
    ciL1 = lme.Coefficients.Lower(2);
    ciU0 = lme.Coefficients.Upper(1);
    ciU1 = lme.Coefficients.Upper(2);

    yFit = b0 + b1 * xlinerange;
    xvector = [xlinerange fliplr(xlinerange)];
    yvector = [ciL0 + ciL1 * xlinerange fliplr(ciU0 + ciU1 * xlinerange)];
    fill(ax, xvector, yvector, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);
    plot(ax, xlinerange, yFit, 'k-', 'LineWidth', 5);
end
scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);

local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
displayExponent = b1;
if modeChar == 'D'
    displayExponent = -b1;
end
titleStr = sprintf(titleFormula, local_format_number(2.^b0), local_format_number(displayExponent), local_format_pvalue(pval), nIDs);
title(ax, titleStr, 'FontSize', 15, 'FontWeight', 'normal', 'Units', 'normalized', 'Position', [0.5 1.01 0]);
end

function local_plot_random_slopes(ax, tbl, subjectcolor, lme, modeChar, minDisp, maxDisp, modelTransform, nIDs, fullUniqueID, mycolormap, sorted_idx, showYLabel, hiddenYAxisColor, plotFixedEffectsRS)
if nargin < 13 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 14 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
if nargin < 15 || isempty(plotFixedEffectsRS)
    plotFixedEffectsRS = false;
end
hold(ax, 'on');
[x, xlog, xlabelText, tickVals, titleFormula] = local_axis_setup(tbl, modeChar, modelTransform);
y = tbl.log2mean_disparity;

if isempty(lme)
    scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);
    local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
    title(ax, {'Model unavailable','rank-deficient or singular'}, 'FontSize', 16, 'FontWeight', 'normal');
    return;
end

local_plot_subject_lines(ax, tbl, lme, modeChar, fullUniqueID, mycolormap, sorted_idx);

xlinerange = linspace(min(xlog), max(xlog), 200);
b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);
pval = lme.Coefficients.pValue(2);

if plotFixedEffectsRS && isfinite(pval) && pval < 0.05
    yFit = b0 + b1 * xlinerange;
    plot(ax, xlinerange, yFit, 'k-', 'LineWidth', 5);
end
scatter_by_measurement(ax, xlog, y, subjectcolor, tbl.Measurement);

local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor);
displayExponent = b1;
if modeChar == 'D'
    displayExponent = -b1;
end
titleStr = sprintf(titleFormula, local_format_number(2.^b0), local_format_number(displayExponent), local_format_pvalue(pval), nIDs);
title(ax, titleStr, 'FontSize', 15, 'FontWeight', 'normal', 'Units', 'normalized', 'Position', [0.5 1.01 0]);
end

function local_plot_linear_fixed_only(ax, tbl, subjectcolor, lme, modeChar, minDisp, maxDisp, modelTransform, nIDs, showYLabel, hiddenYAxisColor)
if nargin < 9 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 11 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end

hold(ax, 'on');
[x, xlabelText, predictorSymbol] = local_linear_axis_setup(tbl, modeChar, modelTransform);
y = tbl.MeanDisparity;

if isempty(lme)
    scatter_by_measurement(ax, x, y, subjectcolor, tbl.Measurement);
    local_finish_linear_axes(ax, xlabelText, minDisp, maxDisp, x, ...
        modeChar, showYLabel, hiddenYAxisColor);
    title(ax, {'Linear model unavailable','rank-deficient or singular'}, 'FontSize', 16, 'FontWeight', 'normal');
    return;
end

xlinerange = linspace(min(x), max(x), 200);
pval = lme.Coefficients.pValue(2);
if isfinite(pval) && pval < 0.05
    local_fill_linear_fixed_ci(ax, xlinerange, lme);
    local_plot_linear_fixed_line(ax, xlinerange, lme);
end
scatter_by_measurement(ax, x, y, subjectcolor, tbl.Measurement);

local_finish_linear_axes(ax, xlabelText, minDisp, maxDisp, x, ...
    modeChar, showYLabel, hiddenYAxisColor);
titleStr = local_linear_title(lme, predictorSymbol, nIDs);
title(ax, titleStr, 'FontSize', 15, 'FontWeight', 'normal', 'Units', 'normalized', 'Position', [0.5 1.01 0]);
end

function local_plot_linear_random_slopes(ax, tbl, subjectcolor, lme, modeChar, minDisp, maxDisp, modelTransform, nIDs, fullUniqueID, mycolormap, sorted_idx, showYLabel, hiddenYAxisColor, plotFixedEffectsRS)
if nargin < 13 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 14 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
if nargin < 15 || isempty(plotFixedEffectsRS)
    plotFixedEffectsRS = false;
end

hold(ax, 'on');
[x, xlabelText, predictorSymbol] = local_linear_axis_setup(tbl, modeChar, modelTransform);
y = tbl.MeanDisparity;

if isempty(lme)
    scatter_by_measurement(ax, x, y, subjectcolor, tbl.Measurement);
    local_finish_linear_axes(ax, xlabelText, minDisp, maxDisp, x, ...
        modeChar, showYLabel, hiddenYAxisColor);
    title(ax, {'Linear model unavailable','rank-deficient or singular'}, 'FontSize', 16, 'FontWeight', 'normal');
    return;
end

local_plot_linear_subject_lines(ax, tbl, lme, modeChar, fullUniqueID, mycolormap, sorted_idx);
pval = lme.Coefficients.pValue(2);
if plotFixedEffectsRS && isfinite(pval) && pval < 0.05
    xlinerange = linspace(min(x), max(x), 200);
    local_plot_linear_fixed_line(ax, xlinerange, lme);
end

scatter_by_measurement(ax, x, y, subjectcolor, tbl.Measurement);

local_finish_linear_axes(ax, xlabelText, minDisp, maxDisp, x, ...
    modeChar, showYLabel, hiddenYAxisColor);
titleStr = local_linear_title(lme, predictorSymbol, nIDs);
title(ax, titleStr, 'FontSize', 15, 'FontWeight', 'normal', 'Units', 'normalized', 'Position', [0.5 1.01 0]);
end

function outputStem = local_output_stem(tblName)
outputStem = regexprep(char(string(tblName)), ...
    '(?i)([_-]?version[_-]?\d+|[_-]?version)', '');
outputStem = regexprep(outputStem, '[_-]{2,}', '_');
outputStem = regexprep(outputStem, '^[_-]+|[_-]+$', '');
end

function local_fill_linear_fixed_ci(ax, xlinerange, lme)
if size(lme.Coefficients, 1) < 2
    return;
end

ciL0 = lme.Coefficients.Lower(1);
ciL1 = lme.Coefficients.Lower(2);
ciU0 = lme.Coefficients.Upper(1);
ciU1 = lme.Coefficients.Upper(2);

yA = ciL0 + ciL1 * xlinerange;
yB = ciU0 + ciU1 * xlinerange;
yLow = min(yA, yB);
yHigh = max(yA, yB);
fill(ax, [xlinerange fliplr(xlinerange)], [yLow fliplr(yHigh)], ...
    'k', 'EdgeColor', 'none', 'FaceAlpha', 0.20);
end

function local_plot_linear_fixed_line(ax, xlinerange, lme)
if size(lme.Coefficients, 1) < 2
    return;
end

b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);
plot(ax, xlinerange, b0 + b1 * xlinerange, 'k-', 'LineWidth', 5);
end

function local_plot_linear_subject_lines(ax, tbl, lme, modeChar, fullUniqueID, mycolormap, sorted_idx)
[reEfx, reNames] = randomEffects(lme);
levels = string(reNames.Level);
names = string(reNames.Name);

if isempty(fullUniqueID)
    uniqueID = string(categories(removecats(tbl.ID)));
else
    uniqueID = string(fullUniqueID(:));
end

if modeChar == 'D'
    slopeName = "inverseDistance";
    xAll = tbl.inverseDistance;
else
    slopeName = "Elevation";
    xAll = tbl.Elevation;
end

plotOrder = local_subject_stereo_score_plot_order(tbl, uniqueID);
for orderIdx = 1:numel(plotOrder)
    i = plotOrder(orderIdx);
    subj = uniqueID(i);
    rowMask = string(tbl.ID) == subj;
    if ~any(rowMask)
        continue;
    end

    cindex = find(strcmp(uniqueID, subj), 1, 'first');
    colorRow = local_lookup_color_row(sorted_idx, cindex, numel(uniqueID), size(mycolormap, 1));
    thisColor = mycolormap(colorRow,:);

    reIntercept = 0;
    reSlope = 0;
    idxIntercept = find(levels == subj & names == "(Intercept)", 1, 'first');
    idxSlope = find(levels == subj & names == slopeName, 1, 'first');
    if ~isempty(idxIntercept)
        reIntercept = reEfx(idxIntercept);
    end
    if ~isempty(idxSlope)
        reSlope = reEfx(idxSlope);
    end

    xSub = xAll(rowMask);
    xgrid = linspace(min(xSub), max(xSub), 50);
    ySubFit = (lme.Coefficients.Estimate(1) + reIntercept) + ...
        (lme.Coefficients.Estimate(2) + reSlope) * xgrid;
    plot(ax, xgrid, ySubFit, '-', 'Color', thisColor, 'LineWidth', 3);
end
end

function [x, xlabelText, predictorSymbol] = local_linear_axis_setup(tbl, modeChar, modelTransform)
switch modeChar
    case 'D'
        x = tbl.inverseDistance;
        xlabelText = {'1/Distance [m^{-1}]','linear scale'};
        predictorSymbol = '1/Distance';
    otherwise
        x = tbl.Elevation;
        predictorSymbol = 'E';
        if modelTransform == 2
            xlabelText = {'|Elevation| [deg]','linear scale'};
        elseif modelTransform == 6
            xlabelText = {'|Elevation|/90','linear scale'};
        else
            xlabelText = {'Elevation/90','linear scale'};
        end
end
end

function local_finish_linear_axes(ax, xlabelText, minDisp, maxDisp, x, modeChar, showYLabel, hiddenYAxisColor)
if nargin < 7 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 8 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end

set(ax, 'FontName', 'Avenir', 'FontSize', 18);
xlabel(ax, xlabelText, 'FontSize', 22);
if showYLabel
    ylabel(ax, {'Perceived Disparity [deg]','linear scale'}, 'FontSize', 22);
else
    ylabel(ax, '');
    ax.YColor = hiddenYAxisColor;
end
if modeChar == 'D'
    [inverseDistanceLimits, inverseDistanceTicks] = ...
        local_inverse_distance_axis(x);
    xlim(ax, inverseDistanceLimits);
    xticks(ax, inverseDistanceTicks);
else
    xlim(ax, local_expand_linear_limits(x));
end
ylim(ax, local_expand_linear_limits([minDisp maxDisp]));
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
normalizedStep = targetStep / scale;
if normalizedStep <= 1
    niceStep = 1 * scale;
elseif normalizedStep <= 2
    niceStep = 2 * scale;
elseif normalizedStep <= 2.5
    niceStep = 2.5 * scale;
elseif normalizedStep <= 5
    niceStep = 5 * scale;
else
    niceStep = 10 * scale;
end

upperLimit = ceil(max(x) / niceStep) * niceStep;
limits = [0 upperLimit];
ticks = 0:niceStep:upperLimit;
end

function lims = local_expand_linear_limits(x)
x = double(x(:));
x = x(isfinite(x));
if isempty(x)
    lims = [0 1];
    return;
end

xmin = min(x);
xmax = max(x);
span = xmax - xmin;
if span <= 0
    pad = max(0.05 * max(abs(xmin), 1), 0.05);
else
    pad = max(0.05 * span, 0.05);
end
lims = [xmin - pad xmax + pad];
end

function titleStr = local_linear_title(lme, predictorSymbol, nIDs)
b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);
pval = lme.Coefficients.pValue(2);
if strcmp(predictorSymbol, '1/Distance')
    if b1 < 0
        termText = [' - ' local_format_number(abs(b1)) '/Distance'];
    else
        termText = [' + ' local_format_number(b1) '/Distance'];
    end
    titleStr = sprintf('Perceived Disparity=%s%s\n p=%s\n n=%d', ...
        local_format_number(b0), termText, local_format_pvalue(pval), nIDs);
else
    titleStr = sprintf('Perceived Disparity=%s%s%s\n p=%s\n n=%d', ...
        local_format_number(b0), local_format_signed_slope(b1), ...
        predictorSymbol, local_format_pvalue(pval), nIDs);
end
end

function slopeStr = local_format_signed_slope(val)
if val < 0
    slopeStr = [' - ' local_format_number(abs(val)) '*'];
else
    slopeStr = [' + ' local_format_number(val) '*'];
end
end

function local_plot_subject_lines(ax, tbl, lme, modeChar, fullUniqueID, mycolormap, sorted_idx)
[reEfx, reNames] = randomEffects(lme);
levels = string(reNames.Level);
names = string(reNames.Name);

if isempty(fullUniqueID)
    uniqueID = string(categories(removecats(tbl.ID)));
else
    uniqueID = string(fullUniqueID(:));
end

switch modeChar
    case 'A'
        slopeName = "log2real_visual_angle";
        xAll = tbl.log2real_visual_angle;
    case 'D'
        slopeName = "log2inverseDistance";
        xAll = tbl.log2inverseDistance;
    otherwise
        slopeName = "log2elevation";
        xAll = tbl.log2elevation;
end

plotOrder = local_subject_stereo_score_plot_order(tbl, uniqueID);
for orderIdx = 1:numel(plotOrder)
    i = plotOrder(orderIdx);
    subj = uniqueID(i);
    rowMask = string(tbl.ID) == subj;
    if ~any(rowMask)
        continue;
    end

    cindex = find(strcmp(uniqueID, subj), 1, 'first');
    colorRow = local_lookup_color_row(sorted_idx, cindex, numel(uniqueID), size(mycolormap, 1));
    thisColor = mycolormap(colorRow,:);

    reIntercept = 0;
    reSlope = 0;
    idxIntercept = find(levels == subj & names == "(Intercept)", 1, 'first');
    idxSlope = find(levels == subj & names == slopeName, 1, 'first');
    if ~isempty(idxIntercept)
        reIntercept = reEfx(idxIntercept);
    end
    if ~isempty(idxSlope)
        reSlope = reEfx(idxSlope);
    end

    xSub = xAll(rowMask);
    xgrid = linspace(min(xSub), max(xSub), 50);
    ySubFit = (lme.Coefficients.Estimate(1) + reIntercept) + (lme.Coefficients.Estimate(2) + reSlope) * xgrid;
    plot(ax, xgrid, ySubFit, '-', 'Color', thisColor, 'LineWidth', 3);
end
end

function plotOrder = local_subject_stereo_score_plot_order(tbl, uniqueID)
plotOrder = 1:numel(uniqueID);
stereoVar = local_find_first_var(tbl, ...
    {'ContinuousStereoScore', 'ContinousStereoScore', 'ContiousStereoScores', ...
    'ContinuousScore', 'ContinousScore', 'NormedStereoScore', 'NormedScore'});
if isempty(stereoVar)
    return;
end

scoreByID = nan(numel(uniqueID), 1);
for iID = 1:numel(uniqueID)
    rowMask = string(tbl.ID) == uniqueID(iID);
    scoreByID(iID) = mean(double(tbl.(stereoVar)(rowMask)), 'omitnan');
end

scoreForSort = scoreByID;
scoreForSort(isnan(scoreForSort)) = inf;
[~, plotOrder] = sort(scoreForSort, 'descend');
end

function [x, xlog, xlabelText, tickVals, titleFormula] = local_axis_setup(tbl, modeChar, modelTransform)
switch modeChar
    case 'A'
        x = tbl.Real_Visual_Angle;
        xlog = tbl.log2real_visual_angle;
        xlabelText = {'Real VA [deg]','log scale'};
        tickVals = local_visual_angle_ticks(min(x), max(x));
        titleFormula = 'Perceived Disparity=%s(VA)^{%s}\n p=%s\n n=%d';
    case 'D'
        x = tbl.inverseDistance;
        xlog = tbl.log2inverseDistance;
        xlabelText = {'1/Distance [m^{-1}]','log scale'};
        tickVals = local_log_ticks(min(x), max(x), false);
        titleFormula = 'Perceived Disparity=%s(Distance)^{%s}\n p=%s\n n=%d';
    otherwise
        x = tbl.ElevationModel;
        xlog = tbl.log2elevation;
        if modelTransform == 2
            xlabelText = {'|Elevation| [deg]','log scale'};
            titleFormula = 'Perceived Disparity=%s(1+|E|)^{%s}\n p=%s\n n=%d';
        elseif modelTransform == 6
            xlabelText = {'|Elevation| [deg]','log scale'};
            titleFormula = 'Perceived Disparity=%s(1+|E|/90)^{%s}\n p=%s\n n=%d';
        else
            xlabelText = {'Elevation [deg]','log scale'};
            titleFormula = 'Perceived Disparity=%s(1+E/90)^{%s}\n p=%s\n n=%d';
        end
        tickVals = local_log_ticks(min(x), max(x), true, modelTransform);
end
end

function local_finish_axes(ax, tickVals, xlabelText, minDisp, maxDisp, x, showYLabel, hiddenYAxisColor)
if nargin < 7 || isempty(showYLabel)
    showYLabel = true;
end
if nargin < 8 || isempty(hiddenYAxisColor)
    hiddenYAxisColor = 'w';
end
set(ax, 'XTick', tickVals.positions, 'XTickLabel', tickVals.labels, ...
    'YTick', floor(log2(minDisp)):ceil(log2(maxDisp)), ...
    'YTickLabel', string(2.^(floor(log2(minDisp)):ceil(log2(maxDisp)))), ...
    'FontName', 'Avenir', 'FontSize', 18);
xlabel(ax, xlabelText, 'FontSize', 22);
if showYLabel
    ylabel(ax, {'Perceived Disparity [deg]','log scale'}, 'FontSize', 22);
else
    ylabel(ax, '');
    ax.YColor = hiddenYAxisColor;
end
xlim(ax, local_expand_log_limits(x));
ylim(ax, [floor(log2(minDisp)) ceil(log2(maxDisp))]);
box(ax, 'off');
grid(ax, 'off');
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

function pStr = local_format_pvalue(pval)
if pval >= 0.01
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

function lme = local_try_fitlme(tbl, formulaStr)
try
    lme = fitlme(tbl, formulaStr);
catch ME
    fprintf('Skipping model: %s\n Reason: %s\n', formulaStr, ME.message);
    lme = [];
end
end

function local_plot_stereo_relationship_figure(tbl, lmeDistanceRS, ...
    ResultsDir, tblName, fullUniqueID, mycolormap, sorted_idx, colorConfig)
stereoTbl = local_subject_distance_rs_table(tbl, lmeDistanceRS, fullUniqueID, mycolormap, sorted_idx);
if isempty(stereoTbl)
    return;
end

scoreVarLabel = stereoTbl.Properties.UserData.StereoScoreVarName;
x = stereoTbl.StereoScore;
xLabel = char(scoreVarLabel);
figSuffix = ['_' char(scoreVarLabel) '.png'];
fitFormulaIntercept = 'SubjectIntercept ~ StereoScore';
fitFormulaSlope = 'SubjectSlope ~ StereoScore';

lmIntercept = fitlm(stereoTbl, fitFormulaIntercept);
lmSlope = fitlm(stereoTbl, fitFormulaSlope);

figStereo = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0 0 .8 .6], ...
    'Name', [tblName figSuffix], 'Visible', 'off');
tStereo = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
tStereo.Position = [0.08 0.14 0.70 0.72];

ax1 = nexttile;
local_plot_stereo_relationship_panel(ax1, x, stereoTbl.SubjectIntercept, stereoTbl.SubjectColor, ...
    xLabel, 'Subject intercept', lmIntercept);

ax2 = nexttile;
local_plot_stereo_relationship_panel(ax2, x, stereoTbl.SubjectSlope, stereoTbl.SubjectColor, ...
    xLabel, 'Subject slope', lmSlope);

local_add_subject_colorbar(figStereo, mycolormap, numel(stereoTbl.ID), ...
    xLabel, colorConfig, ax2);
exportgraphics(figStereo, fullfile(ResultsDir, [tblName figSuffix]), 'Resolution', 600);
close(figStereo);
end

function local_plot_stereo_relationship_panel(ax, x, y, colors, xLabel, yLabel, lm)
hold(ax, 'on');
markerSize=50;
scatter(ax, x, y, markerSize, colors, 'filled', 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', 'none');

pSlope = lm.Coefficients.pValue(2);
if pSlope < 0.05
    xGrid = linspace(min(x), max(x), 200)';
    [yPred, yCI] = predict(lm, ...
        table(xGrid, 'VariableNames', lm.PredictorNames(1)), 'Alpha', 0.05);
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], 'k', ...
        'FaceAlpha', 0.18, 'EdgeColor', 'none');
    plot(ax, xGrid, yPred, ':', 'Color',[.6 .6 .6] ,'LineWidth', 5);
end

set(ax, 'FontName', 'Avenir', 'FontSize', 18);
xlabel(ax, xLabel, 'FontSize', 20);
ylabel(ax, yLabel, 'FontSize', 20);
box(ax, 'off');
grid(ax, 'off');
title(ax, sprintf('%s \n p=%s, slope=%s', yLabel, ...
    local_format_pvalue(pSlope), local_format_number(lm.Coefficients.Estimate(2))), ...
    'FontSize', 16, 'FontWeight', 'normal');
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

if isstruct(colorConfig) && string(colorConfig.Mode) == "clinicalnotes"
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
else
    nColorLevels = min(size(mycolormap, 1), max(1, nIDs));
    displayCmap = mycolormap(1:nColorLevels, :);
end

cbAx = axes('Parent', figHandle, 'Position', [0.86 0.22 0.010 0.52]);
set(cbAx, 'Visible', 'off', 'YDir', 'normal', 'CLim', [1 nColorLevels], ...
    'Color', 'none', 'XColor', 'none', 'YColor', 'none');
colormap(cbAx, displayCmap);

cb = colorbar(cbAx, 'Position', [0.885 0.22 0.012 0.52]);
cb.FontName = 'Avenir';
cb.FontSize = 12;
if isNormedStereoBar
    stereoTickVals = 0:20:100;
    cb.Ticks = 1 + (stereoTickVals ./ 100) * (nColorLevels - 1);
    cb.TickLabels = string(stereoTickVals);
elseif isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
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

function stereoTbl = local_subject_distance_rs_table(tbl, lmeDistanceRS, fullUniqueID, mycolormap, sorted_idx)
if nargin < 3
    fullUniqueID = [];
end
if nargin < 4
    mycolormap = [];
end
if nargin < 5
    sorted_idx = [];
end

if isempty(lmeDistanceRS)
    stereoTbl = [];
    return;
end

stereoVar = local_find_first_var(tbl, {'ContinuousStereoScore', 'ContinousStereoScore', 'ContiousStereoScores', 'ContinuousScore', 'ContinousScore', 'NormedStereoScore', 'NormedScore'});
if isempty(stereoVar)
    stereoTbl = [];
    return;
end

[reEfx, reNames] = randomEffects(lmeDistanceRS);
levels = string(reNames.Level);
names = string(reNames.Name);
fixedIntercept = lmeDistanceRS.Coefficients.Estimate(1);
fixedSlope = lmeDistanceRS.Coefficients.Estimate(2);

subjectCats = categories(removecats(tbl.ID));
nSubjects = numel(subjectCats);
subjectID = strings(nSubjects, 1);
subjectIntercept = nan(nSubjects, 1);
subjectSlope = nan(nSubjects, 1);
stereoScore = nan(nSubjects, 1);

for i = 1:nSubjects
    subj = string(subjectCats{i});
    rowMask = string(tbl.ID) == subj;
    subjectID(i) = subj;
    stereoScore(i) = mean(double(tbl.(stereoVar)(rowMask)), 'omitnan');

    idxIntercept = find(levels == subj & names == "(Intercept)", 1, 'first');
    idxSlope = find(levels == subj & names == "log2inverseDistance", 1, 'first');

    reIntercept = 0;
    reSlope = 0;
    if ~isempty(idxIntercept)
        reIntercept = reEfx(idxIntercept);
    end
    if ~isempty(idxSlope)
        reSlope = reEfx(idxSlope);
    end

    subjectIntercept(i) = fixedIntercept + reIntercept;
    subjectSlope(i) = fixedSlope + reSlope;
end

validRows = ~isnan(stereoScore) & ~isnan(subjectIntercept) & ~isnan(subjectSlope);

subjectID = subjectID(validRows);
subjectIntercept = subjectIntercept(validRows);
subjectSlope = subjectSlope(validRows);
stereoScore = stereoScore(validRows);

if isempty(mycolormap) || isempty(sorted_idx)
    subjectColor = repmat([0 0 0], numel(subjectID), 1);
else
    subjectColor = local_colors_for_subject_ids(subjectID, fullUniqueID, mycolormap, sorted_idx);
end
stereoTbl = table(subjectID, subjectIntercept, subjectSlope, stereoScore, ...
    subjectColor, ...
    'VariableNames', {'ID', 'SubjectIntercept', 'SubjectSlope', 'StereoScore', 'SubjectColor'});
stereoTbl.Properties.UserData.StereoScoreVarName = string(stereoVar);
end

function varName = local_find_first_var(tbl, candidates)
varName = '';
for i = 1:numel(candidates)
    if ismember(candidates{i}, tbl.Properties.VariableNames)
        varName = candidates{i};
        return;
    end
end
end

function subjectColor = local_colors_for_subject_ids(subjectID, fullUniqueID, mycolormap, sorted_idx)
if isempty(fullUniqueID)
    uniqueID = subjectID(:);
else
    uniqueID = string(fullUniqueID(:));
end

subjectColor = zeros(numel(subjectID), 3);
for i = 1:numel(subjectID)
    cindex = find(strcmp(uniqueID, subjectID(i)), 1, 'first');
    if isempty(cindex)
        cindex = i;
    end
    colorRow = local_lookup_color_row(sorted_idx, cindex, numel(uniqueID), size(mycolormap, 1));
    subjectColor(i, :) = mycolormap(colorRow, :);
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
