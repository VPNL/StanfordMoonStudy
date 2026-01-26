function [outTbl]=estimate_PM_fromlmeTbl(dataTbl,lmeTbl )
% [outTbl]= estimate_PM_fromlmeTbl(dataTbl,lmeTbl )
% gets dataTbl and lmeTbl and evaluates for each row in the dataTbl 
% the predicted perceptual magnification for each lme model in lmeTbl
% based on the Real_Visual_Angle, Distance & Elevation
%
% Input
% dataTl
% lmeTbl: each row is a lme model that give coefficients for each parameter
% VA: visual angle
% D: distance
% E: elevation
% verboseFlag: [optional] prints min and max estimated values; default 0
%
% output
%  outTbl which is augmented dataTbl with additional columns (1 per model)
%         each additional columns is model predicted PM  p

if ~exist('verboseFlag','var')
    verboseFlag=0;
end

outTbl=dataTbl;
% --- Map predictors from data table ---
VA = dataTbl.Real_Visual_Angle;   % per your mapping
D  = dataTbl.Distance;
E  = dataTbl.Elevation;

% Guard against nonpositive values (log2 undefined)
if any(VA <= 0 | D <= 0 | E <= 0)
    error("Nonpositive values found in VA, Distance, or Elevation; log2 is undefined.");
end

log2VA = log2(VA);
log2D  = log2(D);
log2E  = log2(E+1); % model has a regularization term for elevation

%% --- Loop over each model (row) in the LME summary table ---
for i = 1:height(lmeTbl)
    modelName = string(lmeTbl.modelName{i});  % desired new column name
    
    % Coefficients (treat missing terms as 0)
    b0  = lmeTbl.Intercept(i);
    bVA = lmeTbl.VAe(i); if isnan(bVA), bVA = 0; end
    bD  = lmeTbl.De(i);  if isnan(bD),  bD  = 0; end
    bE  = lmeTbl.Ee(i);  if isnan(bE),  bE  = 0; end

    % Fixed-effects prediction of log2PM
    predLog2PM = b0 + bVA .* log2VA + bD .* log2D + bE .* log2E;
    PM=2.^predLog2PM;
    if verboseFlag
        fprintf( '%s min PM %.1f max PM %.2f \n', modelName,min(PM), max(PM));
    end
    % Add as a new column named by modelName
    if ~isvarname(modelName)
        % If ever needed, sanitize into a valid MATLAB variable name
        modelName = matlab.lang.makeValidName(modelName);
    end
    columnName=sprintf('predicted_PM_%s',modelName);
    outTbl.(columnName) = PM;
end