function colors = Quad_colors_for_participant_ids(participantIDs, colorConfig)
%QUAD_COLORS_FOR_PARTICIPANT_IDS Look up configured RGB colors by participant ID.

participantIDs = string(participantIDs(:));
[isKnown, colorRows] = ismember(participantIDs, string(colorConfig.ID(:)));
colors = repmat([0.5 0.5 0.5], numel(participantIDs), 1);
colors(isKnown, :) = colorConfig.Color(colorRows(isKnown), :);
end
