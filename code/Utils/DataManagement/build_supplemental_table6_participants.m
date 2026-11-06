function [summaryTbl, audit] = build_supplemental_table6_participants(dataDir, outFile)
% BUILD_SUPPLEMENTAL_TABLE6_PARTICIPANTS Build the cross-study participant table.
%
% [summaryTbl, audit] = build_supplemental_table6_participants(dataDir, outFile)
%
% The table contains one row per participant and one date column for each
% experiment. Multiple dates are separated by semicolons. Gender and age
% come from the earliest dated valid record. NormedStereoScore is the
% participant-level normalized score (0-100) from the Quad matching and
% parallax tables. The Boring control data and combined derivative tables
% are intentionally excluded.

arguments
    dataDir (1, 1) string
    outFile (1, 1) string
end

sourceSpecs = [ ...
    local_spec("MoonPerceptual", fullfile("MoonStudy", ...
        "FullMoonDataLong090225.csv"), "percept", false); ...
    local_spec("MoonAdjusted", fullfile("MoonStudy", ...
        "FullMoonDataLong090225.csv"), "adjust", false); ...
    local_spec("QuadPerceptual", fullfile("QuadStudy", ...
        "Perceptual_StanfordQuadStudyDataProcessed0420.csv"), "", false); ...
    local_spec("QuadPerceptual", fullfile("QuadStudy", ...
        "QuadProcessedMatchingandStereoData.csv"), "percept", true); ...
    local_spec("QuadAdjusted", fullfile("QuadStudy", ...
        "QuadProcessedMatchingandStereoData.csv"), "adjust", true); ...
    local_spec("QuadParallax", fullfile("BinocularParallax", ...
        "QuadProcessedParallaxandStereoData.csv"), "", true); ...
    local_spec("MoonParallax", fullfile("BinocularParallax", ...
        "Parallax_FullMoon_090225.csv"), "", false)];

records = table('Size', [0, 8], ...
    'VariableTypes', {'double', 'string', 'double', 'datetime', ...
    'string', 'string', 'double', 'double'}, ...
    'VariableNames', {'ID', 'Gender', 'Age', 'Date', 'Experiment', ...
    'Source', 'NormedStereoScore', 'SourcePriority'});

for iSource = 1:numel(sourceSpecs)
    sourceFile = fullfile(dataDir, sourceSpecs(iSource).RelativePath);
    if ~isfile(sourceFile)
        error('SupplementalTable6:MissingSource', ...
            'Required source file is missing: %s', sourceFile);
    end

    source = readtable(sourceFile, 'VariableNamingRule', 'preserve');
    sourceRecords = local_source_records(source, sourceSpecs(iSource), iSource);
    records = [records; sourceRecords]; %#ok<AGROW>
end

records = records(isfinite(records.ID) & records.ID == floor(records.ID), :);
participantIDs = sort(unique(records.ID));
nParticipants = numel(participantIDs);

ID = participantIDs;
Gender = strings(nParticipants, 1);
Age = nan(nParticipants, 1);
MoonPerceptual = strings(nParticipants, 1);
MoonAdjusted = strings(nParticipants, 1);
QuadPerceptual = strings(nParticipants, 1);
QuadAdjusted = strings(nParticipants, 1);
QuadParallax = strings(nParticipants, 1);
MoonParallax = strings(nParticipants, 1);
NormedStereoScore = nan(nParticipants, 1);

genderConflictIDs = zeros(0, 1);
ageConflictIDs = zeros(0, 1);
stereoConflictIDs = zeros(0, 1);

for iParticipant = 1:nParticipants
    rows = records.ID == ID(iParticipant);
    participantRecords = records(rows, :);

    [Gender(iParticipant), genderConflict] = local_demographic_string( ...
        participantRecords.Gender, participantRecords.Date);
    [Age(iParticipant), ageConflict] = local_demographic_number( ...
        participantRecords.Age, participantRecords.Date);
    [NormedStereoScore(iParticipant), stereoConflict] = ...
        local_stereo_score(participantRecords);

    if genderConflict
        genderConflictIDs(end + 1, 1) = ID(iParticipant); %#ok<AGROW>
    end
    if ageConflict
        ageConflictIDs(end + 1, 1) = ID(iParticipant); %#ok<AGROW>
    end
    if stereoConflict
        stereoConflictIDs(end + 1, 1) = ID(iParticipant); %#ok<AGROW>
    end

    MoonPerceptual(iParticipant) = local_experiment_dates( ...
        participantRecords, "MoonPerceptual");
    MoonAdjusted(iParticipant) = local_experiment_dates( ...
        participantRecords, "MoonAdjusted");
    QuadPerceptual(iParticipant) = local_experiment_dates( ...
        participantRecords, "QuadPerceptual");
    QuadAdjusted(iParticipant) = local_experiment_dates( ...
        participantRecords, "QuadAdjusted");
    QuadParallax(iParticipant) = local_experiment_dates( ...
        participantRecords, "QuadParallax");
    MoonParallax(iParticipant) = local_experiment_dates( ...
        participantRecords, "MoonParallax");
end

ageValues = Age;
Age = strings(nParticipants, 1);
hasAge = isfinite(ageValues);
Age(hasAge) = compose('%.0f', ageValues(hasAge));

scoreValues = NormedStereoScore;
NormedStereoScore = strings(nParticipants, 1);
hasScore = isfinite(scoreValues);
NormedStereoScore(hasScore) = compose('%.2f', scoreValues(hasScore));

summaryTbl = table(ID, Gender, Age, MoonPerceptual, MoonAdjusted, ...
    QuadPerceptual, QuadAdjusted, QuadParallax, MoonParallax, ...
    NormedStereoScore);

audit = struct();
audit.UniqueParticipantCount = nParticipants;
audit.GenderConflictIDs = genderConflictIDs;
audit.AgeConflictIDs = ageConflictIDs;
audit.StereoScoreConflictIDs = stereoConflictIDs;
audit.SourceFiles = fullfile(dataDir, string({sourceSpecs.RelativePath}))';

outDir = fileparts(outFile);
if strlength(outDir) > 0 && ~isfolder(outDir)
    mkdir(outDir);
end
writetable(summaryTbl, outFile);

fprintf('Supplemental Table 6: %d unique participants.\n', nParticipants);
local_report_conflicts('gender', genderConflictIDs);
local_report_conflicts('age', ageConflictIDs);
local_report_conflicts('normalized stereo score', stereoConflictIDs);
fprintf('Wrote %s\n', outFile);
end

function spec = local_spec(name, relativePath, taskFilter, hasStereoScore)
spec = struct('Name', name, 'RelativePath', relativePath, ...
    'TaskFilter', taskFilter, 'HasStereoScore', hasStereoScore);
end

function records = local_source_records(source, spec, sourcePriority)
nRows = height(source);
idName = local_find_variable(source, ["ID", "IDNumber"]);
if idName == ""
    error('SupplementalTable6:MissingID', ...
        'Source %s does not contain an ID column.', spec.RelativePath);
end

ID = local_numeric(source.(idName));
Gender = repmat("", nRows, 1);
genderName = local_find_variable(source, "Gender");
if genderName ~= ""
    Gender = local_normalize_gender(source.(genderName));
end

Age = nan(nRows, 1);
ageName = local_find_variable(source, "Age");
if ageName ~= ""
    Age = local_numeric(source.(ageName));
    Age(Age <= 0 | Age > 120) = nan;
end

Date = NaT(nRows, 1);
dateName = local_find_variable(source, "Date");
if dateName ~= ""
    Date = local_parse_dates(source.(dateName));
end

Experiment = repmat(spec.Name, nRows, 1);
taskMask = true(nRows, 1);
if spec.TaskFilter ~= ""
    taskName = local_find_variable(source, "Task");
    if taskName == ""
        error('SupplementalTable6:MissingTask', ...
            'Source %s does not contain Task.', spec.RelativePath);
    end
    task = lower(strtrim(string(source.(taskName))));
    taskMask = contains(task, spec.TaskFilter);
end

NormedStereoScore = nan(nRows, 1);
if spec.HasStereoScore
    scoreName = local_find_variable(source, ...
        ["NormedScore", "NormedStereoScore"]);
    if scoreName ~= ""
        NormedStereoScore = local_numeric(source.(scoreName));
        NormedStereoScore(NormedStereoScore < 0 | ...
            NormedStereoScore > 100) = nan;
    end
end

Source = repmat(string(spec.RelativePath), nRows, 1);
SourcePriority = repmat(double(sourcePriority), nRows, 1);
valid = isfinite(ID) & taskMask;
records = table(ID(valid), Gender(valid), Age(valid), Date(valid), ...
    Experiment(valid), Source(valid), NormedStereoScore(valid), ...
    SourcePriority(valid), 'VariableNames', {'ID', 'Gender', 'Age', ...
    'Date', 'Experiment', 'Source', 'NormedStereoScore', 'SourcePriority'});
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

function values = local_numeric(values)
if isnumeric(values)
    values = double(values);
else
    values = str2double(strtrim(string(values)));
end
values(~isfinite(values)) = nan;
end

function gender = local_normalize_gender(values)
raw = strtrim(string(values));
compact = lower(regexprep(raw, '[^a-zA-Z]', ''));
gender = repmat("", size(raw));
gender(ismember(compact, ["f", "female", "woman"])) = "Female";
gender(ismember(compact, ["m", "male", "man"])) = "Male";
gender(ismember(compact, ["nonbinary", "nonbiry", "nb", "gnc", ...
    "gendernonconforming", "gendernonconfirming"])) = ...
    "Gender non confirming";
end

function dates = local_parse_dates(values)
if isdatetime(values)
    dates = values;
    twoDigitYear = ~isnat(dates) & year(dates) < 100;
    dates(twoDigitYear) = dates(twoDigitYear) + calyears(2000);
    return;
end
text = strtrim(string(values));
dates = NaT(size(text));
for iRow = 1:numel(text)
    if text(iRow) == "" || ismissing(text(iRow))
        continue;
    end
    tokens = regexp(char(text(iRow)), ...
        '^(\d{1,2})/(\d{1,2})/(\d{2}|\d{4})$', 'tokens', 'once');
    if isempty(tokens)
        continue;
    end
    monthValue = str2double(tokens{1});
    dayValue = str2double(tokens{2});
    yearValue = str2double(tokens{3});
    if yearValue < 100
        yearValue = 2000 + yearValue;
    end
    try
        dates(iRow) = datetime(yearValue, monthValue, dayValue);
    catch
        dates(iRow) = NaT;
    end
end
end

function [value, conflict] = local_demographic_string(values, dates)
valid = values ~= "" & ~ismissing(values);
uniqueValues = unique(values(valid));
conflict = numel(uniqueValues) > 1;
value = "";
if ~any(valid)
    return;
end
indices = find(valid);
dated = ~isnat(dates(indices));
if any(dated)
    datedIndices = indices(dated);
    [~, order] = min(dates(datedIndices));
    value = values(datedIndices(order));
else
    value = values(indices(1));
end
end

function [value, conflict] = local_demographic_number(values, dates)
valid = isfinite(values);
uniqueValues = unique(values(valid));
conflict = numel(uniqueValues) > 1;
value = nan;
if ~any(valid)
    return;
end
indices = find(valid);
dated = ~isnat(dates(indices));
if any(dated)
    datedIndices = indices(dated);
    [~, order] = min(dates(datedIndices));
    value = values(datedIndices(order));
else
    value = values(indices(1));
end
end

function [score, conflict] = local_stereo_score(records)
valid = isfinite(records.NormedStereoScore);
scores = unique(records.NormedStereoScore(valid));
conflict = numel(scores) > 1;
score = nan;
if isempty(scores)
    return;
end

scoreRows = records(valid, :);
[~, order] = sortrows(scoreRows, {'SourcePriority', 'Date'});
score = scoreRows.NormedStereoScore(order(1));
end

function datesText = local_experiment_dates(records, experiment)
dates = records.Date(records.Experiment == experiment);
dates = unique(dates(~isnat(dates)), 'sorted');
if isempty(dates)
    datesText = "";
else
    datesText = strjoin(string(dates, 'yyyy-MM-dd'), '; ');
end
end

function local_report_conflicts(label, ids)
if isempty(ids)
    fprintf('No participant-level %s conflicts.\n', label);
else
    warning('SupplementalTable6:ConflictingValues', ...
        'Conflicting %s values for IDs: %s', label, ...
        strjoin(string(ids), ', '));
end
end
