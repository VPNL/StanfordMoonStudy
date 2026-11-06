% SMS_SupplementalTable6_110626
% Generate the cross-study participant and experiment-date table.

close all; clear;

SMS_setCodePath;
dataDir = paths.Data;
resultsDir = fullfile(paths.Figures, 'SupplementalTables');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

outFile = fullfile(resultsDir, ...
    'Supplemental_Table6_ParticipantExperiments.csv');
[supplementalTable6, supplementalTable6Audit] = ...
    build_supplemental_table6_participants(dataDir, outFile);
