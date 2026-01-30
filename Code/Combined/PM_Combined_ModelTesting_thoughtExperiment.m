 close all; clear all;
%
% Thought experiment
% estimate effectived distance for PM for Perceptual and Adjusted cases
% distance only model
% PM=I*D^de
% D=(PM/I)^(1/de);
I=2^-0.65; de=0.3; PM=4.1;
D=(PM/I)^(1/de);
fprintf('perceptual: effective D=(PM/I)^(1/de): %.1f[m]\n',D)

% Adjusted case
I=2^-0.096; de=0.054; PM=1.96;
D=(PM/I)^(1/de);
fprintf('adjusted:   effective D=(PM/I)^(1/de): %.1f [m]\n',D)

% D=885755.6
% full model based on QuadStudy0115	


% PM=I*(VA^vae)*((1+E)^ee)*(D^de)
% D=[PM/(I*(VA^vae)*((1+E)^ee)]^(1/de)
%
% Perceptual case
% PM magnification of moon VA=0.5 at an E=2.5 is 4.1
%
% I=2^-1.07=0.4763
% vae=-0.12
% de=0.33
% ee=0.12
% D=495.2728;


% Adjusted case
% PM magnification of moon VA=0.5 at an E=2.5 is 1.96
VA=0.5; E=2.5; PM= 4.1; I=2^-1.07; vae=-0.12; de=0.33; ee=0.12;
D=[PM/(I*(VA^vae)*((1+E)^ee))]^(1/de);
fprintf('perceptual: effective D=[PM/(I*(VA^vae)*((1+E)^ee))]^(1/de): %.1f [m]\n',D)


% D=335.4898
% adjusted case
% PM magnification of moon VA=0.5 at an E=2.5 is 1.96
% I=2^-0.816=0.568
% vae=-0.122
% de=0.111
% ee=0.18
%
% D=4293.2
VA=0.5; E=2.5; PM= 1.96; I=2^-0.816; vae=-0.122; de=0.111; ee=0.18;
D=[PM/(I*(VA^vae)*((1+E)^ee))]^(1/de);

fprintf('adjusted:   effective D=[PM/(I*(VA^vae)*((1+E)^ee))]^(1/de): %.1f [m]\n',D)





%% Paths & parameters
codeDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir));

ResultsDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/test012226';
if ~exist(ResultsDir,'dir')
mkdir(ResultsDir);
end

nIterations  = 100;
QuadFraction = 0.8;
saveLME      = 1; 

% Tasks: must match the labels returned/used by splitTablebyTask
Tasks    = {'Perceptual','Adjusted'};

% Storage struct (one field per task)
R = struct();
for t = 1:numel(Tasks)
taskName = Tasks{t};
R.(taskName).all_testing_Tbl   = [];
R.(taskName).all_training_Tbl  = [];
R.(taskName).all_summarylmeTbl = [];
end

%% Build combined dataset (moon + quad) and ensure all distances are in meters 
MoonExpDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments';
MoonFile   = 'FullMoonDataLong090225.csv';
all_moon_data = readtable(fullfile(MoonExpDir, MoonFile));

MoonBasename = erase(MoonFile,'.csv');
colNames = {'ID','Real_Visual_Angle','Distance','Elevation', ...
        'Task','Reported_Visual_Angle','Ratio_Visual_Angle','Disparity_VA'};

% Moon distances: km -> meters
moon_subset_data = table(all_moon_data.ID, ...
all_moon_data.Real_Visual_Angle, ...
1000*all_moon_data.Distance, ...
all_moon_data.Elevation, ...
all_moon_data.Task, ...
all_moon_data.Reported_Visual_Angle, ...
all_moon_data.Ratio_Visual_Angle, ...
all_moon_data.Disparity_VA, ...
'VariableNames', colNames);

moon_subset_data.Study = repmat({'MoonStudy'}, height(moon_subset_data), 1);

% Quad study
QuadExpDir = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
QuadFile   = 'QuadStudy0115.csv';
all_quad_data = readtable(fullfile(QuadExpDir, QuadFile));
QuadBasename = erase(QuadFile,'.csv');

% Remove subject 26 who is an outlier (did not follow instructions in the adjusted task)
all_quad_data = all_quad_data(all_quad_data.ID ~= 26, :);

% Quad distances: cm -> meters
quad_subset_data = table(all_quad_data.ID, ...
all_quad_data.Real_Visual_Angle, ...
all_quad_data.Distance/100, ...
all_quad_data.Elevation, ...
all_quad_data.Task, ...
all_quad_data.Reported_Visual_Angle, ...
all_quad_data.Ratio_Visual_Angle, ...
all_quad_data.Disparity_VA_1, ...
'VariableNames', colNames);

quad_subset_data.Study = repmat({'QuadStudy'}, height(quad_subset_data), 1);
combinedBasename = sprintf('%s_%s', MoonBasename, QuadBasename);

%% Balance moon training fraction to reduce over-representation in dense conditions
VAs = unique(quad_subset_data.Real_Visual_Angle);
subjPerVA = nan(numel(VAs),1);
for d = 1:numel(VAs)
jj = quad_subset_data.Real_Visual_Angle == VAs(d);
subjPerVA(d) = numel(unique(quad_subset_data.ID(jj)));
end
meansubjVA = round(mean(subjPerVA));

Elevations = unique(quad_subset_data.Elevation);
subjPerE = nan(numel(Elevations),1);
for d = 1:numel(Elevations)
jj = quad_subset_data.Elevation == Elevations(d);
subjPerE(d) = numel(unique(quad_subset_data.ID(jj)));
end
meansubjE = round(mean(subjPerE));

Distances = unique(quad_subset_data.Distance);
subjPerDistance = nan(numel(Distances),1);
for d = 1:numel(Distances)
jj = quad_subset_data.Distance == Distances(d);
subjPerDistance(d) = numel(unique(quad_subset_data.ID(jj)));
end
meansubjDistance = round(mean(subjPerDistance));

meansubPerCond = max([meansubjVA meansubjE meansubjDistance]);

nIDmoon = numel(unique(moon_subset_data.ID));
moontrainingFraction = meansubPerCond / nIDmoon;
moontrainingFraction = max(0, min(1, moontrainingFraction)); % safety clamp

%% Model fitting and testing across random subsets of the data separately per tasks
Hypothetical_moonD=[335 500 4000];
for hd=1:numel(Hypothetical_moonD) % loop on hypothetical distanmnces
    H_moodD=Hypothetical_moonD(hd);
    moon_subset_data.Distance(:)=H_moodD; % substitute real distance with hypothetical distance
    ResultsDir = sprintf('/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/test_%d',H_moodD);
    if ~exist(ResultsDir,'dir')
     mkdir(ResultsDir);
    end
    for itr = 1:nIterations
    
        % Split by IDs ONCE per study and iteration
        [quad_training, quad_testing] = splitTablebyRandomIDs(quad_subset_data, QuadFraction);
        [moon_training, moon_testing] = splitTablebyRandomIDs(moon_subset_data, moontrainingFraction);
    
        combined_training_data = [quad_training; moon_training];
        combined_testing_data  = [quad_testing;  moon_testing];
    
       
        % Split training and testing by task (once)
        [trainP, trainA] = splitTablebyTask(combined_training_data);
        [testP,  testA ] = splitTablebyTask(combined_testing_data);
    
        % Map tables by task for clean looping
        trainByTask = struct('Perceptual', trainP, 'Adjusted', trainA);
        testByTask  = struct('Perceptual', testP,  'Adjusted', testA);
    
        for t = 1:numel(Tasks)
           
            taskName = Tasks{t}; 
            trainTbl = trainByTask.(taskName);
            testTbl  = testByTask.(taskName);
    
            % Fit the 7 LMEs on training data
            %[lme1,lme2,lme3,lme4,lme5,lme6,lme7] = PM_lmes(trainTbl, sprintf('combined_training_I%d', itr));
    
            [lme_logAngle,lme_logDistance,lme_logElevation,...
            lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation,...
            lme_logAngleNDistanceNElevation]=PM_lmes(trainTbl, sprintf('combined_training_I%d', itr));
    
            
            % summaryTbl = Quad_export_LME_summary_csv('combined_training', taskName, ...
            %     lme1, lme2, lme3, lme4, lme5, lme6, lme7);
    
            % Summarize coefficients
            summaryTbl = Quad_export_LME_summary_csv('combined_training', taskName, ...
                         lme_logAngle,lme_logDistance,lme_logElevation,...
                         lme_logAngleNDistance, lme_logAngleNElevation, lme_logDistanceNElevation,...
                         lme_logAngleNDistanceNElevation);
    
           
            summaryTbl.Iteration = repmat(double(itr), height(summaryTbl), 1);
            R.(taskName).all_summarylmeTbl = [R.(taskName).all_summarylmeTbl; summaryTbl];
    
            % Estimate predictions on TESTING data
            outTbl = estimate_PM_fromlmeTbl(testTbl, summaryTbl);
            outTbl.Iteration = repmat(double(itr), height(outTbl), 1);
            R.(taskName).all_testing_Tbl = [R.(taskName).all_testing_Tbl; outTbl];
    
            % Store TRAINING data for provenance
            trainTbl.Iteration = repmat(double(itr), height(trainTbl), 1);
            R.(taskName).all_training_Tbl= [R.(taskName).all_training_Tbl; trainTbl];
        end
    end
    
    %% Save results and generate figures (loop over tasks)
    paramsToPlot = {'Real_Visual_Angle','Distance','Elevation'};
    
    for t = 1:numel(Tasks)
        taskName = Tasks{t};
    
        % training table
        training_Tblname = sprintf('%s_training_%diterations_lme_summary_combined_training_%s', ...
            taskName, nIterations, combinedBasename);
        writetable(R.(taskName).all_training_Tbl, fullfile(ResultsDir, [training_Tblname '.csv']));
    
        % testing table
        testing_Tblname = sprintf('%s_testing_%diterations_lme_summary_combined_training_%s', ...
            taskName, nIterations, combinedBasename);
        writetable(R.(taskName).all_testing_Tbl, fullfile(ResultsDir, [testing_Tblname '.csv']));
    
       
        % Plot coefficients & export mean table
        Tblname = sprintf('%s_%diterations_lme_summary_combined_training_%s', ...
            taskName, nIterations, combinedBasename);
    
      
        coefVars = {'Intercept','VAe','De','Ee'};
        plotCoefVars = {'Intercept', 'VAe', 'De','Ee'}
        outFigName = fullfile(ResultsDir, [Tblname '.png']);
        [outTbl, fh] = PM_plot_meanLMEcoeffs(R.(taskName).all_summarylmeTbl, Tblname, outFigName,coefVars, plotCoefVars);
    
        writetable(outTbl, fullfile(ResultsDir, ['mean_' Tblname '.csv']));
    
        % Plot coefficients without intercepts
        outFigNameNoI = fullfile(ResultsDir, [Tblname 'noIntercepts.png']);
        PM_plot_meanLMEcoeffs(R.(taskName).all_summarylmeTbl, Tblname, outFigNameNoI);
    end

%% Both tasks coefficient comparison
saveFilename = fullfile(ResultsDir, sprintf('bothtasks_lme_coeffs_%diterations_combined_%s.png', ...
    nIterations, combinedBasename));
PM_plot_meanLMEcoeffsI_bothtasks(R.Perceptual.all_summarylmeTbl, R.Adjusted.all_summarylmeTbl, saveFilename);

%% Binned plots (minNID)
minNID = 20;
for t = 1:numel(Tasks)
    taskName = Tasks{t};
    figName  = sprintf('%s_%dminNID', taskName, minNID);
    for p = 1:numel(paramsToPlot)
        Param = paramsToPlot{p};
        saveFilename = fullfile(ResultsDir, sprintf('%s_%diterations_%s_combined_%s.png', ...
            figName, nIterations, Param, combinedBasename));
        plot_MeanPredictedvsReportedPMbyParamwithMpERR_minNID(R.(taskName).all_testing_Tbl, Param, minNID, saveFilename, figName, 'sd');
    end
end
%%
close all;
end
saveFilename = fullfile(ResultsDir, sprintf('%diterations_%s_combined_%s.png',nIterations, Param, combinedBasename));
save(saveFilename)