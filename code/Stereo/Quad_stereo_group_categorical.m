function stereoGroup = Quad_stereo_group_categorical(rawGroup)
%QUAD_STEREO_GROUP_CATEGORICAL Normalize numeric and text stereo groups.

if isnumeric(rawGroup) || islogical(rawGroup)
    groupValues = double(rawGroup);
    groupText = strings(size(groupValues));
    groupText(~isfinite(groupValues)) = "";
    finiteValues = unique(groupValues(isfinite(groupValues)));
    if all(ismember(finiteValues, [0 1 2 3]))
        groupText(groupValues == 1) = "StereoTypical";
        groupText(groupValues == 2) = "StereoDeficient";
        groupText(groupValues == 3) = "StereoBlind";
    else
        validRows = isfinite(groupValues);
        groupText(validRows) = "Group" + string(groupValues(validRows));
    end
else
    groupText = strtrim(string(rawGroup));
end

validText = groupText(~ismissing(groupText) & groupText ~= "");
if ~isempty(validText) && all(ismember(validText, ["1", "2", "3"]))
    groupText(groupText == "1") = "StereoTypical";
    groupText(groupText == "2") = "StereoDeficient";
    groupText(groupText == "3") = "StereoBlind";
end

stereoGroup = categorical(groupText);
stereoGroup = reordercats(stereoGroup, local_order_categories(categories(stereoGroup)));
end

function orderedCategories = local_order_categories(categoriesIn)
categoriesIn = string(categoriesIn(:));
preferred = ["StereoTypical"; "Typical"; "StereoDeficient"; "Deficient"; ...
    "StereoBlind"; "Blind"];
orderedCategories = preferred(ismember(preferred, categoriesIn));
remaining = categoriesIn(~ismember(categoriesIn, orderedCategories));
orderedCategories = cellstr([orderedCategories; remaining]);
end
