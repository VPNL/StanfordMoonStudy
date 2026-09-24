function summaryTbl = write_lme_fixed_effects_summary_csv(study, modelNames, models, outCsvFile)
% WRITE_LME_FIXED_EFFECTS_SUMMARY_CSV Export fitted LME fixed effects to CSV.
%
% summaryTbl = write_lme_fixed_effects_summary_csv(study, modelNames, models, outCsvFile)
%
% Creates a tidy summary table with one row per fixed-effect coefficient in
% each non-empty fitted LinearMixedModel. Empty model slots are skipped, so
% the output does not include placeholder rows full of NaNs.

if nargin < 1 || isempty(study)
    study = "";
end
if nargin < 2 || isempty(modelNames)
    modelNames = {};
end
if nargin < 3 || isempty(models)
    models = {};
end
if nargin < 4
    outCsvFile = "";
end

models = models(:);
modelNames = string(modelNames(:));
if numel(modelNames) ~= numel(models)
    error('write_lme_fixed_effects_summary_csv:ModelNameMismatch', ...
        'modelNames and models must have the same number of elements.');
end

rowTables = cell(numel(models), 1);
for iModel = 1:numel(models)
    lme = models{iModel};
    if isempty(lme)
        continue;
    end

    fixedEffectsTbl = local_fixed_effects_table(lme);
    if isempty(fixedEffectsTbl)
        continue;
    end

    nRows = height(fixedEffectsTbl);
    modelTbl = table();
    modelTbl.Study = repmat(string(study), nRows, 1);
    modelTbl.modelName = repmat(modelNames(iModel), nRows, 1);
    modelTbl.FormulaStr = repmat(local_formula_string(lme), nRows, 1);
    modelTbl.Name = fixedEffectsTbl.Name;
    modelTbl.Estimate = fixedEffectsTbl.Estimate;
    modelTbl.SE = fixedEffectsTbl.SE;
    modelTbl.tStat = fixedEffectsTbl.tStat;
    modelTbl.DF = fixedEffectsTbl.DF;
    modelTbl.pValue = fixedEffectsTbl.pValue;
    modelTbl.Lower = fixedEffectsTbl.Lower;
    modelTbl.Upper = fixedEffectsTbl.Upper;
    modelTbl.LogLikelihood = repmat(local_log_likelihood(lme), nRows, 1);
    modelTbl.AIC = repmat(local_model_criterion(lme, 'AIC'), nRows, 1);
    modelTbl.BIC = repmat(local_model_criterion(lme, 'BIC'), nRows, 1);
    modelTbl.RsqAdj = repmat(local_adjusted_r_squared(lme), nRows, 1);
    rowTables{iModel} = modelTbl;
end

rowTables = rowTables(~cellfun(@isempty, rowTables));
if isempty(rowTables)
    summaryTbl = local_empty_summary_table();
else
    summaryTbl = vertcat(rowTables{:});
end

if strlength(string(outCsvFile)) > 0
    outCsvFile = char(string(outCsvFile));
    [outDir, ~, ~] = fileparts(outCsvFile);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    writetable(summaryTbl, outCsvFile);
end
end

function fixedEffectsTbl = local_fixed_effects_table(lme)
ct = lme.Coefficients;
nRows = size(ct, 1);
varNames = local_var_names(ct);

if ismember('Name', varNames)
    termNames = string(ct.Name);
else
    termNames = string(lme.CoefficientNames(:));
end

fixedEffectsTbl = table();
fixedEffectsTbl.Name = termNames(:);
fixedEffectsTbl.Estimate = local_coef_column(ct, 'Estimate', nRows);
fixedEffectsTbl.SE = local_coef_column(ct, 'SE', nRows);
fixedEffectsTbl.tStat = local_coef_column(ct, 'tStat', nRows);
fixedEffectsTbl.DF = local_coef_column(ct, 'DF', nRows);
fixedEffectsTbl.pValue = local_coef_column(ct, 'pValue', nRows);
fixedEffectsTbl.Lower = local_coef_column(ct, 'Lower', nRows);
fixedEffectsTbl.Upper = local_coef_column(ct, 'Upper', nRows);
end

function values = local_coef_column(coefTbl, varName, nRows)
if ismember(varName, local_var_names(coefTbl))
    values = double(coefTbl.(varName));
else
    values = nan(nRows, 1);
end
values = values(:);
end

function varNames = local_var_names(dataArray)
try
    varNames = cellstr(dataArray.Properties.VariableNames);
    return;
catch
end

try
    varNames = cellstr(dataArray.Properties.VarNames);
    return;
catch
end

try
    varNames = fieldnames(dataArray);
    return;
catch
end

varNames = {};
end

function formulaStr = local_formula_string(lme)
try
    formulaStr = string(char(lme.Formula));
catch
    formulaStr = "";
end
end

function val = local_log_likelihood(lme)
try
    val = double(lme.LogLikelihood);
catch
    val = NaN;
end
end

function val = local_model_criterion(lme, criterionName)
try
    val = double(lme.ModelCriterion.(criterionName));
catch
    val = NaN;
end
end

function val = local_adjusted_r_squared(lme)
try
    val = double(lme.Rsquared.Adjusted);
catch
    val = NaN;
end
end

function summaryTbl = local_empty_summary_table()
summaryTbl = table('Size', [0 15], ...
    'VariableTypes', {'string','string','string','string', ...
    'double','double','double','double','double','double','double', ...
    'double','double','double','double'}, ...
    'VariableNames', {'Study','modelName','FormulaStr','Name', ...
    'Estimate','SE','tStat','DF','pValue','Lower','Upper', ...
    'LogLikelihood','AIC','BIC','RsqAdj'});
end
