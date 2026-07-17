% Combine and fit data across both experiments
close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/Modeltesting_011126'
if ~exist('ResultsDir','dir')
  mkdir(ResultsDir)
end

saveLME=1; % 1 save files; 0 don't save 
%%  generate combined and make all distances to meters
%  the moon data is in km and the quad data is in cm a

MoonExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments';
MoonFile='FullMoonDataLong090225.csv'
all_moon_data=readtable(fullfile(MoonExpDir,MoonFile));
MoonBasename = [erase(MoonFile,'.csv')] ;

% moon study
colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'}
% transform moon distances from km to meters
moon_subset_data=table(all_moon_data.ID, all_moon_data.Real_Visual_Angle,1000*all_moon_data.Distance,all_moon_data.Elevation,...
                       all_moon_data.Task, all_moon_data.Reported_Visual_Angle, all_moon_data.Ratio_Visual_Angle, all_moon_data.Disparity_VA,...
                      'VariableNames',colNames);
hh=height(moon_subset_data);
for h=1:hh
    moon_subset_data.Study(h)={'MoonStudy'};
end


% quad study
% set dirs
QuadExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
%QuadFile='AllQuadDataLong916.csv'
QuadFile='FinalQuadProcessedData109.csv'

all_quad_data=readtable(fullfile(QuadExpDir,QuadFile));
QuadBasename = [erase(QuadFile,'.csv')] ;

% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task
ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  


quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,all_quad_data.Disparity_VA_1,...
                       'VariableNames',colNames);
hh=height(quad_subset_data);
for h=1:hh
    quad_subset_data.Study(h)={'QuadStudy'};
end
%% the purpose of this section is to have about the same number of participants per experimental condition 
% this is important for the moon data as for the moon we have a  lot of
% subjects in similar visual angle and distances and only varying
% elevations; so to have a more balanced fitting and testing we are going
% to equalize both number of subjects per condition across moon and quad
% for training and also approximately equalize the number of subjects per
% condition for testing; 

VAs=unique(quad_subset_data.Real_Visual_Angle);
for d=1:numel(VAs)
    jj=find(quad_subset_data.Real_Visual_Angle==VAs(d));
    subjPerVA(d)=numel(unique(quad_subset_data.ID(jj)));
end
meansubjVA=round(mean(subjPerVA));

Elevations=unique(quad_subset_data.Elevation);
for d=1:numel(Elevations)
    jj=find(quad_subset_data.Elevation==Elevations(d));
    subjPerE(d)=numel(unique(quad_subset_data.ID(jj)));
end
meansubjE=round(mean(subjPerE));

Distances=unique(quad_subset_data.Distance);
for d=1:numel(Distances)
    jj=find(quad_subset_data.Distance==Distances(d));
    subjPerDistance(d)=numel(unique(quad_subset_data.ID(jj)));
end
meansubjDistance=round(mean(subjPerDistance));
meansubPerCond=max([meansubjVA meansubjE meansubjDistance])
nIDmoon=numel(unique(moon_subset_data.ID))
nIDquad=numel(unique(quad_subset_data.ID))
moontrainingFraction=meansubPerCond/nIDmoon;
QuadFraction=.8;
remainder=(1-moontrainingFraction)*nIDmoon;



%% model fitting and testing across random subsets of the data
all_adjusted_Tbl=[];all_perceptual_Tbl=[]; 
nIterations=1;
for itr=1:nIterations
    [quad_training, quad_testing, keepIDs] = splitTablebyRandomIDs(quad_subset_data, QuadFraction);
    [moon_training, moon_rem, keepIDs] = splitTablebyRandomIDs(moon_subset_data, moontrainingFraction);
    [moon_testing, moon_rem2, keepIDs] = splitTablebyRandomIDs(moon_rem, 1-QuadFraction);
    combined_training_data=[quad_training;moon_training];
    combined_testing_data=[quad_testing; moon_testing];
    combined_training_name=sprintf('combined_training_I%d',itr);
    combined_testing_name=sprintf('combined_testing_I%d',itr);
    if itr==1 % plot testing and training range of parameters for an example iteration
        plot_VA_D_E_parameters(combined_training_data,combined_training_name,ResultsDir);
        plot_VA_D_E_parameters(combined_testing_data,combined_testing_name,ResultsDir);
    end
        % now split table by task
    [combined_training_data_perceptual,combined_training_data_adjusted] = splitTablebyTask(combined_training_data);
    [combined_testing_data_adjusted,combined_testing_data_adjusted] = splitTablebyTask(combined_testing_data);

    % let's estimate all lmes for  perceptual case
    [combined_perceptual_lme_logPM_by_logAngle,combined_perceptual_lme_logPM_by_logDistance,combined_perceptual_lme_logPM_by_logElevation,...
    combined_perceptual_lme_logPM_by_logAngleNDistance, combined_perceptual_lme_logPM_by_logAngleNElevation, combined_perceptual_lme_logPM_by_logDistanceNElevation,...
    combined_perceptual_lme_logPM_by_logAngleNDistanceNElevation]=PM_lmes(combined_training_data_perceptual,combined_training_name);
   
    summaryTbl_perceptual = Quad_export_LME_summary_csv('combined_training', 'perceptual',...
    combined_perceptual_lme_logPM_by_logAngle, combined_perceptual_lme_logPM_by_logDistance, combined_perceptual_lme_logPM_by_logElevation, ...
    combined_perceptual_lme_logPM_by_logAngleNDistance, combined_perceptual_lme_logPM_by_logAngleNElevation, combined_perceptual_lme_logPM_by_logDistanceNElevation, ...
    combined_perceptual_lme_logPM_by_logAngleNDistanceNElevation);
    
    summaryTbl_perceptual.Iteration = repmat(double(itr), height(summaryTbl_perceptual), 1);
    all_perceptual_Tbl=[all_perceptual_Tbl; summaryTbl_perceptual];

    % let's estimate for adjusted case
    [combined_adjusted_lme_logPM_by_logAngle,combined_adjusted_lme_logPM_by_logDistance,combined_adjusted_lme_logPM_by_logElevation,...
    combined_adjusted_lme_logPM_by_logAngleNDistance, combined_adjusted_lme_logPM_by_logAngleNElevation, combined_adjusted_lme_logPM_by_logDistanceNElevation,...
    combined_adjusted_lme_logPM_by_logAngleNDistanceNElevation]=PM_lmes(combined_training_data_adjusted,combined_training_name);
    summaryTbl_adjusted = Quad_export_LME_summary_csv('combined_training', 'adjusted',...
    combined_adjusted_lme_logPM_by_logAngle, combined_adjusted_lme_logPM_by_logDistance, combined_adjusted_lme_logPM_by_logElevation, ...
    combined_adjusted_lme_logPM_by_logAngleNDistance, combined_adjusted_lme_logPM_by_logAngleNElevation, combined_adjusted_lme_logPM_by_logDistanceNElevation, ...
    combined_adjusted_lme_logPM_by_logAngleNDistanceNElevation);
    summaryTbl_adjusted.Iteration = repmat(double(itr), height(summaryTbl_adjusted), 1);
    all_adjusted_Tbl=[all_adjusted_Tbl; summaryTbl_adjusted];

end
%% save results and figures
% perceptual
perceptual_Tblname=sprintf('combined_training_perceptual_%diterations_lme_summary',nIterations);
perceptual_outCsvFile=fullfile(ResultsDir,[perceptual_Tblname '.csv'] );
writetable(all_perceptual_Tbl,perceptual_outCsvFile);
perceptual_outFigName=fullfile(ResultsDir,[perceptual_Tblname '.png'] );
[perceptual_outTbl,fh] = PM_plot_meanLMEcoeffsI( all_perceptual_Tbl,perceptual_Tblname,perceptual_outFigName);
perceptual_outCsvFile=fullfile(ResultsDir,['mean_' perceptual_Tblname '.csv'] );
writetable(perceptual_outTbl,perceptual_outCsvFile);
% no intercepts
perceptual_outFigName=fullfile(ResultsDir,[perceptual_Tblname 'noIntercepts.png'] );
[perceptual_outTbl,fh] = PM_plot_meanLMEcoeffs( all_perceptual_Tbl,perceptual_Tblname,perceptual_outFigName); % sans intercept

% adjusted
adjusted_Tblname=sprintf('combined_training_adjusted_%diterations_lme_summary',nIterations);
adjusted_outCsvFile=fullfile(ResultsDir,[adjusted_Tblname '.csv'] );
writetable(all_adjusted_Tbl,adjusted_outCsvFile);

adjusted_outFigName=fullfile(ResultsDir,[adjusted_Tblname '.png'] );
[adjusted_outTbl,fh] = PM_plot_meanLMEcoeffsI( all_adjusted_Tbl,adjusted_Tblname,adjusted_outFigName);
adjusted_outCsvFile=fullfile(ResultsDir,['mean_' adjusted_Tblname '.csv'] );
writetable(adjusted_outTbl,adjusted_outCsvFile);
% no intercepts
adjusted_outFigName=fullfile(ResultsDir,[adjusted_Tblname 'noIntercepts.png'] );
[adjusted_outTbl,fh] = PM_plot_meanLMEcoeffs( all_adjusted_Tbl,adjusted_Tblname,adjusted_outFigName); % sans intercept


% 

outFigName=fullfile(ResultsDir,sprintf('combined_training_bothtasks_%diterations_lme_summary.png',nIterations));
[statsTblP,statsTblA,fh] = PM_plot_meanLMEcoeffsI_bothtasks(all_perceptual_Tbl,all_adjusted_Tbl,outFigName)
%%
%close all

