function colorConfig = Quad_build_participant_color_config( ...
    tbl, resultsDir, quadBaseName, colorMode, recomputeColorIndex)
%QUAD_BUILD_PARTICIPANT_COLOR_CONFIG Build a reusable participant-color configuration.
%
% The returned RankCmap and SortedIdx fields preserve the interface used by
% existing PM plotting functions. Color contains one RGB row per ID and is
% intended for plots that accept the optional colorConfig argument.

if nargin < 4 || isempty(colorMode)
    colorMode = "stereoscore";
end
if nargin < 5 || isempty(recomputeColorIndex)
    recomputeColorIndex = true;
end

colorMode = lower(strtrim(string(colorMode)));
switch colorMode
    case {"stereoscore", "stereo", "normed", "normedstereoscore"}
        colorMode = "stereoscore";
        [sortedIdx, stereoScore, uniqueID, rankCmap] = ...
            Quad_compute_mean_stereo_color_idx(tbl, resultsDir, ...
            quadBaseName, recomputeColorIndex, 'normed');
        category = strings(numel(uniqueID), 1);
        participantColors = colorsByParticipantRank(sortedIdx, rankCmap, numel(uniqueID));

    case {"clinicalnotes", "clinical"}
        colorMode = "clinicalnotes";
        [sortedIdx, category, uniqueID, rankCmap] = ...
            Quad_compute_clinical_notes_color_idx(tbl, resultsDir, ...
            quadBaseName, recomputeColorIndex);
        stereoScore = nan(numel(uniqueID), 1);
        participantColors = colorsByParticipantRank(sortedIdx, rankCmap, numel(uniqueID));

    case {"id", "participant", "participantid"}
        colorMode = "id";
        uniqueID = unique(tbl.ID);
        uniqueID = uniqueID(:);
        nParticipants = numel(uniqueID);
        sortedIdx = (1:nParticipants)';
        category = string(uniqueID);
        stereoScore = nan(nParticipants, 1);
        rankCmap = lines(max(nParticipants, 1));
        rankCmap = rankCmap(1:nParticipants, :);
        participantColors = rankCmap;

    otherwise
        error('QuadParticipantColors:InvalidMode', ...
            'colorMode must be "stereoscore", "clinicalnotes", or "id".');
end

colorConfig = struct( ...
    'Mode', colorMode, ...
    'ID', string(uniqueID(:)), ...
    'Color', participantColors, ...
    'Category', string(category(:)), ...
    'StereoScore', stereoScore(:), ...
    'SortedIdx', sortedIdx(:), ...
    'RankCmap', rankCmap);
end

function participantColors = colorsByParticipantRank(sortedIdx, rankCmap, nParticipants)
participantColors = repmat([0.5 0.5 0.5], nParticipants, 1);
for participantIdx = 1:nParticipants
    colorRow = find(sortedIdx == participantIdx, 1, 'first');
    if ~isempty(colorRow) && colorRow <= size(rankCmap, 1)
        participantColors(participantIdx, :) = rankCmap(colorRow, :);
    end
end
end
