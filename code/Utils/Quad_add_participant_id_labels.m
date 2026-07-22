function Quad_add_participant_id_labels(ax, x, y, participantIDs, colors)
%QUAD_ADD_PARTICIPANT_ID_LABELS Label ID-colored points without a large legend.

participantIDs = string(participantIDs(:));
for participantIdx = 1:numel(participantIDs)
    text(ax, x(participantIdx), y(participantIdx), "  " + participantIDs(participantIdx), ...
        'Color', colors(participantIdx, :), 'FontSize', 7, ...
        'VerticalAlignment', 'middle', 'Interpreter', 'none');
end
end
