function Quad_finish_group_color_key(ax, colorConfig)
%QUAD_FINISH_GROUP_COLOR_KEY Add the appropriate legend or colorbar.

mode = lower(string(colorConfig.Mode));
keyAxis = ax(end);
if mode == "clinicalnotes"
    legendHandle = Quad_add_clinical_notes_legend(keyAxis, colorConfig);
    legendHandle.FontSize = 9;
elseif mode == "stereoscore"
    apply_stereo_score_colormap(ax);
    colorbarHandle = add_stereo_score_colorbar(keyAxis, 'Normed stereo score');
    colorbarHandle.FontSize = 12;
    colorbarHandle.Label.FontSize = 14;
end
end
