function [lme] = fit_PM_full_VA_D_E_model(tbl, tblName, ResultsDir, saveModels, mycolormap, sorted_idx, ElevationTransform)
% fit_PM_full_VA_D_E_model
% Fit the full VA/D/E perceptual magnification LME and plot model fits.
%
% Can use several transforms for Elevation
%   (1) linear mixed-effects model (fitlme): ElevationTranform==1
%       log2(PM) ~ log2(VA) + log2(D) + log2(1+E) + (1|ID)
%   (2)  ElevationTranform==2
%       log2(PM) ~ log2(VA) + log2(D) + log2(1+|E|) + (1|ID)
%   (3)  ElevationTransform==3
%       log2(PM) ~ log2(VA) + log2(D) + log2(1+E/90) + (1|ID)
%   (4)  ElevationTransform==4
%       log2(PM) ~ log2(VA) + log2(D) + log2(1+|E|/90) + (1|ID)
% Also generates a figure:
%   <tblName>.png                       (LME)
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
%   lme : fitted LinearMixedModel from fitlme
% 
%%
% KGS. (and ChatGPT) — generated Jan 2026

%% defaults / input hygiene
if nargin < 2 || isempty(tblName);    tblName = 'PM_Model'; end
if nargin < 3 || isempty(ResultsDir); ResultsDir = ''; end
if nargin < 4 || isempty(saveModels); saveModels = false; end
if nargin < 5; cmap = []; end
if nargin < 6; sorted_idx = []; end
if nargin < 7 || isempty(ElevationTransform); ElevationTransform = 1; end

if ~istable(tbl)
    error('Input tbl must be a MATLAB table.');
end

ElevationTransform = normalize_quad_pm_transform_id(ElevationTransform, 'standard');

%% ensure required variables exist (compute if needed)
tbl = local_ensure_log_variables(tbl,ElevationTransform);

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
% [uniqueGroup, ~, gi] = unique(group, 'stable');
% nSubj = numel(uniqueGroup);
% 
% if isempty(cmap)
%     cmap = jet(max(nSubj, 3));
% end
% 
% if isempty(sorted_idx)
%     sorted_idx = 1:nSubj;
% end
% 
% subjectcolor = zeros(height(tbl), 3);
% for r = 1:height(tbl)
%     cindex = gi(r);
%     % map through sorted order if provided
%     sidx = find(sorted_idx == cindex, 1, 'first');
%     if isempty(sidx); sidx = cindex; end
%     sidx = max(1, min(size(cmap,1), sidx));
%     subjectcolor(r,:) = cmap(sidx,:);
% end

uniqueID=unique(tbl.ID);
nsubjects=length(uniqueID);

ID=tbl.ID;
clear subjectcolor
for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=mycolormap(sorted_cindex,:);
end

%% (1) LME (fitlme)
formula = 'log2ratio_visual_angle ~ 1 + log2real_angle + log2distance + log2elevation + (1|ID)';
lme = fitlme(tbl, formula)
Intercept=lme.Coefficients.Estimate(1);
VAe=lme.Coefficients.Estimate(2);
De=lme.Coefficients.Estimate(3);
Ee=lme.Coefficients.Estimate(4);
if ElevationTransform==1
  titlestr=sprintf('PM=%.2fVA^{%.2f}D^{%.2f}(1+E)^{%.2f}\n', 2.^Intercept,VAe,De,Ee);
elseif ElevationTransform==2
  titlestr=sprintf('PM=%.2fVA^{%.2f}D^{%.2f}(1+|E|)^{%.2f}\n', 2.^Intercept,VAe,De,Ee);
  % titlestr=sprintf('PM=cVA^{%.2f}D^{%.2f}(1+|E|)^{%.2f}\n',VAe,De,Ee);
elseif ElevationTransform==5
  titlestr=sprintf('PM=%.2fVA^{%.2f}D^{%.2f}(1+E/90)^{%.2f}\n', 2.^Intercept,VAe,De,Ee);
elseif ElevationTransform==6
  titlestr=sprintf('PM=%.2fVA^{%.2f}D^{%.2f}(1+|E|/90)^{%.2f}\n', 2.^Intercept,VAe,De,Ee);

end


%% plotting helpers
% Common x-ranges
minPMLim = max(0.05, min(2.^y, [], 'omitnan'));
maxPMLim = max(2.^y, [], 'omitnan');
minPMLim=.25;
maxPMLim=16;
% Hold-at values for partial-effect plots (do NOT center data; just use raw predictor means)
muX = [mean(tbl.log2real_angle,'omitnan'), mean(tbl.log2distance,'omitnan'), mean(tbl.log2elevation,'omitnan')];
muX(~isfinite(muX)) = 0;


% Prepare newTbl for LME prediction (population-level)
newTblBase = table();
newTblBase.ID = repmat(tbl.ID(1), 1, 1); %#ok<STRNU> used only as placeholder

% -------------- FIGURE 1: LME --------------
fig1 = figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .7],'Name',tblName);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme, ...
    'log2real_angle', {'Visual Angle [deg]','log scale'}, muX, minPMLim, maxPMLim, true, ElevationTransform);

local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme, ...
    'log2distance', {'Distance [m]', 'log scale'}, muX, minPMLim, maxPMLim, false, ElevationTransform);

if ElevationTransform==1
    local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme, ...
    'log2elevation', {'Elevation [deg]', 'log scale'}, muX, minPMLim, maxPMLim, true, ElevationTransform);
elseif ElevationTransform==2
    local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme, ...
    'log2elevation', {'|Elevation| [deg]', 'log scale'}, muX, minPMLim, maxPMLim, true, ElevationTransform);
elseif ElevationTransform==5
    local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme, ...
    'log2elevation', {'Elevation [deg]', 'log scale'}, muX, minPMLim, maxPMLim, true, ElevationTransform);
elseif ElevationTransform==6
    local_plot_one_predictor_lme(nexttile, tbl, subjectcolor, lme, ...
    'log2elevation', {'|Elevation| [deg]', 'log scale'}, muX, minPMLim, maxPMLim, true, ElevationTransform);
end
%sgtitle(sprintf('%s: Unconstrained LME', tblName), 'FontName','Avenir','FontSize',18);
sgtitle(titlestr,'FontSize',24,'FontName','Avenir')
if ~isempty(ResultsDir)
    if ~exist(ResultsDir,'dir'); mkdir(ResultsDir); end
    exportgraphics(fig1, fullfile(ResultsDir, [tblName '.png']), 'Resolution', 600);
end


%% optionally save models
if saveModels && ~isempty(ResultsDir)
    if ~exist(ResultsDir,'dir'); mkdir(ResultsDir); end
    save(fullfile(ResultsDir, [tblName '.mat']), 'lme');
end

end

%% ----------------------- Local functions -----------------------

function tbl = local_ensure_log_variables(tbl,ElevationTransform)
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
        if  ElevationTransform==1
            tbl.log2elevation = log2(1 + tbl.Elevation); % l
        elseif ElevationTransform==2
            tbl.log2elevation = log2(1 + abs(tbl.Elevation)); % 
        elseif ElevationTransform==5
            tbl.log2elevation = log2(1 + tbl.Elevation/90); %
        elseif ElevationTransform==6
            tbl.log2elevation = log2(1 + abs(tbl.Elevation)/90); %
        end

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

function local_plot_one_predictor_lme(ax, tbl, subjectcolor, lme, varName, xLabelStr, muX, minPMLim, maxPMLim, addMax, ElevationTransform)
% Partial-effect plot: vary varName, hold others at their mean.
if nargin < 10 || isempty(addMax)
    addMax = true;
end
if nargin < 11 || isempty(ElevationTransform)
    ElevationTransform = 1;
end

axes(ax); 
hold on
markersize=50;
scatter(tbl.(varName), tbl.log2ratio_visual_angle, markersize, subjectcolor, 'filled');

% build new data varying one predictor
x = tbl.(varName);
[xt, xlbl, xlimVals] = local_pm_ticks(x, varName, ElevationTransform);
xgrid = linspace(xlimVals(1), xlimVals(2), 200)';

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
set(ax,'XLim',xlimVals,'XTick',xt,'XTickLabel',xlbl);
% reference line at PM=1
plot([min(xgrid) max(xgrid)], [0 0], 'k-', 'LineWidth', 1);
set(gca, 'FontName','Avenir', 'FontSize', 24);
xlabel(xLabelStr);
if strcmp(varName,'log2real_angle')
    ylabel({'Perceptual Magnification' 'log scale'});
else
    ylabel('');
    ax.YColor = 'w';
end
ylim([log2(minPMLim) ceil(log2(maxPMLim))]);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',round(2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]),1)  );

end

function [xt, xlbl, xlimVals] = local_pm_ticks(x, varName, ElevationTransform)
minX = min(x);
maxX = max(x);

switch varName
    case 'log2real_angle'
        tickdelta = (maxX - minX) / 3;
        if ~isfinite(tickdelta) || tickdelta <= 0
            xt = [minX maxX];
        else
            xt = minX:tickdelta:maxX;
        end
        xlbl = local_format_tick_labels(round(2.^xt, 1));
        xlimVals = [log2((2.^minX) * 0.95) log2((2.^maxX) * 1.05)];
    case 'log2distance'
        xt = unique([minX maxX], 'stable');
        xlbl = local_format_tick_labels(round(2.^xt, 0));
        xlimVals = [log2((2.^minX) * 0.95) log2((2.^maxX) * 1.05)];
    otherwise
        xt = unique([minX maxX], 'stable');
        if any(ElevationTransform == [5 6])
            nativeVals = 90 * ((2.^xt) - 1);
            xlbl = local_format_tick_labels(round(nativeVals, 1));
        else
            nativeVals = (2.^xt) - 1;
            xlbl = local_format_tick_labels(round(nativeVals, 1));
        end
        if any(ElevationTransform == [5 6])
            nativeAll = 90 * ((2.^x) - 1);
            span = max(nativeAll) - min(nativeAll);
            margin = max(0.05 * span, 0.5);
            plotMinNative = max(0, min(nativeAll) - margin);
            plotMaxNative = max(nativeAll) + margin;
            xlimVals = log2([1 + plotMinNative / 90, 1 + plotMaxNative / 90]);
        else
            nativeAll = (2.^x) - 1;
            span = max(nativeAll) - min(nativeAll);
            margin = max(0.05 * span, 0.5);
            plotMinNative = max(0, min(nativeAll) - margin);
            plotMaxNative = max(nativeAll) + margin;
            xlimVals = log2([1 + plotMinNative, 1 + plotMaxNative]);
        end
end
end

function labels = local_format_tick_labels(vals)
labels = strings(size(vals));
for i = 1:numel(vals)
    if abs(vals(i)) > 1000
        labels(i) = sprintf('%.1e', vals(i));
    else
        labels(i) = string(vals(i));
    end
end
end
