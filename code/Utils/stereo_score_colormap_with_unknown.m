function [cmap, colorLimits, ticks, tickLabels, unknownColor] = ...
    stereo_score_colormap_with_unknown()
% STEREO_SCORE_COLORMAP_WITH_UNKNOWN Stereo-score map with an unknown band.

% Distinct from the score-100 gray, but dark enough to remain visible on
% white figure backgrounds.
unknownColor = [0.82 0.82 0.82];
nScoreColors = 256;
nUnknownColors = 51;
cmap = [StereoScores(nScoreColors); repmat(unknownColor, nUnknownColors, 1)];

% Keep scores 0-100 on the original map and reserve 100-120 for Unknown.
colorLimits = [0 120];
ticks = [0:20:100 110];
tickLabels = [string(0:20:100) "Unknown"];
end
