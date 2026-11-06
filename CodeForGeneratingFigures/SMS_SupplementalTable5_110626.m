% SMS_SupplementalTable5_110626
% Regenerate Supplemental Table 5 and compare it with the present table.

close all; clear;

SMS_setCodePath;
dataDir = paths.Data;
resultsDir = fullfile(paths.Figures, 'SupplementalTables');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

presentFile = fullfile(resultsDir, ...
    'Supplemental_Table5_StereoAcuitySubjectLevelData.csv');
discrepancyFile = fullfile(resultsDir, ...
    'Supplemental_Table5_discrepancies.csv');

if isfile(presentFile)
    generatedFile = fullfile(resultsDir, ...
        'Supplemental_Table5_StereoAcuitySubjectLevelData.csv');
    referenceFile = presentFile;
else
    generatedFile = presentFile;
    referenceFile = "";
end

[supplementalTable5, discrepancies, supplementalTable5Audit] = ...
    build_supplemental_table5_stereoacuity( ...
    dataDir, generatedFile, referenceFile);

if isempty(discrepancies)
    if referenceFile == ""
        fprintf('Supplemental Table 5 generated; no reference table was present.\n');
    else
        fprintf('Supplemental Table 5 matches the present table.\n');
    end
    if isfile(discrepancyFile)
        delete(discrepancyFile);
    end
else
    writetable(discrepancies, discrepancyFile);
    warning('SupplementalTable5:DiscrepanciesFound', ...
        ['Supplemental Table 5 differs from the present table in %d ' ...
        'fields. See %s'], height(discrepancies), discrepancyFile);
    disp(discrepancies);
end
