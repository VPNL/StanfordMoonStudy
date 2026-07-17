function cmap = apply_stereo_score_colormap(targetHandles)
% APPLY_STEREO_SCORE_COLORMAP
% Apply the StereoScores colormap and the shared 0-100 scale.

if nargin < 1 || isempty(targetHandles)
    error('apply_stereo_score_colormap requires at least one target handle.');
end

targetHandles = targetHandles(isgraphics(targetHandles));
if isempty(targetHandles)
    error('apply_stereo_score_colormap received no valid graphics handles.');
end

if all(strcmp(get(targetHandles, 'Type'), 'figure'))
    figHandle = targetHandles(1);
    axHandles = findall(figHandle, 'Type', 'axes');
else
    axHandles = targetHandles(strcmp(get(targetHandles, 'Type'), 'axes'));
    if isempty(axHandles)
        error('apply_stereo_score_colormap expected axes or figure handles.');
    end
    figHandle = ancestor(axHandles(1), 'figure');
end

cmap = StereoScores(256);
colormap(figHandle, cmap);

for i = 1:numel(axHandles)
    ax = axHandles(i);
    if isprop(ax, 'CLim')
        caxis(ax, [0 100]);
    end
end
end
