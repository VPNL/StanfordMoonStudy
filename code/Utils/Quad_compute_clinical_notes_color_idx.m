function [sortedColorIdx, categoryByID, uniqueID, cmap] = ...
    Quad_compute_clinical_notes_color_idx(tbl, resultsDir, quadBaseName, recomputeColorIndex)
% QUAD_COMPUTE_CLINICAL_NOTES_COLOR_IDX Assign participant colors by clinical notes.
%
% Categories are checked in this priority order when a note contains more
% than one condition: strabismus, convergence insufficiency, amblyopia,
% nearsightedness, farsightedness, astigmatism, cataract, then ptosis.
% Blank notes use gray; notes without one of these conditions use dark gray.

if nargin < 4 || isempty(recomputeColorIndex)
    recomputeColorIndex = true;
end

if ~ismember('ClinicalNotes', tbl.Properties.VariableNames)
    error('QuadClinicalColors:MissingClinicalNotes', ...
        'Input table must contain a ClinicalNotes variable.');
end

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

saveFile = fullfile(resultsDir, [quadBaseName '_clinical_notes_color_idx.mat']);
summaryFile = fullfile(resultsDir, [quadBaseName '_clinical_notes_colors.csv']);

if ~recomputeColorIndex && exist(saveFile, 'file') == 2
    saved = load(saveFile, 'sortedColorIdx', 'categoryByID', 'uniqueID', 'cmap');
    sortedColorIdx = saved.sortedColorIdx;
    categoryByID = saved.categoryByID;
    uniqueID = saved.uniqueID;
    cmap = saved.cmap;
    return;
end

[uniqueID, ~, idGroup] = unique(tbl.ID);
nSubjects = numel(uniqueID);
sortedColorIdx = (1:nSubjects)';
categoryByID = strings(nSubjects, 1);
notesByID = strings(nSubjects, 1);
cmap = zeros(nSubjects, 3);

for subjectIdx = 1:nSubjects
    subjectNotes = string(tbl.ClinicalNotes(idGroup == subjectIdx));
    subjectNotes = strip(subjectNotes);
    subjectNotes(ismissing(subjectNotes)) = "";
    subjectNotes = unique(subjectNotes(subjectNotes ~= ""), 'stable');
    notesByID(subjectIdx) = strjoin(subjectNotes, '; ');
    [categoryByID(subjectIdx), cmap(subjectIdx, :)] = ...
        local_classify_clinical_notes(notesByID(subjectIdx));
end

participantColors = table(string(uniqueID), notesByID, categoryByID, ...
    cmap(:, 1), cmap(:, 2), cmap(:, 3), ...
    'VariableNames', {'ID', 'ClinicalNotes', 'ClinicalCategory', 'Red', 'Green', 'Blue'});
writetable(participantColors, summaryFile);
save(saveFile, 'sortedColorIdx', 'categoryByID', 'uniqueID', 'cmap', 'notesByID');
end

function [category, color] = local_classify_clinical_notes(note)
note = lower(string(note));

darkGray =    [0.1, 0.1, 0.1];
darkRed =     [0.5, 0, 0];
violet =      [.8, 0.2, .8] ;
purple =      [0.5, 0, 0.8];
yellow =      [0.9290, 0.6940, 0.1250];
navy =        [0.1, .8, .8];
gray =        [.7 .7 .7];
pink =        [.8, 0.5, 0.5];
lightBlue =   [0.3, 0.7, 1];
blue =        [0, 0, 1];

% if  contains(note, 'ptosis')
%     category = "Ptosis";
%     color = [0 0 0];
    
if contains(note, 'one functional eye')
    category = "One functional eye";
    color = blue;
elseif contains(note, 'convergence insufficiency')
    category = "Convergence insufficiency";
    color = darkRed;
elseif  contains(note, 'strabismus')
    category = "Strabismus";
    color = violet;
elseif contains(note, 'amblyopia') || contains(note, 'amplyopia')
    category = "Amblyopia";
    color = purple;
% elseif contains(note, 'farsighted') || contains(note, 'far sighted')
%     category = "Farsighted";
%     color = darkGray;
% elseif contains(note, 'nearsighted') || contains(note, 'near sighted')
%     category = "Nearsighted";
%     color = lightBlue;
% elseif contains(note, 'astigmatism')
%     category = "Astigmatism";
%     color = navy;
elseif contains(note, 'cataract')
    category = "Cataract";
    color = yellow;
elseif strlength(note) == 0
    category = "No clinical note";
    color = gray;
else
    category = "Other clinical note";
    color = navy;
end
end
