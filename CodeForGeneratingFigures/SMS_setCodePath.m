% SMS_setCodePath
% Add repository code, or SMS_CODE_DIR when explicitly configured.
paths = SMS_project_paths();
codeDir = paths.Code;
FigCodeDir = paths.CodeForGeneratingFigures;

addpath(genpath(codeDir));
addpath(genpath(FigCodeDir));
