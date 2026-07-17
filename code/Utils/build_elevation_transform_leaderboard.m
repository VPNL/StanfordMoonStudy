function [leaderboardTbl, detailTbl, deltaTbl, fh] = build_elevation_transform_leaderboard( ...
    quadErrorCsv, combinedErrorCsv, quadCriteriaCsv, moonCriteriaCsv, saveDir, savePrefix)
% build_elevation_transform_leaderboard Summarize aligned elevation transforms across datasets.
%
% The aligned transform families are:
%   Quad absElevation      <-> Moon Elevation
%   Quad absElevationD90   <-> Moon ElevationD90
%   Quad absElevationRAD   <-> Moon ElevationRAD

if nargin < 5 || isempty(saveDir)
    saveDir = '';
end
if nargin < 6 || isempty(savePrefix)
    savePrefix = 'elevation_transform_leaderboard';
end

quadFamilies = {'absElevation','absElevationD90','absElevationRAD'};
commonFamilies = {'Elevation','ElevationD90','ElevationRAD'};
taskOrder = {'Perceptual','Adjusted'};

detailRows = {};

if local_is_readable_file(quadErrorCsv)
    quadErrTbl = readtable(quadErrorCsv);
    detailRows = [detailRows; local_collect_error_rows(quadErrTbl, 'Quad', quadFamilies, commonFamilies, taskOrder)]; %#ok<AGROW>
elseif ~isempty(quadErrorCsv)
    warning('Quad error CSV not found: %s', quadErrorCsv);
end

if local_is_readable_file(combinedErrorCsv)
    combinedErrTbl = readtable(combinedErrorCsv);
    detailRows = [detailRows; local_collect_error_rows(combinedErrTbl, 'Combined', quadFamilies, commonFamilies, taskOrder)]; %#ok<AGROW>
elseif ~isempty(combinedErrorCsv)
    warning('Combined error CSV not found: %s', combinedErrorCsv);
end

if local_is_readable_file(quadCriteriaCsv)
    quadCritTbl = readtable(quadCriteriaCsv);
    detailRows = [detailRows; local_collect_criterion_rows(quadCritTbl, 'Quad', quadFamilies, commonFamilies, taskOrder)]; %#ok<AGROW>
elseif ~isempty(quadCriteriaCsv)
    warning('Quad criteria CSV not found: %s', quadCriteriaCsv);
end

if local_is_readable_file(moonCriteriaCsv)
    moonCritTbl = readtable(moonCriteriaCsv);
    detailRows = [detailRows; local_collect_criterion_rows(moonCritTbl, 'Moon', commonFamilies, commonFamilies, taskOrder)]; %#ok<AGROW>
elseif ~isempty(moonCriteriaCsv)
    warning('Moon criteria CSV not found: %s', moonCriteriaCsv);
end

if isempty(detailRows)
    error('No input rows were collected. Check the input CSV filenames.');
end

function tf = local_is_readable_file(filename)
tf = ~(isempty(filename) || ~(ischar(filename) || isstring(filename))) && isfile(filename);
end

detailTbl = cell2table(detailRows, 'VariableNames', ...
    {'Dataset','Task','Metric','TransformFamily','Value'});
detailTbl.Dataset = string(detailTbl.Dataset);
detailTbl.Task = string(detailTbl.Task);
detailTbl.Metric = string(detailTbl.Metric);
detailTbl.TransformFamily = string(detailTbl.TransformFamily);

detailTbl.Rank = nan(height(detailTbl),1);
detailTbl.NCompared = nan(height(detailTbl),1);
groupKeys = unique(detailTbl(:, {'Dataset','Task','Metric'}), 'rows', 'stable');
for g = 1:height(groupKeys)
    idx = detailTbl.Dataset == groupKeys.Dataset(g) & ...
          detailTbl.Task == groupKeys.Task(g) & ...
          detailTbl.Metric == groupKeys.Metric(g);
    vals = detailTbl.Value(idx);
    if all(isnan(vals))
        continue;
    end
    ranks = tiedrank(vals);
    detailTbl.Rank(idx) = ranks;
    detailTbl.NCompared(idx) = sum(~isnan(vals));
end

familyKeys = unique(detailTbl.TransformFamily, 'stable');
leaderRows = {};
for i = 1:numel(familyKeys)
    family = familyKeys(i);
    idx = detailTbl.TransformFamily == family;
    vals = detailTbl.Value(idx);
    ranks = detailTbl.Rank(idx);
    leaderRows(end+1,:) = {family, mean(ranks, 'omitnan'), std(ranks, 0, 'omitnan'), ... %#ok<AGROW>
        mean(vals, 'omitnan'), sum(~isnan(ranks)), sum(ranks == 1, 'omitnan')};
end

leaderboardTbl = cell2table(leaderRows, 'VariableNames', ...
    {'TransformFamily','MeanRank','StdRank','MeanMetricValue','NEvidence','NBest'});
leaderboardTbl.TransformFamily = string(leaderboardTbl.TransformFamily);
leaderboardTbl = sortrows(leaderboardTbl, {'MeanRank','NBest','TransformFamily'}, {'ascend','descend','ascend'});

deltaTbl = summarize_transform_deltas(detailTbl);
fh = plot_elevation_transform_leaderboard(leaderboardTbl, detailTbl, saveDir, savePrefix);

if ~isempty(saveDir)
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    writetable(detailTbl, fullfile(saveDir, [savePrefix '_detail.csv']));
    writetable(deltaTbl, fullfile(saveDir, [savePrefix '_deltas.csv']));
    writetable(leaderboardTbl, fullfile(saveDir, [savePrefix '_summary.csv']));
    save(fullfile(saveDir, [savePrefix '.mat']), 'leaderboardTbl', 'detailTbl', 'deltaTbl');
end
end

function rows = local_collect_error_rows(errTbl, datasetName, sourceLabels, familyLabels, taskOrder)
rows = {};
for i = 1:numel(sourceLabels)
    srcLabel = string(sourceLabels{i});
    familyLabel = string(familyLabels{i});
    for t = 1:numel(taskOrder)
        taskName = string(taskOrder{t});
        idx = string(errTbl.Task) == taskName & string(errTbl.TransformLabel) == srcLabel;
        if ~any(idx)
            continue;
        end
        val = mean(errTbl.MeanPctError(idx), 'omitnan');
        rows(end+1,:) = {string(datasetName), taskName, "MeanPctError", familyLabel, val}; %#ok<AGROW>
    end
end
end

function rows = local_collect_criterion_rows(criteriaTbl, datasetName, sourceLabels, familyLabels, taskOrder)
rows = {};
for i = 1:numel(sourceLabels)
    srcLabel = string(sourceLabels{i});
    familyLabel = string(familyLabels{i});
    for t = 1:numel(taskOrder)
        taskName = string(taskOrder{t});
        idx = string(criteriaTbl.Task) == taskName & string(criteriaTbl.TransformLabel) == srcLabel;
        if ~any(idx)
            continue;
        end
        rows(end+1,:) = {string(datasetName), taskName, "AIC", familyLabel, mean(criteriaTbl.AIC(idx), 'omitnan')}; %#ok<AGROW>
        rows(end+1,:) = {string(datasetName), taskName, "BIC", familyLabel, mean(criteriaTbl.BIC(idx), 'omitnan')}; %#ok<AGROW>
    end
end
end
