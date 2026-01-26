function summaryTbl = Quad_export_LME_summary_csv(outCsvFile, ...
    lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
    lme_logPM_by_logAngleNDistanceNElevation)
% Quad_export_LME_summary_csv
% Create a tidy CSV summarizing fixed-effect coefficients and fit metrics
% for the LMEs returned by Quad_PM_by_task.
%
% Output columns:
%   Intercept, LogVA, LogDistance, LogElevation, AIC, BIC, R2Adj
%
% Notes:
% - Coefficients are in the model's scale (here: log2 space).
% - Missing predictors in a given model are NaN.
%
% Example:
%   [l1,l2,l3,l4,l5,l6,l7] = Quad_PM_by_task(tbl,tblName,ResultsDir,0,cmap,idx);
%   outCsv = fullfile(ResultsDir, [tblName '_LME_summary.csv']);
%   Quad_export_LME_summary_csv(outCsv, l1,l2,l3,l4,l5,l6,l7);

    if nargin < 1 || isempty(outCsvFile)
        outCsvFile = fullfile(pwd, 'LME_summary.csv');
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
        'logPM_by_logAngle', ...
        'logPM_by_logDistance', ...
        'logPM_by_logElevation', ...
        'logPM_by_logAngleNDistance', ...
        'logPM_by_logAngleNElevation', ...
        'logPM_by_logDistanceNElevation', ...
        'logPM_by_logAngleNDistanceNElevation'};

    n = numel(lmes);

    Intercept   = nan(n,1);
    LogVA       = nan(n,1);
    LogDistance = nan(n,1);
    LogElevation= nan(n,1);
    pVA       = nan(n,1);
    pDistance = nan(n,1);
    pElevation= nan(n,1);
   
    AIC         = nan(n,1);
    BIC         = nan(n,1);
    R2Adj       = nan(n,1);

    % Optional but often useful for provenance
    FormulaStr  = strings(n,1);

    for i = 1:n
        lme = lmes{i};

        if isempty(lme)
            continue;
        end

        % ---- Fixed effects (robust name-based lookup) ----
       
       coefNames = lme.CoefficientNames;     % cellstr
       [fe, fename, festats] = fixedEffects(lme);        % numeric vector
       

        Intercept(i)    = localGetByName(coefNames, fe, '(Intercept)');
        LogVA(i)        = localGetByName(coefNames, fe, 'log2real_visual_angle');
        LogDistance(i)  = localGetByName(coefNames, fe, 'log2distance');
        LogElevation(i) = localGetByName(coefNames, fe, 'log2elevation');
        
        
        % ---- AIC/BIC ----
        [AIC(i), BIC(i)] = localGetAICBIC(lme);

        % ---- Adjusted R^2 ----
        R2Adj(i) = localGetAdjustedR2(lme);

        % ---- Formula string (optional) ----
        try
            FormulaStr(i) = string(char(lme.Formula));
        catch
            FormulaStr(i) = "";
        end
    end

    summaryTbl = table( ...
        string(modelNames(:)), ...
        Intercept, LogVA, LogDistance, LogElevation, ...
        AIC, BIC, R2Adj, ...
        FormulaStr, ...
        'VariableNames', {'Model','Intercept','LogVA','LogDistance','LogElevation','AIC','BIC','R2Adj','Formula'});

    writetable(summaryTbl, outCsvFile);

end

% ---------------- Local helper functions ----------------

function val = localGetByName(coefNames, fe, targetName)
    % Returns fixed-effect estimate for targetName, or NaN if absent.
    val = NaN;
    if isempty(coefNames) || isempty(fe)
        return;
    end

    % Normalize coefNames to cellstr
    if isstring(coefNames)
        coefNames = cellstr(coefNames);
    end

    idx = find(strcmp(coefNames, targetName), 1, 'first');
    if ~isempty(idx) && idx <= numel(fe)
        val = fe(idx);
    end
end

function [aic, bic] = localGetAICBIC(lme)
    aic = NaN; bic = NaN;

    % Common case in fitlme
    try
        aic = lme.ModelCriterion.AIC;
        bic = lme.ModelCriterion.BIC;
        return;
    catch
    end

    % Fallbacks (version differences)
    try
        mc = lme.ModelCriterion;
        if istable(mc)
            if any(strcmpi(mc.Properties.VariableNames,'AIC')); aic = mc.AIC(1); end
            if any(strcmpi(mc.Properties.VariableNames,'BIC')); bic = mc.BIC(1); end
        elseif isstruct(mc)
            if isfield(mc,'AIC'); aic = mc.AIC; end
            if isfield(mc,'BIC'); bic = mc.BIC; end
        end
    catch
    end
end

function r2adj = localGetAdjustedR2(lme)
    r2adj = NaN;

    % Your existing code suggests this exists in your MATLAB version
    try
        r2adj = lme.Rsquared.Adjusted;
        return;
    catch
    end

    % Fallback if rsquared() exists
    try
        r2 = rsquared(lme);
        if isstruct(r2) && isfield(r2,'Adjusted')
            r2adj = r2.Adjusted;
        elseif istable(r2) && any(strcmpi(r2.Properties.VariableNames,'Adjusted'))
            r2adj = r2.Adjusted(1);
        end
    catch
    end
end
