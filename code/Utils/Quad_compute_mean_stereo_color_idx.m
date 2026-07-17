function [sorted_color_idx, mean_stereo_by_id, uniqueID, cmap] = Quad_compute_mean_stereo_color_idx(tbl, resultsDir, quadBaseName, recomputeColorIndex, sortMetric)
% QUAD_COMPUTE_MEAN_STEREO_COLOR_IDX
% Assign subject colors from stereo-score values while preserving the
% older subject-rank interface used by the PM plotting helpers.
%
% sortMetric options:
%   'normed'              -> color by mean NormedScore / NormedStereoScore
%
% Note:
%   Inverse stereo-score coloring has been retired because it is unstable
%   for stereo-blind subjects (division by zero).

if nargin < 4 || isempty(recomputeColorIndex)
    recomputeColorIndex = true;
end

if nargin < 5 || isempty(sortMetric)
    sortMetric = 'normed';
end

sortMetric = lower(string(sortMetric));

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

[scoreValues, metricLabel] = local_get_stereo_metric(tbl, sortMetric);
savefile = fullfile(resultsDir, [quadBaseName '_stereo_color_idx_' char(metricLabel) '.mat']);

if ~recomputeColorIndex && exist(savefile, 'file') == 2
    S = load(savefile, 'sorted_color_idx', 'mean_stereo_by_id', 'uniqueID', 'cmap');
    sorted_color_idx = S.sorted_color_idx;
    mean_stereo_by_id = S.mean_stereo_by_id;
    uniqueID = S.uniqueID;
    cmap = S.cmap;
else
    if ~iscategorical(tbl.ID)
        ids = categorical(tbl.ID);
    else
        ids = tbl.ID;
    end

    uniqueID = categories(removecats(ids));
    mean_stereo_by_id = zeros(numel(uniqueID), 1);
    for i = 1:numel(uniqueID)
        mean_stereo_by_id(i) = mean(scoreValues(ids == categorical(uniqueID(i))), 'omitnan');
    end

    [sorted_color_idx, cmap] = local_build_subject_rank_colormap(mean_stereo_by_id, sortMetric);
    save(savefile, 'sorted_color_idx', 'mean_stereo_by_id', 'uniqueID', 'sortMetric', 'cmap');
end
end

function [scoreValues, metricLabel] = local_get_stereo_metric(tbl, sortMetric)
switch sortMetric
    case {"normed", "normedstereoscore"}
        scoreVar = local_get_first_existing_var(tbl, {'NormedStereoScore', 'NormedScore'});
        scoreValues = tbl.(scoreVar);
        metricLabel = "normed";

    case {"continuous_inverse", "inverse_continuous", "inverse_continous", "1/continuousstereoscore", "1/continousstereoscore"}
        error(['sortMetric "%s" has been retired. Use "normed" for actual stereo-score coloring. ' ...
            'Inverse stereo-score coloring is unstable for stereo-blind subjects.'], sortMetric);

    otherwise
        error('Unsupported sortMetric "%s". Use "normed".', sortMetric);
end

scoreValues = double(scoreValues);
end

function varName = local_get_first_existing_var(tbl, candidates)
for i = 1:numel(candidates)
    if ismember(candidates{i}, tbl.Properties.VariableNames)
        varName = candidates{i};
        return;
    end
end

error('Missing required stereo score column. Looked for: %s', strjoin(candidates, ', '));
end

function [sorted_idx, cmap] = local_build_subject_rank_colormap(score_by_id, sortMetric)
nSubjects = numel(score_by_id);
baseCmap = StereoScores(256);

[~, sorted_idx] = sort(score_by_id, 'ascend', 'MissingPlacement', 'last');
colorRowsBySubject = local_scores_to_base_rows(score_by_id, sortMetric, size(baseCmap, 1));

cmap = zeros(nSubjects, 3);
for rankIdx = 1:nSubjects
    subjIdx = sorted_idx(rankIdx);
    cmap(rankIdx, :) = baseCmap(colorRowsBySubject(subjIdx), :);
end
end

function color_rows = local_scores_to_base_rows(score_by_id, sortMetric, nColors)
color_rows = ones(size(score_by_id));
validMask = ~isnan(score_by_id);

if ~any(validMask)
    return;
end

switch sortMetric
    case {"normed", "normedstereoscore"}
        scoreMin = 0;
        scoreMax = 100;
        scoreScaled = (min(max(score_by_id, scoreMin), scoreMax) - scoreMin) ./ (scoreMax - scoreMin);

    otherwise
        validScores = score_by_id(validMask);
        scoreMin = min(validScores);
        scoreMax = max(validScores);
        if scoreMax > scoreMin
            scoreScaled = (score_by_id - scoreMin) ./ (scoreMax - scoreMin);
        else
            scoreScaled = 0.5 * ones(size(score_by_id));
        end
end

color_rows(validMask) = 1 + round(scoreScaled(validMask) * (nColors - 1));
color_rows(validMask) = min(max(color_rows(validMask), 1), nColors);
color_rows = round(color_rows);
end
