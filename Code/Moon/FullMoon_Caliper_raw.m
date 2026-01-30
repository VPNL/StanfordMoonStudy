%% Caliper (cm) vs Elevation (deg) LME + subject-colored scatter
% Assumes the CSV has one or more "Caliper ..." columns (e.g., Round 1/2),
% and corresponding Elevation columns. Adjust csvFile as needed.

clear; clc;

%% ---- User settings ----
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
cd(dataDir)
csvFile = 'FullMoonRawData090225.csv';          % <-- update path if needed
caliperFieldPattern = 'Caliper Aperture';      % e.g., 'Caliper Aperture' or 'Caliper Distance'

%% ---- Read table (preserve original column names) ----
opts = detectImportOptions(csvFile);
opts.VariableNamingRule = 'preserve';
T = readtable(csvFile, opts);

vars = T.Properties.VariableNames;

%% ---- Identify ID, Elevation, and Caliper columns ----
% ID column
if any(strcmp(vars,'ID Number'))
    idVar = 'ID Number';
elseif any(strcmpi(strtrim(vars),'ID'))
    idVar = vars{find(strcmpi(strtrim(vars),'ID'),1)};
else
    % fallback: first variable that starts with "ID"
    idx = find(startsWith(lower(strtrim(vars)),'id'), 1);
    if isempty(idx), error('Could not find an ID column.'); end
    idVar = vars{idx};
end

% Elevation columns (often one per round; sometimes one has a trailing space)
elevVars = vars( contains(lower(vars),'elevation') & contains(lower(vars),'deg') );
if isempty(elevVars)
    error('Could not find any Elevation columns (expected something like "Elevation (deg)").');
end

% Caliper columns
calVars = vars( contains(lower(vars), lower(caliperFieldPattern)) );
if isempty(calVars)
    % fallback: any caliper columns
    calVars = vars( contains(lower(vars),'caliper') );
end
if isempty(calVars)
    error('Could not find any Caliper columns.');
end

%% ---- Build a long-format table using only rows with caliper entries ----
long = table();
for c = 1:numel(calVars)
    calVar = calVars{c};

    % infer round number from column name (e.g., "Round 2 ...")
    tok = regexp(calVar,'Round\s*(\d+)','tokens','once','ignorecase');
    if ~isempty(tok)
        roundNum = str2double(tok{1});
    else
        roundNum = c;
    end

    % choose an elevation column for this round (assumes elevVars are in round order)
    elevVar = elevVars{min(roundNum, numel(elevVars))};

    tmp = table();
    tmp.ID        = T.(idVar);
    tmp.Elevation = T.(elevVar);
    tmp.Caliper   = T.(calVar);
    tmp.Round     = repmat(roundNum, height(T), 1);

    % keep only rows with entries for caliper (and elevation)
    valid = ~isnan(tmp.Caliper) & ~isnan(tmp.Elevation);
    tmp = tmp(valid,:);

    long = [long; tmp]; %#ok<AGROW>
end

% Make ID categorical (stable labels)
if isnumeric(long.ID)
    long.ID = categorical(compose('%g', long.ID));
else
    long.ID = categorical(string(long.ID));
end

%% ---- Fit LME (recommended: center elevation so intercept is meaningful) ----
muElev = mean(long.Elevation, 'omitnan');
long.Elev_c = long.Elevation - muElev;

lme = fitlme(long, 'Caliper ~ Elev_c + (Elev_c|ID)');
disp(lme);
[feEfx,feRDNames,festats] =fixedEffects(lme);
[reEfx,reNames,reStats] = randomEffects(lme);


%% ---- Subject "intercepts" for sorting (conditional prediction at Elev_c = 0) ----
allIDs = categories(long.ID);
n      = numel(allIDs);

subIntercept = nan(n,1);
for i = 1:n
    % Conditional prediction includes each subject's random intercept (and slope,
    % but slope term drops out at Elev_c = 0)
    tbl0 = table(categorical(allIDs(i)), 0, 'VariableNames', {'ID','Elev_c'});
    subIntercept(i) = predict(lme, tbl0, 'Conditional', true);
end

reInt = table(categorical(allIDs), subIntercept, 'VariableNames', {'ID','SubjectIntercept'});
reInt = sortrows(reInt, 'SubjectIntercept', 'ascend');

%% ---- Plot: CI shaded (light gray) + fit line (black) + colored scatter ----
cmap = jet(n);

figure('Color','w'); hold on;

% (A) Population-level fit + 95% CI (marginal / fixed-effects)
xgrid  = linspace(min(long.Elevation), max(long.Elevation), 200)';  % original elevation scale
xgridc = xgrid - muElev;                                            % centered

dummyID = repmat(reInt.ID(1), numel(xgridc), 1);
newTbl  = table(dummyID, xgridc, 'VariableNames', {'ID','Elev_c'});

[yHat, yCI] = predict(lme, newTbl, 'Conditional', false);  % marginal fit

% shaded CI (light gray)
fill([xgrid; flipud(xgrid)], [yCI(:,1); flipud(yCI(:,2))], [0.85 0.85 0.85], ...
     'EdgeColor','none', 'FaceAlpha', 0.5);

% fit line (black, thick)
plot(xgrid, yHat, 'k-', 'LineWidth', 5);

% (B) Scatter colored by subject intercept rank (low=blue, high=red)
for i = 1:n
    id  = reInt.ID(i);
    idx = (long.ID == id);
    scatter(long.Elevation(idx), long.Caliper(idx), 36, cmap(i,:), ...
        'filled', 'MarkerEdgeColor','none', 'MarkerFaceAlpha',0.85);
end

xlabel('Elevation (deg)');
ylabel('Caliper (cm)');
set(gca,'FontName','Avenir','FontSize',20)
if festats.pValue(2)<0.001
    titlestr=sprintf('Calipher[cm]=%.2f+%.2f*Elevation[deg], p=%.2e\n n=%d',feEfx(1),feEfx(2),festats.pValue(2),n);
else
    titlestr=sprintf('Calipher[cm]=%.2f+%.2f*Elevation[deg], p=%.2f\n n=%d',feEfx(1),feEfx(2),festats.pValue(2),n);
end
title(titlestr,'FontSize',12)

box on;
colormap(jet);
cb = colorbar;
cb.Ticks = [0 1];
cb.TickLabels = {'Lower intercept','Higher intercept'};
cb.Label.String = 'Subject intercept rank';
