function safe_matlab_startup(projectCodeDir)
% SAFE_MATLAB_STARTUP Restore a clean MATLAB path and add project code.
%
%   safe_matlab_startup()
%   safe_matlab_startup(projectCodeDir)

if nargin < 1 || isempty(projectCodeDir)
    projectCodeDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code';
end

restoredefaultpath;
rehash toolboxcache;
clear functions;

userStartup = '/Users/kalanit/matlab/startup.m';
if exist(userStartup, 'file') == 2
    run(userStartup);
end

if exist(projectCodeDir, 'dir') ~= 7
    error('safe_matlab_startup:MissingProjectDir', ...
        'Project code directory not found: %s', projectCodeDir);
end

addpath(genpath(projectCodeDir));

% Prefer software rendering for interactive stability on systems where the
% desktop helper crashes in the graphics stack.
try
    opengl('save', 'software');
catch
    try
        opengl software;
    catch
    end
end

fprintf('Safe MATLAB startup complete.\n');
fprintf('Project path added: %s\n', projectCodeDir);
oglData = opengl('data');
if isfield(oglData, 'Software') && logical(oglData.Software)
    oglMode = 'software';
else
    oglMode = 'hardware';
end
fprintf('OpenGL mode: %s\n', oglMode);
