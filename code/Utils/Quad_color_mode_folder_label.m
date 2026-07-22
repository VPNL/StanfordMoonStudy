function label = Quad_color_mode_folder_label(colorMode)
%QUAD_COLOR_MODE_FOLDER_LABEL Stable result-folder label for a color mode.

switch lower(strtrim(string(colorMode)))
    case {"clinicalnotes", "clinical"}
        label = 'ClinicalNotes';
    case {"stereoscore", "stereo", "normed", "normedstereoscore"}
        label = 'StereoScore';
    case {"id", "participant", "participantid"}
        label = 'ID';
    otherwise
        error('QuadColorMode:InvalidMode', ...
            'Color mode must be "clinicalnotes", "stereoscore", or "id".');
end
end
