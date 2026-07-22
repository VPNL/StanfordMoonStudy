function variableName = quadFindFirstTableVariable(tbl, candidates)
%QUADFIND FIRSTTABLEVARIABLE Return the first candidate table variable present.

for candidateIdx = 1:numel(candidates)
    if ismember(candidates{candidateIdx}, tbl.Properties.VariableNames)
        variableName = candidates{candidateIdx};
        return;
    end
end

error('QuadData:MissingVariable', ...
    'Missing required table variable. Looked for: %s', strjoin(candidates, ', '));
end
