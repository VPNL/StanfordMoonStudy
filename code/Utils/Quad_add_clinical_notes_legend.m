function legendHandle = Quad_add_clinical_notes_legend(ax, colorConfig, location, categoryOrder)
%QUAD_ADD_CLINICAL_NOTES_LEGEND Add a legend for present clinical categories.

if nargin < 3 || isempty(location)
    location = 'eastoutside';
end
if nargin < 4 || isempty(categoryOrder)
    categoryOrder = local_default_category_order();
else
    categoryOrder = string(categoryOrder);
end

categoryByRow = string(colorConfig.Category(:));
validRows = ~ismissing(categoryByRow) & categoryByRow ~= "";
presentCategories = unique(categoryByRow(validRows), 'stable');

categoryNames = strings(0, 1);
firstRows = zeros(0, 1);
for categoryIdx = 1:numel(categoryOrder)
    rowIdx = find(categoryByRow == categoryOrder(categoryIdx), 1, 'first');
    if ~isempty(rowIdx)
        categoryNames(end + 1, 1) = categoryOrder(categoryIdx); %#ok<AGROW>
        firstRows(end + 1, 1) = rowIdx; %#ok<AGROW>
    end
end

for categoryIdx = 1:numel(presentCategories)
    if ~ismember(presentCategories(categoryIdx), categoryNames)
        rowIdx = find(categoryByRow == presentCategories(categoryIdx), 1, 'first');
        categoryNames(end + 1, 1) = presentCategories(categoryIdx); %#ok<AGROW>
        firstRows(end + 1, 1) = rowIdx; %#ok<AGROW>
    end
end

legendHandles = gobjects(numel(categoryNames), 1);
colors = local_color_matrix(colorConfig);
for categoryIdx = 1:numel(categoryNames)
    legendHandles(categoryIdx) = scatter(ax, NaN, NaN, 50, ...
        colors(firstRows(categoryIdx), :), 'filled', ...
        'MarkerEdgeColor', 'none', 'DisplayName', categoryNames(categoryIdx));
end

legendHandle = legend(ax, legendHandles, categoryNames, 'Location', location);
legendHandle.FontName = 'Avenir';
legendHandle.AutoUpdate = 'off';
end

function categoryOrder = local_default_category_order()
categoryOrder = [
    "Ptosis"
    "Convergence insufficiency"
    "Strabismus"
    "Amblyopia"
    "Farsighted"
    "Nearsighted"
    "Astigmatism"
    "Cataract"
    "No clinical note"
    "Other clinical note"
    ];
end

function colors = local_color_matrix(colorConfig)
if isfield(colorConfig, 'Color')
    colors = colorConfig.Color;
elseif isfield(colorConfig, 'Cmap')
    colors = colorConfig.Cmap;
else
    error('QuadClinicalLegend:MissingColors', ...
        'colorConfig must contain a Color or Cmap field.');
end
end
