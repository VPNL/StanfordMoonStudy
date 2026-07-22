function coefficient = Quad_extract_subject_model_coefficient(lmeObj, predictorName, participantIDs)
%QUAD_EXTRACT_SUBJECT_MODEL_COEFFICIENT Fixed plus random coefficient by ID.

participantIDs = string(participantIDs(:));
predictorName = string(predictorName);
coefNames = string(lmeObj.Coefficients.Name);
fixedIdx = find(coefNames == predictorName, 1, 'first');
if isempty(fixedIdx)
    error('QuadModelCoefficient:MissingPredictor', ...
        'Could not find coefficient "%s" in the supplied LME.', predictorName);
end

fixedCoefficient = lmeObj.Coefficients.Estimate(fixedIdx);
[randomValues, randomNames] = randomEffects(lmeObj);
randomLevels = string(randomNames.Level);
randomCoefficientNames = string(randomNames.Name);

coefficient = repmat(fixedCoefficient, numel(participantIDs), 1);
for participantIdx = 1:numel(participantIDs)
    randomIdx = find(randomLevels == participantIDs(participantIdx) & ...
        randomCoefficientNames == predictorName, 1, 'first');
    if ~isempty(randomIdx)
        coefficient(participantIdx) = coefficient(participantIdx) + ...
            randomValues(randomIdx);
    end
end
end
