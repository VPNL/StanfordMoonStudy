function colorConfig = Quad_build_participant_color_config( ...
    tbl, resultsDir, quadBaseName, colorMode, recomputeColorIndex, colorSortBy)
%QUAD_BUILD_PARTICIPANT_COLOR_CONFIG Build a reusable participant-color configuration.
%
% The returned RankCmap and SortedIdx fields preserve the interface used by
% existing PM plotting functions. Color contains one RGB row per ID and is
% intended for plots that accept the optional colorConfig argument.
%
% For colorMode="id", colorSortBy controls the participant rank mapped onto
% the jet colormap. Supported values include "id", "meanDisparity", and
% "meanRatioVisualAngle" / "Ratio_Visual_Angle"; an existing numeric table
% variable name can also be passed.

if nargin < 4 || isempty(colorMode)
    colorMode = "stereoscore";
end
if nargin < 5 || isempty(recomputeColorIndex)
    recomputeColorIndex = true;
end
if nargin < 6 || isempty(colorSortBy)
    colorSortBy = "";
end

colorMode = lower(strtrim(string(colorMode)));
sortByLabel = "";
sortMetric = [];
sortDirection = "ascend";
colorbarTicks = [];
colorbarTickLabels = strings(0, 1);
switch colorMode
    case {"stereoscore", "stereo", "normed", "normedstereoscore"}
        colorMode = "stereoscore";
        [sortedIdx, stereoScore, uniqueID, rankCmap] = ...
            Quad_compute_mean_stereo_color_idx(tbl, resultsDir, ...
            quadBaseName, recomputeColorIndex, 'normed');
        category = strings(numel(uniqueID), 1);
        participantColors = colorsByParticipantRank(sortedIdx, rankCmap, numel(uniqueID));

    case {"clinicalnotes", "clinical"}
        colorMode = "clinicalnotes";
        [sortedIdx, category, uniqueID, rankCmap] = ...
            Quad_compute_clinical_notes_color_idx(tbl, resultsDir, ...
            quadBaseName, recomputeColorIndex);
        stereoScore = nan(numel(uniqueID), 1);
        participantColors = colorsByParticipantRank(sortedIdx, rankCmap, numel(uniqueID));

    case {"id", "participant", "participantid"}
        colorMode = "id";
        uniqueID = unique(tbl.ID);
        uniqueID = uniqueID(:);
        nParticipants = numel(uniqueID);
        [sortedIdx, sortMetric, sortByLabel, sortDirection] = ...
            local_sort_ids(tbl, uniqueID, colorSortBy);
        category = string(uniqueID);
        stereoScore = nan(nParticipants, 1);
        rankCmap = jet(max(nParticipants, 1));
       % for combined data
       % rankCmap=purpleVioletBlueTurquoiseColorMap(max(nParticipants, 1));

        participantColors = colorsByParticipantRank(sortedIdx, rankCmap, nParticipants);
        [colorbarTicks, colorbarTickLabels] = local_id_colorbar_ticks(sortedIdx, uniqueID);

    otherwise
        error('QuadParticipantColors:InvalidMode', ...
            'colorMode must be "stereoscore", "clinicalnotes", or "id".');
end

colorConfig = struct( ...
    'Mode', colorMode, ...
    'ID', string(uniqueID(:)), ...
    'Color', participantColors, ...
    'Category', string(category(:)), ...
    'StereoScore', stereoScore(:), ...
    'SortBy', sortByLabel, ...
    'SortMetric', sortMetric(:), ...
    'SortDirection', sortDirection, ...
    'SortedIdx', sortedIdx(:), ...
    'RankCmap', rankCmap, ...
    'ColorbarTicks', colorbarTicks(:), ...
    'ColorbarTickLabels', colorbarTickLabels(:));
end

function participantColors = colorsByParticipantRank(sortedIdx, rankCmap, nParticipants)
participantColors = repmat([0.5 0.5 0.5], nParticipants, 1);
for participantIdx = 1:nParticipants
    colorRow = find(sortedIdx == participantIdx, 1, 'first');
    if ~isempty(colorRow) && colorRow <= size(rankCmap, 1)
        participantColors(participantIdx, :) = rankCmap(colorRow, :);
    end
end
end

function [sortedIdx, sortMetric, sortByLabel, sortDirection] = local_sort_ids(tbl, uniqueID, colorSortBy)
sortDirection = "ascend";
sortBy = strtrim(string(colorSortBy));

if strlength(sortBy) == 0
    sortBy = "id";
end

sortByLower = lower(sortBy);
if startsWith(sortByLower, "-")
    sortDirection = "descend";
    sortBy = extractAfter(sortBy, 1);
    sortByLower = lower(strtrim(sortBy));
elseif endsWith(sortByLower, "_descend") || endsWith(sortByLower, " descend")
    sortDirection = "descend";
    sortBy = regexprep(sortBy, '(_descend|\s+descend)$', '', 'ignorecase');
    sortByLower = lower(strtrim(sortBy));
elseif endsWith(sortByLower, "_ascend") || endsWith(sortByLower, " ascend")
    sortBy = regexprep(sortBy, '(_ascend|\s+ascend)$', '', 'ignorecase');
    sortByLower = lower(strtrim(sortBy));
end

if any(sortByLower == ["id", "participant", "participantid"])
    sortMetric = local_numeric_id(uniqueID);
    missingMetric = isnan(sortMetric);
    sortMetric(missingMetric) = find(missingMetric);
    sortByLabel = "ID";
else
    [rowValues, sortByLabel] = local_sort_values(tbl, sortBy);
    if isempty(rowValues)
        warning('QuadParticipantColors:MissingSortVariable', ...
            'Could not sort ID colors by "%s"; falling back to participant ID.', sortBy);
        sortMetric = local_numeric_id(uniqueID);
        missingMetric = isnan(sortMetric);
        sortMetric(missingMetric) = find(missingMetric);
        sortByLabel = "ID";
    else
        sortMetric = local_mean_by_id(tbl.ID, rowValues, uniqueID);
    end
end

tieBreak = local_numeric_id(uniqueID);
missingTie = isnan(tieBreak);
tieBreak(missingTie) = find(missingTie);

sortVals = sortMetric;
if sortDirection == "ascend"
    sortVals(isnan(sortVals)) = inf;
else
    sortVals(isnan(sortVals)) = -inf;
end

[~, sortedIdx] = sortrows([sortVals(:) tieBreak(:)], [1 2]);
if sortDirection == "descend"
    sortedIdx = flipud(sortedIdx);
end
end

function [rowValues, sortByLabel] = local_sort_values(tbl, sortBy)
rowValues = [];
sortKey = lower(regexprep(char(sortBy), '[^a-zA-Z0-9]', ''));

switch sortKey
    case {'meandisparity', 'disparity', 'meanoffset', 'meaninterocularoffset'}
        rowValues = local_disparity_values(tbl);
        sortByLabel = "meanDisparity";
    case {'meanratiovisualangle', 'ratiovisualangle', 'meanpm', 'pm', 'perceptualmagnification'}
        varName = local_find_table_variable(tbl, {'Ratio_Visual_Angle', 'ratio_visual_angle'});
        if ~isempty(varName)
            rowValues = double(tbl.(varName));
        end
        sortByLabel = "meanRatioVisualAngle";
    otherwise
        varName = local_find_table_variable(tbl, {char(sortBy)});
        if ~isempty(varName) && isnumeric(tbl.(varName))
            rowValues = double(tbl.(varName));
            sortByLabel = string(varName);
        else
            sortByLabel = string(sortBy);
        end
end
end

function values = local_disparity_values(tbl)
values = [];
varName = local_find_table_variable(tbl, {'MeanDisparity'});
if ~isempty(varName)
    values = double(tbl.(varName));
    return;
end

if all(ismember({'Disparity1', 'Disparity2'}, tbl.Properties.VariableNames))
    values = mean([double(tbl.Disparity1) double(tbl.Disparity2)], 2, 'omitnan');
    return;
end

varName = local_find_table_variable(tbl, {'Disparity'});
if ~isempty(varName)
    values = double(tbl.(varName));
end
end

function varName = local_find_table_variable(tbl, candidates)
varName = '';
tableVars = string(tbl.Properties.VariableNames);
for iCandidate = 1:numel(candidates)
    idx = find(strcmpi(tableVars, string(candidates{iCandidate})), 1, 'first');
    if ~isempty(idx)
        varName = char(tableVars(idx));
        return;
    end
end
end

function meanVals = local_mean_by_id(rowID, rowValues, uniqueID)
rowID = string(rowID);
rowValues = double(rowValues);
meanVals = nan(numel(uniqueID), 1);
for iID = 1:numel(uniqueID)
    rowMask = rowID == string(uniqueID(iID));
    meanVals(iID) = mean(rowValues(rowMask), 'omitnan');
end
end

function numericID = local_numeric_id(uniqueID)
numericID = str2double(string(uniqueID(:)));
end

function [ticks, tickLabels] = local_id_colorbar_ticks(sortedIdx, uniqueID)
nParticipants = numel(uniqueID);
if nParticipants == 0
    ticks = [];
    tickLabels = strings(0, 1);
    return;
end

maxTicks = min(6, nParticipants);
ticks = unique(round(linspace(1, nParticipants, maxTicks)));
participantIdx = sortedIdx(ticks);
tickLabels = string(uniqueID(participantIdx));
end
