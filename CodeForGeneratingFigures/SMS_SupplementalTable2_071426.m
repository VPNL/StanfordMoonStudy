% SMS_SupplementalTable2_071426
% make ground truth table for Stanford Quad Study

dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/QuadStudy/';
QuadDataFile='Perceptual_StanfordQuadStudyDataProcessed0420.csv';
QuadCsv =fullfile(dataDir,QuadDataFile);

ResultsDir='/Users/kalanit/Projects/StanfordMoonStudy/Figures/SupplementalTables/';
if ~exist(ResultsDir,'dir')
   mkdir(ResultsDir)
end

outFile = fullfile(ResultsDir,['Supplemental_Table2_' QuadDataFile]);

ObserverFlag = 1;
includeGroundDistanceColumn=1
[summaryTbl, displayTbl] = build_quad_ground_truth_display_table(QuadCsv, outFile, ObserverFlag,includeGroundDistanceColumn);

