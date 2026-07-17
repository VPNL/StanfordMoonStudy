function write_moon_lme_report(reportFile, reportTitle, summaryLines, models, modelLabels, comparisons, comparisonLabels)
% write_moon_lme_report
%
% Write moon LME results into a readable text report with explicit sections.

if nargin < 3 || isempty(summaryLines)
    summaryLines = {};
end
if nargin < 4 || isempty(models)
    models = {};
end
if nargin < 5 || isempty(modelLabels)
    modelLabels = {};
end
if nargin < 6 || isempty(comparisons)
    comparisons = {};
end
if nargin < 7 || isempty(comparisonLabels)
    comparisonLabels = {};
end

[reportDir,~,~] = fileparts(reportFile);
if ~isempty(reportDir) && ~exist(reportDir,'dir')
    mkdir(reportDir);
end

[fid, msg] = fopen(reportFile, 'w');
if fid == -1
    error('Could not open report file %s: %s', reportFile, msg);
end

cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

%fprintf(fid, '%s\n', reportTitle);
fprintf(fid, 'write_moon_lme_report.m: %s\n', reportTitle);
fprintf(fid, '%s\n\n', repmat('=', 1, numel(reportTitle)));
fprintf(fid, 'Generated: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

if ~isempty(summaryLines)
    local_write_lines(fid, summaryLines);
end

for i = 1:numel(models)
    local_write_block(fid, local_get_label(modelLabels, i, sprintf('model_%d', i)), ...
        local_capture_disp(models{i}));
end

for i = 1:numel(comparisons)
    local_write_block(fid, local_get_label(comparisonLabels, i, sprintf('comparison_%d', i)), ...
        local_capture_disp(comparisons{i}));
end
end

function local_write_lines(fid, lines)
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
fprintf(fid, '\n');
end

function local_write_block(fid, labelText, blockText)
fprintf(fid, '%s = \n\n', labelText);
fprintf(fid, '%s\n\n', local_clean_block(blockText));
end

function labelText = local_get_label(labels, idx, fallback)
if idx <= numel(labels) && ~isempty(labels{idx})
    labelText = labels{idx};
else
    labelText = fallback;
end
end

function blockText = local_capture_disp(value)
if istable(value)
    value = local_prepare_table_for_display(value);
end
blockText = evalc('disp(value)');
end

function cleanText = local_clean_block(rawText)
rawText = regexprep(rawText, '<strong>\s*(.*?)\s*</strong>', '**$1**', 'ignorecase');
rawText = regexprep(rawText, '</?[^>]+>', '');
rawText = regexprep(rawText, '\*\*(.*?)\*\*', '$1');
rawText = regexprep(rawText, '\(Intercept\)''?', 'Intercept');
rawText = regexprep(rawText, '\{\s*''', '');
rawText = regexprep(rawText, '''\s*\}', '');
rawText = regexprep(rawText, '\}\s*\{', ' ');
rawText = strrep(rawText, '{', '');
rawText = strrep(rawText, '}', '');
rawText = strrep(rawText, '''', '');
rawText = regexprep(rawText, '\n+$', '');
lines = regexp(rawText, '\n', 'split');
while ~isempty(lines) && all(isspace(lines{1}))
    lines(1) = [];
end
while ~isempty(lines) && all(isspace(lines{end}))
    lines(end) = [];
end
for i = 1:numel(lines)
    lines{i} = regexprep(lines{i}, '\s+$', '');
    lines{i} = local_tabify_line(lines{i});
end
lines = local_align_tabular_blocks(lines);
cleanText = strjoin(lines, newline);
end

function line = local_tabify_line(line)
if isempty(line) || all(isspace(line))
    return;
end

% Convert MATLAB's wide space-padded display into tab-delimited columns.
% This keeps the diary-like structure but makes headings and numbers line up
% more reliably in text editors and viewers.
if ~isempty(regexp(line, '  +', 'once'))
    line = regexprep(line, ' {2,}', sprintf('\t'));
end
end

function lines = local_align_tabular_blocks(lines)
i = 1;
while i <= numel(lines)
    if contains(lines{i}, sprintf('\t'))
        startIdx = i;
        endIdx = i;
        while endIdx <= numel(lines) && contains(lines{endIdx}, sprintf('\t'))
            endIdx = endIdx + 1;
        end
        endIdx = endIdx - 1;
        lines(startIdx:endIdx) = local_align_one_block(lines(startIdx:endIdx));
        i = endIdx + 1;
    else
        i = i + 1;
    end
end
end

function blockLines = local_align_one_block(blockLines)
splitLines = cell(size(blockLines));
maxCols = 0;
for i = 1:numel(blockLines)
    splitLines{i} = regexp(blockLines{i}, '\t', 'split');
    maxCols = max(maxCols, numel(splitLines{i}));
end

widths = zeros(1, maxCols);
for i = 1:numel(splitLines)
    parts = splitLines{i};
    for j = 1:numel(parts)
        widths(j) = max(widths(j), strlength(string(strtrim(parts{j}))));
    end
end

for i = 1:numel(splitLines)
    parts = splitLines{i};
    formatted = "";
    for j = 1:numel(parts)
        token = string(strtrim(parts{j}));
        if j < numel(parts)
            formatted = formatted + pad(token, widths(j) + 4, 'right');
        else
            formatted = formatted + token;
        end
    end
    blockLines{i} = char(formatted);
end
end

function tbl = local_prepare_table_for_display(tbl)
for i = 1:width(tbl)
    v = tbl.(i);
    if iscellstr(v)
        tbl.(i) = string(v);
    elseif isstring(v)
        tbl.(i) = v;
    elseif iscategorical(v)
        tbl.(i) = string(v);
    end
end

if ismember('Name', tbl.Properties.VariableNames)
    tbl.Name = replace(string(tbl.Name), "(Intercept)", "Intercept");
end
end
