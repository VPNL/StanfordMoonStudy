
%% Paper2_FullMoon_InterocularOffset_081926
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

expDir='/Users/kalanit/Projects/StanfordMoonStudy';
dataDir='/Users/kalanit/Projects/StanfordMoonStudy/Data/OcularOffset/';
datafile='FullMoonDataLong090225.csv';


datafile='Disparity_BothElevations_FullMoonDataLong090225';
dataPath = fullfile(dataDir, datafile);
if ~isfile(dataPath) && isfile([dataPath '.csv'])
    dataPath = [dataPath '.csv'];
end
[~, basename, ~] = fileparts(dataPath);

ResultsDir=fullfile(expDir, 'Figures', 'Fig4d' );
if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end


saveLME=1; % save stats

%% Perceived Interocular Offset and Perceptual Magnification
task='Perceptual';

[feEfxRP, feNamesRP, festatsRP, reEfxRP, reNamesRP, reStatsRP, moonModels, figh, disparity_data] = ...
    FullMoon_PMvInterOcularOffset(dataDir, datafile, task, ResultsDir, saveLME, [], []);

uniqueDate=unique(disparity_data.Date);
disp('dates'); disp(uniqueDate)
IDD=disparity_data.ID;
uniqueIDD=unique(IDD);
nsubjectsD=length(uniqueIDD);
fprintf('%d subjects for full moon interocular-offset data\n ',nsubjectsD);




%% test if effect of disparity varies by task
all_data=readtable(dataPath);
all_data=all_data(~isnan(all_data.Reported_Visual_Angle),:);
all_data.ID=categorical(all_data.ID);
all_data.PerceivedInterocularOffset=all_data.Disparity_VA-all_data.Real_Visual_Angle;
keep=isfinite(all_data.Ratio_Visual_Angle) & isfinite(all_data.PerceivedInterocularOffset);
all_data=all_data(keep,:);

lme_PM_by_offset_and_task = fitlme(all_data,'Ratio_Visual_Angle ~ PerceivedInterocularOffset*Task + (1|ID)');

if saveLME
     savelmefile=fullfile(ResultsDir, [basename  '_lme_moon_PM_vs_interocularOffset_and_task.txt']);
     reportOpts=struct();
     reportOpts.ReportTitle='Full Moon PM by Interocular Offset and Task LME Report';
     reportOpts.GeneratedBy='Paper2_FullMoon_InterocularOffset_081926';
     reportOpts.SourceFile=dataPath;
     reportOpts.ModelLabel='Perceptual magnification predicted by perceived interocular offset and task';
     reportOpts.SummaryLines={
         'Experiment: Full Moon'
         sprintf('Rows in task-comparison model: %d', height(all_data))
         sprintf('Participants in task-comparison model: %d', numel(unique(all_data.ID)))
         'Perceived Interocular Offset = Disparity_VA - Real_Visual_Angle'
         };
     reportOpts.RemoveGroupError=false;
     write_lme_stats_report(lme_PM_by_offset_and_task, savelmefile, reportOpts);
end


%% 




savefile=fullfile(ResultsDir, [basename '_' task '_analysed']);
save(savefile)
