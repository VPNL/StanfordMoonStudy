function lme = fit_PerceivedDisparity_by_DistanceElevation_lme(tbl, tblName, ResultsDir, saveModels, mycolormap, sorted_idx, modelTransform, fullUniqueID, removeOutlierParticipants)
% FIT_PERCEIVEDDISPARITY_BY_DISTANCEELEVATION_LME
% Distance/elevation-only mirror of fit_PerceivedDisparity_lme_wMax.

if nargin < 7 || isempty(modelTransform)
    modelTransform = 2;
end
if nargin < 8 || isempty(fullUniqueID)
    fullUniqueID = [];
end
if nargin < 9 || isempty(removeOutlierParticipants)
    removeOutlierParticipants = false;
end

tbl = Quad_prepare_perceived_disparity_table(tbl, modelTransform, removeOutlierParticipants);
subjectcolor = local_subject_colors(tbl, mycolormap, sorted_idx, fullUniqueID);
local_write_full_model_diagnostics(tbl, tblName, ResultsDir);

try
    lme = fitlme(tbl, 'log2mean_disparity ~ 1 + log2distance + log2elevation + (1|ID)');
catch ME
    local_append_full_model_skip(ResultsDir, tblName, ME.message);
    lme = [];
    return;
end

Intercept = lme.Coefficients.Estimate(1);
De = lme.Coefficients.Estimate(2);
Ee = lme.Coefficients.Estimate(3);

if modelTransform == 2
    titlestr = sprintf('Disparity=%.2f(D)^{%.2f}(1+|E|)^{%.2f}', 2.^Intercept, De, Ee);
elseif modelTransform == 6
    titlestr = sprintf('Disparity=%.2f(D)^{%.2f}(1+|E|/90)^{%.2f}', 2.^Intercept, De, Ee);
else
    titlestr = sprintf('Disparity=%.2f(D)^{%.2f}(1+E/90)^{%.2f}', 2.^Intercept, De, Ee);
end

function local_append_full_model_skip(ResultsDir, tblName, msg)
if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir);
end
fid = fopen(fullfile(ResultsDir, [tblName '.txt']), 'a');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'Model: log2mean_disparity ~ 1 + log2distance + log2elevation + (1|ID)\n');
fprintf(fid, 'Skipped: %s\n\n', msg);
end

muX = [mean(tbl.log2distance,'omitnan'), mean(tbl.log2elevation,'omitnan')];
minDisp = max(0.01, min(tbl.MeanDisparity));
maxDisp = max(tbl.MeanDisparity);

fig1 = figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .8 .6],'Name',tblName,'Visible','off');
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
local_plot_one_predictor(nexttile, tbl, subjectcolor, lme, 'log2distance', {'Distance [m]','log scale'}, muX, minDisp, maxDisp, modelTransform);
if modelTransform == 2 || modelTransform == 6
    local_plot_one_predictor(nexttile, tbl, subjectcolor, lme, 'log2elevation', {'|Elevation| [deg]','log scale'}, muX, minDisp, maxDisp, modelTransform);
else
    local_plot_one_predictor(nexttile, tbl, subjectcolor, lme, 'log2elevation', {'Elevation [deg]','log scale'}, muX, minDisp, maxDisp, modelTransform);
end
sgtitle(titlestr,'FontSize',24,'FontName','Avenir');

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir);
end
exportgraphics(fig1, fullfile(ResultsDir, [tblName '.png']), 'Resolution', 600);
if saveModels
    save(fullfile(ResultsDir, [tblName '_Models.mat']), 'lme');
end
close(fig1);
end

function local_write_full_model_diagnostics(tbl, tblName, ResultsDir)
if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir);
end

X = [tbl.log2distance, tbl.log2elevation];
validRows = all(isfinite(X), 2);
X = X(validRows, :);
diagnosticFile = fullfile(ResultsDir, [tblName '_fullmodel_diagnostics.txt']);
fid = fopen(diagnosticFile, 'w');
if fid < 0
    return;
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'Full model diagnostics for %s\n\n', tblName);
fprintf(fid, 'Rows used: %d\n', size(X,1));
fprintf(fid, 'Unique IDs: %d\n', numel(categories(removecats(tbl.ID))));
fprintf(fid, 'Unique predictor combinations: %d\n', size(unique(round(X, 10), 'rows'), 1));
fprintf(fid, 'Design rank [1 D E]: %d of %d\n\n', rank([ones(size(X,1),1) X]), size(X,2) + 1);

if size(X,1) >= 2
    C = corrcoef(X);
    fprintf(fid, 'Predictor correlation matrix [D E]:\n');
    for i = 1:size(C,1)
        fprintf(fid, '%.4f\t%.4f\n', C(i,1), C(i,2));
    end
else
    fprintf(fid, 'Not enough rows to compute predictor correlation matrix.\n');
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
    sorted_cindex = find(sorted_idx == cindex, 1, 'first');
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    subjectcolor(c,:) = mycolormap(sorted_cindex,:);
end
end

function local_plot_one_predictor(ax, tbl, subjectcolor, lme, varName, xLabelStr, muX, minDisp, maxDisp, modelTransform)
hold(ax,'on');

switch varName
    case 'log2distance'
        x = tbl.log2distance;
        xData = tbl.Distance;
        varyIdx = 1;
    otherwise
        x = tbl.log2elevation;
        xData = tbl.ElevationModel;
        varyIdx = 2;
end

scatter_by_measurement(ax, x, tbl.log2mean_disparity, subjectcolor, tbl.Measurement);

xgrid = linspace(min(x), max(x), 200)';
Xpred = repmat(muX, numel(xgrid), 1);
Xpred(:, varyIdx) = xgrid;

beta = fixedEffects(lme);
covB = lme.CoefficientCovariance;
eta = beta(1) + Xpred * beta(2:3);
Xdesign = [ones(numel(xgrid),1) Xpred];
se = sqrt(sum((Xdesign * covB) .* Xdesign, 2));
lower = eta - 1.96 * se;
upper = eta + 1.96 * se;

fill(ax, [xgrid; flipud(xgrid)], [lower; flipud(upper)], 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);
plot(ax, xgrid, eta, 'k-', 'LineWidth', 3);

set(ax, 'YTick', floor(log2(minDisp)):ceil(log2(maxDisp)), ...
    'YTickLabel', string(2.^(floor(log2(minDisp)):ceil(log2(maxDisp)))), ...
    'FontName','Avenir','FontSize',18);

if strcmp(varName, 'log2elevation')
    if modelTransform == 2
        vals = max(0, round(linspace(min(xData)-1, max(xData)-1, 4), 1));
        vals = unique([max(0, min(xData)-1); vals(:); max(0, max(xData)-1)]);
        xt = log2(vals + 1);
        xl = string(vals);
    else
        guideVals = [-45 -30 -15 -5 0 5 15 30 45 60];
        pos = log2(1 + guideVals/90);
        valid = isfinite(pos) & (1 + guideVals/90) > 0;
        guideVals = guideVals(valid);
        dataMinNative = 90 * (min(xData) - 1);
        dataMaxNative = 90 * (max(xData) - 1);
        inRange = guideVals >= dataMinNative & guideVals <= dataMaxNative;
        guideVals = guideVals(inRange);
        vals = unique([round(dataMinNative,1); guideVals(:); round(dataMaxNative,1)]);
        xt = log2(1 + vals/90);
        xl = string(vals);
    end
    set(ax, 'XTick', xt, 'XTickLabel', xl);
else
    tickVals = unique(round(logspace(log10(min(xData)), log10(max(xData)), 4), 2));
    tickVals = unique([min(xData); tickVals(:); max(xData)]);
    set(ax, 'XTick', log2(tickVals), 'XTickLabel', string(tickVals));
end

xlabel(ax, xLabelStr, 'FontSize',22);
ylabel(ax, {'Perceived Disparity [deg]','log scale'}, 'FontSize',22);
xlim(ax, local_expand_log_limits_from_data(xData, varName, modelTransform));
box(ax,'off');
grid(ax,'off');
end

function lims = local_expand_log_limits_from_data(xData, varName, modelTransform)
if strcmp(varName, 'log2elevation')
    if modelTransform == 2
        xmin = max(0, min(xData) - 1);
        xmax = max(0, max(xData) - 1);
        lims = log2([max(eps, (xmin + 1) * 0.95) (xmax + 1) * 1.05]);
    else
        xmin = min(xData);
        xmax = max(xData);
        lims = log2([max(eps, xmin * 0.95) xmax * 1.05]);
    end
else
    xmin = min(xData);
    xmax = max(xData);
    lims = log2([max(eps, xmin * 0.95) xmax * 1.05]);
end
end
