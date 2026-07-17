matchingFile = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/Merged_Matching_stereoscore_0428.csv';
disparityFile = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/merged_disparity_data0424.csv';

[disparityDir, disparityBase, ~] = fileparts(disparityFile);
outFile = fullfile(disparityDir, [disparityBase '_withStereoScores.csv']);

matchingTbl = readtable(matchingFile, 'VariableNamingRule', 'preserve');
disparityTbl = readtable(disparityFile, 'VariableNamingRule', 'preserve');

if ~ismember('ParticipantID', matchingTbl.Properties.VariableNames)
    error('Matching file must contain ParticipantID.');
end
if ~ismember('ID', disparityTbl.Properties.VariableNames)
    error('Disparity file must contain ID.');
end

scoreVars = { ...
    'Stereoscore Circles', ...
    'Stereoscore Animals', ...
    'Stereoscore Randot', ...
    'NormedScore', ...
    'Stereovision_arcsec'};

for iVar = 1:numel(scoreVars)
    if ~ismember(scoreVars{iVar}, matchingTbl.Properties.VariableNames)
        error('Matching file is missing required stereo column "%s".', scoreVars{iVar});
    end
end

matchingStereoTbl = local_build_stereo_by_id(matchingTbl, scoreVars);

disparityIDs = local_to_numeric(disparityTbl.ID);
if any(isnan(disparityIDs))
    error('Disparity ID column contains values that could not be converted to numeric IDs.');
end

[isMatched, stereoIdx] = ismember(disparityIDs, matchingStereoTbl.ID);

for iVar = 1:numel(scoreVars)
    varName = scoreVars{iVar};
    if ~ismember(varName, disparityTbl.Properties.VariableNames)
        disparityTbl.(varName) = nan(height(disparityTbl), 1);
    end

    mergedValues = nan(height(disparityTbl), 1);
    mergedValues(isMatched) = matchingStereoTbl.(varName)(stereoIdx(isMatched));
    disparityTbl.(varName) = mergedValues;
end

writetable(disparityTbl, outFile);

fprintf('Matching rows read: %d\n', height(matchingTbl));
fprintf('Disparity rows read: %d\n', height(disparityTbl));
fprintf('Unique matching participant IDs: %d\n', height(matchingStereoTbl));
fprintf('Matched disparity rows: %d\n', nnz(isMatched));
fprintf('Matched unique disparity IDs: %d of %d\n', ...
    numel(unique(disparityIDs(isMatched))), numel(unique(disparityIDs)));
fprintf('Saved merged disparity file to:\n%s\n', outFile);

function stereoByID = local_build_stereo_by_id(matchingTbl, scoreVars)
participantIDs = local_to_numeric(matchingTbl.ParticipantID);
validRows = ~isnan(participantIDs);

participantIDs = participantIDs(validRows);
matchingTbl = matchingTbl(validRows, :);

uniqueIDs = unique(participantIDs, 'stable');
stereoByID = table(uniqueIDs, 'VariableNames', {'ID'});

for iVar = 1:numel(scoreVars)
    stereoByID.(scoreVars{iVar}) = nan(numel(uniqueIDs), 1);
end

for iID = 1:numel(uniqueIDs)
    thisID = uniqueIDs(iID);
    rowMask = participantIDs == thisID;
    for iVar = 1:numel(scoreVars)
        varName = scoreVars{iVar};
        values = local_to_numeric(matchingTbl.(varName)(rowMask));
        nonMissing = values(~isnan(values));
        if isempty(nonMissing)
            stereoByID.(varName)(iID) = nan;
        else
            stereoByID.(varName)(iID) = nonMissing(1);
            if any(abs(nonMissing - nonMissing(1)) > 1e-9)
                warning('Participant ID %g has inconsistent values in "%s". Using the first nonmissing value.', ...
                    thisID, varName);
            end
        end
    end
end
end

function out = local_to_numeric(values)
if isnumeric(values)
    out = double(values);
    return
end

out = nan(numel(values), 1);
for i = 1:numel(values)
    value = values(i);
    if isnumeric(value)
        out(i) = double(value);
    else
        value = strtrim(string(value));
        if strlength(value) > 0
            out(i) = str2double(value);
        end
    end
end
end
