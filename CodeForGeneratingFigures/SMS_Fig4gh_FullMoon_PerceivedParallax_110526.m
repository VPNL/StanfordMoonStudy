
%% SMS_Fig4gh_FullMoon_Parallax_110526
set(groot, 'defaultFigureVisible', 'on')
close all; clear all;
SMS_setCodePath;

expDir = paths.Project;
dataDir = fullfile(paths.Data, 'BinocularParallax');
datafile='Parallax_FullMoon_090225.csv';

dataPath = fullfile(dataDir, datafile);
if ~isfile(dataPath) && isfile([dataPath '.csv'])
    dataPath = [dataPath '.csv'];
end
[~, basename, ~] = fileparts(dataPath);

ResultsDir=fullfile(expDir, 'Figures', 'Fig4gh' );
if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end


saveLME=1; % save stats

%% Perceived parallax by elevation and PM by perceived parallax across tasks
task='Perceptual';

[models, lme_PM_by_parallax_and_task, tablewithParallax, ...
    sorteduniqueIDD, figHandles] = ...
    FullMoon_Parallax(dataDir, datafile, task, ResultsDir, saveLME);

savefile=fullfile(ResultsDir, [basename '_' task '_analysed']);
save(savefile)

close all
