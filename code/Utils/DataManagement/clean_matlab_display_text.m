function displayText = clean_matlab_display_text(displayText, removeGroupError)
% clean_matlab_display_text Remove MATLAB rich-display markup from text.
%
% Inputs
%   displayText      : text captured from evalc/disp/anova/compare
%   removeGroupError : optional logical. If true, remove the "Group: Error"
%                      block from LinearMixedModel display text.
%
% Output
%   displayText      : plain text with table-like blocks realigned

if nargin < 2 || isempty(removeGroupError)
    removeGroupError = false;
end

displayText = char(string(displayText));
displayText = regexprep(displayText, '<[^>]+>', '');
displayText = regexprep(displayText, '\{\s*''([^'']*)''\s*\}', '$1');
displayText = strrep(displayText, '{', '');
displayText = strrep(displayText, '}', '');
displayText = strrep(displayText, '''', '');
displayText = strrep(displayText, '"', '');

lines = regexp(displayText, '\r\n|\n|\r', 'split');
lines = local_trim_blank_edges(lines);
lines = local_remove_first_model_fit_line(lines);
if removeGroupError
    lines = local_remove_group_error_block(lines);
end
lines = local_merge_fixed_effects_tables(lines);
lines = local_label_estimated_coefficients_tables(lines);
lines = local_trim_blank_edges(lines);
lines = local_align_tabular_blocks(lines);

displayText = char(strjoin(string(lines), newline));
end

function lines = local_remove_first_model_fit_line(lines)
if isempty(lines)
    return;
end

firstLine = strtrim(lines{1});
fitPrefix = 'Linear mixed-effects model fit by';
if strncmp(firstLine, fitPrefix, numel(fitPrefix))
    lines(1) = [];
end
end

function lines = local_remove_group_error_block(lines)
if isempty(lines)
    return;
end

trimmedLines = strtrim(string(lines));
idx = find(trimmedLines == "Group: Error", 1, 'first');
if ~isempty(idx)
    lines(idx:end) = [];
end
end

function lines = local_trim_blank_edges(lines)
while ~isempty(lines) && strlength(string(strtrim(lines{1}))) == 0
    lines(1) = [];
end
while ~isempty(lines) && strlength(string(strtrim(lines{end}))) == 0
    lines(end) = [];
end
end

function lines = local_merge_fixed_effects_tables(lines)
iLine = 1;
while iLine <= numel(lines)
    if ~strcmp(strtrim(lines{iLine}), 'Fixed effects coefficients (95% CIs):')
        iLine = iLine + 1;
        continue;
    end

    tableStart = iLine + 1;
    tableEnd = tableStart;
    while tableEnd <= numel(lines)
        thisLine = strtrim(lines{tableEnd});
        if startsWith(thisLine, 'Random effects covariance parameters') || ...
                startsWith(thisLine, 'Group:') || ...
                startsWith(thisLine, 'Model:') || ...
                startsWith(thisLine, 'Model comparison:')
            break;
        end
        tableEnd = tableEnd + 1;
    end
    tableEnd = tableEnd - 1;

    [mergedLines, didMerge] = local_fixed_effects_table_lines(lines(tableStart:tableEnd));
    if didMerge
        lines = [lines(1:iLine), mergedLines, lines(tableEnd + 1:end)];
        iLine = iLine + numel(mergedLines) + 1;
    else
        iLine = tableEnd + 1;
    end
end
end

function [mergedLines, didMerge] = local_fixed_effects_table_lines(tableLines)
desiredHeaders = {'Name','Estimate','SE','tStat','DF','pValue','Lower','Upper'};
mergedLines = tableLines;
didMerge = false;

segments = local_table_segments(tableLines);
if isempty(segments)
    return;
end

nRows = numel(segments(1).Rows);
if nRows == 0
    return;
end

rowValues = repmat(struct(), nRows, 1);
for iSegment = 1:numel(segments)
    segment = segments(iSegment);
    if numel(segment.Rows) ~= nRows
        return;
    end

    for iRow = 1:nRows
        rowTokens = segment.Rows{iRow};
        if numel(rowTokens) ~= numel(segment.Headers)
            return;
        end
        for iHeader = 1:numel(segment.Headers)
            fieldName = matlab.lang.makeValidName(segment.Headers{iHeader});
            rowValues(iRow).(fieldName) = rowTokens{iHeader};
        end
    end
end

for iHeader = 1:numel(desiredHeaders)
    fieldName = matlab.lang.makeValidName(desiredHeaders{iHeader});
    for iRow = 1:nRows
        if ~isfield(rowValues(iRow), fieldName)
            return;
        end
    end
end

mergedLines = cell(1, nRows + 1);
mergedLines{1} = ['    ' strjoin(desiredHeaders, sprintf('\t'))];
for iRow = 1:nRows
    rowText = cell(1, numel(desiredHeaders));
    for iHeader = 1:numel(desiredHeaders)
        fieldName = matlab.lang.makeValidName(desiredHeaders{iHeader});
        rowText{iHeader} = rowValues(iRow).(fieldName);
    end
    mergedLines{iRow + 1} = ['    ' strjoin(rowText, sprintf('\t'))];
end
didMerge = true;
end

function segments = local_table_segments(tableLines)
segments = struct('Headers', {}, 'Rows', {});
iLine = 1;
while iLine <= numel(tableLines)
    while iLine <= numel(tableLines) && strlength(string(strtrim(tableLines{iLine}))) == 0
        iLine = iLine + 1;
    end
    if iLine > numel(tableLines)
        break;
    end

    headerTokens = local_split_table_tokens(tableLines{iLine});
    if isempty(headerTokens) || local_is_separator_tokens(headerTokens)
        iLine = iLine + 1;
        continue;
    end
    iLine = iLine + 1;

    rows = {};
    while iLine <= numel(tableLines)
        thisLine = strtrim(tableLines{iLine});
        if strlength(string(thisLine)) == 0
            break;
        end
        rowTokens = local_split_table_tokens(thisLine);
        if ~isempty(rowTokens) && ~local_is_separator_tokens(rowTokens)
            rows{end + 1} = rowTokens; %#ok<AGROW>
        end
        iLine = iLine + 1;
    end

    if ~isempty(rows)
        segments(end + 1).Headers = headerTokens; %#ok<AGROW>
        segments(end).Rows = rows;
    end
end
end

function tokens = local_split_table_tokens(lineText)
lineText = char(string(strtrim(lineText)));
if isempty(lineText)
    tokens = {};
else
    tokens = regexp(lineText, '\s+', 'split');
end
end

function tf = local_is_separator_tokens(tokens)
tf = all(cellfun(@(token) ~isempty(regexp(token, '^[_-]+$', 'once')), tokens));
end

function lines = local_label_estimated_coefficients_tables(lines)
iLine = 1;
while iLine <= numel(lines)
    if ~strcmp(strtrim(lines{iLine}), 'Estimated Coefficients:')
        iLine = iLine + 1;
        continue;
    end

    headerIdx = local_next_nonblank_line(lines, iLine + 1);
    if isempty(headerIdx)
        break;
    end

    headerTokens = local_split_table_tokens(lines{headerIdx});
    if isempty(headerTokens) || any(strcmp(headerTokens, 'Name'))
        iLine = headerIdx + 1;
        continue;
    end

    [hasRowNames, tableEnd] = local_estimated_coefficients_has_row_names( ...
        lines, headerIdx, numel(headerTokens));
    if hasRowNames
        lines{headerIdx} = ['    Name' sprintf('\t') strjoin(headerTokens, sprintf('\t'))];
        for jLine = headerIdx + 1:tableEnd
            tokens = local_split_table_tokens(lines{jLine});
            if local_is_separator_tokens(tokens) && numel(tokens) == numel(headerTokens)
                lines{jLine} = ['    ________' sprintf('\t') strjoin(tokens, sprintf('\t'))];
            end
        end
    end
    iLine = tableEnd + 1;
end
end

function idx = local_next_nonblank_line(lines, startIdx)
idx = [];
for iLine = startIdx:numel(lines)
    if strlength(string(strtrim(lines{iLine}))) > 0
        idx = iLine;
        return;
    end
end
end

function [hasRowNames, tableEnd] = local_estimated_coefficients_has_row_names(lines, headerIdx, nHeaders)
hasRowNames = false;
tableEnd = headerIdx;
seenData = false;

for iLine = headerIdx + 1:numel(lines)
    thisLine = strtrim(lines{iLine});
    if strlength(string(thisLine)) == 0
        if seenData
            tableEnd = iLine - 1;
            return;
        end
        continue;
    end
    if startsWith(thisLine, 'Number of observations') || ...
            startsWith(thisLine, 'Root Mean Squared Error') || ...
            startsWith(thisLine, 'R-squared')
        tableEnd = iLine - 1;
        return;
    end

    tokens = local_split_table_tokens(thisLine);
    if isempty(tokens) || local_is_separator_tokens(tokens)
        tableEnd = iLine;
        continue;
    end

    seenData = true;
    tableEnd = iLine;
    if numel(tokens) == nHeaders + 1 && isnan(str2double(tokens{1}))
        hasRowNames = true;
    end
end
end

function lines = local_align_tabular_blocks(lines)
for iLine = 1:numel(lines)
    lines{iLine} = regexprep(lines{iLine}, '\s+$', '');
    lines{iLine} = local_tabify_table_line(lines{iLine});
end

iLine = 1;
while iLine <= numel(lines)
    if contains(lines{iLine}, sprintf('\t'))
        startIdx = iLine;
        endIdx = iLine;
        while endIdx <= numel(lines) && contains(lines{endIdx}, sprintf('\t'))
            endIdx = endIdx + 1;
        end
        endIdx = endIdx - 1;
        lines(startIdx:endIdx) = local_align_one_tabular_block(lines(startIdx:endIdx));
        iLine = endIdx + 1;
    else
        iLine = iLine + 1;
    end
end
end

function line = local_tabify_table_line(line)
if isempty(line) || all(isspace(line))
    return;
end

if ~isempty(regexp(line, '  +', 'once'))
    line = regexprep(line, ' {2,}', sprintf('\t'));
end
end

function blockLines = local_align_one_tabular_block(blockLines)
splitLines = cell(size(blockLines));
maxCols = 0;
for iLine = 1:numel(blockLines)
    splitLines{iLine} = regexp(blockLines{iLine}, '\t', 'split');
    maxCols = max(maxCols, numel(splitLines{iLine}));
end

widths = zeros(1, maxCols);
for iLine = 1:numel(splitLines)
    parts = splitLines{iLine};
    for iCol = 1:numel(parts)
        widths(iCol) = max(widths(iCol), strlength(string(strtrim(parts{iCol}))));
    end
end

for iLine = 1:numel(splitLines)
    parts = splitLines{iLine};
    formatted = strings(1, numel(parts));
    for iCol = 1:numel(parts)
        token = string(strtrim(parts{iCol}));
        if iCol < numel(parts)
            formatted(iCol) = pad(token, widths(iCol) + 4, 'right');
        else
            formatted(iCol) = token;
        end
    end
    blockLines{iLine} = char(strjoin(formatted, ''));
end
end
