% SMS_SupplementalTable4_110526
% make ground truth table for Stanford Moon Offset Study

SMS_setCodePath;

dataDir = fullfile(paths.Data, 'BinocularParallax');
MoonDataFile='Parallax_FullMoon_090225.csv';
MoonCsv =fullfile(dataDir,MoonDataFile);
ResultsDir = fullfile(paths.Figures, 'SupplementalTables');
if ~exist(ResultsDir,'dir')
   mkdir(ResultsDir)
end

outFile = fullfile(ResultsDir,['Supplemental_Table4_' MoonDataFile]);

[summaryTbl, outFile] = build_moon_supplemental_table1(MoonCsv, outFile)
