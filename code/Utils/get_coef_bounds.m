function [b0L,b0U,b1L,b1U] = get_coef_bounds(lme)
% get_coef_bounds Return 95% bounds for intercept and slope coefficients.

coefTbl = lme.Coefficients;

if istable(coefTbl)
    varNames = coefTbl.Properties.VariableNames;
elseif isa(coefTbl, 'dataset')
    varNames = coefTbl.Properties.VarNames;
else
    varNames = {};
end

if ismember('Lower', varNames) && ismember('Upper', varNames)
    b0L = coefTbl.Lower(1);
    b0U = coefTbl.Upper(1);
    b1L = coefTbl.Lower(2);
    b1U = coefTbl.Upper(2);
else
    b0 = coefTbl.Estimate(1);
    b1 = coefTbl.Estimate(2);
    se0 = coefTbl.SE(1);
    se1 = coefTbl.SE(2);
    z = 1.96;
    b0L = b0 - z*se0;
    b0U = b0 + z*se0;
    b1L = b1 - z*se1;
    b1U = b1 + z*se1;
end
end
