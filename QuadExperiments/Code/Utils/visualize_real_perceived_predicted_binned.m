function summaryTbl = visualize_real_perceived_predicted_binned(data_tbl, lme_logPM_by_logAngleNDistanceNElevation, ResultsDir, FigName, binParam, minUniqueIDs, VAmax, distance_mm, idVar)
%VISUALIZE_REAL_PERCEIVED_PREDICTED_BINNED
% Summarize and visualize Real/Perceived/Predicted size by binned levels of a chosen parameter.
%
% summaryTbl = visualize_real_perceived_predicted_binned(data_tbl, lme, ResultsDir, FigName, ...
%                     binParam, minUniqueIDs, VAmax, distance_mm, idVar)
%
% Inputs
%   data_tbl   : table containing at least
%                Real_Visual_Angle, Ratio_Visual_Angle, Distance, Elevation, and an ID variable.
%   lme        : fitted linear mixed effects model used by evaluatePMbyVisualAngleDistanceElevation
%   ResultsDir : output directory for PNGs (default '.')
%   FigName    : filename prefix for figures (default 'Visualize')
%   binParam   : 'Real_Visual_Angle' or 'Distance' or 'Elevation'
%   minUniqueIDs : minimum number of unique IDs per bin (integer >= 1)
%   VAmax      : optional filter; keep rows with Real_Visual_Angle < VAmax (default Inf)
%   distance_mm: viewing distance used for visualangle2height conversion (default 500)
%   idVar      : name of the ID column (default 'ID'; will auto-detect common alternatives)
%
% Output
%   summaryTbl : table with per-bin means and counts.

% -----------------------
% Input validation
% -----------------------
if ~exist('data_tbl','var') || ~istable(data_tbl)
    error('data_tbl must be a MATLAB table.');
end
if ~exist('lme_logPM_by_logAngleNDistanceNElevation','var')
    error('Must provide lme model to evaluate PM.');
end
if ~exist('ResultsDir','var') || isempty(ResultsDir)
    ResultsDir='.';
end
if ~exist('FigName','var') || isempty(FigName)
    FigName='Visualize';
end
if ~exist('binParam','var') || isempty(binParam)
    error('binParam must be provided: ''Real_Visual_Angle'', ''Distance'', or ''Elevation''.');
end
if isstring(binParam), binParam = char(binParam); end
if ~ischar(binParam)
    error('binParam must be a char or string.');
end
allowedParams = {'Real_Visual_Angle','Distance','Elevation'};
if ~ismember(binParam, allowedParams)
    error('binParam must be one of: %s', strjoin(allowedParams, ', '));
end
if ~exist('minUniqueIDs','var') || isempty(minUniqueIDs)
    minUniqueIDs = 1;
end
if ~(isscalar(minUniqueIDs) && isnumeric(minUniqueIDs) && isfinite(minUniqueIDs) && minUniqueIDs>=1)
    error('minUniqueIDs must be a scalar integer >= 1.');
end
minUniqueIDs = round(minUniqueIDs);
if ~exist('VAmax','var') || isempty(VAmax)
    VAmax = inf;
end
if ~exist('distance_mm','var') || isempty(distance_mm)
    distance_mm = 500;
end

% Required columns
reqVars = {'Real_Visual_Angle','Ratio_Visual_Angle','Distance','Elevation'};
missing = setdiff(reqVars, data_tbl.Properties.VariableNames);
if ~isempty(missing)
    error('data_tbl is missing required variables: %s', strjoin(missing, ', '));
end

% ID column detection
if ~exist('idVar','var') || isempty(idVar)
    idVar = 'ID';
end
if isstring(idVar), idVar = char(idVar); end
if ~ismember(idVar, data_tbl.Properties.VariableNames)
    % Try common alternatives
    candidates = {'Subject','Subj','SubID','Participant','ParticipantID','ID'};
    found = intersect(candidates, data_tbl.Properties.VariableNames, 'stable');
    if ~isempty(found)
        idVar = found{1};
    else
        error('Could not find an ID variable. Provide idVar and ensure it exists in data_tbl.');
    end
end

% -----------------------
% Subset and precompute per-row perceived/predicted
% -----------------------
keep = data_tbl.Real_Visual_Angle < VAmax;
keep = keep & ~isnan(data_tbl.Real_Visual_Angle) & ~isnan(data_tbl.Ratio_Visual_Angle);
keep = keep & ~isnan(data_tbl.Distance) & ~isnan(data_tbl.Elevation);
keep = keep & ~isnan(data_tbl.(binParam));

tbl = data_tbl(keep,:);
if isempty(tbl)
    warning('No data left after filtering. Returning empty summary table.');
    summaryTbl = table();
    return;
end

realVA_row      = tbl.Real_Visual_Angle;
perceivedVA_row = tbl.Real_Visual_Angle .* tbl.Ratio_Visual_Angle;
D_row           = tbl.Distance;
E_row           = tbl.Elevation;

% Evaluate predicted PM per row and derive predicted VA per row
PM_row = arrayfun(@(va,d,e) evaluatePMbyVisualAngleDistanceElevation( ...
    lme_logPM_by_logAngleNDistanceNElevation, va, d, e), realVA_row, D_row, E_row);

predictedVA_row = realVA_row .* PM_row;

% -----------------------
% Build bins over binParam to satisfy minUniqueIDs
% -----------------------
vals = tbl.(binParam);
[uniqueVals, ~, loc] = unique(vals); % loc maps each row to its unique value index
[uniqueValsSorted, sortIdx] = sort(uniqueVals);

% Remap loc to sorted unique indices
invSort(sortIdx,1) = 1:numel(sortIdx); %#ok<AGROW>
locSorted = invSort(loc);

binStarts = [];
binEnds   = [];
startU = 1;
U = numel(uniqueValsSorted);

while startU <= U
    endU = startU;
    while endU <= U
        m = (locSorted >= startU) & (locSorted <= endU);
        nIDs = numel(unique(tbl.(idVar)(m)));
        if nIDs >= minUniqueIDs
            break;
        end
        endU = endU + 1;
    end
    if endU > U
        endU = U; % last bin: take remainder even if it doesn't reach minUniqueIDs
    end
    binStarts(end+1,1) = startU; %#ok<AGROW>
    binEnds(end+1,1)   = endU;   %#ok<AGROW>
    startU = endU + 1;
end

nBins = numel(binStarts);

% -----------------------
% Summarize bins and generate figures
% -----------------------
BinIndex        = (1:nBins)';
BinParamMin     = nan(nBins,1);
BinParamMax     = nan(nBins,1);
NRows           = zeros(nBins,1);
NUniqueIDs      = zeros(nBins,1);
MeanRealVA      = nan(nBins,1);
MeanDistance    = nan(nBins,1);
MeanElevation   = nan(nBins,1);
MeanPerceivedVA = nan(nBins,1);
MeanPredictedVA = nan(nBins,1);

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir);
end

for b = 1:nBins
    u1 = binStarts(b);
    u2 = binEnds(b);
    m = (locSorted >= u1) & (locSorted <= u2);

    BinParamMin(b) = uniqueValsSorted(u1);
    BinParamMax(b) = uniqueValsSorted(u2);

    NRows(b)      = sum(m);
    NUniqueIDs(b) = numel(unique(tbl.(idVar)(m)));

    MeanRealVA(b)      = mean(realVA_row(m), 'omitnan');
    MeanDistance(b)    = mean(D_row(m), 'omitnan');
    MeanElevation(b)   = mean(E_row(m), 'omitnan');
    MeanPerceivedVA(b) = mean(perceivedVA_row(m), 'omitnan');
    MeanPredictedVA(b) = mean(predictedVA_row(m), 'omitnan');

    % Convert mean VAs to radii in mm for display
    realRadius_mm      = visualangle2height(MeanRealVA(b), distance_mm);
    perceivedRadius_mm = visualangle2height(MeanPerceivedVA(b), distance_mm);
    predictedRadius_mm = visualangle2height(MeanPredictedVA(b), distance_mm);

    % Text string includes bin range and mean VA/D/E
    textstring = sprintf('VA=%.1f[{\\circ}] D=%.1f[m] E=%.1f[{\\circ}] n=%d', ...
         MeanRealVA(b), MeanDistance(b), MeanElevation(b), NUniqueIDs(b));

    saveFlag = 1;
    saveFilename = fullfile(ResultsDir, sprintf('%s_VA%.1f_D%.1f_E%.1f.png', FigName, MeanRealVA(b), MeanDistance(b), MeanElevation(b)));
    drawRealPerceivedPredictedVA(realRadius_mm, perceivedRadius_mm, predictedRadius_mm, textstring, saveFlag, saveFilename);
end

summaryTbl = table(BinIndex, BinParamMin, BinParamMax, NRows, NUniqueIDs, ...
                   MeanRealVA, MeanDistance, MeanElevation, MeanPerceivedVA, MeanPredictedVA);

close all; % close figures to remove clutter
end
