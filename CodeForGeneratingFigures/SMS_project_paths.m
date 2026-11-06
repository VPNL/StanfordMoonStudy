function paths = SMS_project_paths()
%SMS_PROJECT_PATHS Resolve repository paths without machine-specific names.

figureCodeDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(figureCodeDir);

paths.Project = projectDir;
paths.CodeForGeneratingFigures = figureCodeDir;
paths.Data = fullfile(projectDir, 'Data');
paths.Figures = fullfile(projectDir, 'Figures');
paths.Code = fullfile(projectDir, 'code');

developmentCodeDir = strtrim(getenv('SMS_CODE_DIR'));
if ~isempty(developmentCodeDir)
    if ~isfolder(developmentCodeDir)
        error('SMS:InvalidCodeDirectory', ...
            'SMS_CODE_DIR does not identify a directory: %s', ...
            developmentCodeDir);
    end
    paths.Code = developmentCodeDir;
end

requiredDirectories = {paths.Data, paths.Figures, paths.Code};
requiredNames = {'Data', 'Figures', 'code'};
for index = 1:numel(requiredDirectories)
    if ~isfolder(requiredDirectories{index})
        error('SMS:MissingProjectDirectory', ...
            'Missing %s directory: %s', requiredNames{index}, ...
            requiredDirectories{index});
    end
end
end
