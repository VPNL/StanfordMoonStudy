function [lme_unconstrained, nlme_constrained] = fit_PM_lme_and_constrained_nlme(tbl, tblName, ResultsDir, saveModels, cmap, sorted_idx)
% fit_PM_lme_and_constrained_nlme
%
% Fits:
%   (1) Unconstrained linear mixed-effects model (fitlme):
%       log2(PM) ~ log2(VA) + log2(D) + log2(1+E) + (1|ID)
%
%   (2) Constrained negative-elevation nonlinear mixed-effects model (nlmefit):
%       log2(PM) = b1 + b2*X1 + b3*X2 - exp(b4)*X3  (raw X; elevation slope constrained negative)
%       where the elevation slope is -exp(b4) < 0 (by construction).
%
% Also generates two figures:
%   <tblName>.png                       (unconstrained LME)
%   <tblName>_ConstrainedNegElev.png    (constrained NLME)
%
% Inputs
%   tbl        : MATLAB table containing at least ID and either:
%                - log2ratio_visual_angle, log2real_angle, log2distance, log2elevation
%                  OR
%                - Ratio_Visual_Angle (or Reported_Visual_Angle + Real_Visual_Angle),
%                  Real_Visual_Angle, Distance, Elevation
%   tblName    : string/char used for figure titles and output filenames
%   ResultsDir : output directory for figures/models (set [] or '' to skip saving)
%   saveModels : logical, if true saves fitted model outputs to .mat
%   cmap       : Nx3 colormap (optional). If empty, uses jet.
%   sorted_idx : ordering for subject colors (optional). If empty, uses 1:N.
%
% Outputs
%   lme_unconstrained : fitted LinearMixedModel from fitlme
%   nlme_constrained  : struct with fields:
%       .beta, .psi, .stats, .b, .xMean, .modelFcn, .didFit, .message
%
% Notes
% - This function avoids version-specific nlmefit name-value pairs
%   (e.g., no 'ComputeStdErrors') to improve compatibility.
% - Predictors are not mean-centered (user preference).
%
% K. (and ChatGPT) — generated Jan 2026

%% defaults / input hygiene
if nargin < 2 || isempty(tblName);    tblName = 'PM_Model'; end
if nargin < 3 || isempty(ResultsDir); ResultsDir = ''; end
if nargin < 4 || isempty(saveModels); saveModels = false; end
if nargin < 5; cmap = []; end
if nargin < 6; sorted_idx = []; end

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

group = tbl.ID;
group = local_group_to_numeric(group);

good = all(isfinite([Xraw yraw group]), 2);
tbl  = tbl(good,:);
Xraw = Xraw(good,:);
y    = yraw(good,:);
group = group(good,:);

if height(tbl) < 10
    error('Not enough valid rows after filtering (n=%d).', height(tbl));
end

%% subject colors
[uniqueGroup, ~, gi] = unique(group, 'stable');
nSubj = numel(uniqueGroup);

if isempty(cmap)
    cmap = jet(max(nSubj, 3));
end

if isempty(sorted_idx)
    sorted_idx = 1:nSubj;
end

subjectcolor = zeros(height(tbl), 3);
for r = 1:height(tbl)
    cindex = gi(r);
    % map through sorted order if provided
    sidx = find(sorted_idx == cindex, 1, 'first');
    if isempty(sidx); sidx = cindex; end
    sidx = max(1, min(size(cmap,1), sidx));
    subjectcolor(r,:) = cmap(sidx,:);
end

%% (1) Unconstrained LME (fitlme)
formula = 'log2ratio_visual_angle ~ 1 + log2real_angle + log2distance + log2elevation + (1|ID)';
lme_unconstrained = fitlme(tbl, formula);

%% (2) Constrained NLME with negative elevation slope
% Do not mean-center predictors (user preference). Keep raw predictors.
xMean = mean(Xraw, 1, 'omitnan');
X = Xraw;
model_constrained = @(beta, X) beta(1) + beta(2)*X(:,1) + beta(3)*X(:,2) - exp(beta(4))*X(:,3);

% robust starting values
fe = fixedEffects(lme_unconstrained);
% fe = [intercept; slope_VA; slope_D; slope_E]
b2_0 = fe(2);
b3_0 = fe(3);

elevMag0 = max(0.05, abs(fe(4)));      % avoid exp(beta4) ~ 0
beta0 = [mean(y,'omitnan'), b2_0, b3_0, log(elevMag0)];

% nlmefit options
opts = statset('nlmefit');
opts.MaxIter = 200;
opts.TolFun  = 1e-8;
opts.TolX    = 1e-8;

nlme_constrained = struct();
nlme_constrained.didFit  = false;
nlme_constrained.message = '';

try
    [beta_c, psi_c, stats_c, b_c] = nlmefit(X, y, group, [], model_constrained, beta0, ...
        'FEParamsSelect', true(1,4), ...
        'REParamsSelect', [true false false false], ... % random intercept only
        'Vectorization', 'SingleGroup', ...
        'Options', opts);

    nlme_constrained.beta = beta_c;
    nlme_constrained.psi  = psi_c;
    nlme_constrained.stats = stats_c;
    nlme_constrained.b    = b_c;
    nlme_constrained.muX  = [];
    nlme_constrained.xMean = xMean;
    nlme_constrained.modelFcn = model_constrained;
    nlme_constrained.didFit = true;
catch ME
    nlme_constrained.beta = [];
    nlme_constrained.psi  = [];
    nlme_constrained.stats = [];
    nlme_constrained.b    = [];
    nlme_constrained.muX  = [];
    nlme_constrained.xMean = xMean;
    nlme_constrained.modelFcn = model_constrained;
    nlme_constrained.didFit = false;
    nlme_constrained.message = ME.message;
end

%% plotting helpers
% Common x-ranges
minPMLim = max(0.05, min(2.^y, [], 'omitnan'));
maxPMLim = max(2.^y, [], 'omitnan');

% Hold-at values for partial-effect plots (do NOT center data; just use raw predictor means)
muX = [mean(tbl.log2real_angle,'omitnan'), mean(tbl.log2distance,'omitnan'), mean(tbl.log2elevation,'omitnan')];
muX(~isfinite(muX)) = 0;


% Prepare newTbl for LME prediction (population-level)
newTblBase = table();
newTblBase.ID = repmat(tbl.ID(1), 1, 1); %#ok<STRNU> used only as placeholder

% -------------- FIGURE 1: Unconstrained LME --------------
fig1 = figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .5],'Name',tblName);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme_unconstrained, ...
    'log2real_angle', 'Visual Angle [deg], log2 scale', muX, minPMLim, maxPMLim);

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme_unconstrained, ...
    'log2distance', 'Distance [m], log2 scale', muX, minPMLim, maxPMLim);

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme_unconstrained, ...
    'log2elevation', 'Elevation [deg], log2 scale (log2(1+E))', muX, minPMLim, maxPMLim);

sgtitle(sprintf('%s: Unconstrained LME', tblName), 'FontName','Avenir','FontSize',18);

if ~isempty(ResultsDir)
    if ~exist(ResultsDir,'dir'); mkdir(ResultsDir); end
    exportgraphics(fig1, fullfile(ResultsDir, [tblName '.png']), 'Resolution', 600);
end

% -------------- FIGURE 2: Constrained negative elevation slope --------------
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
        1, 'Visual Angle [deg], log2 scale', minPMLim, maxPMLim);

    local_plot_one_predictor_nlme(ax2, tbl, subjectcolor, nlme_constrained, ...
        2, 'Distance [m], log2 scale', minPMLim, maxPMLim);

    local_plot_one_predictor_nlme(ax3, tbl, subjectcolor, nlme_constrained, ...
        3, 'Elevation [deg], log2 scale (log2(1+E))', minPMLim, maxPMLim);

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

% VA
if ~ismember('log2real_angle', tbl.Properties.VariableNames)
    if ismember('Real_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = log2(tbl.Real_Visual_Angle);
    elseif ismember('log2Real_Visual_Angle', tbl.Properties.VariableNames)
        tbl.log2real_angle = tbl.log2Real_Visual_Angle;
    else
        error('Need Real_Visual_Angle to compute log2real_angle.');
    end
end

% Distance
if ~ismember('log2distance', tbl.Properties.VariableNames)
    if ismember('Distance', tbl.Properties.VariableNames)
        tbl.log2distance = log2(tbl.Distance);
    else
        error('Need Distance to compute log2distance.');
    end
end

% Elevation (regularized as 1+E before log)
if ~ismember('log2elevation', tbl.Properties.VariableNames)
    if ismember('Elevation', tbl.Properties.VariableNames)
        tbl.log2elevation = log2(1 + tbl.Elevation);
    else
        error('Need Elevation to compute log2elevation.');
    end
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

function local_plot_one_predictor_lme(ax, tbl, subjectcolor, lme, varName, xLabelStr, muX, minPMLim, maxPMLim)
% Partial-effect plot: vary varName, hold others at their mean.
axes(ax); %#ok<LAXES>
hold on

scatter(tbl.(varName), tbl.log2ratio_visual_angle, 30, subjectcolor, 'filled');

% build new data varying one predictor
x = tbl.(varName);
xgrid = linspace(min(x), max(x), 200)';

newTbl = table();
newTbl.log2real_angle = repmat(muX(1), size(xgrid));
newTbl.log2distance   = repmat(muX(2), size(xgrid));
newTbl.log2elevation  = repmat(muX(3), size(xgrid));
newTbl.(varName)      = xgrid;

% dummy ID for predict; use Conditional=false to get population-level
newTbl.ID = repmat(tbl.ID(1), size(xgrid));

[yhat, yCI] = predict(lme, newTbl, 'Conditional', false);

plot(xgrid, yhat, 'k-', 'LineWidth', 3);

% CI ribbon
fill([xgrid; flipud(xgrid)], [yCI(:,1); flipud(yCI(:,2))], 1, ...
    'FaceColor', 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);

% reference line at PM=1
plot([min(xgrid) max(xgrid)], [0 0], 'k:', 'LineWidth', 1);

xlabel(xLabelStr);
ylabel('Perceptual Magnification, log2 scale');
ylim([log2(minPMLim) ceil(log2(maxPMLim))]);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',round(2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]),1)  );

set(gca, 'FontName','Avenir', 'FontSize', 14);
grid on
end

function local_plot_one_predictor_nlme(ax, tbl, subjectcolor, nlmeS, whichPred, xLabelStr, minPMLim, maxPMLim)
% Partial-effect plot for NLME (predictors not mean-centered):
% y = b1 + b2*X1 + b3*X2 - exp(b4)*X3
axes(ax); %#ok<LAXES>
hold on

% choose x variable
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

scatter(x, tbl.log2ratio_visual_angle, 30, subjectcolor, 'filled');

xgrid = linspace(min(x), max(x), 200)';

beta = nlmeS.beta;

% Hold the two non-plotted predictors at their sample means (not centered)
x1m = mean(tbl.log2real_angle, 'omitnan');
x2m = mean(tbl.log2distance,   'omitnan');
x3m = mean(tbl.log2elevation,  'omitnan');

Xplot = [repmat(x1m, size(xgrid)), repmat(x2m, size(xgrid)), repmat(x3m, size(xgrid))];
Xplot(:, whichPred) = xgrid;

% Predicted mean
yhat = beta(1) + beta(2)*Xplot(:,1) + beta(3)*Xplot(:,2) - exp(beta(4))*Xplot(:,3);

% Jacobian of yhat wrt beta (delta method)
g = [ones(size(xgrid)), Xplot(:,1), Xplot(:,2), -(exp(beta(4))*Xplot(:,3))];
plot(xgrid, yhat, 'k-', 'LineWidth', 3);

% CI via delta method if covb present
ylo = []; yhi = [];
stats = nlmeS.stats;
covb = [];
if isstruct(stats) && isfield(stats,'covb') && ~isempty(stats.covb)
    covb = stats.covb;
end
if ~isempty(covb)
    varY = zeros(size(xgrid));
    for i = 1:numel(xgrid)
        gi = g(i,:); %#ok<NASGU>
        varY(i) = gi * covb * gi';
    end
    seY = sqrt(max(varY,0));
    ylo = yhat - 1.96*seY;
    yhi = yhat + 1.96*seY;

    fill([xgrid; flipud(xgrid)], [ylo; flipud(yhi)], 1, ...
        'FaceColor', 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.25);
end

plot([min(xgrid) max(xgrid)], [0 0], 'k:', 'LineWidth', 1);

xlabel(xLabelStr);
ylabel('Perceptual Magnification, log2 scale');
ylim([log2(minPMLim) ceil(log2(maxPMLim))]);
set(gca, 'FontName','Avenir', 'FontSize', 14);
grid on
end


function local_sgtitle(tstr)
% Compatible super-title helper.
if exist('sgtitle','file') == 2
    sgtitle(tstr, 'FontName','Avenir','FontSize',18);
elseif exist('suptitle','file') == 2
    suptitle(tstr);
else
    % fallback: do nothing
end
end