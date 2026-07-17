% SMS_setCodePath;
% Set paths relative to this public StanfordMoonStudy repository.
FigCodeDir = fileparts(mfilename('fullpath'));
repoDir = fileparts(FigCodeDir);

codeDir = fullfile(repoDir, 'code');

addpath(genpath(codeDir))
addpath(genpath(FigCodeDir))
