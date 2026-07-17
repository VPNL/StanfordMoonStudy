function plot_rs_subject_lines(ax, xData, idData, uniqueID, cmap, sorted_idx, lme, slopeVarName)
% plot_rs_subject_lines Plot subject-specific random-slope fits.

[reEfx, reNames] = randomEffects(lme);
levels = string(reNames.Level);
names = string(reNames.Name);
idStr = string(idData);
uniqueIDStr = string(uniqueID);

for i = 1:numel(uniqueIDStr)
    subj = uniqueIDStr(i);
    rowMask = idStr == subj;
    if ~any(rowMask)
        continue;
    end

    idxIntercept = find(levels == subj & names == "(Intercept)", 1, 'first');
    idxSlope = find(levels == subj & names == string(slopeVarName), 1, 'first');
    reIntercept = 0;
    reSlope = 0;
    if ~isempty(idxIntercept), reIntercept = reEfx(idxIntercept); end
    if ~isempty(idxSlope), reSlope = reEfx(idxSlope); end

    xSub = sort(unique(xData(rowMask)));
    if numel(xSub) < 2
        continue;
    end

    cindex = find(uniqueIDStr == subj, 1, 'first');
    sorted_cindex = find(sorted_idx == cindex, 1, 'first');
    if isempty(sorted_cindex)
        sorted_cindex = cindex;
    end
    thisColor = 0.9*cmap(sorted_cindex, :);
    yFit = (lme.Coefficients.Estimate(1) + reIntercept) + (lme.Coefficients.Estimate(2) + reSlope) * xSub;
    plot(ax, xSub, yFit, ':', 'Color', thisColor, 'LineWidth', 1);
end
end
