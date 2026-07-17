% SMS_setCodePath;
% Set paths relative to this public StanfordMoonStudy repository.
FigCodeDir = fileparts(mfilename('fullpath'));
repoDir = fileparts(FigCodeDir);

repoCodeDir = fullfile(repoDir, 'code');
devCodeDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code';

if exist(repoCodeDir, 'dir')
    codeDir = repoCodeDir;
elseif exist(devCodeDir, 'dir')
    codeDir = devCodeDir;
else
    error('Could not find StanfordMoonStudy code directory.');
end

addpath(genpath(codeDir))
addpath(genpath(FigCodeDir))
