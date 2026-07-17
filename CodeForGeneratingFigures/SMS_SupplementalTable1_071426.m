% SMS_SupplementalTable1_071426
% make ground truth table for Stanford Moon Study
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/MoonStudy/';
MoonDataFile='Perceptual_FullMoonDataProcessed090225.csv';
MoonCsv =fullfile(dataDir,MoonDataFile);
ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Figures/SupplementalTables/';
if ~exist(ResultsDir,'dir')
   mkdir(ResultsDir)
end

outFile = fullfile(ResultsDir,['Supplemental_Table1_' MoonDataFile]);

[summaryTbl, outFile] = build_moon_supplemental_table1(MoonCsv, outFile)
