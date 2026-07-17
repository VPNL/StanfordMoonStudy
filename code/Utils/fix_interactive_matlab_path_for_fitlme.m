function fix_interactive_matlab_path_for_fitlme()
% FIX_INTERACTIVE_MATLAB_PATH_FOR_FITLME
% Remove known compatibility shim folders that shadow built-in MATLAB
% functions and destabilize fitlme / table internals in recent releases.

compatDirs = { ...
    '/Users/kalanit/software/spm12/external/fieldtrip/compat/matlablt2010b', ...
    '/Users/kalanit/software/spm12/external/fieldtrip/compat/matlablt2011b', ...
    '/Users/kalanit/software/spm12/external/fieldtrip/compat/matlablt2012a', ...
    '/Users/kalanit/software/spm12/external/fieldtrip/compat/matlablt2016b', ...
    '/Users/kalanit/software/spm12/external/fieldtrip/compat/matlablt2017b'};

for iDir = 1:numel(compatDirs)
    if contains(path, compatDirs{iDir})
        rmpath(compatDirs{iDir});
    end
end

clear iDir compatDirs;
rehash toolboxcache;
clear functions;
clear classes;

fprintf('Removed known FieldTrip compatibility shim directories from the MATLAB path.\n');
disp('Current resolutions:');
which contains -all
which startsWith -all
which isfile -all
which isfolder -all
