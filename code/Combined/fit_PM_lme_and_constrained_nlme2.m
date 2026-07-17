function [lme_unconstrained, nlme_constrained] = fit_PM_lme_and_constrained_nlme(tbl, tblName, ResultsDir, saveModels, cmap, sorted_idx)
% fit_PM_lme_and_constrained_nlme
%
% Fits:
%   (1) Confirmatory unconstrained linear mixed-effects model (fitlme):
%       log2(PM) ~ 1 + log2(VA) + log2(D) + log2(1+E) + (1|ID)
%
%   (2) Constrained negative-elevation nonlinear mixed-effects model (nlmefit):
%       log2(PM) = b1 + b2*X1 + b3*X2 - exp(b4)*X3
%       where X = [log2(VA), log2(D), log2(1+E)] and the elevation slope is
%       -exp(b4) < 0 (by construction).
%
% Figures saved (if ResultsDir provided):
%   <tblName>.png                       (unconstrained LME; PM on linear scale)
%   <tblName>_ConstrainedNegElev.png    (constrained NLME; PM on linear scale)
%   <tblName>_ObsVsPred.png             (observed PM vs predicted PM; optional diagnostic)
%
% Participant coloring:
%   Colors are assigned by sorting participants according to their subject-specific
%   intercepts from the unconstrained LME (fixed intercept + random intercept BLUP).
%
% Notes:
% - Predictors are NOT mean-centered (user preference).
% - Plots show ORIGINAL PM (linear scale): PM = 2.^log2(PM).
% - The model is still fit on log2(PM) for numerical stability / linearity.
%
% Jan 2026

%% defaults / input hygiene
if nargin < 2 || isempty(tblName);    tblName = 'PM_Model'; end
if nargin < 3 || isempty(ResultsDir); ResultsDir = ''; end
if nargin < 4 || isempty(saveModels); saveModels = false; end
if nargin < 5; cmap = []; end %#ok<NASGU>
if nargin < 6; sorted_idx = []; end %#ok<NASGU>

if ~istable(tbl)
    error('Input tbl must be a MATLAB table.');
end

%% ensure required variables exist (compute if needed)
tbl = local_ensure_log_variables(tbl);

required = {'ID','log2ratio_visual_angle','log2real_angle','log2distance','log2elevation'};
for i = 1:numel(required)
    if ~ismember(required{i}, tbl.Properties.VariableNames)
        error('Missing required variable "%s" after preprocessing.', required{i});
    end
end

% drop non-finite rows early
Xraw = [tbl.log2real_angle, tbl.log2distance, tbl.log2elevation];
yraw = tbl.log2ratio_visual_angle;

idLabels = tbl.ID;
group = local_group_to_numeric(idLabels);

good = all(isfinite([Xraw yraw group]), 2);
tbl  = tbl(good,:);
Xraw = Xraw(good,:);
y    = yraw(good,:);
group = group(good,:);

if height(tbl) < 10
    error('Not enough valid rows after filtering (n=%d).', height(tbl));
end

pm_obs_all = 2.^y;

%% (1) Unconstrained LME (fitlme)
formula = 'log2ratio_visual_angle ~ 1 + log2real_angle + log2distance + log2elevation + (1|ID)';
lme_unconstrained = fitlme(tbl, formula);

%% Subject ordering and colors based on unconstrained LME intercept solutions
[idU, ~, gi] = unique(tbl.ID, 'stable');
nSubj = numel(idU);

if nargin < 5 || isempty(cmap)
    cmap = jet(max(nSubj, 3));
end
cmap = local_resample_cmap(cmap, nSubj);

[order_subj, subjIntercept] = local_order_subjects_by_intercept(lme_unconstrained, idU); %#ok<NASGU>
rankInv = zeros(nSubj, 1);
rankInv(order_subj) = 1:nSubj;
subjectcolor = cmap(rankInv(gi), :);

%% (2) Constrained NLME with negative elevation slope (no centering)
model_constrained = @(beta, X) beta(1) + beta(2)*X(:,1) + beta(3)*X(:,2) - exp(beta(4))*X(:,3);

% robust starting values from LME fixed effects
fe = fixedEffects(lme_unconstrained); % [intercept; slope_VA; slope_D; slope_E]
b2_0 = fe(2);
b3_0 = fe(3);

elevMag0 = max(0.05, abs(fe(4)));   % avoid exp(beta4) ~ 0 (Jacobian column ~ 0)
beta0 = [mean(y,'omitnan'), b2_0, b3_0, log(elevMag0)];
% guardrails
beta0(4) = min(max(beta0(4), log(0.05)), log(5)); % exp(beta4) in [0.05, 5]

% nlmefit options
opts = statset('nlmefit');
opts.MaxIter = 200;
opts.TolFun  = 1e-8;
opts.TolX    = 1e-8;

nlme_constrained = struct();
nlme_constrained.didFit  = false;
nlme_constrained.message = '';
nlme_constrained.beta = [];
nlme_constrained.psi  = [];
nlme_constrained.stats = [];
nlme_constrained.b    = [];
nlme_constrained.modelFcn = model_constrained;

try
    [beta_c, psi_c, stats_c, b_c] = nlmefit(Xraw, y, group, [], model_constrained, beta0, ...
        'FEParamsSelect', true(1,4), ...
        'REParamsSelect', [true false false false], ... % random intercept only
        'Vectorization', 'SingleGroup', ...
        'Options', opts);

    nlme_constrained.beta = beta_c;
    nlme_constrained.psi  = psi_c;
    nlme_constrained.stats = stats_c;
    nlme_constrained.b    = b_c;
    nlme_constrained.didFit = true;
catch ME
    nlme_constrained.didFit = false;
    nlme_constrained.message = ME.message;
end

%% plotting constants (PM linear scale)
maxPMLim = max(pm_obs_all, [], 'omitnan');
if ~isfinite(maxPMLim) || maxPMLim <= 0
    maxPMLim = 2;
end
maxPMLim = maxPMLim * 1.05;

muX = [mean(tbl.log2real_angle,'omitnan'), mean(tbl.log2distance,'omitnan'), mean(tbl.log2elevation,'omitnan')];
muX(~isfinite(muX)) = 0;

%% -------------- FIGURE 1: Unconstrained LME (PM scale) --------------
fig1 = figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5],'Name',tblName);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme_unconstrained, ...
    'log2real_angle', 'Visual Angle [deg], log2 scale', muX, maxPMLim);

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme_unconstrained, ...
    'log2distance', 'Distance [m], log2 scale', muX, maxPMLim);

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme_unconstrained, ...
    'log2elevation', 'Elevation [deg], log2 scale (log2(1+E))', muX, maxPMLim);

sgtitle(sprintf('%s: Unconstrained LME', tblName), 'FontName','Avenir','FontSize',18);

if ~isempty(ResultsDir)
    if ~exist(ResultsDir,'dir'); mkdir(ResultsDir); end
    exportgraphics(fig1, fullfile(ResultsDir, [tblName '.png']), 'Resolution', 600);
end

%% -------------- FIGURE 2: Constrained NLME (PM scale) --------------
fig2 = figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5], ...
    'Name',[tblName '_ConstrainedNegElev']);

if exist('tiledlayout','file') == 2
    tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
    ax1 = nexttile; ax2 = nexttile; ax3 = nexttile;
else
    ax1 = subplot(1,3,1);
    ax2 = subplot(1,3,2);
    ax3 = subplot(1,3,3);
end

if nlme_constrained.didFit
    local_plot_one_predictor_nlme(ax1, tbl, subjectcolor, nlme_constrained, ...
        1, 'Visual Angle [deg], log2 scale', maxPMLim);

    local_plot_one_predictor_nlme(ax2, tbl, subjectcolor, nlme_constrained, ...
        2, 'Distance [m], log2 scale', maxPMLim);

    local_plot_one_predictor_nlme(ax3, tbl, subjectcolor, nlme_constrained, ...
        3, 'Elevation [deg], log2 scale (log2(1+E))', maxPMLim);

    elevSlope = -exp(nlme_constrained.beta(4));
    local_sgtitle(sprintf('%s: Constrained NLME (elev slope = %.3f)', tblName, elevSlope));
else
    axes(ax1); axis off
    text(0,0.65,'Constrained NLME did not fit.','FontName','Avenir','FontSize',16);
    text(0,0.45,'Reason:','FontName','Avenir','FontSize',14);
    text(0,0.25,nlme_constrained.message,'FontName','Avenir','FontSize',10,'Interpreter','none');

    axes(ax2); axis off
    axes(ax3); axis off

    local_sgtitle(sprintf('%s: Constrained NLME (fit failed)', tblName));
end

if ~isempty(ResultsDir)
    if ~exist(ResultsDir,'dir'); mkdir(ResultsDir); end
    exportgraphics(fig2, fullfile(ResultsDir, [tblName '_ConstrainedNegElev.png']), 'Resolution', 600);
end

%% -------------- FIGURE 3: Observed PM vs Predicted PM (diagnostic) --------------
% This directly answers "original PM values vs predicted values".
fig3 = figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .9 .45], ...
    'Name',[tblName '_ObsVsPred']);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');

% LME population predictions (log2 scale), then back-transform
yhat_lme_log2 = predict(lme_unconstrained, tbl, 'Conditional', false);
pm_hat_lme = 2.^yhat_lme_log2;

ax = nexttile;
local_plot_obs_vs_pred(ax, pm_obs_all, pm_hat_lme, subjectcolor, 'Unconstrained LME');

ax = nexttile;
if nlme_constrained.didFit
    yhat_nlme_log2 = nlme_constrained.modelFcn(nlme_constrained.beta, Xraw);
    pm_hat_nlme = 2.^yhat_nlme_log2;
    local_plot_obs_vs_pred(ax, pm_obs_all, pm_hat_nlme, subjectcolor, 'Constrained NLME');
else
    axis(ax,'off');
    text(ax, 0, 0.6, 'Constrained NLME did not fit.', 'FontName','Avenir','FontSize',14);
end

local_sgtitle(sprintf('%s: Observed PM vs Predicted PM', tblName));

if ~isempty(ResultsDir)
    if ~exist(ResultsDir,'dir'); mkdir(ResultsDir); end
    exportgraphics(fig3, fullfile(ResultsDir, [tblName '_ObsVsPred.png']), 'Resolution', 600);
end

%% optionally save models
if saveModels && ~isempty(ResultsDir)
    if ~exist(ResultsDir,'dir'); mkdir(ResultsDir); end
    save(fullfile(ResultsDir, [tblName '_Models.mat']), 'lme_unconstrained', 'nlme_constrained');
end

end

%% ----------------------- Local functions -----------------------

function tbl = local_ensure_log_variables(tbl)
% Ensure log2ratio_visual_angle, log2real_angle, log2distance, log2elevation exist.

% PM ratio
if ~ismember('log2ratio_visual_angle', tbl.Properties.VariableNames)
    if ismember('Ratio_Visual_Angle', tbl.Properties.VariableNames)
        ratio = tbl.Ratio_Visual_Angle;
    elseif all(ismember({'Reported_Visual_Angle','Real_Visual_Angle'}, tbl.Properties.VariableNames))
        ratio = tbl.Reported_Visual_Angle ./ tbl.Real_Visual_Angle;
    else
        error('Need Ratio_Visual_Angle OR (Reported_Visual_Angle and Real_Visual_Angle) to compute PM ratio.');
    end
    tbl.log2ratio_visual_angle = log2(ratio);
end

% log2(VA)
if ~ismember('log2real_angle', tbl.Properties.VariableNames)
    if ismember('Real_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = log2(tbl.Real_Visual_Angle);
    elseif ismember('log2Real_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = tbl.log2Real_Visual_Angle;
    else
        error('Need Real_Visual_Angle (or log2Real_Visual_Angle) to compute log2real_angle.');
    end
end

% log2(Distance)
if ~ismember('log2distance', tbl.Properties.VariableNames)
    if ismember('Distance', tbl.Properties.VariableNames)
        tbl.log2distance = log2(tbl.Distance);
    else
        error('Need Distance to compute log2distance.');
    end
end

% log2(1 + Elevation)
if ~ismember('log2elevation', tbl.Properties.VariableNames)
    if ismember('Elevation', tbl.Properties.VariableNames)
        tbl.log2elevation = log2(1 + tbl.Elevation);
    else
        error('Need Elevation to compute log2elevation.');
    end
end

% ID
if ~ismember('ID', tbl.Properties.VariableNames)
    error('Need ID column in table.');
end

end

function g = local_group_to_numeric(group)
% Convert group labels to numeric indices (required by nlmefit).
if isnumeric(group)
    g = group(:);
elseif iscategorical(group)
    g = double(group(:));
elseif isstring(group) || iscellstr(group)
    g = grp2idx(string(group(:)));
else
    try
        g = grp2idx(group(:));
    catch
        error('Unsupported ID/group type for nlmefit.');
    end
end
end

function cmap2 = local_resample_cmap(cmap, n)
% Ensure cmap is n-by-3. If not, interpolate.
if size(cmap,2) ~= 3
    error('cmap must be Nx3.');
end
m = size(cmap,1);
if m == n
    cmap2 = cmap;
    return
end
x0 = linspace(0,1,m);
x1 = linspace(0,1,n);
cmap2 = interp1(x0, cmap, x1, 'linear');
cmap2 = max(min(cmap2,1),0);
end

function [order_subj, subjIntercept] = local_order_subjects_by_intercept(lme, idU)
% Compute subject-specific intercepts (fixed + random intercept BLUP) and sort.

fe = fixedEffects(lme);
fixedIntercept = fe(1);

[re ,renames, restats] = randomEffects(lme); % table with Group/Level/Name/Estimate
name=renames.Name;
% Try to find intercept random effect rows robustly
isInt = contains(lower(name), 'intercept');

reInt = re(isInt, :);

% Map Level -> Estimate
lvl = string(reInt.Level);
est = reInt.Estimate;

subjIntercept = fixedIntercept + zeros(numel(idU),1);
for i = 1:numel(idU)
    key = string(idU(i));
    idx = find(lvl == key, 1, 'first');
    if ~isempty(idx)
        subjIntercept(i) = fixedIntercept + est(idx);
    else
        subjIntercept(i) = fixedIntercept; % fallback
    end
end

[~, order_subj] = sort(subjIntercept, 'ascend');
end

function local_plot_one_predictor_lme(ax, tbl, subjectcolor, lme, varName, xLabelStr, muX, maxPMLim)
% Partial-effect plot: vary varName, hold others at their mean.
% Plot ORIGINAL PM (linear) and back-transformed model predictions.

axes(ax); %#ok<LAXES>
hold on

pm_obs = 2.^tbl.log2ratio_visual_angle;
scatter(tbl.(varName), pm_obs, 30, subjectcolor, 'filled');

x = tbl.(varName);
xgrid = linspace(min(x), max(x), 200)';

newTbl = table();
newTbl.log2real_angle = repmat(muX(1), size(xgrid));
newTbl.log2distance   = repmat(muX(2), size(xgrid));
newTbl.log2elevation  = repmat(muX(3), size(xgrid));
newTbl.(varName)      = xgrid;
newTbl.ID = repmat(tbl.ID(1), size(xgrid)); % dummy ID

[yhat_log2, yCI_log2] = predict(lme, newTbl, 'Conditional', false);

pm_hat = 2.^yhat_log2;
pm_lo  = 2.^yCI_log2(:,1);
pm_hi  = 2.^yCI_log2(:,2);

plot(xgrid, pm_hat, 'k-', 'LineWidth', 3);
fill([xgrid; flipud(xgrid)], [pm_lo; flipud(pm_hi)], 1, ...
    'FaceColor', 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);

plot([min(xgrid) max(xgrid)], [1 1], 'k:', 'LineWidth', 1);

xlabel(xLabelStr);
ylabel('Perceptual Magnification (PM)');
ylim([0 maxPMLim]);
set(gca, 'FontName','Avenir', 'FontSize', 14);
grid on
end

function local_plot_one_predictor_nlme(ax, tbl, subjectcolor, nlmeS, whichPred, xLabelStr, maxPMLim)
% Partial-effect plot for NLME (predictors not centered).
% Plot ORIGINAL PM (linear) and back-transformed predictions.

axes(ax); %#ok<LAXES>
hold on

switch whichPred
    case 1
        x = tbl.log2real_angle;
    case 2
        x = tbl.log2distance;
    case 3
        x = tbl.log2elevation;
    otherwise
        error('whichPred must be 1,2,3.');
end

pm_obs = 2.^tbl.log2ratio_visual_angle;
scatter(x, pm_obs, 30, subjectcolor, 'filled');

xgrid = linspace(min(x), max(x), 200)';

beta = nlmeS.beta;

% Hold non-plotted predictors at raw means
x1m = mean(tbl.log2real_angle, 'omitnan');
x2m = mean(tbl.log2distance,   'omitnan');
x3m = mean(tbl.log2elevation,  'omitnan');

Xplot = [repmat(x1m, size(xgrid)), repmat(x2m, size(xgrid)), repmat(x3m, size(xgrid))];
Xplot(:, whichPred) = xgrid;

% Predicted mean in log2 space
yhat_log2 = beta(1) + beta(2)*Xplot(:,1) + beta(3)*Xplot(:,2) - exp(beta(4))*Xplot(:,3);

pm_hat = 2.^yhat_log2;
plot(xgrid, pm_hat, 'k-', 'LineWidth', 3);

% CI via delta method in log2 space (if covb available), then back-transform
stats = nlmeS.stats;
covb = [];
if isstruct(stats) && isfield(stats,'covb') && ~isempty(stats.covb)
    covb = stats.covb;
end

if ~isempty(covb)
    g = [ones(size(xgrid)), Xplot(:,1), Xplot(:,2), -(exp(beta(4))*Xplot(:,3))];

    varY = zeros(size(xgrid));
    for i = 1:numel(xgrid)
        gi = g(i,:);
        varY(i) = gi * covb * gi';
    end
    seY = sqrt(max(varY,0));
    ylo = yhat_log2 - 1.96*seY;
    yhi = yhat_log2 + 1.96*seY;

    pm_lo = 2.^ylo;
    pm_hi = 2.^yhi;

    fill([xgrid; flipud(xgrid)], [pm_lo; flipud(pm_hi)], 1, ...
        'FaceColor', 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);
end

plot([min(xgrid) max(xgrid)], [1 1], 'k:', 'LineWidth', 1);

xlabel(xLabelStr);
ylabel('Perceptual Magnification (PM)');
ylim([0 maxPMLim]);
set(gca, 'FontName','Avenir', 'FontSize', 14);
grid on
end

function local_plot_obs_vs_pred(ax, pm_obs, pm_pred, subjectcolor, titleStr)
axes(ax); %#ok<LAXES>
hold on
scatter(pm_obs, pm_pred, 30, subjectcolor, 'filled');

mx = max([pm_obs(:); pm_pred(:)], [], 'omitnan');
if ~isfinite(mx) || mx <= 0
    mx = 2;
end
mx = mx * 1.05;

plot([0 mx], [0 mx], 'k-', 'LineWidth', 2);
xlabel('Observed PM');
ylabel('Predicted PM');
title(titleStr, 'FontName','Avenir', 'FontSize', 14);

xlim([0 mx]); ylim([0 mx]);
axis square
grid on
set(gca, 'FontName','Avenir', 'FontSize', 12);
end

function local_sgtitle(tstr)
if exist('sgtitle','file') == 2
    sgtitle(tstr, 'FontName','Avenir','FontSize',18);
elseif exist('suptitle','file') == 2
    suptitle(tstr);
end
end
