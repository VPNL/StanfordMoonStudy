% Combine and fit data across both experiments
close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Paper_Fig3_Modeltesting_011826'

if ~exist('ResultsDir','dir')
  mkdir(ResultsDir)
end

saveLME=1; % 1 save files; 0 don't save 
% 
% quad study
% set dirs
QuadExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
QuadFile='QuadStudy0115.csv'
all_quad_data=readtable(fullfile(QuadExpDir,QuadFile));
QuadBasename = [erase(QuadFile,'.csv')] ;

nIterations=100;
QuadFraction=.8;

%%

% remove subject 26 who is an outlier because did not follow the
% instructions in the adjusted task
ii=find(all_quad_data.ID~=26); 
all_quad_data=all_quad_data(ii,:);  

colNames=   {'ID', 'Real_Visual_Angle','Distance','Elevation' ,...
            'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'};

quad_subset_data=table(all_quad_data.ID,all_quad_data.Real_Visual_Angle,all_quad_data.Distance/100, all_quad_data.Elevation,...
                       all_quad_data.Task, all_quad_data.Reported_Visual_Angle,all_quad_data.Ratio_Visual_Angle,all_quad_data.Disparity_VA_1,...
                       'VariableNames',colNames);
hh=height(quad_subset_data);
for h=1:hh
    quad_subset_data.Study(h)={'QuadStudy'};
end


%% model fitting and testing across random subsets of the data
all_adjusted_testing_Tbl=[];all_perceptual_testing_Tbl=[]; 
all_adjusted_training_Tbl=[];all_perceptual_training_Tbl=[]; 
all_summarylmeTbl_adjusted=[]; all_summarylmeTbl_perceptual=[];  

tasks=flipud(sort(unique(quad_subset_data.Task)));

for itr=1:nIterations
    [quad_training_data, quad_testing_data, keepIDs] = splitTablebyRandomIDs(quad_subset_data, QuadFraction);
    
    quad_training_name=sprintf('quad_training_I%d',itr);
    quad_testing_name=sprintf('quad_testing_I%d',itr);
    if itr==1 % plot testing and training range of parameters for an example iteration
         plot_VA_D_E_parameters(quad_training_data,quad_training_name,ResultsDir);
         plot_VA_D_E_parameters(quad_testing_data,quad_testing_name,ResultsDir);
     end
        % now split table by task
    [quad_training_data_perceptual,quad_training_data_adjusted] = splitTablebyTask(quad_training_data);
    [quad_testing_data_perceptual,quad_testing_data_adjusted] = splitTablebyTask(quad_testing_data);

    % let's estimate all lmes for  perceptual case
    [quad_perceptual_lme_logPM_by_logAngle,quad_perceptual_lme_logPM_by_logDistance,quad_perceptual_lme_logPM_by_logElevation,...
    quad_perceptual_lme_logPM_by_logAngleNDistance, quad_perceptual_lme_logPM_by_logAngleNElevation, quad_perceptual_lme_logPM_by_logDistanceNElevation,...
    quad_perceptual_lme_logPM_by_logAngleNDistanceNElevation]=PM_lmes(quad_training_data_perceptual,quad_training_name);
   
    summarylmeTbl_perceptual = Quad_export_LME_summary_csv('quad_training', 'perceptual',...
    quad_perceptual_lme_logPM_by_logAngle, quad_perceptual_lme_logPM_by_logDistance, quad_perceptual_lme_logPM_by_logElevation, ...
    quad_perceptual_lme_logPM_by_logAngleNDistance, quad_perceptual_lme_logPM_by_logAngleNElevation, quad_perceptual_lme_logPM_by_logDistanceNElevation, ...
    quad_perceptual_lme_logPM_by_logAngleNDistanceNElevation);
   
    summarylmeTbl_perceptual.Iteration = repmat(double(itr), height(summarylmeTbl_perceptual), 1);
    all_summarylmeTbl_perceptual= [all_summarylmeTbl_perceptual;  summarylmeTbl_perceptual];
    [outTbl_perceptual]=estimate_PM_fromlmeTbl(quad_testing_data_perceptual,summarylmeTbl_perceptual);
    outTbl_perceptual.Iteration=repmat(double(itr), height(outTbl_perceptual), 1);
    all_perceptual_testing_Tbl=[all_perceptual_testing_Tbl; outTbl_perceptual];

    quad_training_data_perceptual.Iteration=repmat(double(itr),height(quad_training_data_perceptual), 1);
    all_perceptual_training_Tbl=[all_perceptual_training_Tbl; quad_training_data_perceptual];

    % let's estimate all lmes for  adjusted case
    [quad_adjusted_lme_logPM_by_logAngle,quad_adjusted_lme_logPM_by_logDistance,quad_adjusted_lme_logPM_by_logElevation,...
    quad_adjusted_lme_logPM_by_logAngleNDistance, quad_adjusted_lme_logPM_by_logAngleNElevation,...
    quad_adjusted_lme_logPM_by_logDistanceNElevation,...
    quad_adjusted_lme_logPM_by_logAngleNDistanceNElevation]=PM_lmes(quad_training_data_adjusted,quad_training_name);
   
    summarylmeTbl_adjusted = Quad_export_LME_summary_csv('quad_training', 'adjusted',...
    quad_adjusted_lme_logPM_by_logAngle, quad_adjusted_lme_logPM_by_logDistance, quad_adjusted_lme_logPM_by_logElevation, ...
    quad_adjusted_lme_logPM_by_logAngleNDistance, quad_adjusted_lme_logPM_by_logAngleNElevation, ...
    quad_adjusted_lme_logPM_by_logDistanceNElevation, ...
    quad_adjusted_lme_logPM_by_logAngleNDistanceNElevation);
   
    summarylmeTbl_adjusted.Iteration = repmat(double(itr), height(summarylmeTbl_adjusted), 1);
    all_summarylmeTbl_adjusted= [all_summarylmeTbl_adjusted;  summarylmeTbl_adjusted];
    [outTbl_adjusted]=estimate_PM_fromlmeTbl(quad_testing_data_adjusted,summarylmeTbl_adjusted);
    outTbl_adjusted.Iteration=repmat(double(itr), height(outTbl_adjusted), 1);
    all_adjusted_testing_Tbl=[all_adjusted_testing_Tbl; outTbl_adjusted];

    quad_training_data_adjusted.Iteration=repmat(double(itr),height(quad_training_data_adjusted), 1);
    all_adjusted_training_Tbl=[all_adjusted_training_Tbl; quad_training_data_adjusted];


end
%% save results and figures
% perceptual
%training data
perceptual_training_Tblname=sprintf('perceptual_training_%diterations_lme_summary_%s',nIterations,QuadBasename);
perceptual_outCsvFile=fullfile(ResultsDir,[perceptual_training_Tblname '.csv'] );
writetable(all_perceptual_training_Tbl,perceptual_outCsvFile);

% testing data with estimates
perceptual_testing_Tblname=sprintf('perceptual_testing_%diterations_lme_summary_%s',nIterations,QuadBasename);
perceptual_testing_outCsvFile=fullfile(ResultsDir,[perceptual_testing_Tblname '.csv'] );
writetable(all_perceptual_testing_Tbl,perceptual_testing_outCsvFile);


figName='Perceptual';
Param='Real_Visual_Angle';
saveFilename=sprintf('%s_%diterations_%s_%s.png',figName,nIterations,Param,QuadBasename);
saveFilename=fullfile(ResultsDir,saveFilename );

[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr,...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_perceptual_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Distance';
saveFilename=sprintf('%s_%diterations_%s_%s.png',figName,nIterations,Param,QuadBasename);
saveFilename=fullfile(ResultsDir,saveFilename );
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr,...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_perceptual_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Elevation';
saveFilename=sprintf('%s_%diterations_%s_%s.png',figName,nIterations,Param,QuadBasename);
saveFilename=fullfile(ResultsDir,saveFilename );
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr,...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_perceptual_testing_Tbl, Param, saveFilename, figName, 'sd')


perceptual_Tblname=sprintf('Perceptual_%diterations_lme_summary_%s',nIterations,QuadBasename);
perceptual_outFigName=fullfile(ResultsDir,[perceptual_Tblname '.png'] );
[perceptual_outTbl,fh] = PM_plot_meanLMEcoeffsI(all_summarylmeTbl_perceptual,perceptual_Tblname,perceptual_outFigName);


perceptual_outFigName=fullfile(ResultsDir,[perceptual_Tblname '.png'] );

perceptual_outCsvFile=fullfile(ResultsDir,['mean_' perceptual_Tblname '.csv'] );
writetable(perceptual_outTbl,perceptual_outCsvFile);
% no intercepts
perceptual_outFigName=fullfile(ResultsDir,[perceptual_Tblname '_noIntercepts.png'] );
[perceptual_outTbl,fh] = PM_plot_meanLMEcoeffs(all_summarylmeTbl_perceptual,perceptual_Tblname,perceptual_outFigName); % sans intercept


%%
% adjusted
%training data

adjusted_training_Tblname=sprintf('adjusted_training_%d_iterations_lme_summary_%s', nIterations,QuadBasename);
adjusted_outCsvFile=fullfile(ResultsDir,[adjusted_training_Tblname '.csv'] );
writetable(all_adjusted_training_Tbl,adjusted_outCsvFile);

% testing data with estimates
adjusted_testing_Tblname=sprintf('adjusted_testing_%d_iterations_lme_summary_%s', nIterations,QuadBasename);
adjusted_testing_outCsvFile=fullfile(ResultsDir,[adjusted_testing_Tblname '.csv'] );
writetable(all_adjusted_testing_Tbl,adjusted_testing_outCsvFile);

figName='Adjusted';
Param='Real_Visual_Angle';
saveFilename=sprintf('%s_%diterations_%s_%s.png',figName,nIterations,Param,QuadBasename);
saveFilename=fullfile(ResultsDir,saveFilename );
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, ....
    fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_adjusted_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Distance';
saveFilename=sprintf('%s_%diterations_%s_%s.png',figName,nIterations,Param,QuadBasename);
saveFilename=fullfile(ResultsDir,saveFilename );
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, ...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_adjusted_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Elevation';
saveFilename=sprintf('%s_%diterations_%s_%s.png',figName,nIterations,Param,QuadBasename);
saveFilename=fullfile(ResultsDir,saveFilename );
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr,....
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_adjusted_testing_Tbl, Param, saveFilename, figName, 'sd')


adjusted_Tblname=sprintf('adjusted_%diterations_lme_summary_%s',nIterations,QuadBasename);
adjusted_outFigName=fullfile(ResultsDir,[adjusted_Tblname '.png'] );
[adjusted_outTbl,fh] = PM_plot_meanLMEcoeffsI(all_summarylmeTbl_adjusted,adjusted_Tblname,adjusted_outFigName);
adjusted_outCsvFile=fullfile(ResultsDir,['mean_' adjusted_Tblname '.csv'] );
writetable(adjusted_outTbl,adjusted_outCsvFile);
% no intercepts
adjusted_outFigName=fullfile(ResultsDir,[adjusted_Tblname 'noIntercepts.png'] );
[adjusted_outTbl,fh] = PM_plot_meanLMEcoeffs(all_summarylmeTbl_adjusted,adjusted_Tblname,adjusted_outFigName); % sans intercept

% both tasks
saveFilename=fullfile(ResultsDir, sprintf('both_tasks_%diterations_lme_coeffs_%s.png',nIterations,QuadBasename));
[statsTblP,statsTblA,fh] = PM_plot_meanLMEcoeffsI_bothtasks(all_summarylmeTbl_perceptual,all_summarylmeTbl_adjusted,saveFilename)


%%
%% now binned values 
minNID=20;
figName=sprintf('Perceptual_%dminNID',minNID);

Param='Real_Visual_Angle';
saveFilename=sprintf('%s_%diterations_%s_%s',figName,nIterations,Param,QuadBasename)
saveFilename=fullfile(ResultsDir,[saveFilename,'.png'] );
[SummaryItrParambinned, SummaryParambinned, MSE_ItrParam, MSE_Itr, ...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(all_perceptual_testing_Tbl, Param, minNID, saveFilename, figName, 'sd')

Param='Distance';
saveFilename=sprintf('%s_%diterations_%s_%s',figName,nIterations,Param,QuadBasename)
saveFilename=fullfile(ResultsDir,[saveFilename,'.png'] );
[SummaryItrParambinned, SummaryParambinned, MSE_ItrParam, MSE_Itr, ...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(all_perceptual_testing_Tbl, Param, minNID, saveFilename, figName, 'sd')

Param='Elevation';
saveFilename=sprintf('%s_%diterations_%s_%s',figName,nIterations,Param,QuadBasename)
saveFilename=fullfile(ResultsDir,[saveFilename,'.png'] );
[SummaryItrParambinned, SummaryParambinned, MSE_ItrParam, MSE_Itr, ...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(all_perceptual_testing_Tbl, Param, minNID, saveFilename, figName, 'sd')



%% repeat with binned values
minNID=20;
figName=sprintf('Adjusted_%dminNID',minNID);

Param='Real_Visual_Angle';
saveFilename=sprintf('%s_%diterations_%s_combined_%s',figName,nIterations,Param,QuadBasename)
saveFilename=fullfile(ResultsDir,[saveFilename,'.png'] );
[SummaryItrParambinned, SummaryParambinned, MSE_ItrParam, MSE_Itr, ...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(all_adjusted_testing_Tbl, Param, minNID, saveFilename, figName, 'sd')
Param='Distance';
saveFilename=sprintf('%s_%diterations_%s_combined_%s',figName,nIterations,Param,QuadBasename)
saveFilename=fullfile(ResultsDir,[saveFilename,'.png'] );
[SummaryItrParambinned, SummaryParambinned, MSE_ItrParam, MSE_Itr, ...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(all_adjusted_testing_Tbl, Param, minNID, saveFilename, figName, 'sd')
Param='Elevation';
saveFilename=sprintf('%s_%diterations_%s_combined_%s',figName,nIterations,Param,QuadBasename)
saveFilename=fullfile(ResultsDir,[saveFilename,'.png'] );
[SummaryItrParambinned, SummaryParambinned, MSE_ItrParam, MSE_Itr, ...
    fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(all_adjusted_testing_Tbl, Param, minNID, saveFilename, figName, 'sd')



%%
close all


