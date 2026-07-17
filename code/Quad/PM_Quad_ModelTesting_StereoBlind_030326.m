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

%QuadFile='QuadStudy0115.csv'
QuadFile='AllStereoQuadDataLong030326_with_NormedScore.csv'

% %%
all_quad_data=readtable(fullfile(QuadExpDir,QuadFile));
QuadBasename = [erase(QuadFile,'.csv')] ;


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
nIterations=100;
QuadFraction=.8;
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
perceptual_Tblname=sprintf('%s_quad_training_perceptual_%d_iterations_lme_summary',QuadBasename,nIterations);
perceptual_outCsvFile=fullfile(ResultsDir,[perceptual_Tblname '.csv'] );
writetable(all_perceptual_training_Tbl,perceptual_outCsvFile);

% testing data with estimates
perceptual_testing_Tblname=sprintf('%s_quad_testing_perceptual_%d_iterations_lme_summary',QuadBasename,nIterations);
perceptual_testing_outCsvFile=fullfile(ResultsDir,[perceptual_testing_Tblname '.csv'] );
writetable(all_perceptual_testing_Tbl,perceptual_testing_outCsvFile);

figName='Perceptual'
% compare mean error across models
perceptual_testing_png=fullfile(ResultsDir,[perceptual_testing_Tblname '.png'] );

Param='Real_Visual_Angle';
saveFilename=fullfile(ResultsDir,[perceptual_testing_Tblname '_by_VisualAngle.png'] );
%[SummaryItrParam, SummaryParam, fh] = plot_MeanPredictedvsReportedPMbyParam(all_perceptual_testing_Tbl,Param, saveFilename, figName,'sd')
%[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin] = plot_MeanPredictedvsReportedPMbyParamwithMSE(all_perceptual_testing_Tbl, Param, saveFilename, figName,'sd');
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_perceptual_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Distance';
saveFilename=fullfile(ResultsDir,[perceptual_testing_Tblname '_by_Distance.png'] );
%[SummaryItrParam, SummaryParam, fh] = plot_MeanPredictedvsReportedPMbyParam(all_perceptual_testing_Tbl,Param, saveFilename, figName,'sd')
%[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin] = plot_MeanPredictedvsReportedPMbyParamwithMSE(all_perceptual_testing_Tbl, Param, saveFilename, figName,'sd');
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_perceptual_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Elevation';
saveFilename=fullfile(ResultsDir,[perceptual_testing_Tblname '_by_Elevation.png'] );
%[SummaryItrParam, SummaryParam, fh] = plot_MeanPredictedvsReportedPMbyParam(all_perceptual_testing_Tbl,Param, saveFilename, figName,'sd')
%[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin] = plot_MeanPredictedvsReportedPMbyParamwithMSE(all_perceptual_testing_Tbl, Param, saveFilename, figName,'sd');
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_perceptual_testing_Tbl, Param, saveFilename, figName, 'sd')

perceptual_outFigName=fullfile(ResultsDir,[perceptual_Tblname '.png'] );
[perceptual_outTbl,fh] = PM_plot_meanLMEcoeffsI(all_summarylmeTbl_perceptual,perceptual_Tblname,perceptual_outFigName);

perceptual_outCsvFile=fullfile(ResultsDir,['mean_' perceptual_Tblname '.csv'] );
writetable(perceptual_outTbl,perceptual_outCsvFile);
% no intercepts
perceptual_outFigName=fullfile(ResultsDir,[perceptual_Tblname 'noIntercepts.png'] );
[perceptual_outTbl,fh] = PM_plot_meanLMEcoeffs(all_summarylmeTbl_perceptual,perceptual_Tblname,perceptual_outFigName); % sans intercept


%%
% adjusted
%training data
adjusted_Tblname=sprintf('%s_quad_training_adjusted_%d_iterations_lme_summary',QuadBasename,nIterations);
adjusted_outCsvFile=fullfile(ResultsDir,[adjusted_Tblname '.csv'] );
writetable(all_adjusted_training_Tbl,adjusted_outCsvFile);

% testing data with estimates
adjusted_testing_Tblname=sprintf('%s_quad_testing_adjusted_%d_iterations_lme_summary',QuadBasename,nIterations);
adjusted_testing_outCsvFile=fullfile(ResultsDir,[adjusted_testing_Tblname '.csv'] );
writetable(all_adjusted_testing_Tbl,adjusted_testing_outCsvFile);

% compare mean error across models
figName='Adjusted'
adjusted_testing_png=fullfile(ResultsDir,[adjusted_testing_Tblname '.png'] );

% compare mean error across models
perceptual_testing_png=fullfile(ResultsDir,[adjusted_testing_Tblname '.png'] );

Param='Real_Visual_Angle';
saveFilename=fullfile(ResultsDir,[adjusted_testing_Tblname '_by_VisualAngle.png'] );
%[SummaryItrParam, SummaryParam, fh] = plot_MeanPredictedvsReportedPMbyParam(all_adjusted_testing_Tbl,Param, saveFilename, figName,'sd')
%[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin] = plot_MeanPredictedvsReportedPMbyParamwithMSE(all_adjusted_testing_Tbl, Param, saveFilename, figName,'sd');
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_adjusted_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Distance';
saveFilename=fullfile(ResultsDir,[adjusted_testing_Tblname '_by_Distance.png'] );
%[SummaryItrParam, SummaryParam, fh] = plot_MeanPredictedvsReportedPMbyParam(all_adjusted_testing_Tbl,Param, saveFilename, figName,'sd')
%[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin] = plot_MeanPredictedvsReportedPMbyParamwithMSE(all_adjusted_testing_Tbl, Param, saveFilename, figName,'sd');
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_adjusted_testing_Tbl, Param, saveFilename, figName, 'sd')

Param='Elevation';
saveFilename=fullfile(ResultsDir,[adjusted_testing_Tblname '_by_Elevation.png'] );
%[SummaryItrParam, SummaryParam, fh] = plot_MeanPredictedvsReportedPMbyParam(all_adjusted_testing_Tbl,Param, saveFilename, figName,'sd')
%[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin] = plot_MeanPredictedvsReportedPMbyParamwithMSE(all_adjusted_testing_Tbl, Param, saveFilename, figName,'sd');
[SummaryItrParam, SummaryParam, MSE_ItrParam, MSE_Itr, fh, fh_violin, PctErr_ItrParam, PctErr_Itr, fh_pctbar] = plot_MeanPredictedvsReportedPMbyParamwithMpERR(all_adjusted_testing_Tbl, Param, saveFilename, figName, 'sd')


adjusted_outFigName=fullfile(ResultsDir,[adjusted_Tblname '.png'] );
[adjusted_outTbl,fh] = PM_plot_meanLMEcoeffsI(all_summarylmeTbl_adjusted,adjusted_Tblname,adjusted_outFigName);
adjusted_outCsvFile=fullfile(ResultsDir,['mean_' adjusted_Tblname '.csv'] );
writetable(adjusted_outTbl,adjusted_outCsvFile);
% no intercepts
adjusted_outFigName=fullfile(ResultsDir,[adjusted_Tblname 'noIntercepts.png'] );
[adjusted_outTbl,fh] = PM_plot_meanLMEcoeffs(all_summarylmeTbl_adjusted,adjusted_Tblname,adjusted_outFigName); % sans intercept

% both tasks
saveFilename=fullfile(ResultsDir, sprintf('%s_quad_modelcomps_%d_iterations_lme_coeffs.png',QuadBasename,nIterations));
[statsTblP,statsTblA,fh] = PM_plot_meanLMEcoeffsI_bothtasks(all_summarylmeTbl_perceptual,all_summarylmeTbl_adjusted,saveFilename)


%%
close all

