function summaryTbl = Quad_export_PercievedDisparity_LME_summary_csv(study, ...
    lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
    lme_logPM_by_logAngleNDistanceNElevation, outCsvFile)
% QUAD_EXPORT_PERCIEVEDDISPARITY_LME_SUMMARY_CSV
% Export a tidy summary table for perceived-disparity LMEs.

if nargin < 9 || isempty(outCsvFile)
    saveTable = false;
else
    saveTable = true;
end
if nargin < 1 || isempty(study)
    study = "";
end

lmes = { ...
    lme_logPM_by_logAngle, ...
    lme_logPM_by_logDistance, ...
    lme_logPM_by_logElevation, ...
    lme_logPM_by_logAngleNDistance, ...
    lme_logPM_by_logAngleNElevation, ...
    lme_logPM_by_logDistanceNElevation, ...
    lme_logPM_by_logAngleNDistanceNElevation};

modelNames = { ...
    'logDisparity_by_logAngle', ...
    'logDisparity_by_logDistance', ...
    'logDisparity_by_logElevation', ...
    'logDisparity_by_logAngleNDistance', ...
    'logDisparity_by_logAngleNElevation', ...
    'logDisparity_by_logDistanceNElevation', ...
    'logDisparity_by_logAngleNDistanceNElevation'};

varNames = { ...
    'Study','modelName','FormulaStr', ...
    'Intercept','IciL','IciU','Ip', ...
    'VAe','VAciL','VAciU','VAp', ...
    'De','DciL','DciU','Dp', ...
    'Ee','EciL','EciU','Ep', ...
    'AIC','BIC','RsqAdj'};
varTypes = [repmat("string",1,3), repmat("double",1,19)];

summaryTbl = table('Size', [numel(lmes), numel(varNames)], ...
    'VariableNames', varNames, ...
    'VariableTypes', varTypes);
summaryTbl.Study(:) = string(study);
summaryTbl.modelName(:) = string(modelNames(:));
summaryTbl.FormulaStr(:) = "";

numVars = setdiff(varNames, {'Study','modelName','FormulaStr'});
for k = 1:numel(numVars)
    summaryTbl.(numVars{k})(:) = NaN;
end

for i = 1:numel(lmes)
    lme = lmes{i};
    if isempty(lme)
        continue;
    end

    try
        summaryTbl.FormulaStr(i) = string(char(lme.Formula));
    catch
        summaryTbl.FormulaStr(i) = "";
    end

    [e, cL, cU, p] = local_get_coef(lme, {"(Intercept)"}, true);
    summaryTbl.Intercept(i) = e; summaryTbl.IciL(i) = cL; summaryTbl.IciU(i) = cU; summaryTbl.Ip(i) = p;

    [e, cL, cU, p] = local_get_coef(lme, {"log2real_visual_angle"}, false);
    summaryTbl.VAe(i) = e; summaryTbl.VAciL(i) = cL; summaryTbl.VAciU(i) = cU; summaryTbl.VAp(i) = p;

    [e, cL, cU, p] = local_get_coef(lme, {"log2distance"}, false);
    summaryTbl.De(i) = e; summaryTbl.DciL(i) = cL; summaryTbl.DciU(i) = cU; summaryTbl.Dp(i) = p;

    [e, cL, cU, p] = local_get_coef(lme, {"log2elevation"}, false);
    summaryTbl.Ee(i) = e; summaryTbl.EciL(i) = cL; summaryTbl.EciU(i) = cU; summaryTbl.Ep(i) = p;

    summaryTbl.AIC(i) = local_get_field_or_nan(lme, 'ModelCriterion', 'AIC');
    summaryTbl.BIC(i) = local_get_field_or_nan(lme, 'ModelCriterion', 'BIC');
    try
        summaryTbl.RsqAdj(i) = double(lme.Rsquared.Adjusted);
    catch
        summaryTbl.RsqAdj(i) = NaN;
    end
end

if saveTable
    writetable(summaryTbl, outCsvFile);
end
end

function [est, ciL, ciU, p] = local_get_coef(lme, targetNames, isIntercept)
est = NaN; ciL = NaN; ciU = NaN; p = NaN;
try
    coefNames = string(lme.CoefficientNames);
    ct = lme.Coefficients;
catch
    return;
end

targets = lower(string(targetNames));
coefLower = lower(coefNames);
idx = [];
for t = 1:numel(targets)
    j = find(coefLower == targets(t), 1, 'first');
    if ~isempty(j)
        idx = j;
        break;
    end
end
if isempty(idx) && isIntercept
    idx = find(contains(coefLower, "intercept"), 1, 'first');
end
if isempty(idx)
    return;
end

est = double(ct.Estimate(idx));
ciL = double(ct.Lower(idx));
ciU = double(ct.Upper(idx));
p = double(ct.pValue(idx));
end

function val = local_get_field_or_nan(obj, field1, field2)
val = NaN;
try
    val = double(obj.(field1).(field2));
catch
end
end
