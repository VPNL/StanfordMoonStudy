function [fitStatsTbl, ok] = Quad_lme_fit_stat_table(models, formulas, labels, responseScales)
%QUAD_LME_FIT_STAT_TABLE Build a common LME likelihood-criterion table.

valid = ~cellfun(@isempty, models);
models = models(valid);
formulas = formulas(valid);
labels = labels(valid);
responseScales = responseScales(valid);
ok = ~isempty(models);

if ~ok
    fitStatsTbl = table();
    return;
end

nModels = numel(models);
nObs = nan(nModels, 1);
logLikelihood = nan(nModels, 1);
aic = nan(nModels, 1);
bic = nan(nModels, 1);
deviance = nan(nModels, 1);

for iModel = 1:nModels
    model = models{iModel};
    nObs(iModel) = model.NumObservations;
    logLikelihood(iModel) = model.LogLikelihood;
    aic(iModel) = model.ModelCriterion.AIC;
    bic(iModel) = model.ModelCriterion.BIC;
    deviance(iModel) = -2 * model.LogLikelihood;
end

fitStatsTbl = table(labels(:), string(formulas(:)), responseScales(:), ...
    nObs, logLikelihood, aic, bic, deviance, ...
    'VariableNames', {'Model','Formula','Response','N','LogLikelihood','AIC','BIC','Deviance'});
end
