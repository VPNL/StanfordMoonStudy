function [summaryTbl, reportFile] = write_numeric_table_summary_report(dataInput, ResultsDir, reportName, opts)
% write_numeric_table_summary_report
%
% Write a text report with summary ranges for numeric, date, and time-like
% columns in a table or spreadsheet file. ID columns are counted separately.
%
% The report includes, for each summarized column:
%   min, max, median, mean, and standard deviation
%
% Inputs
%   dataInput  : table, CSV file path, or spreadsheet file path
%   ResultsDir : output directory for the text report
%   reportName : optional report filename, or an opts struct
%   opts       : optional struct with fields:
%                DateFormat, TimeFormat, DateTimeFormat, DurationFormat,
%                IDColumnNames, DateColumns, TimeColumns, DateTimeColumns,
%                AutoDetectDateTimeColumns, TimeDayStartHour
%
% Outputs
%   summaryTbl : summary table with one row per summarized column
%   reportFile : full path to the written text report

if nargin < 1 || isempty(dataInput)
    error('dataInput is required.');
end
if nargin < 2 || isempty(ResultsDir)
    ResultsDir = fullfile(pwd, 'Results');
end
if nargin < 3
    reportName = [];
end
if nargin < 4
    opts = struct();
end
if isstruct(reportName)
    opts = reportName;
    reportName = [];
end
opts = local_parse_options(opts);

if istable(dataInput)
    dataTbl = dataInput;
    sourceLabel = '<table input>';
    inputBase = 'table';
else
    dataFile = char(string(dataInput));
    if ~exist(dataFile, 'file')
        error('Could not find input file: %s', dataFile);
    end
    dataTbl = readtable(dataFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
    sourceLabel = dataFile;
    [~, inputBase, ~] = fileparts(dataFile);
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

if isempty(reportName)
    reportName = [inputBase '_numeric_summary.txt'];
else
    reportName = char(string(reportName));
    [~,~,ext] = fileparts(reportName);
    if isempty(ext)
        reportName = [reportName '.txt'];
    end
end
reportFile = fullfile(ResultsDir, reportName);

varNames = string(dataTbl.Properties.VariableNames);
idVarIdx = find(local_is_id_column(varNames, opts), 1, 'first');
if isempty(idVarIdx)
    uniqueIDCount = NaN;
else
    uniqueIDCount = local_count_unique_ids(dataTbl.(varNames(idVarIdx)));
end

summaryTbl = table('Size', [0 8], ...
    'VariableTypes', {'string','string','string','string','string','string','string','string'}, ...
    'VariableNames', {'Parameter','Type','Min','Max','Median','Mean','Std','Notes'});

for iVar = 1:numel(varNames)
    varName = varNames(iVar);
    if local_is_id_column(varName, opts)
        continue;
    end

    [summaryRow, hasSummary] = local_summarize_column(dataTbl.(varName), varName, opts);
    if hasSummary
        summaryTbl(end+1,:) = summaryRow; %#ok<AGROW>
    end
end

local_write_report(reportFile, sourceLabel, height(dataTbl), uniqueIDCount, summaryTbl, opts);
end

function opts = local_parse_options(opts)
if isempty(opts)
    opts = struct();
end
if ~isstruct(opts)
    error('opts must be a struct.');
end

opts.DateFormat = char(string(local_get_option(opts, 'DateFormat', 'MM/dd/yyyy')));
opts.TimeFormat = char(string(local_get_option(opts, 'TimeFormat', 'HH:mm:ss')));
opts.DateTimeFormat = char(string(local_get_option(opts, 'DateTimeFormat', 'MM/dd/yyyy HH:mm:ss')));
opts.DurationFormat = char(string(local_get_option(opts, 'DurationFormat', 'hh:mm:ss')));
opts.IDColumnNames = local_string_array_option(opts, 'IDColumnNames', ...
    ["ID"; "ID Number"; "SubjectID"; "Subject ID"]);
opts.DateColumns = local_string_array_option(opts, 'DateColumns', strings(0,1));
opts.TimeColumns = local_string_array_option(opts, 'TimeColumns', strings(0,1));
opts.DateTimeColumns = local_string_array_option(opts, 'DateTimeColumns', strings(0,1));
opts.AutoDetectDateTimeColumns = logical(local_get_option(opts, 'AutoDetectDateTimeColumns', true));
opts.TimeDayStartHour = double(local_get_option(opts, 'TimeDayStartHour', 12));
if ~isscalar(opts.TimeDayStartHour) || opts.TimeDayStartHour < 0 || opts.TimeDayStartHour >= 24
    error('opts.TimeDayStartHour must be a scalar hour in the range [0, 24).');
end
end

function value = local_get_option(opts, fieldName, defaultValue)
if isfield(opts, fieldName) && ~isempty(opts.(fieldName))
    value = opts.(fieldName);
else
    value = defaultValue;
end
end

function values = local_string_array_option(opts, fieldName, defaultValue)
if isfield(opts, fieldName) && ~isempty(opts.(fieldName))
    values = string(opts.(fieldName));
    values = values(:);
else
    values = defaultValue;
end
end

function tf = local_is_id_column(varNames, opts)
normalizedIds = local_normalize_names(opts.IDColumnNames);
varNames = string(varNames);
tf = false(size(varNames));
for iVar = 1:numel(varNames)
    tf(iVar) = any(local_normalize_name(varNames(iVar)) == normalizedIds);
end
end

function [summaryRow, hasSummary] = local_summarize_column(columnData, varName, opts)
summaryRow = cell(1, 8);
hasSummary = false;
requestedKind = local_requested_datetime_kind(varName, opts);
if strlength(requestedKind) == 0 && opts.AutoDetectDateTimeColumns
    requestedKind = local_auto_name_datetime_kind(varName);
end

if isdatetime(columnData)
    values = columnData(:);
    values = values(~isnat(values));
    if isempty(values)
        return;
    end
    if strlength(requestedKind) == 0
        requestedKind = local_auto_datetime_kind(varName, values, opts);
    end
    summaryRow = local_datetime_summary(varName, values, requestedKind, opts);
    hasSummary = true;
    return;
end

if isduration(columnData)
    values = columnData(:);
    values = values(~isnan(seconds(values)));
    if isempty(values)
        return;
    end
    summaryRow = local_duration_summary(varName, values, "Time", opts);
    hasSummary = true;
    return;
end

if requestedKind == "time"
    [values, invalidValues] = local_time_values(columnData);
    values = values(~isnan(seconds(values)));
    if ~isempty(values)
        summaryRow = local_duration_summary(varName, values, "Time", opts);
        summaryRow{8} = local_invalid_note(invalidValues);
        hasSummary = true;
        return;
    elseif ~isempty(invalidValues)
        summaryRow = {varName, "Time", "", "", "", "", "", local_invalid_note(invalidValues)};
        hasSummary = true;
        return;
    end
end

numericValues = local_numeric_values(columnData);
numericValues = numericValues(isfinite(numericValues));
if isempty(numericValues)
    return;
end

if strlength(requestedKind) == 0 && opts.AutoDetectDateTimeColumns
    requestedKind = local_auto_numeric_datetime_kind(varName, numericValues);
end

if requestedKind == "date" || requestedKind == "datetime"
    values = datetime(numericValues, 'ConvertFrom', 'excel');
    summaryRow = local_datetime_summary(varName, values, requestedKind, opts);
elseif requestedKind == "time"
    values = days(mod(numericValues, 1));
    summaryRow = local_duration_summary(varName, values, "Time", opts);
else
    summaryRow = local_numeric_summary(varName, numericValues);
end
hasSummary = true;
end

function requestedKind = local_requested_datetime_kind(varName, opts)
if local_matches_column_option(varName, opts.DateTimeColumns)
    requestedKind = "datetime";
elseif local_matches_column_option(varName, opts.DateColumns)
    requestedKind = "date";
elseif local_matches_column_option(varName, opts.TimeColumns)
    requestedKind = "time";
else
    requestedKind = "";
end
end

function kind = local_auto_datetime_kind(varName, values, opts)
kind = "";
if opts.AutoDetectDateTimeColumns
    kind = local_auto_name_datetime_kind(varName);
end
if strlength(kind) > 0
    return;
end

if all(hour(values) == 0 & minute(values) == 0 & second(values) == 0)
    kind = "date";
else
    kind = "datetime";
end
end

function kind = local_auto_numeric_datetime_kind(varName, numericValues)
kind = local_auto_name_datetime_kind(varName);
if kind == "date" || kind == "datetime"
    if ~all(numericValues > 20000 & numericValues < 100000)
        kind = "";
    end
elseif kind == "time"
    if ~all(numericValues >= 0 & numericValues < 1)
        kind = "";
    end
end
end

function kind = local_auto_name_datetime_kind(varName)
normalizedName = local_normalize_name(varName);
if contains(normalizedName, "datetime") || contains(normalizedName, "timestamp")
    kind = "datetime";
elseif contains(normalizedName, "date")
    kind = "date";
elseif contains(normalizedName, "time")
    kind = "time";
else
    kind = "";
end
end

function tf = local_matches_column_option(varName, optionNames)
if isempty(optionNames)
    tf = false;
    return;
end

normalizedName = local_normalize_name(varName);
normalizedOptions = local_normalize_names(optionNames);
tf = false;
for iOption = 1:numel(normalizedOptions)
    optionName = normalizedOptions(iOption);
    if strlength(optionName) == 0
        continue;
    end
    if normalizedName == optionName || startsWith(normalizedName, optionName)
        tf = true;
        return;
    end
end
end

function summaryRow = local_numeric_summary(varName, values)
summaryRow = { ...
    varName, ...
    "Numeric", ...
    local_format_number(min(values)), ...
    local_format_number(max(values)), ...
    local_format_number(median(values)), ...
    local_format_number(mean(values)), ...
    local_format_number(std(values)), ...
    ""};
end

function summaryRow = local_datetime_summary(varName, values, kind, opts)
if kind == "time"
    summaryRow = local_duration_summary(varName, timeofday(values), "Time", opts);
    return;
end

anchorValue = min(values);
dayOffsets = days(values - anchorValue);
minValue = anchorValue + days(min(dayOffsets));
maxValue = anchorValue + days(max(dayOffsets));
medianValue = anchorValue + days(median(dayOffsets));
meanValue = anchorValue + days(mean(dayOffsets));
stdValue = days(std(dayOffsets));

if kind == "date"
    typeLabel = "Date";
else
    typeLabel = "DateTime";
end

summaryRow = { ...
    varName, ...
    typeLabel, ...
    local_format_datetime(minValue, kind, opts), ...
    local_format_datetime(maxValue, kind, opts), ...
    local_format_datetime(medianValue, kind, opts), ...
    local_format_datetime(meanValue, kind, opts), ...
    local_format_duration(stdValue, opts), ...
    ""};
end

function summaryRow = local_duration_summary(varName, values, typeLabel, opts)
if string(typeLabel) == "Time"
    summaryRow = local_time_summary(varName, values, typeLabel, opts);
    return;
end

secondsValues = seconds(values);
summaryRow = { ...
    varName, ...
    typeLabel, ...
    local_format_duration(seconds(min(secondsValues)), opts), ...
    local_format_duration(seconds(max(secondsValues)), opts), ...
    local_format_duration(seconds(median(secondsValues)), opts), ...
    local_format_duration(seconds(mean(secondsValues)), opts), ...
    local_format_duration(seconds(std(secondsValues)), opts), ...
    ""};
end

function summaryRow = local_time_summary(varName, values, typeLabel, opts)
secondsValues = local_wrap_time_seconds(seconds(values), opts);
summaryRow = { ...
    varName, ...
    typeLabel, ...
    local_format_wrapped_time(min(secondsValues), opts), ...
    local_format_wrapped_time(max(secondsValues), opts), ...
    local_format_wrapped_time(median(secondsValues), opts), ...
    local_format_wrapped_time(mean(secondsValues), opts), ...
    local_format_duration(seconds(std(secondsValues)), opts), ...
    ""};
end

function wrappedSeconds = local_wrap_time_seconds(secondsValues, opts)
secondsPerDay = 24 * 60 * 60;
dayStartSeconds = opts.TimeDayStartHour * 60 * 60;
wrappedSeconds = mod(secondsValues, secondsPerDay);
wrappedSeconds(wrappedSeconds < dayStartSeconds) = wrappedSeconds(wrappedSeconds < dayStartSeconds) + secondsPerDay;
end

function [values, invalidValues] = local_time_values(columnData)
if isduration(columnData)
    values = columnData(:);
    invalidValues = strings(0, 1);
    return;
end

if isdatetime(columnData)
    values = timeofday(columnData(:));
    invalidValues = strings(0, 1);
    return;
end

if isnumeric(columnData) || islogical(columnData)
    [values, invalidValues] = local_numeric_time_values(double(columnData(:)));
    return;
end

if iscell(columnData)
    values = seconds(nan(numel(columnData), 1));
    invalidValues = strings(0, 1);
    for iValue = 1:numel(columnData)
        [values(iValue), invalidValue] = local_single_time_value(columnData{iValue});
        invalidValues = local_append_invalid_value(invalidValues, invalidValue);
    end
    return;
end

if isstring(columnData) || ischar(columnData) || iscategorical(columnData)
    textValues = string(columnData(:));
    values = seconds(nan(numel(textValues), 1));
    invalidValues = strings(0, 1);
    for iValue = 1:numel(textValues)
        [values(iValue), invalidValue] = local_text_time_value(textValues(iValue));
        invalidValues = local_append_invalid_value(invalidValues, invalidValue);
    end
    return;
end

values = seconds(nan(0, 1));
invalidValues = strings(0, 1);
end

function [values, invalidValues] = local_numeric_time_values(numericValues)
values = seconds(nan(size(numericValues)));
invalidValues = strings(0, 1);
for iValue = 1:numel(numericValues)
    [values(iValue), invalidValue] = local_numeric_time_value(numericValues(iValue));
    invalidValues = local_append_invalid_value(invalidValues, invalidValue);
end
end

function [value, invalidValue] = local_single_time_value(rawValue)
invalidValue = "";
if isnumeric(rawValue) || islogical(rawValue)
    if isscalar(rawValue)
        [value, invalidValue] = local_numeric_time_value(double(rawValue));
    else
        value = seconds(nan);
        invalidValue = string(mat2str(rawValue));
    end
elseif isduration(rawValue)
    value = rawValue;
elseif isdatetime(rawValue)
    value = timeofday(rawValue);
elseif isstring(rawValue) || ischar(rawValue) || iscategorical(rawValue)
    [value, invalidValue] = local_text_time_value(string(rawValue));
else
    value = seconds(nan);
end
end

function [value, invalidValue] = local_numeric_time_value(rawValue)
invalidValue = "";
if isempty(rawValue) || ~isfinite(rawValue) || rawValue < 0
    value = seconds(nan);
    if ~isempty(rawValue) && ~isnan(rawValue)
        invalidValue = string(rawValue);
    end
    return;
end

if rawValue < 1
    value = days(rawValue);
    return;
end

value = seconds(nan);
invalidValue = string(rawValue);
end

function [value, invalidValue] = local_text_time_value(textValue)
invalidValue = "";
textValue = strtrim(string(textValue));
if ismissing(textValue) || strlength(textValue) == 0
    value = seconds(nan);
    return;
end

numericValue = str2double(textValue);
if ~isnan(numericValue)
    [value, invalidValue] = local_numeric_time_value(numericValue);
    return;
end

timeText = char(textValue);
timeMatch = regexp(timeText, '^\s*(?<hour>\d{1,2}):(?<minute>\d{2}):(?<second>\d{2}(\.\d+)?)\s*(?<suffix>[apAP])\.?[mM]\.?\s*$', 'names', 'once');
if isempty(timeMatch)
    timeMatch = regexp(timeText, '^\s*(?<hour>\d{1,2}):(?<minute>\d{2})\s*(?<suffix>[apAP])\.?[mM]\.?\s*$', 'names', 'once');
end
if ~isempty(timeMatch)
    hourValue = str2double(timeMatch.hour);
    minuteValue = str2double(timeMatch.minute);
    if isfield(timeMatch, 'second') && ~isempty(timeMatch.second)
        secondValue = str2double(timeMatch.second);
    else
        secondValue = 0;
    end
    suffixValue = lower(timeMatch.suffix);
    if strcmp(suffixValue, 'p') && hourValue < 12
        hourValue = hourValue + 12;
    elseif strcmp(suffixValue, 'a') && hourValue == 12
        hourValue = 0;
    end

    if hourValue < 24 && minuteValue < 60 && secondValue < 60
        value = hours(hourValue) + minutes(minuteValue) + seconds(secondValue);
    else
        value = seconds(nan);
        invalidValue = textValue;
    end
    return;
end

timeMatch = regexp(timeText, '^\s*(?<hour>\d{1,2}):(?<minute>\d{2}):(?<second>\d{2}(\.\d+)?)\s*$', 'names', 'once');
if isempty(timeMatch)
    timeMatch = regexp(timeText, '^\s*(?<hour>\d{1,2}):(?<minute>\d{2})\s*$', 'names', 'once');
end
if isempty(timeMatch)
    value = seconds(nan);
    invalidValue = textValue;
    return;
end

hourValue = str2double(timeMatch.hour);
minuteValue = str2double(timeMatch.minute);
if isfield(timeMatch, 'second') && ~isempty(timeMatch.second)
    secondValue = str2double(timeMatch.second);
else
    secondValue = 0;
end

if hourValue < 24 && minuteValue < 60 && secondValue < 60
    value = hours(hourValue) + minutes(minuteValue) + seconds(secondValue);
else
    value = seconds(nan);
    invalidValue = textValue;
end
end

function invalidValues = local_append_invalid_value(invalidValues, invalidValue)
if strlength(invalidValue) > 0
    invalidValues(end+1, 1) = invalidValue;
end
end

function note = local_invalid_note(invalidValues)
invalidValues = string(invalidValues(:));
invalidValues = invalidValues(strlength(invalidValues) > 0);
if isempty(invalidValues)
    note = "";
    return;
end

exampleValues = unique(invalidValues, 'stable');
maxExamples = min(numel(exampleValues), 3);
examples = strjoin(exampleValues(1:maxExamples), ", ");
note = string(sprintf('%d invalid excluded: %s', numel(invalidValues), examples));
end

function textValue = local_format_number(value)
textValue = string(sprintf('%.6g', value));
end

function textValue = local_format_datetime(value, kind, opts)
if kind == "date"
    value.Format = opts.DateFormat;
elseif kind == "time"
    value.Format = opts.TimeFormat;
else
    value.Format = opts.DateTimeFormat;
end
textValue = string(value);
end

function textValue = local_format_duration(value, opts)
value.Format = opts.DurationFormat;
textValue = string(value);
end

function textValue = local_format_wrapped_time(secondsValue, opts)
secondsPerDay = 24 * 60 * 60;
dayOffset = floor(secondsValue / secondsPerDay);
timeSeconds = mod(secondsValue, secondsPerDay);
textValue = local_format_duration(seconds(timeSeconds), opts);
if dayOffset == 1
    textValue = textValue + " (+1 day)";
elseif dayOffset > 1
    textValue = textValue + string(sprintf(' (+%d days)', dayOffset));
end
end

function values = local_numeric_values(columnData)
if isnumeric(columnData) || islogical(columnData)
    values = double(columnData(:));
    return;
end

if iscell(columnData)
    values = local_numeric_values_from_cell(columnData);
    return;
end

if isstring(columnData) || ischar(columnData) || iscategorical(columnData)
    values = str2double(string(columnData(:)));
    return;
end

values = [];
end

function values = local_numeric_values_from_cell(columnData)
values = nan(numel(columnData), 1);
for i = 1:numel(columnData)
    thisValue = columnData{i};
    if isnumeric(thisValue) || islogical(thisValue)
        if isscalar(thisValue)
            values(i) = double(thisValue);
        end
    elseif isstring(thisValue) || ischar(thisValue) || iscategorical(thisValue)
        values(i) = str2double(string(thisValue));
    end
end
end

function n = local_count_unique_ids(ids)
if isnumeric(ids)
    ids = ids(~isnan(ids));
elseif iscategorical(ids)
    ids = ids(~isundefined(ids));
elseif isdatetime(ids)
    ids = ids(~isnat(ids));
end

ids = strtrim(string(ids(:)));
ids = ids(~ismissing(ids) & strlength(ids) > 0 & lower(ids) ~= "nan");
n = numel(unique(ids));
end

function local_write_report(reportFile, sourceLabel, nRows, uniqueIDCount, summaryTbl, opts)
[reportDir,~,~] = fileparts(reportFile);
if ~isempty(reportDir) && ~exist(reportDir, 'dir')
    mkdir(reportDir);
end

[fid, msg] = fopen(reportFile, 'w');
if fid == -1
    error('Could not open report file %s: %s', reportFile, msg);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'Table Summary Report\n');
fprintf(fid, '====================\n\n');
fprintf(fid, 'Source: %s\n', sourceLabel);
fprintf(fid, 'Generated: %s\n', string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss")));
fprintf(fid, 'Rows: %d\n', nRows);
if isnan(uniqueIDCount)
    fprintf(fid, 'Unique IDs: ID column not found\n');
else
    fprintf(fid, 'Unique IDs: %d\n', uniqueIDCount);
end
fprintf(fid, 'Date format: %s\n', opts.DateFormat);
fprintf(fid, 'Time format: %s\n', opts.TimeFormat);
fprintf(fid, 'Time day starts at: %02d:00:00\n', opts.TimeDayStartHour);
fprintf(fid, 'Columns summarized: %d\n\n', height(summaryTbl));

if isempty(summaryTbl)
    fprintf(fid, 'No numeric, date, or time-like columns were found after excluding ID.\n');
    return;
end

reportTbl = removevars(summaryTbl, 'Type');
write_plain_text_table(fid, reportTbl);
end

function normalizedNames = local_normalize_names(names)
names = string(names(:));
normalizedNames = strings(size(names));
for iName = 1:numel(names)
    normalizedNames(iName) = local_normalize_name(names(iName));
end
end

function normalizedName = local_normalize_name(name)
normalizedName = lower(regexprep(char(string(name)), '[^a-zA-Z0-9]', ''));
normalizedName = string(normalizedName);
end
