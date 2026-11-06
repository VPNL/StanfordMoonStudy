function [table5, discrepancies, audit] = ...
    build_supplemental_table5_stereoacuity(dataDir, outputFile, referenceFile)
% BUILD_SUPPLEMENTAL_TABLE5_STEREOACUITY Build and verify Supplemental Table 5.
%
% The generated table contains one row per participant with a normalized
% stereo score in either the Quad matching or Quad parallax data. Age and
% gender are inherited from Supplemental Table 6, which uses the earliest
% dated valid record across experiments.

arguments
    dataDir (1, 1) string
    outputFile (1, 1) string
    referenceFile (1, 1) string = ""
end

temporaryTable6 = string(tempname) + ".csv";
cleanup = onCleanup(@() local_delete_if_present(temporaryTable6));
[participantTable, table6Audit] = ...
    build_supplemental_table6_participants(dataDir, temporaryTable6);

hasStereoScore = participantTable.NormedStereoScore ~= "";
participantTable = participantTable(hasStereoScore, :);
nParticipants = height(participantTable);

ID = participantTable.ID;
Gender = participantTable.Gender;
Age = participantTable.Age;
NormedStereoscore = str2double(participantTable.NormedStereoScore);
VisualDeficiency = strings(nParticipants, 1);
MatchingExperiment = strings(nParticipants, 1);
ParallaxExperiment = strings(nParticipants, 1);

matchingFile = fullfile(dataDir, 'QuadStudy', ...
    'QuadProcessedMatchingandStereoData.csv');
parallaxFile = fullfile(dataDir, 'BinocularParallax', ...
    'QuadProcessedParallaxandStereoData.csv');
matching = readtable(matchingFile, 'VariableNamingRule', 'preserve');
parallax = readtable(parallaxFile, 'VariableNamingRule', 'preserve');

matchingID = local_numeric_column(matching, ["ID", "IDNumber"]);
parallaxID = local_numeric_column(parallax, ["ID", "IDNumber"]);
matchingNotes = local_string_column(matching, ...
    ["Clinical Notes", "ClinicalNotes"]);
parallaxNotes = local_string_column(parallax, ...
    ["Clinical Notes", "ClinicalNotes"]);

clinicalNoteConflictIDs = zeros(0, 1);
for iParticipant = 1:nParticipants
    participantID = ID(iParticipant);
    if any(matchingID == participantID)
        MatchingExperiment(iParticipant) = "Y";
    end
    if any(parallaxID == participantID)
        ParallaxExperiment(iParticipant) = "Y";
    end

    notes = [matchingNotes(matchingID == participantID); ...
        parallaxNotes(parallaxID == participantID)];
    notes = local_clean_notes(notes);
    uniqueNotes = unique(notes(notes ~= ""), 'stable');
    if numel(uniqueNotes) > 1
        clinicalNoteConflictIDs(end + 1, 1) = participantID; %#ok<AGROW>
    end
    if ~isempty(uniqueNotes)
        VisualDeficiency(iParticipant) = strjoin(uniqueNotes, '; ');
    end
end

table5 = table(ID, Gender, Age, NormedStereoscore, VisualDeficiency, ...
    MatchingExperiment, ParallaxExperiment);
table5.Properties.VariableNames = {'ID', 'Gender', 'Age', ...
    'Normed Stereoscore', 'Visual Deficiency', ...
    'Matching Experiment', 'Parallax Experiment'};

outputDir = fileparts(outputFile);
if strlength(outputDir) > 0 && ~isfolder(outputDir)
    mkdir(outputDir);
end
writetable(table5, outputFile);

discrepancies = table('Size', [0, 4], ...
    'VariableTypes', {'double', 'string', 'string', 'string'}, ...
    'VariableNames', {'ID', 'Field', 'PresentValue', 'GeneratedValue'});
if referenceFile ~= "" && isfile(referenceFile)
    reference = readtable(referenceFile, 'VariableNamingRule', 'preserve');
    discrepancies = local_compare_tables(reference, table5);
end

audit = struct();
audit.UniqueParticipantCount = nParticipants;
audit.ClinicalNoteConflictIDs = clinicalNoteConflictIDs;
audit.Table6Audit = table6Audit;
audit.MatchingFile = matchingFile;
audit.ParallaxFile = parallaxFile;

fprintf('Supplemental Table 5: %d stereo-tested participants.\n', ...
    nParticipants);
if isempty(clinicalNoteConflictIDs)
    fprintf('No participant-level clinical-note conflicts.\n');
else
    warning('SupplementalTable5:ClinicalNoteConflict', ...
        'Conflicting clinical notes for IDs: %s', ...
        strjoin(string(clinicalNoteConflictIDs), ', '));
end
if referenceFile ~= ""
    fprintf('Comparison with present Table 5: %d discrepancies.\n', ...
        height(discrepancies));
end
fprintf('Wrote %s\n', outputFile);

clear cleanup;
end

function values = local_numeric_column(tbl, candidates)
name = local_find_variable(tbl, candidates);
if name == ""
    error('SupplementalTable5:MissingVariable', ...
        'Missing required variable: %s', strjoin(candidates, ' or '));
end
raw = tbl.(name);
if isnumeric(raw)
    values = double(raw);
else
    values = str2double(strtrim(string(raw)));
end
values(~isfinite(values)) = nan;
end

function values = local_string_column(tbl, candidates)
name = local_find_variable(tbl, candidates);
if name == ""
    values = strings(height(tbl), 1);
else
    values = string(tbl.(name));
end
end

function name = local_find_variable(tbl, candidates)
names = string(tbl.Properties.VariableNames);
normalizedNames = lower(regexprep(names, '[^a-zA-Z0-9]', ''));
normalizedCandidates = lower(regexprep(string(candidates), ...
    '[^a-zA-Z0-9]', ''));
name = "";
for iCandidate = 1:numel(normalizedCandidates)
    index = find(normalizedNames == normalizedCandidates(iCandidate), 1);
    if ~isempty(index)
        name = names(index);
        return;
    end
end
end

function notes = local_clean_notes(notes)
notes = strtrim(string(notes));
missing = ismissing(notes) | notes == "" | ...
    lower(notes) == "nan" | lower(notes) == "na";
notes(missing) = "";
notes = regexprep(notes, '\s+', ' ');
end

function discrepancies = local_compare_tables(reference, generated)
reference = local_standardize_table(reference);
generated = local_standardize_table(generated);
fields = ["Gender", "Age", "NormedStereoscore", ...
    "VisualDeficiency", "MatchingExperiment", "ParallaxExperiment"];
allIDs = sort(unique([reference.ID; generated.ID]));

ID = zeros(0, 1);
Field = strings(0, 1);
PresentValue = strings(0, 1);
GeneratedValue = strings(0, 1);

for iID = 1:numel(allIDs)
    participantID = allIDs(iID);
    referenceRow = reference(reference.ID == participantID, :);
    generatedRow = generated(generated.ID == participantID, :);
    if isempty(referenceRow)
        [ID, Field, PresentValue, GeneratedValue] = local_add_difference( ...
            ID, Field, PresentValue, GeneratedValue, participantID, ...
            "Participant", "<missing>", "present");
        continue;
    end
    if isempty(generatedRow)
        [ID, Field, PresentValue, GeneratedValue] = local_add_difference( ...
            ID, Field, PresentValue, GeneratedValue, participantID, ...
            "Participant", "present", "<missing>");
        continue;
    end

    for iField = 1:numel(fields)
        field = fields(iField);
        presentValue = local_display_value(referenceRow.(field)(1), field);
        generatedValue = local_display_value(generatedRow.(field)(1), field);
        if ~local_values_equal(presentValue, generatedValue, field)
            [ID, Field, PresentValue, GeneratedValue] = ...
                local_add_difference(ID, Field, PresentValue, ...
                GeneratedValue, participantID, field, presentValue, ...
                generatedValue);
        end
    end
end

discrepancies = table(ID, Field, PresentValue, GeneratedValue);
end

function standardized = local_standardize_table(tbl)
names = string(tbl.Properties.VariableNames);
normalized = lower(regexprep(names, '[^a-zA-Z0-9]', ''));
required = ["id", "gender", "age", "normedstereoscore", ...
    "visualdeficiency", "matchingexperiment", "parallaxexperiment"];
newNames = ["ID", "Gender", "Age", "NormedStereoscore", ...
    "VisualDeficiency", "MatchingExperiment", "ParallaxExperiment"];
standardized = table();
for iField = 1:numel(required)
    index = find(normalized == required(iField), 1);
    if isempty(index)
        error('SupplementalTable5:MissingComparisonField', ...
            'Table is missing comparison field %s.', newNames(iField));
    end
    standardized.(newNames(iField)) = tbl.(names(index));
end
standardized.ID = local_to_numeric(standardized.ID);
end

function value = local_display_value(value, field)
if field == "Age" || field == "NormedStereoscore"
    numericValue = local_to_numeric(value);
    if isempty(numericValue) || ~isfinite(numericValue(1))
        value = "";
    elseif field == "Age"
        value = compose('%.0f', numericValue(1));
    else
        value = compose('%.2f', numericValue(1));
    end
else
    value = strtrim(string(value));
    if ismissing(value) || lower(value) == "nan" || lower(value) == "na"
        value = "";
    end
end
end

function values = local_to_numeric(values)
if isnumeric(values)
    values = double(values);
else
    values = str2double(strtrim(string(values)));
end
end

function equal = local_values_equal(present, generated, field)
present = string(present);
generated = string(generated);
if field == "NormedStereoscore"
    a = str2double(present);
    b = str2double(generated);
    if isnan(a) && isnan(b)
        equal = true;
    else
        equal = isfinite(a) && isfinite(b) && abs(a - b) < 0.011;
    end
elseif field == "VisualDeficiency"
    normalize = @(x) lower(regexprep(string(x), '[^a-zA-Z0-9]', ''));
    equal = normalize(present) == normalize(generated);
else
    equal = lower(strtrim(present)) == lower(strtrim(generated));
end
end

function [ID, Field, PresentValue, GeneratedValue] = local_add_difference( ...
    ID, Field, PresentValue, GeneratedValue, participantID, field, ...
    presentValue, generatedValue)
ID(end + 1, 1) = participantID;
Field(end + 1, 1) = field;
PresentValue(end + 1, 1) = presentValue;
GeneratedValue(end + 1, 1) = generatedValue;
end

function local_delete_if_present(fileName)
if isfile(fileName)
    delete(fileName);
end
end
