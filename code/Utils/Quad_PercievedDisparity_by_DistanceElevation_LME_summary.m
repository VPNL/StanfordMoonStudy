function summaryTbl = Quad_PercievedDisparity_by_DistanceElevation_LME_summary(study, ...
    lme_logPM_by_logDistance, lme_logPM_by_logElevation, lme_logPM_by_logDistanceNElevation, outCsvFile)
% QUAD_PERCIEVEDDISPARITY_BY_DISTANCEELEVATION_LME_SUMMARY
% Export a tidy summary table for distance/elevation perceived-disparity LMEs.

if nargin < 4 || isempty(outCsvFile)
    saveTable = false;
else
    saveTable = true;
    [baseDir, baseName, ext] = fileparts(outCsvFile);
    outCsvFile = fullfile(baseDir, [baseName ext]);
end
if nargin < 1 || isempty(study)
    study = "";
end

lmes = { ...
    lme_logPM_by_logDistance, ...
    lme_logPM_by_logElevation, ...
    lme_logPM_by_logDistanceNElevation};

modelNames = { ...
    'logDisparity_by_logDistance', ...
    'logDisparity_by_logElevation', ...
    'logDisparity_by_logDistanceNElevation'};

varNames = { ...
    'Study','modelName','FormulaStr', ...
    'Intercept','IciL','IciU','Ip', ...
    'De','DciL','DciU','Dp', ...
    'Ee','EciL','EciU','Ep', ...
    'AIC','BIC','RsqAdj'};
varTypes = [repmat("string",1,3), repmat("double",1,15)];

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
    outDir = fileparts(outCsvFile);
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
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
