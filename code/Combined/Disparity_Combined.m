% Disparity_Combined

close all; clear all;

% set code path & dirs
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir));

ResultsDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/combinedQuadMoon/SupplementalDisparityFigure122925'
if ~exist('ResultsDir','dir')
  mkdir(ResultsDir)
end

saveLME=1;

%% Read and organize Quad data
% set Quad dir& file
QuadExpDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data/';
cd(QuadExpDir)
Quadfile='AllChinRestDisparityData.csv';
QuadBasename = [erase(Quadfile,'.csv')]
% Read Quad Data
all_quad_data=readtable(Quadfile);

% Keep only quad measurements containing 'probe'
% these are the 5 probes on lamp 5
if ~ismember('Measurement', all_quad_data.Properties.VariableNames)
    error('Column "Measurement" not found in the table.');
end

measurementStr = string(all_quad_data.Measurement);
idxProbe = contains(lower(measurementStr), "probe");
all_quad_data= all_quad_data(idxProbe, :);

% Compute MeanDisparity_Minus_GT and add to table
reqVars = ["Disparity1_Minus_GT","Disparity2_Minus_GT","Elevation"];
missing = reqVars(~ismember(reqVars, all_quad_data.Properties.VariableNames));
if ~isempty(missing)
    error('Missing required columns: %s', strjoin(missing, ', '));
end

all_quad_data.MeanDisparity = mean([all_quad_data.Disparity1_Minus_GT all_quad_data.Disparity2_Minus_GT], 2, 'omitnan');


% Remove rows with missing key values
keep = ~isnan(all_quad_data.MeanDisparity) & ~isnan(all_quad_data.Elevation) ;
all_quad_data = all_quad_data(keep, :);

all_quad_data.Disparity=all_quad_data.MeanDisparity; % prepare to have the same variable names as moon

IDquad=all_quad_data.ID;
uniqueIDquad=unique(IDquad);
nSubjquad=length(uniqueIDquad);
fprintf('%d subjects for quad disparity data\n ',nSubjquad);

% calculate relative disparity
for i = 1:nSubjquad
    % Indices for this subject's random effects
   subjectRows = find(all_quad_data.ID == uniqueIDquad(i));
   meanD=mean(all_quad_data.MeanDisparity(subjectRows));
   all_quad_data.RelativeDisparity(subjectRows)=all_quad_data.MeanDisparity(subjectRows)-meanD; 
end


%% read moon data

MoonDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/'
cd(MoonDir)

Moonfile='Disparity_BothElevations_FullMoonDataLong090225';
Moonbasename = [erase( Moonfile,'.csv')] ; % for saving
all_moon_data=readtable(Moonfile);
% correct disparity by the real visual angle of the moon on the day of the
% measurement; there is one disparity measurement per elevation per
% participant

all_moon_data.Disparity=all_moon_data.Disparity_VA-all_moon_data.Real_Visual_Angle;

% calculate relative disparity

IDmoon=all_moon_data.ID;
uniqueIDmoon=unique(IDmoon);
nSubjmoon=length(uniqueIDmoon);
fprintf('%d subjects for full moon disparity data\n ',nSubjmoon);

for i = 1:nSubjmoon
    % Indices for this subject's random effects
   subjectRows = find(all_moon_data.ID == uniqueIDmoon(i));
   meanDmoon=mean(all_moon_data.Disparity(subjectRows));
   all_moon_data.RelativeDisparity(subjectRows)=all_moon_data.Disparity(subjectRows)-meanDmoon; 
end

%% Generate combined data 

colNames=   {'ID', 'Gender', 'Age','Date','Elevation','Disparity', 'RelativeDisparity', 'Real_Visual_Angle', 'Distance'}


% organize new moon subset table and transform moon distances from km to meters
moon_subset_data=table(all_moon_data.ID,all_moon_data.Gender,all_moon_data.Age, all_moon_data.Date,...
    all_moon_data.Elevation,all_moon_data.Disparity,all_moon_data.RelativeDisparity, all_moon_data.Real_Visual_Angle, 1000*all_moon_data.Distance,...
    'VariableNames',colNames)
moonfileName=fullfile(ResultsDir,[Moonbasename '.csv']);
writetable(moon_subset_data,moonfileName);


% organize new quad subset table and transform quad distances from cm to meters
quad_subset_data=table(all_quad_data.ID,all_quad_data.Gender,all_quad_data.Age, all_quad_data.Date,...
   all_quad_data.Elevation,all_quad_data.Disparity, all_quad_data.RelativeDisparity , all_quad_data.Real_Visual_Angle, 0.01*all_quad_data.Distance,...
    'VariableNames',colNames)


quadfileName=fullfile(ResultsDir,[QuadBasename '.csv']);
writetable(quad_subset_data,quadfileName);

% make combined table and write to file
combined_data=[moon_subset_data;quad_subset_data];
combined_basename=['combined_' Moonbasename '_' QuadBasename];
combinedfileName=fullfile(ResultsDir,[combined_basename  '.csv']);
writetable(combined_data,combinedfileName);


%% test if there is a relation between disparity and elevation 
lme_disparity_by_Elevation = fitlme(combined_data,'Disparity ~ Elevation  + (1|ID)')
lme_disparity_by_Elevation_RS = fitlme(combined_data,'Disparity ~ Elevation  + (Elevation|ID)')
compare_linear_disparity_models=compare(lme_disparity_by_Elevation,lme_disparity_by_Elevation_RS)
aicValue = lme_disparity_by_Elevation.ModelCriterion.AIC;
bicValue = lme_disparity_by_Elevation.ModelCriterion.BIC;
Rsq_Adjusted = lme_disparity_by_Elevation.Rsquared.Adjusted;


lme_relativedisparity_by_Elevation = fitlme(combined_data,'RelativeDisparity ~ Elevation  + (1|ID)')
lme_relativedisparity_by_Elevation_RS = fitlme(combined_data,'RelativeDisparity ~ Elevation  + (Elevation|ID)')
compare_linear_relativedisparity_models=compare(lme_relativedisparity_by_Elevation,lme_relativedisparity_by_Elevation_RS)

aicValueRD = lme_relativedisparity_by_Elevation.ModelCriterion.AIC;
bicValueRD = lme_relativedisparity_by_Elevation.ModelCriterion.BIC;
Rsq_AdjustedRD = lme_relativedisparity_by_Elevation.Rsquared.Adjusted;


if saveLME % save stats table
     savelmefile=fullfile(ResultsDir, [combined_basename '.txt']);
     diary(savelmefile)
     lme_disparity_by_Elevation
     lme_disparity_by_Elevation_RS
     compare_linear_disparity_models
     
     lme_relativedisparity_by_Elevation
     lme_relativedisparity_by_Elevation_RS
     compare_linear_relativedisparity_models
     
     fprintf('Comparing random intercepts linear models for absolute and relative disparity \n');
     fprintf('AIC                disparity:%.3f  relative disparity:%.3f\n',aicValue, aicValueRD)
     fprintf('BIC                disparity:%.3f  relative disparity:%.3f\n',bicValue, bicValueRD)
     fprintf('Adjusted R-squared dispartiy:%.3f  relative disparity:%.3f\n',Rsq_Adjusted, Rsq_AdjustedRD)
     diary off
end

%% plot data
%% Plot relative disparity
% Estimate relationship between disparity and Elevation
IDcombined=combined_data.ID;
uniqueIDcombined=unique(IDcombined);
nSubjcombined=length(uniqueIDcombined);
fprintf('%d subjects for combined disparity data\n ',nSubjcombined);


% get lme results & estimates
[reEfx,reNames,reStats] = randomEffects(lme_disparity_by_Elevation_RS);
[feEfx,feNames,festats] =fixedEffects(lme_disparity_by_Elevation_RS);

individualIntercepts = zeros(nSubjcombined,1);
individualSlopes = zeros(nSubjcombined,1);
for i = 1:nSubjcombined
    % Indices for this subject's random effects
    subjectRows = find(strcmp(reNames.Level, string(uniqueIDcombined(i)))); 
    individualIntercepts(i) = feEfx(1) + reEfx(subjectRows(1));
    individualSlopes(i)    = feEfx(2) + reEfx(subjectRows(2));
end

% sort by intercepts
[sorted_individualIntercepts, sorted_idx] = sort(individualIntercepts);

%set colormap & marker
cmap=jet(nSubjcombined);
clear subjectcolor;
markerScale=36;

for c=1:length(IDcombined)
    cindex=find(uniqueIDcombined==IDcombined(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=cmap(sorted_cindex,:);
end

%% get lme results for relative disparity

% get lme results & estimates
[reEfxRD,reNamesRD,reStatsRD] = randomEffects(lme_relativedisparity_by_Elevation_RS);
[feEfxRD,feRDNamesRD,festatsRD] =fixedEffects(lme_relativedisparity_by_Elevation_RS);

individualInterceptsRD = zeros(nSubjcombined,1);
individualSlopesRD = zeros(nSubjcombined,1);
for i = 1:nSubjcombined
    % Indices for this subject's random effects
    subjectRows = find(strcmp(reNamesRD.Level, string(uniqueIDcombined(i)))); 
    individualInterceptsRD(i) = feEfxRD(1) + reEfxRD(subjectRows(1));
    individualSlopesRD(i)    = feEfxRD(2) + reEfxRD(subjectRows(2));
end


%%

figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .6],'Name',[combined_basename 'Disparity'])
%
subplot (1,2,1)
hold on; box off
scatter(combined_data.Elevation, combined_data.Disparity ,markerScale, subjectcolor, 'o','filled');

xlabel('Elevation (degree)');
ylabel('Disparity (degree)');
set(gca,'FontSize',20,'FontName', 'Avenir')
titlestr=sprintf('Disparity=%.2f+%.2f*Elevation\n p=%.2e n=%d',feEfx(1),feEfx(2),festats.pValue(2),nSubjcombined);
title(titlestr,'FontSize',12)

subplot (1,2,2)
hold on; box off
scatter(combined_data.Elevation, combined_data.RelativeDisparity ,markerScale, subjectcolor, 'o','filled');
xlimvals=get(gca,'xlim')
plot(xlimvals, [ 0 0],'k-')
xlabel('Elevation (degree)');
ylabel('Relative Disparity (degree)');
set(gca,'FontSize',20,'FontName', 'Avenir')
titlestr=sprintf('RelativeDisparity=%.2f+%.2f*Elevation \n  p=%.2e n=%d',feEfxRD(1),feEfxRD(2),festatsRD.pValue(2),nSubjcombined);
title(titlestr,'FontSize',12)


% %%
% plotinvidual=1
% if plotinvidual
% % % plot individual subject lines
%     for s=1:nSubjcombined
%         sortedID=sorted_cindex(s);
%         sindex=find(uniqueIDcombined==IDcombined(sorted_cindex));
%         jj=find(combined_data.ID==uniqueIDcombined(sindex));
%         % if length(jj>1)
%         %     sdata=combined_data(jj,:);
%         %     xvectorS=;
%         %     % rand effex: each subject has different intercept
%         %     yvectorS=  RDsubjSlopes(sortedID)*xvectorS+RDsubjIntercepts(sortedID);
%         %     plot (xvectorS,yvectorS,':','Color', cmapRD(s,:),'LineWidth',1);
%         % end
%     end
% end
