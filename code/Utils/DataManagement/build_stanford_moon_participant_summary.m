function summaryTbl = build_stanford_moon_participant_summary(dataDir, outFile)
% BUILD_STANFORD_MOON_PARTICIPANT_SUMMARY Summarize participants across studies.
%
% summaryTbl = build_stanford_moon_participant_summary(dataDir, outFile)
%
% The output has one row per numeric participant ID. Gender and age are
% taken from the earliest dated record where each value is available.
% Experiment-specific columns contain all unique participation dates,
% separated by semicolons when an experiment was completed more than once.

if nargin < 1 || isempty(dataDir)
    error('dataDir is required.');
end
if nargin < 2 || isempty(outFile)
    outFile = fullfile(dataDir, 'StanfordMoonStudy_participant_summary.csv');
end

sourceSpecs = struct( ...
    'Experiment', {"MoonStudy", "QuadStudy", ...
        "FullMoonParallax", "QuadParallax"}, ...
    'IDPrefix', {"", "", "", ""}, ...
    'RelativePath', { ...
        fullfile('MoonStudy', 'Perceptual_FullMoonDataRaw090225.csv'), ...
        fullfile('QuadStudy', 'Perceptual_StanfordQuadStudyDataRaw0420.csv'), ...
        fullfile('BinocularParallax', 'FullMoonRawData090225.csv'), ...
        fullfile('BinocularParallax', 'QuadProcessedParallaxandStereoData1008.csv')});

allID = strings(0, 1);
allGender = strings(0, 1);
allAge = zeros(0, 1);
allDate = NaT(0, 1);
allExperiment = strings(0, 1);

for iSource = 1:numel(sourceSpecs)
    sourceFile = fullfile(dataDir, sourceSpecs(iSource).RelativePath);
    if ~isfile(sourceFile)
        warning('build_stanford_moon_participant_summary:MissingSource', ...
            'Skipping missing source file: %s', sourceFile);
        continue;
    end

    importOptions = detectImportOptions(sourceFile, ...
        'VariableNamingRule', 'modify');
    importOptions = setvartype(importOptions, ...
        importOptions.VariableNames, 'string');
    source = readtable(sourceFile, importOptions);
    idName = local_find_variable(source, ["ID", "IDNumber"]);
    if idName == ""
        warning('build_stanford_moon_participant_summary:MissingID', ...
            'Skipping source without an ID variable: %s', sourceFile);
        continue;
    end
    genderName = local_find_variable(source, "Gender");
    ageName = local_find_variable(source, "Age");
    dateName = local_find_variable(source, "Date");

    idNumber = str2double(strtrim(string(source.(idName))));
    validID = isfinite(idNumber) & idNumber == floor(idNumber);
    source = source(validID, :);
    idNumber = idNumber(validID);
    nRows = height(source);

    gender = strings(nRows, 1);
    if genderName ~= ""
        gender = local_normalize_gender(source.(genderName));
    end

    age = nan(nRows, 1);
    if ageName ~= ""
        age = str2double(strtrim(string(source.(ageName))));
        age(~isfinite(age) | age <= 0 | age > 120) = nan;
    end

    participationDate = NaT(nRows, 1);
    if dateName ~= ""
        participationDate = local_parse_dates(source.(dateName));
    end

    validRecord = gender ~= "" | isfinite(age) | ~isnat(participationDate);
    idNumber = idNumber(validRecord);
    gender = gender(validRecord);
    age = age(validRecord);
    participationDate = participationDate(validRecord);
    nRows = numel(idNumber);

    allID = [allID; sourceSpecs(iSource).IDPrefix + string(idNumber)]; %#ok<AGROW>
    allGender = [allGender; gender]; %#ok<AGROW>
    allAge = [allAge; age]; %#ok<AGROW>
    allDate = [allDate; participationDate]; %#ok<AGROW>
    allExperiment = [allExperiment; ...
        repmat(sourceSpecs(iSource).Experiment, nRows, 1)]; %#ok<AGROW>
end

if isempty(allID)
    error('No valid participant records were found under %s.', dataDir);
end

uniqueID = unique(allID);
numericID = str2double(regexprep(uniqueID, '[^0-9]', ''));
prefixedID = false(size(uniqueID));
[~, idOrder] = sortrows(table(prefixedID, numericID), ...
    {'prefixedID', 'numericID'});
uniqueID = uniqueID(idOrder);
nParticipants = numel(uniqueID);
experimentNames = string({sourceSpecs.Experiment});

UniqueID = uniqueID;
Gender = strings(nParticipants, 1);
Age = nan(nParticipants, 1);
Experiment = strings(nParticipants, 1);
experimentDates = strings(nParticipants, numel(experimentNames));

for iParticipant = 1:nParticipants
    participantRows = allID == UniqueID(iParticipant);
    Gender(iParticipant) = local_earliest_string( ...
        allGender(participantRows), allDate(participantRows));
    Age(iParticipant) = local_earliest_number( ...
        allAge(participantRows), allDate(participantRows));

    participantExperiments = strings(0, 1);
    for iExperiment = 1:numel(experimentNames)
        experimentRows = participantRows & ...
            allExperiment == experimentNames(iExperiment);
        if ~any(experimentRows)
            continue;
        end
        participantExperiments(end + 1, 1) = ...
            experimentNames(iExperiment); %#ok<AGROW>
        experimentDates(iParticipant, iExperiment) = ...
            local_join_dates(allDate(experimentRows));
    end
    Experiment(iParticipant) = strjoin(participantExperiments, '; ');
end

summaryTbl = table(UniqueID, Gender, Age, Experiment);
for iExperiment = 1:numel(experimentNames)
    variableName = matlab.lang.makeValidName( ...
        experimentNames(iExperiment) + "_Date");
    summaryTbl.(variableName) = experimentDates(:, iExperiment);
end

[outDir, ~, extension] = fileparts(outFile);
if isempty(extension)
    outFile = outFile + ".csv";
end
if ~isempty(outDir) && ~isfolder(outDir)
    mkdir(outDir);
end
writetable(summaryTbl, outFile);
end

function variableName = local_find_variable(tbl, candidates)
variableName = "";
normalizedNames = local_normalize_name(tbl.Properties.VariableNames);
normalizedCandidates = local_normalize_name(candidates);
for iCandidate = 1:numel(normalizedCandidates)
    index = find(normalizedNames == normalizedCandidates(iCandidate), 1);
    if ~isempty(index)
        variableName = string(tbl.Properties.VariableNames{index});
        return;
    end
end
end

function normalized = local_normalize_name(values)
normalized = lower(regexprep(string(values), '[^a-zA-Z0-9]', ''));
end

function gender = local_normalize_gender(values)
gender = strtrim(string(values));
missing = ismissing(gender) | gender == "" | ...
    upper(gender) == "NA" | upper(gender) == "NAN";
compact = lower(regexprep(gender, '[^a-zA-Z]', ''));
gender(compact == "f" | compact == "female" | compact == "woman") = "Female";
gender(compact == "m" | compact == "male" | compact == "man") = "Male";
gender(compact == "nonbinary" | compact == "nonbiry" | ...
    compact == "nb") = "Nonbinary";
gender(compact == "gnc") = "GNC";
gender(missing) = "";
end

function dates = local_parse_dates(values)
dateText = strtrim(string(values));
dates = NaT(size(dateText));
currentTwoDigitYear = mod(year(datetime('today')), 100);
for iDate = 1:numel(dateText)
    if ismissing(dateText(iDate)) || dateText(iDate) == ""
        continue;
    end
    tokens = regexp(char(dateText(iDate)), ...
        '^(\d{1,2})/(\d{1,2})/(\d{2}|\d{4})$', 'tokens', 'once');
    if isempty(tokens)
        continue;
    end
    monthValue = str2double(tokens{1});
    dayValue = str2double(tokens{2});
    yearValue = str2double(tokens{3});
    if strlength(tokens{3}) == 2
        if yearValue <= currentTwoDigitYear
            yearValue = 2000 + yearValue;
        else
            yearValue = 1900 + yearValue;
        end
    elseif yearValue < 100
        yearValue = 2000 + yearValue;
    end
    try
        dates(iDate) = datetime(yearValue, monthValue, dayValue);
    catch
        dates(iDate) = NaT;
    end
end
end

function value = local_earliest_string(values, dates)
valid = values ~= "" & ~ismissing(values);
if ~any(valid)
    value = "";
    return;
end
validIndex = find(valid);
validDates = dates(valid);
dated = ~isnat(validDates);
if any(dated)
    datedIndex = validIndex(dated);
    [~, firstIndex] = min(dates(datedIndex));
    value = values(datedIndex(firstIndex));
else
    value = values(validIndex(1));
end
end

function value = local_earliest_number(values, dates)
valid = isfinite(values);
if ~any(valid)
    value = nan;
    return;
end
validIndex = find(valid);
validDates = dates(valid);
dated = ~isnat(validDates);
if any(dated)
    datedIndex = validIndex(dated);
    [~, firstIndex] = min(dates(datedIndex));
    value = values(datedIndex(firstIndex));
else
    value = values(validIndex(1));
end
end

function joinedDates = local_join_dates(dates)
dates = unique(dates(~isnat(dates)), 'sorted');
if isempty(dates)
    joinedDates = "";
    return;
end
dateText = string(dates, 'yyyy-MM-dd');
joinedDates = strjoin(dateText, '; ');
end
