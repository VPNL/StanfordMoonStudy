function cb = Quad_add_participant_colorbar(figHandle, mycolormap, nIDs, ...
    labelText, colorConfig, legendAxes, options)
% QUAD_ADD_PARTICIPANT_COLORBAR Add a shared Quad participant color key.

arguments
    figHandle
    mycolormap double = []
    nIDs (1,1) double = 0
    labelText = 'Participant color order'
    colorConfig = []
    legendAxes = []
    options.Position (1,4) double = [0.885 0.22 0.012 0.52]
    options.StereoUnknownLabel = 'Unknown'
    options.StereoLabelPosition = []
end

cb = [];
if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
        string(colorConfig.Mode) == "clinicalnotes"
    if isempty(legendAxes)
        legendAxes = findobj(figHandle, 'Type', 'axes', '-not', ...
            'Tag', 'Colorbar');
        legendAxes = legendAxes(1);
    end
    legendHandle = Quad_add_clinical_notes_legend(legendAxes, colorConfig);
    legendHandle.FontSize = 11;
    return;
end
if isempty(mycolormap)
    return;
end

labelLower = lower(string(labelText));
isStereo = contains(labelLower, 'normed stereo score') || ...
    contains(labelLower, 'normedscore') || ...
    contains(labelLower, 'normedstereoscore');
if isStereo
    plotAxes = findall(figHandle, 'Type', 'axes');
    plotAxes = plotAxes(~arrayfun(@(ax) ...
        isa(ax, 'matlab.graphics.illustration.ColorBar'), plotAxes));
    if ~isempty(plotAxes)
        apply_stereo_score_colormap(plotAxes);
    end
    cb = add_stereo_score_colorbar(figHandle, labelText, options.Position);
    tickLabels = string(cb.TickLabels);
    tickLabels(strcmpi(tickLabels, "Unknown")) = ...
        string(options.StereoUnknownLabel);
    cb.TickLabels = tickLabels;
    if ~isempty(options.StereoLabelPosition)
        cb.Label.Units = 'normalized';
        cb.Label.Position = options.StereoLabelPosition;
    end
else
    nColorLevels = min(size(mycolormap, 1), max(1, nIDs));
    cbAx = axes('Parent', figHandle, 'Position', options.Position, ...
        'Visible', 'off', 'YDir', 'normal', 'Color', 'none', ...
        'XColor', 'none', 'YColor', 'none', 'CLim', [1 nColorLevels]);
    colormap(cbAx, mycolormap(1:nColorLevels, :));
    cb = colorbar(cbAx, 'Position', options.Position);
    if isstruct(colorConfig) && isfield(colorConfig, 'Mode') && ...
            string(colorConfig.Mode) == "id" && ...
            isfield(colorConfig, 'ColorbarTicks') && ...
            isfield(colorConfig, 'ColorbarTickLabels') && ...
            ~isempty(colorConfig.ColorbarTicks)
        cb.Ticks = max(1, min(nColorLevels, colorConfig.ColorbarTicks(:)'));
        cb.TickLabels = string(colorConfig.ColorbarTickLabels(:)');
    else
        cb.Ticks = unique(max(1, min(nColorLevels, [1 nColorLevels])));
        cb.TickLabels = string(cb.Ticks);
    end
end
cb.FontName = 'Avenir';
cb.FontSize = 18;
cb.Label.String = labelText;
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 20;
end
