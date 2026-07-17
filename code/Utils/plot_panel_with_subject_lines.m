function plot_panel_with_subject_lines(ax, xData, yData, subjectcolor, lme, uniqueID, cmap, sorted_idx, idData, slopeVarName, xLimits, yLimits, xlabelText, ylabelText, titleText, useCustomTicks, xTickLabelFcn, yTickLabelFcn, markerSize)
% plot_panel_with_subject_lines Plot scatter, RS subject lines, fixed effect, and CI.

if ~exist('markerSize')
    markerSize = 15;
end
hold(ax, 'on');

[b0L,b0U,b1L,b1U] = get_coef_bounds(lme);
b0 = lme.Coefficients.Estimate(1);
b1 = lme.Coefficients.Estimate(2);
xline = linspace(xLimits(1), xLimits(2), 200);
yfit = b0 + b1*xline;
xU = xline;
xD = fliplr(xline);
yL = b0L + b1L*xU;
yU = b0U + b1U*xD;

scatter(ax, xData, yData, markerSize, subjectcolor, 'filled');

plot(ax, xline, zeros(size(xline)), 'k:', 'LineWidth', 1);
fill(ax, [xU xD], [yL yU], 1, 'FaceColor','k', 'EdgeColor','none', 'FaceAlpha',0.3);
plot_rs_subject_lines(ax, xData, idData, uniqueID, cmap, sorted_idx, lme, slopeVarName);
plot(ax, xline, yfit, 'k-', 'LineWidth', 3);

set(ax,'FontName','Avenir','FontSize',18);
xlim(ax, xLimits);
ylim(ax, yLimits);
xlabel(ax, xlabelText, 'FontSize',18);
ylabel(ax, ylabelText, 'FontSize',18);
title(ax, titleText, 'FontSize',18,'FontWeight','normal');

if useCustomTicks
    xticks_vals = get(ax, 'XTick');
    xticklabels_vals = arrayfun(xTickLabelFcn, xticks_vals, 'UniformOutput', false);
    set(ax, 'XTickLabel', xticklabels_vals);
    yticks_vals = get(ax, 'YTick');
    yticklabels_vals = arrayfun(yTickLabelFcn, yticks_vals, 'UniformOutput', false);
    set(ax, 'YTickLabel', yticklabels_vals);
end
end
