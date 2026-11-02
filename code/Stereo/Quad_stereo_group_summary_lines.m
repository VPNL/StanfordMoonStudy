function groupSummaryLines = Quad_stereo_group_summary_lines(tbl)
%QUAD_STEREO_GROUP_SUMMARY_LINES Summarize rows and IDs by stereo group.

groupNames = string(categories(tbl.StereoGroup));
groupSummaryLines = cell(1, numel(groupNames) + 1);
groupSummaryLines{1} = 'StereoGroup counts:';
for iGroup = 1:numel(groupNames)
    rowMask = string(tbl.StereoGroup) == groupNames(iGroup);
    groupSummaryLines{iGroup + 1} = sprintf( ...
        '  %s: %d rows, %d participants', groupNames(iGroup), ...
        sum(rowMask), numel(unique(tbl.ID(rowMask))));
end
end
