function summaryTbl = Quad_export_LME_summary_csv(outCsvFile,study, task, ...
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
    if ~exist('study','var')
        study=[];
    end
    if ~exist('task','var')
        task=[];
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

   varNames={'Study','Task', 'modelName', 'Formula',...,
            'Intercept','IciL', 'IciU','Ip',...
             'VAe', 'VAciL','VAciU','VAp',...
             'De', 'DciL','DciU','Dp', ...
              'Ee', 'EciL','EciU','Ep',...
               'AIC','BIC','RsqA',};
    
    varTypes = {'string','string','string','string',...
        'double', 'double', 'double', 'double',...
        'double', 'double', 'double', 'double',...
        'double', 'double', 'double', 'double',...
        'double', 'double', 'double', 'double',...
        'double', 'double', 'double'}; 

% Create a 0x4 empty table
summaryTbl = table('Size', [n, numel(varNames)], 'VariableNames', varNames, 'VariableTypes', varTypes);

    % 
    % 

    % Optional but often useful for provenance
    FormulaStr  = strings(n,1);

    for i = 1:n % runs on lmes
        lme = lmes{i};

        if isempty(lme)
            continue;
        end

        % ---- Fixed effects (robust name-based lookup) ----
        statstable(i).Study=string(study);
        statstable(i).Task=string(task);
        statstable(i).modelName=string(modelNames{i});
        statstable(i).FormulaStr=string(char(lme.Formula));
        ncoeffs=numel(lme.CoefficientNames);
        for nc=1:ncoeffs % runs on coefficients
             if strcmp(lme.CoefficientNames(nc),'(Intercept)') | strcmp(lme.CoefficientNames(nc),'(intercept)')
                statstable(i).Intercept=lme.Coefficients.Estimate(nc);
                statstable(i).IciL=lme.Coefficients.Lower(nc);
                statstable(i).IciU=lme.Coefficients.Upper(nc);
                statstable(i).Ip=lme.Coefficients.pValue(nc);
             end
             if strcmp(lower(lme.CoefficientNames(nc)),'log2real_visual_angle')
                statstable(i).VAe=lme.Coefficients.Estimate(nc);
                statstable(i).VAciL=lme.Coefficients.Lower(nc);
                statstable(i).VAciU=lme.Coefficients.Upper(nc);
                statstable(i).VAp=lme.Coefficients.pValue(nc);
             end

             if strcmp(lower(lme.CoefficientNames(nc)),'log2distance')
                statstable(i).De=lme.Coefficients.Estimate(nc);
                statstable(i).DciL=lme.Coefficients.Lower(nc);
                statstable(i).DciU=lme.Coefficients.Upper(nc);
                statstable(i).Dp=lme.Coefficients.pValue(nc);
             end
             if strcmp(lower(lme.CoefficientNames(nc)),'log2elevation')
                statstable(i).Ee=lme.Coefficients.Estimate(nc);
                statstable(i).EciL=lme.Coefficients.Lower(nc);
                statstable(i).EciU=lme.Coefficients.Upper(nc);
                statstable(i).Ep=lme.Coefficients.pValue(nc);
             end
             statstable(i).AIC = lme.ModelCriterion.AIC;
             statstable(i).BIC=lme.ModelCriterion.BIC;
             statstable(i).RsqAdj = lme.Rsquared.Adjusted
        end
        
          % coefNames = lme.CoefficientNames;     % cellstr
       % [fe, fename, festats] = fixedEffects(lme);        % numeric vector
       % 
       % 
       %  Intercept(i)    = localGetByName(coefNames, fe, '(Intercept)');
       %  LogVA(i)        = localGetByName(coefNames, fe, 'log2real_visual_angle');
       %  LogDistance(i)  = localGetByName(coefNames, fe, 'log2distance');
       %  LogElevation(i) = localGetByName(coefNames, fe, 'log2elevation');
       % 
        
        % % ---- AIC/BIC ----
        % [AIC(i), BIC(i)] = localGetAICBIC(lme);
        % 
        % % ---- Adjusted R^2 ----
        % R2Adj(i) = localGetAdjustedR2(lme);
        % 
        % % ---- Formula string (optional) ----
        
        % try
        %     FormulaStr(i) = string(char(lme.Formula));
        % catch
        %     FormulaStr(i) = "";
        % end
    end

    % summaryTbl = table( ...
    %     string(modelNames(:)), ...
    %     Intercept, LogVA, LogDistance, LogElevation, ...
    %     AIC, BIC, R2Adj, ...
    %     FormulaStr, ...
    %     'VariableNames', {'Model','Intercept','LogVA','LogDistance','LogElevation','AIC','BIC','R2Adj','Formula'});

    summaryTbl=struct2table(statstable);
    writetable(summaryTbl, outCsvFile);

end

% % ---------------- Local helper functions ----------------
% 
% function val = localGetByName(coefNames, fe, targetName)
%     % Returns fixed-effect estimate for targetName, or NaN if absent.
%     val = NaN;
%     if isempty(coefNames) || isempty(fe)
%         return;
%     end
% 
%     % Normalize coefNames to cellstr
%     if isstring(coefNames)
%         coefNames = cellstr(coefNames);
%     end
% 
%     idx = find(strcmp(coefNames, targetName), 1, 'first');
%     if ~isempty(idx) && idx <= numel(fe)
%         val = fe(idx);
%     end
% end

% function [aic, bic] = localGetAICBIC(lme)
%     aic = NaN; bic = NaN;
% 
%     % Common case in fitlme
%     try
%         aic = lme.ModelCriterion.AIC;
%         bic = lme.ModelCriterion.BIC;
%         return;
%     catch
%     end
% 
%     % Fallbacks (version differences)
%     try
%         mc = lme.ModelCriterion;
%         if istable(mc)
%             if any(strcmpi(mc.Properties.VariableNames,'AIC')); aic = mc.AIC(1); end
%             if any(strcmpi(mc.Properties.VariableNames,'BIC')); bic = mc.BIC(1); end
%         elseif isstruct(mc)
%             if isfield(mc,'AIC'); aic = mc.AIC; end
%             if isfield(mc,'BIC'); bic = mc.BIC; end
%         end
%     catch
%     end
% end

% function r2adj = localGetAdjustedR2(lme)
%     r2adj = NaN;
% 
%     % Your existing code suggests this exists in your MATLAB version
%     try
%         r2adj = lme.Rsquared.Adjusted;
%         return;
%     catch
%     end
% 
%     % Fallback if rsquared() exists
%     try
%         r2 = rsquared(lme);
%         if isstruct(r2) && isfield(r2,'Adjusted')
%             r2adj = r2.Adjusted;
%         elseif istable(r2) && any(strcmpi(r2.Properties.VariableNames,'Adjusted'))
%             r2adj = r2.Adjusted(1);
%         end
%     catch
%     end
% end
