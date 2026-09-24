function [models, figHandle, reportFile, plotTbl] = Combined_InterocularOffsetVE(offsetData, tblName, ResultsDir, saveLME)
% Combined_InterocularOffsetVE
%
% Fit and plot combined Moon/Quad interocular-offset models as a function
% of elevation.
%
% Inputs
%   offsetData : table or CSV path with ID, InterocularOffset, Elevation
%   tblName    : output/report base name
%   ResultsDir : output directory
%   saveLME    : write the LME text report
%
% Models
%   1. InterocularOffset ~ Elevation + (1|ID)
%   2. InterocularOffset ~ Elevation + (Elevation|ID)
%   3. logInterocularOffset ~ logAbsElevation + (1|ID)
%   4. logInterocularOffset ~ logAbsElevation + (logAbsElevation|ID)
%
% The plotted participant order is sorted by mean InterocularOffset.

if nargin < 2 || isempty(tblName)
    tblName = 'combined_interocular_offset';
end
if nargin < 3 || isempty(ResultsDir)
    ResultsDir = pwd;
end
if nargin < 4 || isempty(saveLME)
    saveLME = true;
end

[plotTbl, sourceCsv] = local_prepare_table(offsetData);
if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

models = struct();
models.linearRI = local_fit_lme(plotTbl, ...
    'InterocularOffset ~ Elevation + (1|ID)', ...
    'linear offset by elevation RI');
models.linearRS = local_fit_lme(plotTbl, ...
    'InterocularOffset ~ Elevation + (Elevation|ID)', ...
    'linear offset by elevation RS');
models.linearRIvsRS = local_compare_lmes(models.linearRI, models.linearRS);

models.logRI = local_fit_lme(plotTbl, ...
    'logInterocularOffset ~ logAbsElevation + (1|ID)', ...
    'log offset by log absolute elevation RI');
models.logRS = local_fit_lme(plotTbl, ...
    'logInterocularOffset ~ logAbsElevation + (logAbsElevation|ID)', ...
    'log offset by log absolute elevation RS');
models.logRIvsRS = local_compare_lmes(models.logRI, models.logRS);

[rowColors, sortedIDs, idCmap] = local_id_colors(plotTbl);

figHandle = figure('Color', [1 1 1], 'Units', 'normalized', ...
    'Position', [0 0 .95 .85], 'Name', [char(string(tblName)) '_offset_by_elevation_4models']);
tiledlayout(figHandle, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
local_plot_ri_panel(ax1, plotTbl, rowColors, models.linearRI, ...
    'Elevation', 'InterocularOffset', 'InterocularOffset ~ Elevation + (1|ID)', ...
    'Elevation [deg]', 'Interocular Offset [deg]', false);

ax2 = nexttile;
local_plot_rs_panel(ax2, plotTbl, rowColors, sortedIDs, idCmap, models.linearRS, ...
    'Elevation', 'InterocularOffset', 'InterocularOffset ~ Elevation + (Elevation|ID)', ...
    'Elevation [deg]', 'Interocular Offset [deg]', false);

ax3 = nexttile;
local_plot_ri_panel(ax3, plotTbl, rowColors, models.logRI, ...
    'logAbsElevation', 'logInterocularOffset', ...
    'log Offset ~ log(1+|Elevation|) + (1|ID)', ...
    'log_2(1+|Elevation|)', 'log_2(Interocular Offset)', true);

ax4 = nexttile;
local_plot_rs_panel(ax4, plotTbl, rowColors, sortedIDs, idCmap, models.logRS, ...
    'logAbsElevation', 'logInterocularOffset', ...
    'log Offset ~ log(1+|Elevation|) + (log(1+|Elevation|)|ID)', ...
    'log_2(1+|Elevation|)', 'log_2(Interocular Offset)', true);

exportgraphics(figHandle, fullfile(ResultsDir, [char(string(tblName)) '_offset_by_elevation_4models.png']), ...
    'Resolution', 600);

reportFile = fullfile(ResultsDir, [char(string(tblName)) '_offset_by_elevation_4models.txt']);
if saveLME
    local_write_report(reportFile, models, plotTbl, sourceCsv);
end
end

function [tbl, sourceCsv] = local_prepare_table(offsetData)
if istable(offsetData)
    tbl = offsetData;
    sourceCsv = '<table input>';
else
    sourceCsv = char(string(offsetData));
    tbl = readtable(sourceCsv, 'VariableNamingRule', 'modify');
end

required = {'ID','InterocularOffset','Elevation'};
missing = required(~ismember(required, tbl.Properties.VariableNames));
if ~isempty(missing)
    error('Combined_InterocularOffsetVE:MissingVars', ...
        'Missing required variable(s): %s', strjoin(missing, ', '));
end

tbl.InterocularOffset = double(tbl.InterocularOffset);
tbl.Elevation = double(tbl.Elevation);
keep = isfinite(tbl.InterocularOffset) & tbl.InterocularOffset > 0 & ...
    isfinite(tbl.Elevation);
tbl = tbl(keep, :);

tbl.logInterocularOffset = log2(tbl.InterocularOffset);
tbl.logAbsElevation = log2(1 + abs(tbl.Elevation));
if ~iscategorical(tbl.ID)
    tbl.ID = categorical(string(tbl.ID));
end
end

function lme = local_fit_lme(tbl, formula, label)
try
    lme = fitlme(tbl, formula);
catch ME
    warning('CombinedInterocularOffsetVE:FitFailed', ...
        'Could not fit %s: %s', label, ME.message);
    lme = [];
end
end

function comparison = local_compare_lmes(lme1, lme2)
comparison = [];
if isempty(lme1) || isempty(lme2)
    return;
end

try
    comparison = compare(lme1, lme2);
catch ME
    warning('CombinedInterocularOffsetVE:CompareFailed', ...
        'Could not compare models: %s', ME.message);
end
end

function [rowColors, sortedIDs, idCmap] = local_id_colors(tbl)
[groupIdx, groupIDs] = findgroups(string(tbl.ID));
meanOffset = splitapply(@mean, tbl.InterocularOffset, groupIdx);
[~, order] = sort(meanOffset, 'ascend');
sortedIDs = groupIDs(order);
idCmap = jet(numel(sortedIDs));

idText = string(tbl.ID);
rowColors = zeros(height(tbl), 3);
for iRow = 1:height(tbl)
    colorIdx = find(sortedIDs == idText(iRow), 1, 'first');
    rowColors(iRow, :) = idCmap(colorIdx, :);
end
end

function local_plot_ri_panel(ax, tbl, rowColors, lme, xName, yName, titleText, xLabelText, yLabelText, usePaddedY)
hold(ax, 'on');
local_plot_fixed_effect_line(ax, tbl, lme, xName, yName, true);
scatter(ax, tbl.(xName), tbl.(yName), 38, rowColors, 'o', 'filled', ...
    'MarkerFaceAlpha', 0.85, 'MarkerEdgeAlpha', 0.25);
local_format_axis(ax, tbl, xName, yName, xLabelText, yLabelText, usePaddedY);
title(ax, local_title_with_p(lme, xName, titleText), ...
    'FontSize', 13, 'FontName', 'Avenir', 'Interpreter', 'none');
end

function local_plot_rs_panel(ax, tbl, rowColors, sortedIDs, idCmap, lme, xName, yName, titleText, xLabelText, yLabelText, usePaddedY)
hold(ax, 'on');
local_plot_random_subject_lines(ax, tbl, lme, sortedIDs, idCmap, xName);
scatter(ax, tbl.(xName), tbl.(yName), 38, rowColors, 'o', 'filled', ...
    'MarkerFaceAlpha', 0.85, 'MarkerEdgeAlpha', 0.25);
local_format_axis(ax, tbl, xName, yName, xLabelText, yLabelText, usePaddedY);
title(ax, local_title_with_p(lme, xName, titleText), ...
    'FontSize', 13, 'FontName', 'Avenir', 'Interpreter', 'none');
end

function local_plot_fixed_effect_line(ax, tbl, lme, xName, ~, showCi)
if isempty(lme)
    return;
end

[beta, coefNames, coefStats] = fixedEffects(lme);
coefText = local_coef_names(coefNames, lme);
interceptIdx = find(strcmp(coefText, '(Intercept)'), 1);
xIdx = find(strcmp(coefText, xName), 1);
if isempty(interceptIdx) || isempty(xIdx)
    return;
end

xVals = linspace(min(tbl.(xName)), max(tbl.(xName)), 120);
yVals = beta(interceptIdx) + beta(xIdx) .* xVals;

if showCi && ismember('Lower', local_table_var_names(coefStats)) && ismember('Upper', local_table_var_names(coefStats))
    xDown = sort(xVals, 'descend');
    yLow = coefStats.Lower(interceptIdx) + coefStats.Lower(xIdx) .* xVals;
    yHigh = coefStats.Upper(interceptIdx) + coefStats.Upper(xIdx) .* xDown;
    fill(ax, [xVals xDown], [yLow yHigh], [0 0 0], ...
        'FaceAlpha', 0.10, 'EdgeColor', 'none');
end

plot(ax, xVals, yVals, 'k-', 'LineWidth', 4);
end

function local_plot_random_subject_lines(ax, tbl, lme, sortedIDs, idCmap, xName)
if isempty(lme)
    return;
end

[feEfx, feNames] = fixedEffects(lme);
[reEfx, reNames] = randomEffects(lme);
coefText = local_coef_names(feNames, lme);
interceptFixedIdx = find(strcmp(coefText, '(Intercept)'), 1);
slopeFixedIdx = find(strcmp(coefText, xName), 1);
if isempty(interceptFixedIdx) || isempty(slopeFixedIdx)
    return;
end

reNameText = string(reNames.Name);
reLevelText = string(reNames.Level);
idText = string(tbl.ID);
for iID = 1:numel(sortedIDs)
    thisID = sortedIDs(iID);
    rowIdx = idText == thisID;
    if nnz(rowIdx) < 2
        continue;
    end

    interceptIdx = find(reLevelText == thisID & reNameText == "(Intercept)", 1);
    slopeIdx = find(reLevelText == thisID & reNameText == string(xName), 1);
    if isempty(interceptIdx) || isempty(slopeIdx)
        continue;
    end

    xVals = [min(tbl.(xName)(rowIdx)) max(tbl.(xName)(rowIdx))];
    yVals = (feEfx(interceptFixedIdx) + reEfx(interceptIdx)) + ...
        (feEfx(slopeFixedIdx) + reEfx(slopeIdx)) .* xVals;
    plot(ax, xVals, yVals, '-', 'Color', idCmap(iID, :), 'LineWidth', 1.3);
end
end

function local_format_axis(ax, tbl, xName, yName, xLabelText, yLabelText, usePaddedY)
xlim(ax, local_range_with_padding(tbl.(xName)));
if usePaddedY
    ylim(ax, local_range_with_padding(tbl.(yName)));
else
    ylim(ax, [0 max(tbl.(yName)) * 1.05]);
end
xlabel(ax, xLabelText, 'FontName', 'Avenir');
ylabel(ax, yLabelText, 'FontName', 'Avenir');
set(ax, 'FontSize', 16, 'FontName', 'Avenir', 'Box', 'off');
end

function rangeVals = local_range_with_padding(values)
values = values(isfinite(values));
if isempty(values)
    rangeVals = [0 1];
    return;
end

minVal = min(values);
maxVal = max(values);
if minVal == maxVal
    pad = max(abs(minVal) * 0.05, 0.5);
else
    pad = 0.05 * (maxVal - minVal);
end
rangeVals = [minVal - pad maxVal + pad];
end

function titleText = local_title_with_p(lme, xName, baseText)
if isempty(lme)
    titleText = sprintf('%s\nmodel did not fit', baseText);
    return;
end

[~, coefNames, coefStats] = fixedEffects(lme);
coefText = local_coef_names(coefNames, lme);
xIdx = find(strcmp(coefText, xName), 1);
if isempty(xIdx)
    titleText = baseText;
else
    titleText = sprintf('%s\n%s', baseText, local_format_p(coefStats.pValue(xIdx)));
end
end

function local_write_report(reportFile, models, tbl, sourceCsv)
modelList = {models.linearRI, models.linearRS, models.logRI, models.logRS};
modelLabels = {
    'Model 1: InterocularOffset ~ Elevation + (1|ID)'
    'Model 2: InterocularOffset ~ Elevation + (Elevation|ID)'
    'Model 3: logInterocularOffset ~ logAbsElevation + (1|ID)'
    'Model 4: logInterocularOffset ~ logAbsElevation + (logAbsElevation|ID)'
    };
comparisons = {models.linearRIvsRS, models.logRIvsRS};
comparisonLabels = {
    'Model comparison: linear RI vs linear RS'
    'Model comparison: log RI vs log RS'
    };

validModel = ~cellfun(@isempty, modelList);
validComparison = ~cellfun(@isempty, comparisons);
experiments = "<not available>";
if ismember('Experiment', tbl.Properties.VariableNames)
    experiments = strjoin(cellstr(unique(string(tbl.Experiment))), ', ');
end

reportOpts = struct();
reportOpts.ReportTitle = 'Combined Moon/Quad Interocular Offset by Elevation LME Report';
reportOpts.GeneratedBy = mfilename;
reportOpts.SourceFile = sourceCsv;
reportOpts.ModelLabel = 'Interocular offset predicted by elevation';
reportOpts.SummaryLines = {
    sprintf('Rows in model table: %d', height(tbl))
    sprintf('Participants in model table: %d', numel(categories(removecats(tbl.ID))))
    sprintf('Experiments: %s', experiments)
    'InterocularOffset is in degrees.'
    'logInterocularOffset = log2(InterocularOffset)'
    'logAbsElevation = log2(1 + abs(Elevation))'
    'Participant colors are sorted by mean InterocularOffset.'
    };
reportOpts.Models = modelList(validModel);
reportOpts.ModelLabels = modelLabels(validModel);
reportOpts.Comparisons = comparisons(validComparison);
reportOpts.ComparisonLabels = comparisonLabels(validComparison);
reportOpts.RemoveGroupError = false;
write_lme_stats_report(modelList{find(validModel, 1, 'first')}, reportFile, reportOpts);
end

function coefText = local_coef_names(coefNames, lme)
try
    if istable(coefNames) && ismember('Name', coefNames.Properties.VariableNames)
        coefText = cellstr(string(coefNames.Name));
    elseif isstruct(coefNames) && isfield(coefNames, 'Name')
        coefText = cellstr(string(coefNames.Name));
    elseif iscell(coefNames)
        coefText = cellstr(string(coefNames));
    else
        coefText = cellstr(string(coefNames));
    end
catch
    coefText = cellstr(string(lme.CoefficientNames(:)));
end
coefText = strrep(coefText, '''', '');
coefText = strrep(coefText, '{', '');
coefText = strrep(coefText, '}', '');
end

function varNames = local_table_var_names(tbl)
try
    varNames = cellstr(tbl.Properties.VariableNames);
    return;
catch
end

try
    varNames = cellstr(tbl.Properties.VarNames);
    return;
catch
end

varNames = {};
end

function pText = local_format_p(pValue)
if isnan(pValue)
    pText = 'p=NA';
elseif pValue < 0.001
    pText = sprintf('p=%.2e', pValue);
else
    pText = sprintf('p=%.3f', pValue);
end
end
