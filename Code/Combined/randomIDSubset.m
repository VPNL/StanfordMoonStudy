function subTbl = randomIDSubset(T, f, seed)
% randomSubsetByID  Return a random subset of rows containing all data from
% a fraction f of the unique IDs.
%
% subTbl = randomSubsetByID(T, f, idVar)
% subTbl = randomSubsetByID(T, f, idVar, seed)
%
% Inputs
%   T     : input table
%   f     : fraction in [0,1]
%   seed  : (optional) RNG seed for reproducibility
%
% Output
%   subTbl: subset table containing ALL rows for the sampled IDs

    if ~exist('f', 'var')
        f=1; % return all table
    end
   
    arguments
        T table
        f (1,1) double {mustBeFinite, mustBeGreaterThanOrEqual(f,0), mustBeLessThanOrEqual(f,1)}
        seed (1,1) double {mustBeFinite} = NaN
    end

    if ~isnan(seed)
        rng(seed);
    end

  
    ids = T.ID;

   
    uniqueIDs = unique(ids);
    nUnique   = numel(uniqueIDs);

    nKeep = round(f * nUnique);        % per your spec: new IDs = f * numUnique (rounded)
    nKeep = max(0, min(nKeep, nUnique));

   if nKeep == 0
        keepTbl = T([],:);
        remTbl  = T;
        keepIDs = uniqueIDs([]); % empty
        return;
    elseif nKeep == nUnique
        keepTbl = T;
        remTbl  = T([],:);
        keepIDs = uniqueIDs;
        return;
    end

    % Sample IDs without replacement
    idx = randperm(nUnique, nKeep);
    keepIDs = uniqueIDs(idx);

    % Keep all rows whose ID is in keepIDs
    rowMask = ismember(ids, keepIDs);
    subTbl = T(rowMask, :);
end

