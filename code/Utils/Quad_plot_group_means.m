function Quad_plot_group_means(ax, groupValues, y, groupOrder)
%QUAD_PLOT_GROUP_MEANS Overlay a thick horizontal mean for each group.

groupValues = string(groupValues(:));
groupOrder = string(groupOrder(:));
for groupIdx = 1:numel(groupOrder)
    groupMean = mean(y(groupValues == groupOrder(groupIdx)), 'omitnan');
    plot(ax, groupIdx + [-0.22 0.22], [groupMean groupMean], ...
        'k-', 'LineWidth', 4);
end
end
