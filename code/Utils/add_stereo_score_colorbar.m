function cb = add_stereo_score_colorbar(targetHandle, labelText, position)
% ADD_STEREO_SCORE_COLORBAR
% Add a shared StereoScores colorbar reflecting 0-100 plus Unknown.

if nargin < 2 || isempty(labelText)
    labelText = 'Normed stereo score';
end
if nargin < 3
    position = [];
end

if ~isgraphics(targetHandle)
    error('add_stereo_score_colorbar requires a valid figure or axes handle.');
end

[stereoMap, colorLimits, ticks, tickLabels] = ...
    stereo_score_colormap_with_unknown();

if strcmp(get(targetHandle, 'Type'), 'figure')
    figHandle = targetHandle;
    if isempty(position)
        position = [0.885 0.22 0.012 0.52];
    end
    cbAx = axes('Parent', figHandle, 'Position', position, ...
        'Visible', 'off', 'YDir', 'normal', 'Color', 'none', ...
        'XColor', 'none', 'YColor', 'none');
    colormap(cbAx, stereoMap);
    caxis(cbAx, colorLimits);
    cb = colorbar(cbAx, 'Position', position);
else
    cb = colorbar(targetHandle, 'eastoutside');
end

cb.Ticks = ticks;
cb.TickLabels = tickLabels;
cb.Label.String = labelText;
cb.FontName = 'Avenir';
cb.FontSize = 16;
cb.Label.FontName = 'Avenir';
cb.Label.FontSize = 20;
end
