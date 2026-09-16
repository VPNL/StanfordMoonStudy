% SMS_SupplementalTable4_090426
% make ground truth table for Stanford Moon Offset Study

SMS_setCodePath;

dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/OcularOffset/';
MoonDataFile='Disparity_BothElevations_FullMoonDataLong090225';
MoonCsv =fullfile(dataDir,[MoonDataFile '.csv']);
ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Figures/SupplementalTables/';
if ~exist(ResultsDir,'dir')
   mkdir(ResultsDir)
end

outFile = fullfile(ResultsDir,['Supplemental_Table4_' MoonDataFile '.csv']);

[summaryTbl, outFile] = build_moon_supplemental_table1(MoonCsv, outFile)
