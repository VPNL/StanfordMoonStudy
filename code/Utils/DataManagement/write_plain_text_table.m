function write_plain_text_table(fid, tbl)
% write_plain_text_table Write a MATLAB table as aligned plain text.
%
% Inputs
%   fid : open file identifier
%   tbl : MATLAB table

if nargin < 2
    error('write_plain_text_table requires fid and tbl.');
end
if ~(isnumeric(fid) && isscalar(fid) && fid >= 0)
    error('fid must be an open file identifier.');
end
if ~istable(tbl)
    error('tbl must be a MATLAB table.');
end

nRows = height(tbl);
nCols = width(tbl);
varNames = string(tbl.Properties.VariableNames);

textValues = strings(nRows + 1, nCols);
textValues(1,:) = varNames;
rightAlign = false(1, nCols);

for iCol = 1:nCols
    varName = tbl.Properties.VariableNames{iCol};
    columnValues = tbl.(varName);
    rightAlign(iCol) = isnumeric(columnValues) || islogical(columnValues);

    for iRow = 1:nRows
        textValues(iRow + 1, iCol) = local_value_to_text(tbl{iRow, iCol});
    end
end

widths = zeros(1, nCols);
for iCol = 1:nCols
    widths(iCol) = max(strlength(textValues(:, iCol)));
end

local_write_row(fid, textValues(1,:), widths, rightAlign);
for iCol = 1:nCols
    fprintf(fid, '%s', repmat('-', 1, widths(iCol)));
    if iCol < nCols
        fprintf(fid, '    ');
    end
end
fprintf(fid, '\n');

for iRow = 2:size(textValues, 1)
    local_write_row(fid, textValues(iRow,:), widths, rightAlign);
end
fprintf(fid, '\n');
end

function local_write_row(fid, rowValues, widths, rightAlign)
for iCol = 1:numel(rowValues)
    token = rowValues(iCol);
    if rightAlign(iCol)
        token = pad(token, widths(iCol), 'left');
    else
        token = pad(token, widths(iCol), 'right');
    end
    fprintf(fid, '%s', char(token));
    if iCol < numel(rowValues)
        fprintf(fid, '    ');
    end
end
fprintf(fid, '\n');
end

function textValue = local_value_to_text(value)
if iscell(value)
    if isempty(value)
        textValue = "";
    else
        textValue = local_value_to_text(value{1});
    end
elseif isstring(value)
    if ismissing(value)
        textValue = "";
    else
        textValue = value;
    end
elseif ischar(value)
    textValue = string(value);
elseif iscategorical(value)
    textValue = string(value);
elseif isnumeric(value) || islogical(value)
    textValue = local_numeric_to_text(value);
else
    textValue = string(value);
end

textValue = regexprep(char(textValue), '<[^>]+>', '');
textValue = strrep(textValue, '{', '');
textValue = strrep(textValue, '}', '');
textValue = strrep(textValue, '''', '');
textValue = strrep(textValue, '"', '');
textValue = string(textValue);
end

function textValue = local_numeric_to_text(value)
if isempty(value)
    textValue = "";
elseif isscalar(value)
    numericValue = double(value);
    if isnan(numericValue)
        textValue = "NaN";
    elseif isinf(numericValue)
        if numericValue > 0
            textValue = "Inf";
        else
            textValue = "-Inf";
        end
    else
        textValue = string(sprintf('%.6g', numericValue));
    end
else
    parts = strings(1, numel(value));
    for iValue = 1:numel(value)
        parts(iValue) = local_numeric_to_text(value(iValue));
    end
    textValue = strjoin(parts, ',');
end
end
