function [quad_disparity_data, out_datafile, resultsTxtFile, figureFiles] = run_quad_disparity_lme_analysis(csvFile, dataDir, topstick, elevationVarName, distanceVarName)
% RUN_QUAD_DISPARITY_LME_ANALYSIS
% Read a quad disparity CSV, optionally apply the top-stick elevation
% adjustment, construct a mean-disparity column, run disparity LMEs for
% each experiment version and for the full table, and save summary figures.
%
% Inputs
%   csvFile          : input CSV filename or full path
%   dataDir          : directory containing the CSV/output files
%   topstick         : logical flag passed to apply_topstick_observer_adjustment
%   elevationVarName : table variable copied into quad_disparity_data.Elevation
%                      and used by the top-stick adjustment
%                      default = 'Elevation'
%   distanceVarName  : table variable copied into quad_disparity_data.Distance
%                      default = 'Distance'
%
% Outputs
%   quad_disparity_data : processed table used in the model fits
%   out_datafile        : path to the written top-stick CSV (or original file)
%   resultsTxtFile      : path to the saved text report
%   figureFiles         : paths to saved summary figures

if nargin < 3 || isempty(topstick)
    topstick = true;
end
if nargin < 4 || isempty(elevationVarName)
    elevationVarName = 'Elevation';
end
if nargin < 5 || isempty(distanceVarName)
    distanceVarName = 'Distance';
end

elevationVarName = char(string(elevationVarName));
distanceVarName = char(string(distanceVarName));

[quad_disparity_data, out_datafile] = apply_topstick_observer_adjustment( ...
    csvFile, dataDir, topstick, elevationVarName);

requiredVars = {elevationVarName, distanceVarName, 'Version', 'ID'};
missingVars = requiredVars(~ismember(requiredVars, quad_disparity_data.Properties.VariableNames));
if ~isempty(missingVars)
    error('run_quad_disparity_lme_analysis:MissingVars', ...
        'Missing required variable(s): %s', strjoin(missingVars, ', '));
end

quad_disparity_data.Elevation = double(quad_disparity_data.(elevationVarName));
quad_disparity_data.Distance = double(quad_disparity_data.(distanceVarName)) ./ 100;
quad_disparity_data.MeanDisparity = local_compute_mean_disparity(quad_disparity_data);

keep = isfinite(quad_disparity_data.MeanDisparity) & ...
       isfinite(quad_disparity_data.Elevation) & ...
       isfinite(quad_disparity_data.Distance) & ...
       quad_disparity_data.MeanDisparity > 0 & ...
       (1 + quad_disparity_data.Elevation ./ 90) > 0 & ...
       quad_disparity_data.Distance > 0;

quad_disparity_data = quad_disparity_data(keep,:);
quad_disparity_data.log2disparity = log2(quad_disparity_data.MeanDisparity);
quad_disparity_data.ElevationD90 = 1 + quad_disparity_data.Elevation ./ 90;
quad_disparity_data.log2elevation = log2(quad_disparity_data.ElevationD90);
quad_disparity_data.log2distance = log2(quad_disparity_data.Distance);

if ~iscategorical(quad_disparity_data.ID)
    quad_disparity_data.ID = categorical(quad_disparity_data.ID);
end

[~, baseName, ~] = fileparts(out_datafile);
resultsTxtFile = fullfile(dataDir, [baseName '_disparity_lme_results.txt']);
fid = fopen(resultsTxtFile, 'w');
if fid < 0
    error('run_quad_disparity_lme_analysis:OpenFailed', ...
        'Could not open results file for writing: %s', resultsTxtFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Quad disparity LME analysis\n');
fprintf(fid, 'Input CSV: %s\n', csvFile);
fprintf(fid, 'Processed CSV: %s\n', out_datafile);
fprintf(fid, 'Elevation source: %s\n', elevationVarName);
fprintf(fid, 'Distance source: %s (converted from cm to m)\n', distanceVarName);
fprintf(fid, 'Rows retained for modeling: %d\n\n', height(quad_disparity_data));

versionValues = unique(quad_disparity_data.Version, 'stable');
versionValues = versionValues(:);
figureFiles = {};

for iVersion = 1:numel(versionValues)
    versionValue = versionValues(iVersion);
    versionMask = local_version_mask(quad_disparity_data.Version, versionValue);
    tblVersion = quad_disparity_data(versionMask,:);
    label = sprintf('Version %s', string(versionValue));
    [lmeStruct, summaryText] = local_fit_lme_set(tblVersion);
    fprintf(fid, '========================================\n');
    fprintf(fid, '%s\n', label);
    fprintf(fid, 'Rows: %d\n', height(tblVersion));
    fprintf(fid, 'Subjects: %d\n\n', numel(categories(removecats(tblVersion.ID))));
    fprintf(fid, '%s\n', summaryText);
    if ~isempty(lmeStruct)
        figureFiles{end+1,1} = local_plot_lme_summary_figure(tblVersion, lmeStruct, dataDir, baseName, label); %#ok<AGROW>
    end
end

[lmeStruct23, summaryText23] = local_fit_lme_set(quad_disparity_data(ismember(string(quad_disparity_data.Version), ["2","3"]),:));
fprintf(fid, '========================================\n');
fprintf(fid, 'Versions 2 and 3\n');
fprintf(fid, 'Rows: %d\n', height(quad_disparity_data(ismember(string(quad_disparity_data.Version), ["2","3"]),:)));
fprintf(fid, 'Subjects: %d\n\n', numel(categories(removecats(quad_disparity_data.ID(ismember(string(quad_disparity_data.Version), ["2","3"]))))));
fprintf(fid, '%s\n', summaryText23);
if ~isempty(lmeStruct23)
    figureFiles{end+1,1} = local_plot_lme_summary_figure( ...
        quad_disparity_data(ismember(string(quad_disparity_data.Version), ["2","3"]),:), ...
        lmeStruct23, dataDir, baseName, 'Versions2and3'); %#ok<AGROW>
end

[lmeStructAll, summaryTextAll] = local_fit_lme_set(quad_disparity_data);
fprintf(fid, '========================================\n');
fprintf(fid, 'All Versions\n');
fprintf(fid, 'Rows: %d\n', height(quad_disparity_data));
fprintf(fid, 'Subjects: %d\n\n', numel(categories(removecats(quad_disparity_data.ID))));
fprintf(fid, '%s\n', summaryTextAll);
if ~isempty(lmeStructAll)
    figureFiles{end+1,1} = local_plot_lme_summary_figure(quad_disparity_data, lmeStructAll, dataDir, baseName, 'AllVersions'); %#ok<AGROW>
end

figureFiles = string(figureFiles);

end

function meanDisparity = local_compute_mean_disparity(T)
hasD1 = ismember('Disparity1', T.Properties.VariableNames);
hasD2 = ismember('Disparity2', T.Properties.VariableNames);

if hasD1 && hasD2
    d1 = double(T.Disparity1);
    d2 = double(T.Disparity2);
    meanDisparity = mean([d1 d2], 2, 'omitnan');
elseif ismember('Disparity', T.Properties.VariableNames)
    meanDisparity = double(T.Disparity);
else
    error('run_quad_disparity_lme_analysis:MissingDisparityVars', ...
        'Need either Disparity1/Disparity2 or Disparity in the input table.');
end
end

function tf = local_version_mask(versionColumn, versionValue)
if iscategorical(versionColumn)
    tf = versionColumn == categorical(versionValue);
elseif isstring(versionColumn)
    tf = versionColumn == string(versionValue);
elseif iscellstr(versionColumn) || iscell(versionColumn)
    tf = strcmp(string(versionColumn), string(versionValue));
else
    tf = versionColumn == versionValue;
end
end

function [lmeStruct, summaryText] = local_fit_lme_set(tbl)
if height(tbl) < 3 || numel(categories(removecats(tbl.ID))) < 2
    lmeStruct = [];
    summaryText = sprintf('Not enough data to fit models.\n');
    return
end

lmeStruct = struct();
lmeStruct.twoFactor = fitlme(tbl, 'log2disparity ~ log2elevation + log2distance + (1|ID)');
lmeStruct.elevationOnly = fitlme(tbl, 'log2disparity ~ log2elevation + (1|ID)');
lmeStruct.distanceOnly = fitlme(tbl, 'log2disparity ~ log2distance + (1|ID)');

summaryText = sprintf([ ...
    'Model 1: log2disparity ~ log2(1 + Elevation/90) + log2(Distance_m) + (1|ID)\n%s\n' ...
    'Model 2: log2disparity ~ log2(1 + Elevation/90) + (1|ID)\n%s\n' ...
    'Model 3: log2disparity ~ log2(Distance_m) + (1|ID)\n%s\n'], ...
    evalc('disp(lmeStruct.twoFactor)'), ...
    evalc('disp(lmeStruct.elevationOnly)'), ...
    evalc('disp(lmeStruct.distanceOnly)'));
end

function figureFile = local_plot_lme_summary_figure(tbl, lmeStruct, saveDir, baseName, label)
ids = categories(removecats(tbl.ID));

figh = figure('Color', 'w', 'Position', [100 100 1600 1100], 'Visible', 'off');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

local_plot_single_predictor_panel(nexttile, tbl, ids, lmeStruct.elevationOnly, ...
    'Elevation', 'Panel A: Disparity vs Elevation', 'log2elevation');

local_plot_single_predictor_panel(nexttile, tbl, ids, lmeStruct.distanceOnly, ...
    'Distance', 'Panel B: Disparity vs Distance', 'log2distance');

local_plot_twofactor_marginal_panel(nexttile, tbl, ids, lmeStruct.twoFactor, ...
    'Elevation', median(tbl.Distance, 'omitnan'), ...
    'Panel C: Two-factor model by Elevation', 'log2elevation');

local_plot_twofactor_marginal_panel(nexttile, tbl, ids, lmeStruct.twoFactor, ...
    'Distance', median(tbl.Elevation, 'omitnan'), ...
    'Panel D: Two-factor model by Distance', 'log2distance');

sgtitle(sprintf('%s: Disparity LME Analysis', label), 'FontSize', 16, 'FontWeight', 'bold');

fileLabel = local_make_safe_filename(label);
figureFile = fullfile(saveDir, sprintf('%s_%s_disparity_lme.png', baseName, fileLabel));
exportgraphics(figh, figureFile, 'Resolution', 600);
close(figh);
end

function [subjectOrder, subjectColors] = local_subject_color_order(lme, ids)
[reEfx, reNames] = randomEffects(lme);
nameCol = string(reNames.Name);
levelCol = string(reNames.Level);
estimateCol = reEfx;

intercepts = zeros(numel(ids), 1);
for i = 1:numel(ids)
    match = levelCol == string(ids{i}) & nameCol == "(Intercept)";
    if any(match)
        intercepts(i) = estimateCol(find(match, 1, 'first'));
    end
end

[~, subjectOrder] = sort(intercepts, 'ascend');
cmap = turbo(max(numel(ids), 2));
subjectColors = cmap(1:numel(ids), :);
subjectColors = subjectColors(subjectOrder, :);
end

function local_plot_single_predictor_panel(ax, tbl, ids, lme, xVar, panelTitle, logVarName)
hold(ax, 'on');
[subjectOrder, subjectColors] = local_subject_color_order(lme, ids);

for i = 1:numel(subjectOrder)
    subjIdx = subjectOrder(i);
    subjMask = tbl.ID == ids{subjIdx};
    xData = local_display_xdata(tbl(subjMask,:), xVar);
    scatter(ax, xData, tbl.MeanDisparity(subjMask), 28, ...
        subjectColors(i,:), 'filled', 'MarkerFaceAlpha', 0.75, 'MarkerEdgeAlpha', 0.75);
end

xGridModel = logspace(log10(min(local_model_xdata(tbl, xVar))), log10(max(local_model_xdata(tbl, xVar))), 200)';
[etaFixed, etaLower, etaUpper] = local_fixed_effect_curve(lme, xGridModel, logVarName, '');
yHat = 2.^etaFixed;
yLower = 2.^etaLower;
yUpper = 2.^etaUpper;
xGridDisplay = local_display_xgrid(xGridModel, xVar);

fill(ax, [xGridDisplay; flipud(xGridDisplay)], [yLower; flipud(yUpper)], [0.75 0.75 0.75], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.3);

local_plot_subject_lines(ax, lme, ids, subjectOrder, subjectColors, xGridModel, xVar, logVarName, []);
plot(ax, xGridDisplay, yHat, 'k-', 'LineWidth', 3);

set(ax, 'XScale', 'log', 'YScale', 'log', 'FontSize', 12, 'Box', 'off');
grid(ax, 'off');
xlabel(ax, local_xlabel(xVar));
ylabel(ax, 'Mean Disparity [deg]');
if strcmp(xVar, 'Elevation')
    local_set_native_elevation_ticks(ax);
end
title(ax, panelTitle, 'FontSize', 13);
end

function local_plot_twofactor_marginal_panel(ax, tbl, ids, lme, xVar, heldValue, panelTitle, logVarName)
hold(ax, 'on');
[subjectOrder, subjectColors] = local_subject_color_order(lme, ids);

for i = 1:numel(subjectOrder)
    subjIdx = subjectOrder(i);
    subjMask = tbl.ID == ids{subjIdx};
    xData = local_display_xdata(tbl(subjMask,:), xVar);
    scatter(ax, xData, tbl.MeanDisparity(subjMask), 28, ...
        subjectColors(i,:), 'filled', 'MarkerFaceAlpha', 0.75, 'MarkerEdgeAlpha', 0.75);
end

xGridModel = logspace(log10(min(local_model_xdata(tbl, xVar))), log10(max(local_model_xdata(tbl, xVar))), 200)';
if strcmp(xVar, 'Elevation')
    otherLogVal = log2(heldValue);
    heldStruct.log2distance = otherLogVal;
    heldStruct.log2elevation = [];
else
    otherLogVal = log2(1 + heldValue / 90);
    heldStruct.log2elevation = otherLogVal;
    heldStruct.log2distance = [];
end

[etaFixed, etaLower, etaUpper] = local_fixed_effect_curve(lme, xGridModel, logVarName, heldStruct);
yHat = 2.^etaFixed;
yLower = 2.^etaLower;
yUpper = 2.^etaUpper;
xGridDisplay = local_display_xgrid(xGridModel, xVar);

fill(ax, [xGridDisplay; flipud(xGridDisplay)], [yLower; flipud(yUpper)], [0.75 0.75 0.75], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.3);

local_plot_subject_lines(ax, lme, ids, subjectOrder, subjectColors, xGridModel, xVar, logVarName, heldStruct);
plot(ax, xGridDisplay, yHat, 'k-', 'LineWidth', 3);

set(ax, 'XScale', 'log', 'YScale', 'log', 'FontSize', 12, 'Box', 'off');
grid(ax, 'off');
xlabel(ax, local_xlabel(xVar));
ylabel(ax, 'Mean Disparity [deg]');
if strcmp(xVar, 'Elevation')
    local_set_native_elevation_ticks(ax);
end
title(ax, panelTitle, 'FontSize', 13);
end

function [etaFixed, etaLower, etaUpper] = local_fixed_effect_curve(lme, xGrid, varyingLogName, heldStruct)
coefNames = string(lme.CoefficientNames(:));
beta = fixedEffects(lme);
covB = lme.CoefficientCovariance;

nGrid = numel(xGrid);
X = zeros(nGrid, numel(coefNames));
interceptIdx = find(coefNames == "(Intercept)", 1, 'first');
if ~isempty(interceptIdx)
    X(:, interceptIdx) = 1;
end

varyingLog = log2(xGrid);
varyingIdx = find(coefNames == varyingLogName, 1, 'first');
if ~isempty(varyingIdx)
    X(:, varyingIdx) = varyingLog;
end

if ischar(heldStruct) || isempty(heldStruct)
    heldStruct = struct();
end

if isfield(heldStruct, 'log2elevation') && ~isempty(heldStruct.log2elevation)
    idx = find(coefNames == "log2elevation", 1, 'first');
    if ~isempty(idx)
        X(:, idx) = heldStruct.log2elevation;
    end
end
if isfield(heldStruct, 'log2distance') && ~isempty(heldStruct.log2distance)
    idx = find(coefNames == "log2distance", 1, 'first');
    if ~isempty(idx)
        X(:, idx) = heldStruct.log2distance;
    end
end

etaFixed = X * beta;
se = sqrt(max(sum((X * covB) .* X, 2), 0));
etaLower = etaFixed - 1.96 * se;
etaUpper = etaFixed + 1.96 * se;
end

function local_plot_subject_lines(ax, lme, ids, subjectOrder, subjectColors, xGridModel, xVar, varyingLogName, heldStruct)
[reEfx, reNames] = randomEffects(lme);
levelCol = string(reNames.Level);
nameCol = string(reNames.Name);
estimateCol = reEfx;

if ischar(heldStruct) || isempty(heldStruct)
    heldStruct = struct();
end

for i = 1:numel(subjectOrder)
    subjIdx = subjectOrder(i);
    subjId = string(ids{subjIdx});

    eta = zeros(size(xGridModel));
    coefNames = string(lme.CoefficientNames(:));
    beta = fixedEffects(lme);
    interceptIdx = find(coefNames == "(Intercept)", 1, 'first');
    varyingIdx = find(coefNames == varyingLogName, 1, 'first');

    if ~isempty(interceptIdx)
        eta = eta + beta(interceptIdx);
    end
    if ~isempty(varyingIdx)
        eta = eta + beta(varyingIdx) * log2(xGridModel);
    end

    if isfield(heldStruct, 'log2elevation') && ~isempty(heldStruct.log2elevation)
        idx = find(coefNames == "log2elevation", 1, 'first');
        if ~isempty(idx) && coefNames(idx) ~= varyingLogName
            eta = eta + beta(idx) * heldStruct.log2elevation;
        end
    end
    if isfield(heldStruct, 'log2distance') && ~isempty(heldStruct.log2distance)
        idx = find(coefNames == "log2distance", 1, 'first');
        if ~isempty(idx) && coefNames(idx) ~= varyingLogName
            eta = eta + beta(idx) * heldStruct.log2distance;
        end
    end

    subjIntercept = 0;
    match = levelCol == subjId & nameCol == "(Intercept)";
    if any(match)
        subjIntercept = estimateCol(find(match, 1, 'first'));
    end

    plot(ax, local_display_xgrid(xGridModel, xVar), 2.^(eta + subjIntercept), ':', 'Color', subjectColors(i,:), 'LineWidth', 1.1);
end
end

function safeName = local_make_safe_filename(label)
safeName = regexprep(char(string(label)), '[^A-Za-z0-9]+', '_');
safeName = regexprep(safeName, '_+', '_');
safeName = regexprep(safeName, '^_|_$', '');
end

function xData = local_model_xdata(tbl, xVar)
if strcmp(xVar, 'Elevation')
    xData = tbl.ElevationD90;
else
    xData = tbl.Distance;
end
end

function xData = local_display_xdata(tbl, xVar)
if strcmp(xVar, 'Elevation')
    xData = tbl.ElevationD90;
else
    xData = tbl.Distance;
end
end

function xDisplay = local_display_xgrid(xGridModel, xVar)
if strcmp(xVar, 'Elevation')
    xDisplay = xGridModel;
else
    xDisplay = xGridModel;
end
end

function label = local_xlabel(xVar)
if strcmp(xVar, 'Elevation')
    label = 'Elevation [deg]';
else
    label = 'Distance [m]';
end
end

function local_set_native_elevation_ticks(ax)
nativeTicks = [-45 -30 -15 -5 0 5 15 30 45 60];
tickPos = 1 + nativeTicks ./ 90;
valid = tickPos > 0;
nativeTicks = nativeTicks(valid);
tickPos = tickPos(valid);
xlimVals = xlim(ax);
keep = tickPos >= xlimVals(1) & tickPos <= xlimVals(2);
set(ax, 'XTick', tickPos(keep), 'XTickLabel', string(nativeTicks(keep)));
end
