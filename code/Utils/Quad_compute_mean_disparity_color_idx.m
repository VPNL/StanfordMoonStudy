function [sorted_color_idx, mean_disparity_by_id, uniqueID, cmap] = Quad_compute_mean_disparity_color_idx(tbl, resultsDir, quadBaseName, recomputeColorIndex)
% QUAD_COMPUTE_MEAN_DISPARITY_COLOR_IDX
% Sort subjects by mean disparity and save/load the color order.

if nargin < 4 || isempty(recomputeColorIndex)
    recomputeColorIndex = true;
end

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

savefile = fullfile(resultsDir, [quadBaseName '_color_idx.mat']);

if ~recomputeColorIndex && exist(savefile, 'file') == 2
    S = load(savefile, 'sorted_color_idx', 'mean_disparity_by_id', 'uniqueID');
    sorted_color_idx = S.sorted_color_idx;
    mean_disparity_by_id = S.mean_disparity_by_id;
    uniqueID = S.uniqueID;
else
    if ~iscategorical(tbl.ID)
        ids = categorical(tbl.ID);
    else
        ids = tbl.ID;
    end
    uniqueID = categories(removecats(ids));
    mean_disparity_by_id = zeros(numel(uniqueID), 1);
    for i = 1:numel(uniqueID)
        mean_disparity_by_id(i) = mean(tbl.MeanDisparity(ids == categorical(uniqueID(i))), 'omitnan');
    end
    [~, sorted_color_idx] = sort(mean_disparity_by_id, 'ascend');
    save(savefile, 'sorted_color_idx', 'mean_disparity_by_id', 'uniqueID');
end

nsubjects = numel(uniqueID);
%cmap = brighten(plasma(ceil(nsubjects*1.1)), 0);
cmap = brighten(magma(ceil(nsubjects*1.1)), 0);
if size(cmap,1) < nsubjects
    cmap = brighten(plasma(nsubjects), 0);
end
end
