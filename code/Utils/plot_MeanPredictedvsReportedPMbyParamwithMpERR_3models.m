function [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_3models(T, Param, minNID, saveFilename, figName, errType, Study, rebinTolPct, nLevels)
% plot_MeanPredictedvsReportedPMbyParamwithMpERR_3models
% Plot predicted PM versus perceived PM for three selected LME models.
%
% This is a focused wrapper around
% plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNIDbinned. It keeps the
% same binning, color maps, figure export behavior, percent-error plot, and
% binned text report, but restricts the plotted model panels to three
% models chosen from the requested binning parameter:
%
%   1. The one-factor model for the parameter of interest.
%   2. The two-factor model for the other two parameters.
%   3. The three-factor model containing visual angle, distance, and
%      elevation.
%
% Model panels selected by Param:
%
%   Param = 'Real_Visual_Angle'
%       plotted models: VA, D+E, VA+D+E
%
%   Param = 'Distance'
%       plotted models: D, VA+E, VA+D+E
%
%   Param = 'Elevation'
%       plotted models: E, VA+D, VA+D+E
%
% Inputs
%   T
%       Table containing model-testing data. Required columns are the same
%       as for plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNIDbinned:
%       Iteration, ID, Param, Ratio_Visual_Angle, and predicted PM columns.
%       The predicted PM columns are expected to include columns whose names
%       contain predicted_PM and end with model labels such as logAngle,
%       logDistanceNElevation, and logAngleNDistanceNElevation.
%
%   Param
%       Character vector or string naming the parameter used for binning and
%       coloring. Supported values are:
%           'Real_Visual_Angle'
%           'Distance'
%           'Elevation'
%
%   minNID
%       Minimum target number of unique participant IDs per bin. If omitted
%       or empty, the wrapped function uses its default. Adaptive binning may
%       leave a bin below minNID if merging would violate the other-parameter
%       similarity constraint.
%
%   saveFilename
%       Optional full path for saving the main predicted-versus-perceived PM
%       figure. If provided, the wrapped function also saves the percent-error
%       figure and the concise bin error text report using related filenames.
%
%   figName
%       Optional figure name/title label passed through to the wrapped
%       plotting function.
%
%   errType
%       Error bar type for across-iteration summaries:
%           'sd'  - standard deviation (default)
%           'sem' - standard error of the mean
%
%   Study
%       Optional study label used by the wrapped plotting function to choose
%       the elevation colormap. Values containing 'Quad' use the quad
%       elevation colormap. Default is 'QuadStudy'.
%
%   rebinTolPct
%       Optional tolerance, in percent, for adaptive re-binning across the
%       other parameters. Passed directly to the wrapped function.
%
%   nLevels
%       Optional number of color levels. Passed directly to the wrapped
%       function for compatibility with the original call signature.
%
% Outputs
%   SummaryItrParam
%       Table with one row per Iteration x binned Param group. Includes mean
%       reported PM, mean predicted PM for the three selected models, and
%       error metrics.
%
%   SummaryParam
%       Table with one row per binned Param group. Includes bin ranges,
%       participant counts, and across-iteration summary statistics for the
%       three selected models.
%
%   MSE_ItrParam
%       Long-format table of mean squared error for each Iteration x bin x
%       selected model.
%
%   MSE_Itr
%       Table summarizing mean squared error across bins for each iteration
%       and selected model.
%
%   fh
%       Figure handle for the 1 x 3 predicted-versus-perceived PM plot.
%
%   fh_violin
%       Figure handle for the optional violin plot. The wrapped function
%       currently leaves this empty unless violin plotting is enabled there.
%
%   PctErr_ItrParam
%       Long-format table of mean absolute percent error for each Iteration x
%       bin x selected model.
%
%   PctErr_Itr
%       Table summarizing mean absolute percent error across bins for each
%       iteration and selected model.
%
%   fh_pctbar
%       Figure handle for the percent-error bar plot. This plot contains only
%       the three selected models.
%
% Example
%   Param = 'Real_Visual_Angle';
%   figName = sprintf('Perceptual_%dminNID_absElevation', minNID);
%   saveBase = sprintf('%s_%diterations_%s_%s_%s', ...
%       figName, nIterations, Param, QuadBasename, sfx);
%   saveFilename = fullfile(ResultsDir, [saveBase '.png']);
%
%   [SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, ...
%       fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = ...
%       plot_MeanPredictedvsReportedPMbyParamwithMpERR_3models( ...
%       S.(task).all_testing_Tbl, Param, minNID, saveFilename, ...
%       figName, 'sd', 'Quad');
%
%   if ~isempty(fh); close(fh); end
%   if ~isempty(fh_violin); close(fh_violin); end
%   if ~isempty(fh_pctbar); close(fh_pctbar); end

if nargin < 3
    minNID = [];
end
if nargin < 4
    saveFilename = [];
end
if nargin < 5
    figName = [];
end
if nargin < 6 || isempty(errType)
    errType = 'sd';
end
if nargin < 7 || isempty(Study)
    Study = 'QuadStudy';
end
if nargin < 8
    rebinTolPct = [];
end
if nargin < 9
    nLevels = [];
end

T3 = local_keep_three_model_columns(T, Param);

[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = ...
    plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNIDbinned(T3, Param, minNID, saveFilename, figName, errType, Study, rebinTolPct, nLevels);
end

function T3 = local_keep_three_model_columns(T, Param)
if ~istable(T)
    error('Input T must be a table.');
end

vnames = string(T.Properties.VariableNames);
predCols = vnames(contains(lower(vnames), "predicted_pm"));
if isempty(predCols)
    predCols = vnames(contains(lower(vnames), "predicted"));
end
if isempty(predCols)
    error("No predicted PM columns were found.");
end

selectedPredCols = local_select_three_model_columns(predCols, Param);
nonPredCols = setdiff(vnames, predCols, 'stable');
keepCols = [nonPredCols, selectedPredCols];
T3 = T(:, cellstr(keepCols));
end

function selectedPredCols = local_select_three_model_columns(predCols, Param)
paramKey = local_param_key(Param);

switch paramKey
    case "va"
        modelSuffixes = ["logAngle", "logDistanceNElevation", "logAngleNDistanceNElevation"];
    case "distance"
        modelSuffixes = ["logDistance", "logAngleNElevation", "logAngleNDistanceNElevation"];
    case "elevation"
        modelSuffixes = ["logElevation", "logAngleNDistance", "logAngleNDistanceNElevation"];
    otherwise
        error("Unsupported Param '%s'. Expected Real_Visual_Angle, Distance, or Elevation.", string(Param));
end

selectedPredCols = strings(1, numel(modelSuffixes));
for ii = 1:numel(modelSuffixes)
    selectedPredCols(ii) = local_find_model_column(predCols, modelSuffixes(ii));
end
end

function paramKey = local_param_key(Param)
p = lower(string(Param));
p = replace(p, "_", "");
p = replace(p, " ", "");

if p == "realvisualangle" || p == "visualangle" || p == "va"
    paramKey = "va";
elseif p == "distance" || p == "d"
    paramKey = "distance";
elseif p == "elevation" || p == "e"
    paramKey = "elevation";
else
    paramKey = "";
end
end

function modelCol = local_find_model_column(predCols, suffix)
predCols = string(predCols);
suffix = string(suffix);

idx = find(endsWith(predCols, suffix), 1, "first");
if isempty(idx)
    idx = find(contains(predCols, suffix), 1, "first");
end
if isempty(idx)
    error("Missing predicted model column ending in '%s'.", suffix);
end

modelCol = predCols(idx);
end
