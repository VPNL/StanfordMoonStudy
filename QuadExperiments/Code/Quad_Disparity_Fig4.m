% Quad_Disparity_Fig4
close all; clear all;

%codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))

% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
dataDir=fullfile(expDir,'Data')
cd(dataDir)
Quadfile='AllChinRestDisparityData.csv'
QuadBasename = [erase(Quadfile,'.csv')]
% Read Table
all_data=readtable(Quadfile);
ResultsDir=fullfile(expDir,'Paper_Fig4_122825');
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end
saveLME=1;


%% Keep only measurements containing 'probe'
if ~ismember('Measurement', all_data.Properties.VariableNames)
    error('Column "Measurement" not found in the table.');
end

measurementStr = string(all_data.Measurement);
idxProbe = contains(lower(measurementStr), "probe");
Tp = all_data(idxProbe, :);

%% Compute MeanDisparity_Minus_GT and add to table
reqVars = ["Disparity1_Minus_GT","Disparity2_Minus_GT","Elevation"];
missing = reqVars(~ismember(reqVars, Tp.Properties.VariableNames));
if ~isempty(missing)
    error('Missing required columns: %s', strjoin(missing, ', '));
end

% Ensure numeric
d1 = double(Tp.Disparity1_Minus_GT);
d2 = double(Tp.Disparity2_Minus_GT);

Tp.MeanDisparity_Minus_GT = mean([d1 d2], 2, 'omitnan');
% Save updated table with new column
writetable(Tp, 'AllChinRestDisparityData_withMean.csv');


%% Prepare subject ID for LME
idVar="ID"
Tp.(idVar) = categorical(Tp.(idVar));   % random effects grouping var

% Remove rows with missing key values
keep = ~isnan(Tp.MeanDisparity_Minus_GT) & ~isnan(Tp.Elevation) & ~isundefined(Tp.(idVar));
Tp = Tp(keep, :);

ID=Tp.ID;
uniqueID=unique(ID);
nSubj=length(uniqueID);

%% Fit LME: MeanDisparity_Minus_GT ~ Elevation + (1|ID)
formula = sprintf('MeanDisparity_Minus_GT ~ Elevation + (1|%s)', idVar);
lme = fitlme(Tp, formula);
disp(lme);

% random slopes and intercepts
formula = sprintf('MeanDisparity_Minus_GT ~ Elevation + (Elevation|%s)', idVar);
lme_RS = fitlme(Tp, formula);
disp(lme_RS);
modelcompRS=compare(lme,lme_RS);

% log model
Tp.logDisparity=log2(Tp.MeanDisparity_Minus_GT);
Tp.logElevation=log2(Tp.Elevation+1);
formula = sprintf('logDisparity ~ logElevation + (1|%s)', idVar);
lme_log = fitlme(Tp, formula);
disp(lme_log);


formula = sprintf('logDisparity ~ logElevation + (logElevation|%s)', idVar);
lme_logRS = fitlme(Tp, formula);
disp(lme_logRS);
modelcompLOG=compare(lme_log,lme_logRS);


% compare linear and log models
aicValue = lme.ModelCriterion.AIC;
bicValue = lme.ModelCriterion.BIC;
Rsq_Adjusted = lme.Rsquared.Adjusted;

aicValuelog = lme_log.ModelCriterion.AIC;
bicValuelog = lme_log.ModelCriterion.BIC;
Rsq_Adjustedlog = lme_log.Rsquared.Adjusted;


if saveLME
    savelmefile=fullfile(ResultsDir, [QuadBasename '_'  num2str(nSubj) '.txt']);
    diary(savelmefile)
    lme 
    lme_RS
    modelcompRS
    lme_log
    lme_logRS
    modelcompLOG
    fprintf('Comparing linear and log models\n');
    fprintf('AIC                linear:%.3f  log:%.3f\n',aicValue, aicValuelog)
    fprintf('BIC                linear:%.3f  log:%.3f\n',bicValue, bicValuelog)
    fprintf('Adjusted R-squared linear:%.3f  log:%.3f\n',Rsq_Adjusted, Rsq_Adjustedlog)
    diary off
end


%% plot data and linear fit

[reEfx,reNames,reStats] = randomEffects(lme_RS);
[feEfx,feNames,festats] =fixedEffects(lme_RS);


individualIntercepts = zeros(nSubj,1);
individualSlopes = zeros(nSubj,1);
for i = 1:nSubj
    % Indices for this subject's random effects
    subjectRows = find(strcmp(reNames.Level, string(uniqueID(i)))); 
    individualIntercepts(i) = feEfx(1) + reEfx(subjectRows(1));
    individualSlopes(i)    = feEfx(2) + reEfx(subjectRows(2));
end

% set colormap

% sort by intercepts
[sorted_individualIntercepts, sorted_idx] = sort(individualIntercepts);
clear subjectcolor;
cmap=jet(nSubj);


for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=cmap(sorted_cindex,:);
end

%
figh=figure('Color','w','Units','normalized','Position',[ 0 0 1 .6],'Name','Disparity vs Elevation'); hold on;
subplot(1,2,1)
hold on
markerSize=30

xvectorS= linspace(min(Tp.Elevation), max(Tp.Elevation), 100)';

% plot individual subjects line estimates
for s=1:nSubj
    sortedID=sorted_idx(s);
    yvectorS= individualSlopes(sortedID)*xvectorS+individualIntercepts(sortedID);
    plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
end

% Scatter: MeanDisparity_Minus_GT vs Elevation, subject color-coded (jet)
scatter(Tp.Elevation, Tp.MeanDisparity_Minus_GT, markerSize,subjectcolor,'o','filled');


% Add LME fixed-effect fit + 95% CI band
xGrid = linspace(min(Tp.Elevation), max(Tp.Elevation), 100)';
Tpred = table(xGrid, 'VariableNames', {'Elevation'});

% Set grouping var to an existing level so predict() is well-defined; then force fixed-only.
Tpred.(idVar) = categorical(repmat(uniqueID(1), size(xGrid)), uniqueID);

% Fixed-effects prediction and CI
[yHat, yCI] = predict(lme, Tpred, 'Conditional', false); % population-level

% Plot fit and CI
% CI band
fill([xGrid; flipud(xGrid)], [yCI(:,1); flipud(yCI(:,2))], ...
    [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.35);

% Fit line
plot(xGrid, yHat, 'k-', 'LineWidth', 5);

% Improve layering (bring points forward)
uistack(findobj(gca,'Type','Scatter'),'top');

box off
xlabel('Elevation (degree)');
ylabel('Mean Disparity (degree)');
set(gca,'FontSize',20,'FontName', 'Avenir')
titlestr=sprintf('Disparity=%.2f+%.2f*Elevation, p=%.2e\n n=%d',feEfx(1),feEfx(2),festats.pValue(2),nSubj);
title(titlestr,'FontSize',12)

%
subplot(1,2,2)
hold on
[reEfxlog,reNameslog,reStatslog] = randomEffects(lme_logRS);
[feEfxlog,feNameslog,festatslog] =fixedEffects(lme_logRS);
xGrid = linspace(min(Tp.Elevation), max(Tp.Elevation), 100)';


yHat_log_bt = 2^feEfxlog(1)*(1+xGrid).^feEfxlog(2);

yHat_log_lower=2^lme_logRS.Coefficients.Lower(1)*(1+xGrid).^lme_logRS.Coefficients.Lower(2);
yHat_log_upper=2^lme_logRS.Coefficients.Upper(1)*(1+xGrid).^lme_logRS.Coefficients.Upper(2);
yHat_log_CI=[yHat_log_lower yHat_log_upper];
fill([xGrid; flipud(xGrid)], [yHat_log_CI(:,1); flipud(yHat_log_CI(:,2))], ...
    [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.35);

% Scatter: MeanDisparity_Minus_GT vs Elevation, subject color-coded (jet)
scatter(Tp.Elevation, Tp.MeanDisparity_Minus_GT, markerSize,subjectcolor,'o','filled');

% plot individual subjects line estimates
for i = 1:nSubj
    % Indices for this subject's random effects
    subjectRows = find(strcmp(reNames.Level, string(uniqueID(i)))); 
    individualInterceptslog(i) = feEfxlog(1) + reEfxlog(subjectRows(1));
    individualSlopeslog(i)    = feEfxlog(2) + reEfxlog(subjectRows(2));
end
for s=1:nSubj
    sortedID=sorted_idx(s);
    yvectorS = 2^individualInterceptslog(sortedID)*(1+xGrid).^individualSlopeslog(sortedID);
    plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
end

% Fit line
plot(xGrid, yHat_log_bt, 'k-', 'LineWidth', 5);

% Improve layering (bring points forward)
uistack(findobj(gca,'Type','Scatter'),'top');

box off

xlabel('Elevation (degree)');
ylabel('Mean Disparity (degree)');
set(gca,'FontSize',20,'FontName', 'Avenir')

titlestr=sprintf('Disparity=%.2f*(Elevation+1)^{%.2f}, p=%.2e\n n=%d',2^feEfxlog(1),feEfxlog(2),festatslog.pValue(2),nSubj);
title(titlestr,'FontSize',12)


filenamePNG=fullfile(ResultsDir, [QuadBasename '_' num2str(nSubj),'.png'])
exportgraphics(figh,filenamePNG,'Resolution',600);

%% now let's redo plot with relative disparity rather than absolute disparity

% ii=find(strcmp(Tp.Measurement,'First_BottomProbeDisparity_VA'));
% meanD=mean(Tp(ii,:).MeanDisparity_Minus_GT); % mean across all subjects of first measurementd
% Tp.RelativeDisparity=Tp.MeanDisparity_Minus_GT-meanD % de-mean data
% 
% 
for i = 1:nSubj
    % Indices for this subject's random effects
   subjectRows = find(Tp.ID == uniqueID(i));
   % TT=Tp(subjectRows,:);
   % ii=find(strcmp(TT.Measurement,'First_BottomProbeDisparity_VA'));
   % firstDisparity=TT(ii,:).MeanDisparity_Minus_GT;
   % Tp.RelativeDisparity(subjectRows)=Tp.MeanDisparity_Minus_GT(subjectRows)-firstDisparity;
  meanD=mean(Tp.MeanDisparity_Minus_GT(subjectRows));
  Tp.RelativeDisparity(subjectRows)=Tp.MeanDisparity_Minus_GT(subjectRows)-meanD; 
end


%% Fit LME: MeanDisparity_Minus_GT ~ Elevation + (1|ID)
formula = sprintf('RelativeDisparity ~ Elevation + (1|%s)', idVar);
lmeRD = fitlme(Tp, formula);
disp(lmeRD);

% random slopes and intercepts
formula = sprintf('RelativeDisparity ~ Elevation + (Elevation|%s)', idVar);
lmeRD_RS = fitlme(Tp, formula);
disp(lmeRD_RS);
modelcompRD=compare(lmeRD,lmeRD_RS);

% LOG MODEL random intercepts
formula = sprintf('RelativeDisparity ~ logElevation + (1|%s)', idVar);
lmeRDlog = fitlme(Tp, formula);
disp(lmeRDlog);

% LOG MODEL random slopes and intercepts
formula = sprintf('RelativeDisparity ~ logElevation + (Elevation|%s)', idVar);
lmeRDlog_RS = fitlme(Tp, formula);
disp(lmeRDlog_RS);
modelcomplogRD=compare(lmeRDlog,lmeRDlog_RS);

% compare linear and log models
modelcomplinearlogRD=compare(lmeRD,lmeRDlog);
aicValueRD = lmeRD.ModelCriterion.AIC;
bicValueRD = lmeRD.ModelCriterion.BIC;
Rsq_AdjustedRD = lmeRD.Rsquared.Adjusted;

aicValueRDlog = lmeRDlog.ModelCriterion.AIC;
bicValueRDlog = lmeRDlog.ModelCriterion.BIC;
Rsq_AdjustedRDlog = lmeRDlog.Rsquared.Adjusted;

if saveLME
    savelmefile=fullfile(ResultsDir, [QuadBasename '_RelativeDisparity_'  num2str(nSubj) '.txt']);
    diary(savelmefile)
    lmeRD 
    lmeRD_RS
    modelcompRD
    lmeRDlog
    lmeRDlog_RS 
    modelcomplogRD
    fprintf('Comparing RD linear and log models\n');
    fprintf('AIC                linear:%.3f  log:%.3f\n',aicValueRD, aicValueRDlog)
    fprintf('BIC                linear:%.3f  log:%.3f\n',bicValueRD, bicValueRDlog)
    fprintf('Adjusted R-squared linear:%.3f  log:%.3f\n',Rsq_AdjustedRD, Rsq_AdjustedRDlog)
    diary off
end



%% plot data and linear fit

[reEfxRD,reNamesRD,reStatsRD] = randomEffects(lmeRD_RS);
[feEfxRD,feNamesRD,festatsRD] =fixedEffects(lmeRD_RS);


individualInterceptsRD = zeros(nSubj,1);
individualSlopesrD = zeros(nSubj,1);
% plot individual subjects line estimates
for i = 1:nSubj
    % Indices for this subject's random effects
    subjectRowsRD = find(strcmp(reNamesRD.Level, string(uniqueID(i)))); 
    individualInterceptsRD(i) = feEfxRD(1) + reEfxRD(subjectRowsRD(1));
    individualSlopesRD(i)    = feEfxRD(2) + reEfxRD(subjectRowsRD(2));
end


% set colormap

% sort by intercepts
[sorted_individualInterceptsRD, sorted_idxRD] = sort(individualInterceptsRD);

clear subjectcolorRD;
cmapRD=jet(nSubj);

for c=1:length(ID)
    cindexRD=find(uniqueID==ID(c));
    sorted_cindexRD=find(sorted_idxRD==cindexRD);
    subjectcolorRD(c,:)=cmapRD(sorted_cindexRD,:);
end

%%

figRD=figure('Color','w','Units','normalized','Position',[ 0 0 1 .6],'Name','Disparity vs Elevation'); hold on;
subplot(1,2,1)
hold on
% Scatter: MeanDisparity_Minus_GT vs Elevation, subject color-coded (jet)
scatter(Tp.Elevation, Tp.RelativeDisparity, markerSize,subjectcolorRD,'o','filled');

%scatter(Tp.Elevation, Tp.RelativeDisparity, markerSize,subjectcolor,'o','filled');
box off
xlimvals=get(gca, 'xlim');
plot(xlimvals,[0 0],'k-')

% plot individual subjects line estimates
% plot individual subjects line estimates

for s=1:nSubj
    sortedRDID=sorted_idxRD(s);
    yvectorRDS= individualSlopesRD(sortedRDID)*xvectorS+individualInterceptsRD(sortedRDID);
    plot (xvectorS,yvectorRDS,':','Color', cmap(s,:),'LineWidth',1);
end

% Add LME fixed-effect fit + 95% CI band
xGrid = linspace(min(Tp.Elevation), max(Tp.Elevation), 100)';
TpredRD = table(xGrid, 'VariableNames', {'Elevation'});

% Set grouping var to an existing level so predict() is well-defined; then force fixed-only.
TpredRD.(idVar) = categorical(repmat(uniqueID(1), size(xGrid)), uniqueID);

% Fixed-effects prediction and CI
[yRDHat, yRDCI] = predict(lmeRD, TpredRD, 'Conditional', false); % population-level

% Plot fit and CI
% CI band
fill([xGrid; flipud(xGrid)], [yRDCI(:,1); flipud(yRDCI(:,2))], ...
    [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.35);

% Fit line
plot(xGrid, yRDHat, 'k-', 'LineWidth', 5);

% Improve layering (bring points forward)
uistack(findobj(gca,'Type','Scatter'),'top');



xlabel('Elevation (degree)');
ylabel('Relative Disparity (degree)');
set(gca,'FontSize',20,'FontName', 'Avenir')

titlestr=sprintf('RelativeDisparity=%.2f+%.2f*Elevation, p=%.2e\n n=%d',feEfxRD(1),feEfxRD(2),festatsRD.pValue(2),nSubj);
title(titlestr,'FontSize',12)



%%
 subplot(1,2,2)
hold on
box off

% Scatter: MeanDisparity_Minus_GT vs Elevation, subject color-coded (jet)
scatter(Tp.Elevation, Tp.RelativeDisparity, markerSize,subjectcolorRD,'o','filled');
% %RelativeDisparity ~ logElevation + (Elevation|%s)', 

[reEfxRDlog,reNamesRDlog,reStatsRDlog] = randomEffects(lmeRDlog_RS);
[feEfxRDlog,feNamesRDlog,festatsRDlog] =fixedEffects(lmeRDlog_RS);


yRDHat_log_bt = feEfxRDlog(1)+ log2(1+xGrid)*feEfxRDlog(2);

yRDHat_log_lower=lmeRDlog_RS.Coefficients.Lower(1)+ log2(1+xGrid)*lmeRDlog_RS.Coefficients.Lower(2);
yRDHat_log_upper=lmeRDlog_RS.Coefficients.Upper(1)+ log2(1+xGrid)*lmeRDlog_RS.Coefficients.Upper(2);
yRDHat_log_CI=[yRDHat_log_lower yRDHat_log_upper];
fill([xGrid; flipud(xGrid)], [yRDHat_log_CI(:,1); flipud(yRDHat_log_CI(:,2))], ...
    [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.35);


% plot individual subjects line estimates
for i = 1:nSubj
    % Indices for this subject's random effects
    subjectRowsRDlog = find(strcmp(reNamesRDlog.Level, string(uniqueID(i)))); 
    individualInterceptsRDlog(i) = feEfxRDlog(1) + reEfxRDlog(subjectRowsRDlog(1));
    individualSlopesRDlog(i)    = feEfxRDlog(2) + reEfxRDlog(subjectRowsRDlog(2));
end


for s=1:nSubj
    sortedRDID=sorted_idxRD(s);
    yvectorS = individualInterceptsRDlog(sortedRDID)+ log2(1+xGrid)*individualSlopesRDlog(sortedRDID);
    plot (xvectorS,yvectorS,':','Color', cmap(s,:),'LineWidth',1);
end

% Fit line
plot(xGrid, yRDHat_log_bt, 'k-', 'LineWidth', 5);

% Improve layering (bring points forward)
uistack(findobj(gca,'Type','Scatter'),'top');

box off

xlabel('Elevation (degree)');
ylabel('Relative Disparity (degree)');
set(gca,'FontSize',20,'FontName', 'Avenir')

titlestr=sprintf('Relative Disparity=%.2f+%.2f*log2(Elevation+1), p=%.2e\n n=%d',feEfxRDlog(1),feEfxRDlog(2),festatsRDlog.pValue(2),nSubj);
title(titlestr,'FontSize',12)
filenamePNG=fullfile(ResultsDir, [QuadBasename 'RelativeDisparity_' num2str(nSubj),'.png'])
exportgraphics(figRD,filenamePNG,'Resolution',600);
