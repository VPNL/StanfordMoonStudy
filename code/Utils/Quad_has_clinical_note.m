function hasClinicalNote = Quad_has_clinical_note(tbl)
%QUAD_HAS_CLINICAL_NOTE True for rows containing a substantive clinical note.

if ~ismember('ClinicalNotes', tbl.Properties.VariableNames)
    error('QuadClinicalNoteGroups:MissingClinicalNotes', ...
        'Input table must contain ClinicalNotes.');
end
notes = strip(string(tbl.ClinicalNotes));
hasClinicalNote = ~ismissing(notes) & notes ~= "" & lower(notes) ~= "nan" & ...
    lower(notes) ~= "none" & lower(notes) ~= "no clinical note";
end
