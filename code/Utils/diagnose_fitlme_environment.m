function results = diagnose_fitlme_environment(codeDir, runRestoreDefaultPath)
% diagnose_fitlme_environment
%
% Small diagnostic for fitlme failures caused by MATLAB path shadowing or
% environment issues.
%
% Example
%   codeDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code';
%   results = diagnose_fitlme_environment(codeDir, true);
%
% Inputs
%   codeDir : project code directory to add back after restoredefaultpath
%   runRestoreDefaultPath : logical, if true starts from restoredefaultpath
%
% Output
%   results : struct with path info and smoke-test status

if nargin < 1 || isempty(codeDir)
    codeDir = pwd;
end
if nargin < 2 || isempty(runRestoreDefaultPath)
    runRestoreDefaultPath = true;
end

results = struct();
results.Timestamp = datetime('now');
results.CodeDir = string(codeDir);
results.RunRestoreDefaultPath = logical(runRestoreDefaultPath);

if runRestoreDefaultPath
    restoredefaultpath;
    rehash toolboxcache;
end
addpath(genpath(codeDir));

shadowNames = {'contains','startsWith','endsWith','isfile','isfolder', ...
    'newline','isrow','iscolumn','ismatrix','isequaln','narginchk', ...
    'writecell','writetable'};

shadowTbl = table('Size',[0 3], ...
    'VariableTypes',{'string','string','double'}, ...
    'VariableNames',{'FunctionName','ResolvedPath','PathRank'});

fprintf('\n=== fitlme Environment Diagnostic ===\n');
fprintf('Code dir: %s\n', codeDir);
fprintf('restoredefaultpath used: %d\n\n', runRestoreDefaultPath);

for i = 1:numel(shadowNames)
    name = shadowNames{i};
    resolved = which(name, '-all');
    if ischar(resolved)
        resolved = string({resolved});
    elseif iscell(resolved)
        resolved = string(resolved);
    else
        resolved = string(resolved);
    end
    resolved = resolved(:);

    if isempty(resolved)
        shadowTbl(end+1,:) = {string(name), "<not found>", 1}; %#ok<AGROW>
        fprintf('%s:\n  <not found>\n', name);
        continue;
    end

    fprintf('%s:\n', name);
    for j = 1:numel(resolved)
        shadowTbl(end+1,:) = {string(name), resolved(j), j}; %#ok<AGROW>
        fprintf('  %d. %s\n', j, resolved(j));
    end
end

results.PathResolution = shadowTbl;

fprintf('\n=== Minimal fitlme Smoke Test ===\n');
smokeTbl = table( ...
    [1; 2; 1; 2; 1; 2], ...
    [2.0; 4.1; 2.2; 4.2; 1.8; 3.9], ...
    categorical([1; 1; 2; 2; 3; 3]), ...
    'VariableNames', {'x','y','ID'});

try
    lme = fitlme(smokeTbl, 'y ~ x + (1|ID)');
    results.SmokeTestPassed = true;
    results.SmokeTestMessage = "fitlme smoke test passed";
    results.SmokeModel = lme;
    fprintf('fitlme smoke test passed.\n');
    disp(lme);
catch ME
    results.SmokeTestPassed = false;
    results.SmokeTestMessage = string(ME.message);
    results.SmokeError = ME;
    fprintf('fitlme smoke test FAILED.\n');
    fprintf('%s\n', ME.getReport('extended', 'hyperlinks', 'off'));
end

fprintf('\n=== Interpretation ===\n');
if results.SmokeTestPassed
    fprintf('Basic fitlme works in this environment.\n');
    fprintf('That suggests your remaining error is likely script/data/formula specific.\n');
else
    fprintf('Basic fitlme failed in this environment.\n');
    fprintf('That strongly suggests a MATLAB path/environment problem rather than only one script.\n');
end

end
