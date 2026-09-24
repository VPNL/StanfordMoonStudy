function summaryTbl = Quad_export_S_D_E_summary_csv(study, task, ...
    lme_logPM_by_logSize, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
    lme_logPM_by_logSizeNDistance, lme_logPM_by_logSizeNElevation, lme_logPM_by_logDistanceNElevation, ...
    lme_logPM_by_logSizeNDistanceNElevation,outCsvFile)
%
%  summaryTbl = Quad_export_S_D_E_summary_csv(study, task, ...
%           lme_logPM_by_logSize, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
%           lme_logPM_by_logSizeNDistance, lme_logPM_by_logSizeNElevation, lme_logPM_by_logDistanceNElevation, ...
%           lme_logPM_by_logSizeNDistanceNElevation,outCsvFile)
%
%   Create a tidy CSV/table summarizing fixed-effect coefficients (estimate,
%   CI, p-value) and fit metrics (AIC, BIC, adjusted R^2) for LMEs testing different models of PM.
%
%   The following columns are numeric in summaryTbl:
%   Intercept, IciL, IciU, Ip, AIC, BIC, RsqAdj,
%   Se, SciL, SciU, Sp,
%   De,  DciL,  DciU,  Dp,
%   Ee,  EciL,  EciU,  Ep
%
%  Missing predictors are set to NaN.
% 
% If outCsvFile is given just retunrs summaryTbl
% If outCsvFile is given writes summaryTbl into outCsvFile 
%
% KGS Sep 2026

    if ~exist('outCsvFile','var')
        saveTable=0;
    else
        saveTable=1;
    end
    if ~exist('study','var') || isempty(study)
        study = "";
    end
    if ~exist('task','var') || isempty(task)
        task = "";
    end

    lmes = { ...
        lme_logPM_by_logSize, ...
        lme_logPM_by_logDistance, ...
        lme_logPM_by_logElevation, ...
        lme_logPM_by_logSizeNDistance, ...
        lme_logPM_by_logSizeNElevation, ...
        lme_logPM_by_logDistanceNElevation, ...
        lme_logPM_by_logSizeNDistanceNElevation};

   
    modelNames = { ...
        'logPM_by_logSize', ...
        'logPM_by_logDistance', ...
        'logPM_by_logElevation', ...
        'logPM_by_logSizeNDistance', ...
        'logPM_by_logSizeNElevation', ...
        'logPM_by_logDistanceNElevation', ...
        'logPM_by_logSizeNDistanceNElevation'};

    n = numel(lmes);

    % ----- Preallocate table with explicit types (avoids cell/string numeric columns) -----
    % varNames = { ...
    %     'Study','Task','modelName','FormulaStr', ...
    %     'Intercept','IciL','IciU','Ip', ...
    %     'AIC','BIC','RsqAdj', ...
    %     'Se','SciL','SciU','Sp', ...
    %     'De','DciL','DciU','Dp', ...
    %     'Ee','EciL','EciU','Ep'};
     varNames = { ...
        'Study','Task','modelName','FormulaStr', ...
        'Intercept','IciL','IciU','Ip', ...
        'Se','Scil','SciU','Sp', ...
        'De','DciL','DciU','Dp', ...
        'Ee','EciL','EciU','Ep',...
         'AIC','BIC','RsqAdj'};


    varTypes = [repmat("string",1,4), repmat("double",1,19)];

    summaryTbl = table('Size', [n, numel(varNames)], ...
        'VariableNames', varNames, ...
        'VariableTypes', varTypes);

    % Defaults
    summaryTbl.Study(:)     = string(study);
    summaryTbl.Task(:)      = string(task);
    summaryTbl.modelName(:) = string(modelNames(:));
    summaryTbl.FormulaStr(:)= "";

    % Initialize numeric columns to NaN explicitly (table constructor already does,
    % but this makes intent obvious and robust across MATLAB versions).
    numVars = setdiff(varNames, {'Study','Task','modelName','FormulaStr'});
    for k = 1:numel(numVars)
        summaryTbl.(numVars{k})(:) = NaN;
    end

    % ----- Populate rows -----
    for i = 1:n
        lme = lmes{i};
        if isempty(lme)
            continue;
        end

        % Formula
        try
            summaryTbl.FormulaStr(i) = string(char(lme.Formula));
        catch
            summaryTbl.FormulaStr(i) = "";
        end

        % Intercept
        [e, cL, cU, p] = localGetCoef(lme, {"(Intercept)","(intercept)","intercept"}, true);
        summaryTbl.Intercept(i) = e;
        summaryTbl.IciL(i)      = cL;
        summaryTbl.IciU(i)      = cU;
        summaryTbl.Ip(i)        = p;

        % log2size
        [e, cL, cU, p] = localGetCoef(lme, {"log2size"}, false);
        summaryTbl.Se(i)   = e;
        summaryTbl.Scil(i) = cL;
        summaryTbl.SciU(i) = cU;
        summaryTbl.Sp(i)   = p;

        % log2distance
        [e, cL, cU, p] = localGetCoef(lme, {"log2distance"}, false);
        summaryTbl.De(i)   = e;
        summaryTbl.DciL(i) = cL;
        summaryTbl.DciU(i) = cU;
        summaryTbl.Dp(i)   = p;

        % log2elevation
        [e, cL, cU, p] = localGetCoef(lme, {"log2elevation"}, false);
        summaryTbl.Ee(i)   = e;
        summaryTbl.EciL(i) = cL;
        summaryTbl.EciU(i) = cU;
        summaryTbl.Ep(i)   = p;

        % Fit criteria
        summaryTbl.AIC(i) = localGetFieldOrNaN(lme, 'ModelCriterion', 'AIC');
        summaryTbl.BIC(i) = localGetFieldOrNaN(lme, 'ModelCriterion', 'BIC');

        % Adjusted R^2
        try
            summaryTbl.RsqAdj(i) = double(lme.Rsquared.Adjusted);
        catch
            summaryTbl.RsqAdj(i) = NaN;
        end
    end

    % Write CSV
    if  saveTable
        writetable(summaryTbl, outCsvFile);
    end

end

% ---------------- Local helper functions ----------------

function [est, ciL, ciU, p] = localGetCoef(lme, targetNames, isIntercept)
% Return estimate/CI/pValue for the first matching coefficient name.
% If not present, returns NaN.
    est = NaN; ciL = NaN; ciU = NaN; p = NaN;

    if isempty(lme)
        return;
    end

    % Get coefficient names and coefficient table
    try
        coefNames = string(lme.CoefficientNames);
    catch
        coefNames = strings(0,1);
    end

    try
        ct = lme.Coefficients;
    catch
        return;
    end

    % Normalize targets
    targets = lower(string(targetNames));
    cnLower = lower(coefNames);

    idx = [];

    % 1) Exact match to any target
    for t = 1:numel(targets)
        j = find(cnLower == targets(t), 1, 'first');
        if ~isempty(j)
            idx = j;
            break;
        end
    end

    % 2) Intercept fallback: match any name containing 'intercept'
    if isempty(idx) && isIntercept
        j = find(contains(cnLower, "intercept"), 1, 'first');
        if ~isempty(j)
            idx = j;
        end
    end

    if isempty(idx)
        return;
    end

    % Pull stats
    try
        est = double(ct.Estimate(idx));
    catch
        est = NaN;
    end
    try
        ciL = double(ct.Lower(idx));
    catch
        ciL = NaN;
    end
    try
        ciU = double(ct.Upper(idx));
    catch
        ciU = NaN;
    end
    try
        p = double(ct.pValue(idx));
    catch
        p = NaN;
    end
end

function val = localGetFieldOrNaN(obj, field1, field2)
% Safely try obj.(field1).(field2) and return NaN on failure.
    val = NaN;
    try
        s = obj.(field1);
        val = double(s.(field2));
    catch
        val = NaN;
    end
end
