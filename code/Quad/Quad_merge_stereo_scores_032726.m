stereoFile = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/StereoQuadRawData0226(CURRENT) - RandDot Stereo Test.csv';
quadFile = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/QuadProcessedDisparityData032626_11pm_6001cleanedV3.csv';

[quadDir, quadBase, ~] = fileparts(quadFile);
outFile = fullfile(quadDir, [quadBase '_StereoScores.csv']);

stereoTbl = local_read_stereo_scores(stereoFile);
quadTbl = readtable(quadFile);

if ~ismember('ID', quadTbl.Properties.VariableNames)
    error('Quad file must contain an ID column.');
end

quadIDs = double(quadTbl.ID);
if any(isnan(quadIDs))
    error('Quad ID column contains nonnumeric values that could not be matched.');
end

[isMatched, stereoIdx] = ismember(quadIDs, stereoTbl.ID);

quadTbl.NormedStereoScore = nan(height(quadTbl), 1);
quadTbl.ContinuousStereoScore = nan(height(quadTbl), 1);
quadTbl.NormedStereoScore(isMatched) = stereoTbl.NormedScore(stereoIdx(isMatched));
quadTbl.ContinuousStereoScore(isMatched) = stereoTbl.ContinuousScore(stereoIdx(isMatched));

writetable(quadTbl, outFile);

fprintf('Stereo rows read: %d\n', height(stereoTbl));
fprintf('Quad rows read: %d\n', height(quadTbl));
fprintf('Matched quad rows: %d\n', nnz(isMatched));
fprintf('Matched unique IDs: %d of %d quad IDs\n', ...
    numel(unique(quadIDs(isMatched))), numel(unique(quadIDs)));
fprintf('Saved updated file to:\n%s\n', outFile);

function stereoTbl = local_read_stereo_scores(stereoFile)
raw = readcell(stereoFile, 'FileType', 'text');

if size(raw, 1) < 4 || size(raw, 2) < 21
    error('Stereo file does not have the expected layout.');
end

dataRows = raw(4:end, :);
idCol = local_to_numeric_column(dataRows(:, 1));
normedCol = local_to_numeric_column(dataRows(:, 20));
continuousCol = local_to_numeric_column(dataRows(:, 21));

validRows = ~isnan(idCol);

stereoTbl = table( ...
    idCol(validRows), ...
    normedCol(validRows), ...
    continuousCol(validRows), ...
    'VariableNames', {'ID', 'NormedScore', 'ContinuousScore'});

[uniqueIDs, ia] = unique(stereoTbl.ID, 'stable');
if numel(uniqueIDs) ~= height(stereoTbl)
    stereoTbl = stereoTbl(ia, :);
end
end

function out = local_to_numeric_column(col)
out = nan(numel(col), 1);
for i = 1:numel(col)
    value = col{i};
    if isnumeric(value)
        out(i) = value;
    elseif isstring(value) || ischar(value)
        value = strtrim(string(value));
        if strlength(value) > 0
            out(i) = str2double(value);
        end
    end
end
end
