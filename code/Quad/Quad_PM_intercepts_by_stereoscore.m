function [interceptTbl, lmStereo] = Quad_PM_intercepts_by_stereoscore( ...
    tblStereo, lmeFull, figName, ResultsDir, colorConfig)
% QUAD_PM_INTERCEPTS_BY_STEREOSCORE
% Plot subject power-law intercepts from the full PM model against normed stereo score.
% An optional participant color configuration may select clinical-note
% colors. Omitting it preserves the original stereo-score coloring.

if nargin < 4 || isempty(ResultsDir)
    ResultsDir = pwd;
end
if nargin < 5
    colorConfig = [];
end

if ~exist(ResultsDir, 'dir')
    mkdir(ResultsDir);
end

interceptTbl = local_build_intercept_table(tblStereo, lmeFull);
validMask = ~isnan(interceptTbl.PowerLawIntercept) & ~isnan(interceptTbl.NormedStereoScore);
interceptTbl = interceptTbl(validMask, :);

lmStereo = [];
if isempty(interceptTbl)
    warning('Quad_PM_intercepts_by_stereoscore:NoData', ...
        'No subjects with both intercept and normed stereo score for %s.', figName);
    return;
end

lmStereo = fitlm(interceptTbl, ...
    'PowerLawIntercept ~ NormedStereoScore');
pval = lmStereo.Coefficients.pValue(2);
nSubjects = height(interceptTbl);

participantFile = fullfile(ResultsDir, ...
    [figName '_intercepts_vs_normedstereo_participants.csv']);
coefficientFile = fullfile(ResultsDir, ...
    [figName '_intercepts_vs_normedstereo_coefficients.csv']);
reportFile = fullfile(ResultsDir, ...
    [figName '_intercepts_vs_normedstereo_model.txt']);
writetable(interceptTbl, participantFile);
coefficientStats = lmStereo.Coefficients;
coefficientNames = string(coefficientStats.Properties.RowNames);
coefficientDF = repmat(lmStereo.DFE, height(coefficientStats), 1);
coefficientCI = coefCI(lmStereo);
coefficientOutputTbl = table(coefficientNames, coefficientStats.Estimate, ...
    coefficientStats.SE, coefficientStats.tStat, coefficientDF, ...
    coefficientStats.pValue, coefficientCI(:, 1), coefficientCI(:, 2), ...
    'VariableNames', {'Parameter', 'Estimate', 'SE', 'tStat', 'DF', ...
    'pValue', 'Lower', 'Upper'});
writetable(coefficientOutputTbl, coefficientFile);

fileID = fopen(reportFile, 'w');
if fileID == -1
    error('QuadPMInterceptStereo:ReportOpenFailed', ...
        'Could not open report file %s.', reportFile);
end
cleanupObject = onCleanup(@() fclose(fileID));
fprintf(fileID, 'Power-law intercept versus normed stereo score\n');
fprintf(fileID, 'Formula: PowerLawIntercept ~ NormedStereoScore\n');
fprintf(fileID, 'Participants: %d   RMSE: %.6g   R2: %.6g   Adjusted R2: %.6g\n', ...
    nSubjects, lmStereo.RMSE, lmStereo.Rsquared.Ordinary, ...
    lmStereo.Rsquared.Adjusted);
fprintf(fileID, '%-24s %12s %12s %12s %8s %12s %12s %12s\n', ...
    'Parameter', 'Estimate', 'SE', 'tStat', 'DF', 'pValue', 'Lower', 'Upper');
for coefficientIdx = 1:height(coefficientStats)
    fprintf(fileID, '%-24s %12.6g %12.6g %12.6g %8.0f %12.6g %12.6g %12.6g\n', ...
        coefficientNames(coefficientIdx), ...
        coefficientStats.Estimate(coefficientIdx), ...
        coefficientStats.SE(coefficientIdx), ...
        coefficientStats.tStat(coefficientIdx), ...
        coefficientDF(coefficientIdx), ...
        coefficientStats.pValue(coefficientIdx), ...
        coefficientCI(coefficientIdx, 1), ...
        coefficientCI(coefficientIdx, 2));
end

figH = figure('Color', [1 1 1], 'Units', 'normalized', 'Position', [0.15 0.15 0.5 0.6], ...
    'Name', [figName '_intercepts_vs_normedstereo'], 'Visible', 'off');
ax = axes(figH, 'Position', [0.14 0.16 0.70 0.72]);
hold(ax, 'on');

if isstruct(colorConfig) && string(colorConfig.Mode) == "clinicalnotes"
    pointColors = Quad_colors_for_participant_ids(interceptTbl.ID, colorConfig);
    scatter(ax, interceptTbl.NormedStereoScore, interceptTbl.PowerLawIntercept, 90, ...
        pointColors, 'filled', 'MarkerEdgeColor', 'none');
    legendHandle = Quad_add_clinical_notes_legend(ax, colorConfig);
    legendHandle.FontSize = 12;
else
    scatter(ax, interceptTbl.NormedStereoScore, interceptTbl.PowerLawIntercept, 90, ...
        interceptTbl.NormedStereoScore, 'filled', 'MarkerEdgeColor', 'none');
    apply_stereo_score_colormap(ax);
    cb = add_stereo_score_colorbar(ax, 'Normed stereo score');
    cb.FontSize = 18;
    cb.Label.FontSize = 22;
    cb.Label.Rotation = 90;
end

if pval < 0.05
    xGrid = linspace(0, 100, 200)';
    [yHat, yCI] = predict(lmStereo, xGrid);
    fill(ax, [xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
        'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    plot(ax, xGrid, yHat, 'k-', 'LineWidth', 3);
end

set(ax, 'FontName', 'Avenir', 'FontSize', 20);
xlabel(ax, 'Normed stereo score', 'FontSize', 24);
ylabel(ax, 'Subject power-law intercept [2^{log_2 PM}]', 'FontSize', 24);
box(ax, 'off');
grid(ax, 'off');
xlim(ax, [0 100]);

title(ax, sprintf('Power-law Intercept vs NormedStereoScore\np=%s\nn=%d', local_format_pvalue(pval), nSubjects), ...
    'FontSize', 18, 'FontWeight', 'normal');

exportgraphics(figH, fullfile(ResultsDir, [figName '_intercepts_vs_normedstereo.png']), 'Resolution', 600);
close(figH);
end

function interceptTbl = local_build_intercept_table(tblStereo, lmeFull)
scoreVar = local_find_first_var(tblStereo, {'NormedStereoScore', 'NormedScore'});

if ~iscategorical(tblStereo.ID)
    ids = categorical(tblStereo.ID);
else
    ids = tblStereo.ID;
end
uniqueID = categories(removecats(ids));

[reEfx, reNames] = randomEffects(lmeFull);
levels = string(reNames.Level);
names = string(reNames.Name);
coefNames = string(lmeFull.Coefficients.Name);
fixedInterceptIdx = find(strcmp(coefNames, '(Intercept)'), 1, 'first');

if isempty(fixedInterceptIdx)
    error('Quad_PM_intercepts_by_stereoscore:MissingIntercept', ...
        'The supplied LME does not contain a fixed intercept.');
end

fixedIntercept = lmeFull.Coefficients.Estimate(fixedInterceptIdx);

subjectIntercept = nan(numel(uniqueID), 1);
normedScore = nan(numel(uniqueID), 1);

for i = 1:numel(uniqueID)
    idCat = categorical(uniqueID(i));
    rowMask = ids == idCat;
    normedScore(i) = mean(double(tblStereo.(scoreVar)(rowMask)), 'omitnan');

    idxIntercept = find(strcmp(levels, string(uniqueID(i))) & strcmp(names, "(Intercept)"), 1, 'first');
    if ~isempty(idxIntercept)
        subjectIntercept(i) = fixedIntercept + reEfx(idxIntercept);
    else
        subjectIntercept(i) = fixedIntercept;
    end
end

powerLawIntercept = 2 .^ subjectIntercept;
interceptTbl = table(uniqueID, normedScore, subjectIntercept, powerLawIntercept, ...
    'VariableNames', {'ID', 'NormedStereoScore', 'SubjectIntercept', 'PowerLawIntercept'});
end

function varName = local_find_first_var(tbl, candidates)
for i = 1:numel(candidates)
    if ismember(candidates{i}, tbl.Properties.VariableNames)
        varName = candidates{i};
        return;
    end
end
error('Quad_PM_intercepts_by_stereoscore:MissingStereoColumn', ...
    'Missing stereo score column. Looked for: %s', strjoin(candidates, ', '));
end

function pStr = local_format_pvalue(pval)
if pval >= 0.01
    pStr = sprintf('%.2f', pval);
else
    pStr = sprintf('%.2e', pval);
end
end
