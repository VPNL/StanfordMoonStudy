function x = Quad_group_plot_x_positions(groupValues, groupOrder)
%QUAD_GROUP_PLOT_X_POSITIONS Deterministic horizontal jitter for grouped points.

groupValues = string(groupValues(:));
groupOrder = string(groupOrder(:));
x = nan(numel(groupValues), 1);
for groupIdx = 1:numel(groupOrder)
    rows = find(groupValues == groupOrder(groupIdx));
    if numel(rows) == 1
        jitter = 0;
    else
        jitter = linspace(-0.16, 0.16, numel(rows))';
    end
    x(rows) = groupIdx + jitter;
end
end
