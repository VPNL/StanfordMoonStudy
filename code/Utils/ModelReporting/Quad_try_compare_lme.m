function [comparisonTbl, ok] = Quad_try_compare_lme(lme1, lme2)
%QUAD_TRY_COMPARE_LME Compare two LME models without aborting a report.

comparisonTbl = [];
ok = false;
if isempty(lme1) || isempty(lme2)
    return;
end

try
    comparisonTbl = compare(lme1, lme2);
    ok = true;
catch ME
    fprintf('Skipping model comparison: %s\n', ME.message);
end
end
