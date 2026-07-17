function [tblFiltered, singletonTbl] = Quad_remove_singleton_conditions(tblIn, paramsToCheck)
% Quad_remove_singleton_conditions Remove rows from singleton condition bins.
%
% [tblFiltered, singletonTbl] = Quad_remove_singleton_conditions(tblIn, paramsToCheck)
%
% Finds values of each parameter in paramsToCheck that are represented by
% only one unique ID. Rows in those singleton bins are removed, then the
% check is repeated until all remaining parameter values have more than one
% unique ID.
%
% Inputs
%   tblIn         : Quad data table with an ID variable.
%   paramsToCheck : cell array or string array of variable names, usually
%                   {'Real_Visual_Angle','Distance','Elevation'}.
%
% Outputs
%   tblFiltered  : tblIn with singleton-condition rows removed.
%   singletonTbl : table listing the removed rows and the singleton
%                  parameter(s) that caused removal.

if ~isa(tblIn, 'table')
    error('tblIn must be a table.');
end
if ~ismember('ID', tblIn.Properties.VariableNames)
    error('tblIn must contain an ID variable.');
end

paramsToCheck = cellstr(string(paramsToCheck));
missingParams = setdiff(paramsToCheck, tblIn.Properties.VariableNames);
if ~isempty(missingParams)
    error('tblIn is missing singleton-check parameter(s): %s', strjoin(missingParams, ', '));
end

tblFiltered = tblIn;
singletonTbl = table();
pass = 0;

while ~isempty(tblFiltered)
    pass = pass + 1;
    [removeMask, singletonParamText, singletonNIDText] = local_find_singleton_rows(tblFiltered, paramsToCheck);
    if ~any(removeMask)
        break;
    end

    removedThisPass = local_removed_rows_table( ...
        tblFiltered(removeMask, :), singletonParamText(removeMask), singletonNIDText(removeMask), pass);
    singletonTbl = [singletonTbl; removedThisPass]; %#ok<AGROW>
    tblFiltered = tblFiltered(~removeMask, :);
end

if isempty(singletonTbl)
    fprintf('Quad singleton-condition check: no rows removed.\n');
else
    fprintf('Quad singleton-condition check: removed %d row(s) across %d pass(es).\n', ...
        height(singletonTbl), max(singletonTbl.Pass));
    local_print_removed_rows(singletonTbl);
end

end

function [removeMask, singletonParamText, singletonNIDText] = local_find_singleton_rows(tbl, paramsToCheck)
nRows = height(tbl);
removeMask = false(nRows, 1);
singletonParamText = strings(nRows, 1);
singletonNIDText = strings(nRows, 1);

for iParam = 1:numel(paramsToCheck)
    paramName = paramsToCheck{iParam};
    [thisMask, nIDByRow] = local_singleton_mask(tbl, paramName);
    removeMask = removeMask | thisMask;

    affectedRows = find(thisMask);
    for iRow = affectedRows(:)'
        singletonParamText(iRow) = local_append_token(singletonParamText(iRow), string(paramName));
        singletonNIDText(iRow) = local_append_token( ...
            singletonNIDText(iRow), sprintf('%s=%d', paramName, nIDByRow(iRow)));
    end
end
end

function [singletonMask, nIDByRow] = local_singleton_mask(tbl, paramName)
values = tbl.(paramName);
if isnumeric(values) || islogical(values)
    valid = ~isnan(double(values));
    keyValues = values(valid);
else
    keyValues = string(values);
    valid = ~ismissing(keyValues) & strlength(strtrim(keyValues)) > 0;
    keyValues = strtrim(keyValues(valid));
end

singletonMask = false(height(tbl), 1);
nIDByRow = nan(height(tbl), 1);
validRows = find(valid);
if isempty(validRows)
    return;
end

[~, ~, groupIdx] = unique(keyValues);
for iGroup = 1:max(groupIdx)
    rowsThisGroup = validRows(groupIdx == iGroup);
    nID = local_count_unique_ids(tbl.ID(rowsThisGroup));
    nIDByRow(rowsThisGroup) = nID;
    if nID <= 1
        singletonMask(rowsThisGroup) = true;
    end
end
end

function n = local_count_unique_ids(ids)
ids = strtrim(string(ids(:)));
ids = ids(~ismissing(ids) & strlength(ids) > 0 & lower(ids) ~= "nan");
n = numel(unique(ids));
end

function txt = local_append_token(txt, token)
if strlength(txt) == 0
    txt = token;
else
    txt = txt + "; " + token;
end
end

function removedTbl = local_removed_rows_table(rowsTbl, singletonParamText, singletonNIDText, pass)
nRows = height(rowsTbl);
removedTbl = table( ...
    repmat(pass, nRows, 1), ...
    local_string_column(rowsTbl, 'ID'), ...
    local_string_column(rowsTbl, 'Version'), ...
    local_string_column(rowsTbl, 'Measurement'), ...
    local_string_column(rowsTbl, 'Object'), ...
    local_numeric_column(rowsTbl, 'Real_Visual_Angle'), ...
    local_numeric_column(rowsTbl, 'Elevation'), ...
    local_numeric_column(rowsTbl, 'Distance'), ...
    singletonParamText(:), ...
    singletonNIDText(:), ...
    'VariableNames', {'Pass','ID','Version','Measurement','Object', ...
                      'Real_Visual_Angle','Elevation','Distance', ...
                      'SingletonParameters','SingletonN_ID'});
end

function values = local_string_column(tbl, varName)
if ismember(varName, tbl.Properties.VariableNames)
    values = string(tbl.(varName));
else
    values = strings(height(tbl), 1);
end
values = strtrim(values(:));
end

function values = local_numeric_column(tbl, varName)
if ismember(varName, tbl.Properties.VariableNames)
    values = double(tbl.(varName));
else
    values = nan(height(tbl), 1);
end
values = values(:);
end

function local_print_removed_rows(singletonTbl)
fprintf('Removed singleton-condition rows:\n');
fprintf('ID\tObject\tMeasurement\tVA\tE\tDistance\n');
for iRow = 1:height(singletonTbl)
    fprintf('%s\t%s\t%s\t%.10g\t%.10g\t%.10g\n', ...
        char(singletonTbl.ID(iRow)), ...
        char(singletonTbl.Object(iRow)), ...
        char(singletonTbl.Measurement(iRow)), ...
        singletonTbl.Real_Visual_Angle(iRow), ...
        singletonTbl.Elevation(iRow), ...
        singletonTbl.Distance(iRow));
end
end
