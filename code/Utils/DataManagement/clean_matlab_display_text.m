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
