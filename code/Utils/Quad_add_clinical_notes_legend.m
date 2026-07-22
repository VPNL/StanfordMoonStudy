function legendHandle = Quad_add_clinical_notes_legend(ax, colorConfig, location)
%QUAD_ADD_CLINICAL_NOTES_LEGEND Add a legend for present clinical categories.

if nargin < 3 || isempty(location)
    location = 'eastoutside';
end

[categoryNames, firstRows] = unique(string(colorConfig.Category), 'stable');
validRows = ~ismissing(categoryNames) & categoryNames ~= "";
categoryNames = categoryNames(validRows);
firstRows = firstRows(validRows);

legendHandles = gobjects(numel(categoryNames), 1);
for categoryIdx = 1:numel(categoryNames)
    legendHandles(categoryIdx) = scatter(ax, NaN, NaN, 50, ...
        colorConfig.Color(firstRows(categoryIdx), :), 'filled', ...
        'MarkerEdgeColor', 'none', 'DisplayName', categoryNames(categoryIdx));
end

legendHandle = legend(ax, legendHandles, categoryNames, 'Location', location);
legendHandle.FontName = 'Avenir';
legendHandle.AutoUpdate = 'off';
end
