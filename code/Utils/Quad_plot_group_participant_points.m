function Quad_plot_group_participant_points(ax, x, y, participantIDs, colorConfig)
%QUAD_PLOT_GROUP_PARTICIPANT_POINTS Plot points using a shared color mode.

mode = lower(string(colorConfig.Mode));
participantIDs = string(participantIDs(:));
switch mode
    case "stereoscore"
        [known, rows] = ismember(participantIDs, string(colorConfig.ID(:)));
        scores = nan(numel(participantIDs), 1);
        scores(known) = colorConfig.StereoScore(rows(known));
        scatter(ax, x, y, 70, scores, 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.25);
    case {"clinicalnotes", "id"}
        colors = Quad_colors_for_participant_ids(participantIDs, colorConfig);
        scatter(ax, x, y, 70, colors, 'filled', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.25);
        if mode == "id"
            Quad_add_participant_id_labels(ax, x, y, participantIDs, colors);
        end
    otherwise
        error('QuadGroupPlot:InvalidColorMode', ...
            'Unsupported participant color mode "%s".', mode);
end
end
