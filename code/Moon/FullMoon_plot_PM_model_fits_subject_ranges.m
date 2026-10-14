function figHandle = FullMoon_plot_PM_model_fits_subject_ranges( ...
    sourceFig, tbl, linearRS, logRS, task, resultsDir, baseName, sortedIdx)
%FULLMOON_PLOT_PM_MODEL_FITS_SUBJECT_RANGES Bound fits on original canvas.

tbl = local_prepare_table(tbl);
[uniqueID, subjectColors] = local_subject_colors(tbl, sortedIdx);
nSubjects = numel(uniqueID);

% The caller has already saved the original supplemental PNG. Reuse its
% exact canvas and change only the participant-specific dotted lines.
figHandle = sourceFig;
figHandle.Name = [baseName ' supplemental participant-range fits'];
axesHandles = findall(figHandle, 'Type', 'axes');
positions = vertcat(axesHandles.Position);
[~, order] = sort(positions(:, 1));
axLinear = axesHandles(order(1));
axLog = axesHandles(order(end));

delete(findall(axLinear, 'Type', 'line', 'LineStyle', ':'));
delete(findall(axLog, 'Type', 'line', 'LineStyle', ':'));
hold(axLinear, 'on');
hold(axLog, 'on');
local_plot_conditional_lines(axLinear, tbl, linearRS, uniqueID, ...
    subjectColors, 'Elevation');
local_plot_conditional_lines(axLog, tbl, logRS, uniqueID, ...
    subjectColors, 'logElevation');

for iAxis = 1:numel(axesHandles)
    axesHandles(iAxis).Toolbar.Visible = 'off';
end
drawnow;

outputFile = fullfile(resultsDir, sprintf( ...
    'SuppFig_LogLinModelComps_SubjectRanges_%s_%s_%d.png', ...
    baseName, task, nSubjects));
exportgraphics(figHandle, outputFile, 'Resolution', 600);
end

function tbl = local_prepare_table(tbl)
if ~ismember('logElevation', tbl.Properties.VariableNames)
    tbl.logElevation = log2(1 + tbl.Elevation);
end
if ~ismember('logRatio', tbl.Properties.VariableNames)
    tbl.logRatio = log2(tbl.Ratio_Visual_Angle);
end
valid = isfinite(tbl.Elevation) & isfinite(tbl.Ratio_Visual_Angle) & ...
    isfinite(tbl.logElevation) & isfinite(tbl.logRatio);
tbl = tbl(valid, :);
end

function [uniqueID, subjectColors] = local_subject_colors(tbl, sortedIdx)
uniqueID = unique(tbl.ID);
nSubjects = numel(uniqueID);
if numel(sortedIdx) ~= nSubjects || ...
        ~isequal(sort(sortedIdx(:)), (1:nSubjects)')
    sortedIdx = (1:nSubjects)';
end
cmap = jet(max(nSubjects, 1));
subjectColors = zeros(nSubjects, 3);
for iSubject = 1:nSubjects
    rank = find(sortedIdx == iSubject, 1);
    subjectColors(iSubject, :) = cmap(rank, :);
end
end

function local_plot_conditional_lines(ax, tbl, model, uniqueID, ...
    subjectColors, xName)
for iSubject = 1:numel(uniqueID)
    rows = tbl.ID == uniqueID(iSubject);
    xColumn = tbl.(xName);
    xObserved = xColumn(rows);
    xObserved = xObserved(isfinite(xObserved));
    if numel(unique(xObserved)) < 2
        continue;
    end
    xFit = linspace(min(xObserved), max(xObserved), 60)';
    templateRow = find(rows, 1);
    predictionTbl = tbl(repmat(templateRow, numel(xFit), 1), :);
    predictionTbl.(xName) = xFit;
    yFit = predict(model, predictionTbl, 'Conditional', true);
    plot(ax, xFit, yFit, ':', 'Color', subjectColors(iSubject, :), ...
        'LineWidth', 1);
end
end
