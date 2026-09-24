function [lme_logPM_by_logSize,lme_logPM_by_logDistance,lme_logPM_by_logVA,...
    lme_logPM_by_logSizeNDistance, lme_logPM_by_logSizeNVA,lme_logPM_by_logVANDistance,...
    lme_logPM_by_logSizeNDistanceNVA]=Quad_PM_by_task_S_VA_D(tbl,tblName,ResultsDir,saveLME,colormap, sorted_idx)
% [lme_logPM_by_logSize,lme_logPM_by_logDistance,lme_logPM_by_logVA,...
%    lme_logPM_by_logSizeNDistance, lme_logPM_by_logSizeNVA,lme_logPM_by_logVANDistance,...
%    lme_logPM_by_logSizeNDistanceNVA]=Quad_PM_by_task_S_VA_D(tbl,tblName,ResultsDir,saveLME,colormap, sorted_idx)
% This function gets the task relevant data of the Stanford Quad Experiment
% and plots the relation 
% between log2(PM) and each of log2(S), log2(VA), log2(D)
% then uses fitlme to determine if all factors are signficant 
% and estimates the coeffients of the function:
% PM=C*VA^n1*D^n2*S^n3
% PM: Perceptual magnification
% VA: visual angle (degrees)
% D: distance (meters)
% S: Size in meters
% 
% tbl:        data table
% tblname:    table name that indicates the original file and the task
% ResultsDir: directory where the results are saved
% saveLME:    save flag 1: saves the fitlme results; 0: doesn't save
% colormap:   which colormap to use for scatter plot  
% sorted_idx: index of sorted colormap 
% It plots the single factor lmes
% and all the pair and triple factor lmes
% KGS Sep 2026

requiredVariables = {'ID', 'Size', 'Real_Visual_Angle', 'Distance', 'Ratio_Visual_Angle'};
missingVariables = setdiff(requiredVariables, tbl.Properties.VariableNames);
if ~isempty(missingVariables)
    error('Quad_PM_by_task_S_VA_D:MissingVariables', ...
        'tbl is missing required variable(s): %s', strjoin(missingVariables, ', '));
end

% Units expected by this function: Size and Distance in meters, VA in degrees.
positiveVariables = {'Size', 'Real_Visual_Angle', 'Distance', 'Ratio_Visual_Angle'};
for iVariable = 1:numel(positiveVariables)
    variableName = positiveVariables{iVariable};
    values = tbl.(variableName);
    if ~isnumeric(values) || ~isvector(values) || numel(values) ~= height(tbl)
        error('Quad_PM_by_task_S_VA_D:InvalidVariable', ...
            '%s must be a numeric table variable with one value per row.', variableName);
    end
    if any(~isfinite(values) | values <= 0)
        error('Quad_PM_by_task_S_VA_D:NonPositiveValues', ...
            '%s must contain only finite, positive values before applying log2.', variableName);
    end
end
%% find max angle and maxRatio for graphs
uniqueID=unique(tbl.ID);
nsubjects=length(uniqueID);
maxSize=max(tbl.Size);
minSize=min(tbl.Size);
maxRatio=max(tbl.Ratio_Visual_Angle);
minRatio=min(tbl.Ratio_Visual_Angle);
maxDistance=max(tbl.Distance);
minDistance=min(tbl.Distance);
maxPMLim=16;
minPMLim=.25;
if maxRatio>maxPMLim
    fprintf(1,'Warning: max Ratio %.2f exceeds Ylim max %.2f\n', maxRatio, maxPMLim)
end
if minRatio<minPMLim
    fprintf(1,'Warning: max Ratio %.2f less than Ylim ,om %.2f\n', minRatio, maxPMLim)
end

tbl.log2ratio_visual_angle=log2(tbl.Ratio_Visual_Angle); % PM
tbl.log2VA=log2(tbl.Real_Visual_Angle); 
tbl.log2Size=log2(tbl.Size);
tbl.log2distance=log2(tbl.Distance);

lme_logPM_by_logSize= fitlme(tbl,'log2ratio_visual_angle ~ log2Size +  (1| ID)');
lme_logPM_by_logDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2distance +  (1| ID)');
lme_logPM_by_logVA= fitlme(tbl,'log2ratio_visual_angle ~ log2VA +  (1| ID)');

lme_logPM_by_logSizeNDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2Size + log2distance + (1| ID)');
lme_logPM_by_logSizeNVA= fitlme(tbl,'log2ratio_visual_angle ~ log2Size + log2VA + (1| ID)');
lme_logPM_by_logVANDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2VA + log2distance + (1| ID)');

lme_logPM_by_logSizeNDistanceNVA= fitlme(tbl,'log2ratio_visual_angle ~ log2Size + log2distance + log2VA+ (1| ID)');
if saveLME
    savelmefile=fullfile(ResultsDir, [tblName '.txt']);
    sourceCsv = char(string(tblName));
    try
        if isstruct(tbl.Properties.UserData) && isfield(tbl.Properties.UserData, 'SourceFile')
            sourceCsv = char(string(tbl.Properties.UserData.SourceFile));
        end
    catch
    end
    if ~endsWith(string(sourceCsv), ".csv", "IgnoreCase", true)
        sourceCsv = sprintf('%s.csv (inferred from tblName; function input is a table)', sourceCsv);
    end

    reportOpts = struct();
    reportOpts.ReportTitle = sprintf('Quad PM Multi-Factor LME Report: %s', char(string(tblName)));
    reportOpts.GeneratedBy = mfilename;
    reportOpts.SourceFile = sourceCsv;
    reportOpts.ModelLabel = 'Log perceptual magnification predicted by log size, log distance, and log VA';
    reportOpts.SummaryLines = { ...
        sprintf('Rows in model table: %d', height(tbl)), ...
        sprintf('Participants in model table: %d', nsubjects), ...
        sprintf('Full model R-squared: ordinary = %.3f; adjusted = %.3f', ...
        lme_logPM_by_logSizeNDistanceNVA.Rsquared.Ordinary, ...
        lme_logPM_by_logSizeNDistanceNVA.Rsquared.Adjusted)};
    reportOpts.Models = { ...
        lme_logPM_by_logSize, ...
        lme_logPM_by_logDistance, ...
        lme_logPM_by_logVA, ...
        lme_logPM_by_logSizeNDistance, ...
        lme_logPM_by_logSizeNVA, ...
        lme_logPM_by_logVANDistance, ...
        lme_logPM_by_logSizeNDistanceNVA};
    reportOpts.ModelLabels = { ...
        'Model: log2ratio_visual_angle ~ log2Size + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2distance + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2VA + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2Size + log2distance + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2Size + log2VA + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2distance + log2VA + (1|ID)', ...
        'Model: log2ratio_visual_angle ~ log2Size + log2distance + log2VA + (1|ID)'};
    reportOpts.Comparisons = { ...
        compare(lme_logPM_by_logSize, lme_logPM_by_logSizeNDistance), ...
        compare(lme_logPM_by_logSize, lme_logPM_by_logSizeNVA), ...
        compare(lme_logPM_by_logDistance, lme_logPM_by_logSizeNDistance), ...
        compare(lme_logPM_by_logDistance, lme_logPM_by_logVANDistance), ...
        compare(lme_logPM_by_logVA, lme_logPM_by_logSizeNVA), ...
        compare(lme_logPM_by_logVA, lme_logPM_by_logVANDistance), ...
        compare(lme_logPM_by_logSizeNDistance, lme_logPM_by_logSizeNDistanceNVA), ...
        compare(lme_logPM_by_logSizeNVA, lme_logPM_by_logSizeNDistanceNVA), ...
        compare(lme_logPM_by_logVANDistance, lme_logPM_by_logSizeNDistanceNVA), ...
        compare(lme_logPM_by_logSize, lme_logPM_by_logSizeNDistanceNVA), ...
        compare(lme_logPM_by_logDistance, lme_logPM_by_logSizeNDistanceNVA), ...
        compare(lme_logPM_by_logVA, lme_logPM_by_logSizeNDistanceNVA)};
    reportOpts.ComparisonLabels = { ...
        'Model comparison: size vs size + distance', ...
        'Model comparison: size vs size + VA', ...
        'Model comparison: distance vs size + distance', ...
        'Model comparison: distance vs distance + VA', ...
        'Model comparison: VA vs size + VA', ...
        'Model comparison: VA vs distance + VA', ...
        'Model comparison: size + distance vs size + distance + VA', ...
        'Model comparison: size + VA vs size + distance + VA', ...
        'Model comparison: distance + VA vs size + distance + VA', ...
        'Model comparison: size vs size + distance + VA', ...
        'Model comparison: distance vs size + distance + VA', ...
        'Model comparison: VA vs size + distance + VA'};
    reportOpts.RemoveGroupError = false;
    write_lme_stats_report(lme_logPM_by_logSizeNDistanceNVA, savelmefile, reportOpts);
end


%%
% set sorted colormap
ID=tbl.ID;
clear subjectcolor
for c=1:length(ID)
    cindex=find(uniqueID==ID(c));
    sorted_cindex=find(sorted_idx==cindex);
    subjectcolor(c,:)=colormap(sorted_cindex,:);
end


% plot results
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 .7],'Name',tblName)
markerSize=50;

mean_intercept_angle=lme_logPM_by_logSize.Coefficients.Estimate(1);
mean_slope_angle=lme_logPM_by_logSize.Coefficients.Estimate(2);
pval_angle=lme_logPM_by_logSize.Coefficients.pValue(2);

% get upper and lower coeffiecents
mean_intercept_angleL=lme_logPM_by_logSize.Coefficients.Lower(1)
mean_slope_angleL=lme_logPM_by_logSize.Coefficients.Lower(2)
mean_intercept_angleU=lme_logPM_by_logSize.Coefficients.Upper(1)
mean_slope_angleU=lme_logPM_by_logSize.Coefficients.Upper(2)
% 
% set plotting range
xlinerange=log2(minSize):.01:log2(maxSize);
ylinerange=zeros(size(xlinerange));
xvectoru=xlinerange;
xvectord = sort(xvectoru, 'descend');

% fixed effects estimate
y_fit =mean_intercept_angle+mean_slope_angle*xlinerange;


% fixed effects confidence interval
yvector1=mean_slope_angleL*xvectoru+mean_intercept_angleL;
yvector2=mean_slope_angleU*xvectord+mean_intercept_angleU;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

subplot(1,3,1); 
hold on 
scatter(tbl.log2Size, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled');    % individual data scatter; colroed by subject color
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
plot (xlinerange, mean_intercept_angle+mean_slope_angle*xlinerange,'k-','LineWidth',3); % fixed effect
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.4); % confidence interval

[angleTickPos, angleTickLabels] = local_adaptive_log_ticks(minSize, maxSize, 1);
set(gca,'XTick',angleTickPos,'XTickLabel',angleTickLabels);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim):1: ceil(log2(maxPMLim))]));
xlim([log2(minSize*.95) log2(maxSize*1.05)]);
ylim([log2(minPMLim) ceil(log2(maxPMLim))]);
set(gca,'FontName','Avenir','FontSize', 20)
xlabel ({'Size [m]','log scale'},'FontSize', 24)
ylabel ({'Perceptual Magnification', 'log scale'},'FontSize', 24)

titlestr=sprintf('PM=%.2fS^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_angle,mean_slope_angle,pval_angle, nsubjects);
title(titlestr,'FontSize',18,'FontWeight','normal')

% plot PM by distance different colors per subject sorted by PM in perceptual task
%
mean_slope_distance=lme_logPM_by_logDistance.Coefficients.Estimate(2);
mean_intercept_distance=lme_logPM_by_logDistance.Coefficients.Estimate(1);
pval_distance=lme_logPM_by_logDistance.Coefficients.pValue(2);

% get upper and lower coeffiecents
mean_intercept_distanceL=lme_logPM_by_logDistance.Coefficients.Lower(1)
mean_slope_distanceL=lme_logPM_by_logDistance.Coefficients.Lower(2)
mean_intercept_distanceU=lme_logPM_by_logDistance.Coefficients.Upper(1)
mean_slope_distanceU=lme_logPM_by_logDistance.Coefficients.Upper(2)
% 
% set plotting range
xlinerange=log2(minDistance-1):.05:log2(maxDistance+1); 
ylinerange=zeros(size(xlinerange));
xvectoru=xlinerange;
xvectord = sort(xvectoru, 'descend');

% fixed effects confidence interval
yvector1=mean_slope_distanceL*xvectoru+mean_intercept_distanceL;
yvector2=mean_slope_distanceU*xvectord+mean_intercept_distanceU;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

subplot(1,3,2); 
hold on 
scatter(tbl.log2distance, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled'); % individual subject data
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
plot (xlinerange, mean_intercept_distance+mean_slope_distance*xlinerange,'k-','LineWidth',3); % fixed effects linear estimate
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.4); % confidence interval on fixed effect

[distanceTickPos, distanceTickLabels] = local_adaptive_log_ticks(minDistance, maxDistance, 0);
set(gca,'XTick',distanceTickPos,'XTickLabel',distanceTickLabels);
set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
xlim([log2(minDistance*.95) log2(maxDistance*1.05)]);
ylim([log2(minPMLim) ceil(log2(maxPMLim))])
set(gca,'FontName','Avenir','FontSize', 20)
xlabel ({'Distance [m]', 'log scale'},'FontSize', 24)
ylabel ('')

ax = gca;
ax.YColor = 'w';
mean_slope=lme_logPM_by_logDistance.Coefficients.Estimate(2);
pval=lme_logPM_by_logDistance.Coefficients.pValue(2);
titlestr=sprintf('PM=%.2fD^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_distance,mean_slope_distance,pval_distance, nsubjects);
title(titlestr,'FontSize',18,'FontWeight','normal')

%% plot by VA
mean_slope_VA=lme_logPM_by_logVA.Coefficients.Estimate(2);
mean_intercept_VA=lme_logPM_by_logVA.Coefficients.Estimate(1);
pval_VA=lme_logPM_by_logVA.Coefficients.pValue(2);


% get upper and lower coeffiecents
mean_intercept_VAL=lme_logPM_by_logVA.Coefficients.Lower(1)
mean_slope_VAL=lme_logPM_by_logVA.Coefficients.Lower(2)
mean_intercept_VAU=lme_logPM_by_logVA.Coefficients.Upper(1)
mean_slope_VAU=lme_logPM_by_logVA.Coefficients.Upper(2)
% 
% Set the plotting range from real visual angle, not the preceding distance panel.
minVA = min(tbl.Real_Visual_Angle);
maxVA = max(tbl.Real_Visual_Angle);
xlinerange = linspace(log2(minVA), log2(maxVA), 200);
ylinerange = zeros(size(xlinerange));
xvectoru=xlinerange;
xvectord = sort(xvectoru, 'descend');

% fixed effects confidence interval
yvector1=mean_slope_VAL*xvectoru+mean_intercept_VAL;
yvector2=mean_slope_VAU*xvectord+mean_intercept_VAU;
xvector=[xvectoru xvectord];
yvector=[yvector1 yvector2];

subplot(1,3,3); 
hold on 
scatter(tbl.log2VA, tbl.log2ratio_visual_angle, markerSize, subjectcolor, 'filled');

plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
plot (xlinerange, mean_intercept_VA+mean_slope_VA*xlinerange,'k-','LineWidth',3); % fixed effects linear estimate
fill(xvector, yvector, 1,'facecolor', 'k', 'edgecolor', 'none', 'facealpha', 0.4); % confidence interval on fixed effect

set(gca,'YTick',log2(minPMLim):1:log2(maxPMLim) ,'YTickLabel',2.^([log2(minPMLim) :1: ceil(log2(maxPMLim))]));
[VATickPos, VATickLabels] = local_adaptive_log_ticks(minVA, maxVA, 1);
set(gca,'XTick',VATickPos,'XTickLabel',VATickLabels,'XTickLabelRotation',0);
xlim([log2(minVA*.95) log2(maxVA*1.05)]);
ylim([log2(minPMLim) ceil(log2(maxPMLim))]);
set(gca,'FontName','Avenir','FontSize', 20)


ax = gca;
ax.YColor = 'w';
 titlestr=sprintf('PM=%.2fVA^{%.2f}\n p=%-.2e \n n=%d',2.^mean_intercept_VA,mean_slope_VA,pval_VA, nsubjects);
 xlabel ({'Real Visual Angle [deg]','log scale'},'FontSize', 24)

title(titlestr,'FontSize',18,'FontWeight','normal')

%% save figure
filenamePNG=fullfile(ResultsDir, [tblName 'single.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);

%% full model
%lme_logPM_by_logSizeNDistanceNVA= fitlme(tbl,'log2ratio_visual_angle ~ log2Size + log2distance + log2VA+ (1| ID)');
% first coefficient intercept
%log2Size
%log2distance
%log2VA

coefficients = lme_logPM_by_logSizeNDistanceNVA.Coefficients;
intercept_fe = local_coefficient_value(coefficients, '(Intercept)', 'Estimate');
size_fe = local_coefficient_value(coefficients, 'log2Size', 'Estimate');
pval_size = local_coefficient_value(coefficients, 'log2Size', 'pValue');
distance_fe = local_coefficient_value(coefficients, 'log2distance', 'Estimate');
pval_distance = local_coefficient_value(coefficients, 'log2distance', 'pValue');
VA_fe = local_coefficient_value(coefficients, 'log2VA', 'Estimate');
pval_VA = local_coefficient_value(coefficients, 'log2VA', 'pValue');
% full formula
fprintf(1,'PM=%.2f*S^{%.2f}*VA^{%.2f}*D^{%.2f}\n p_S=%-.2e, p_VA=%-.2e, p_D=%-.2e, n=%d\n',...
    2.^intercept_fe,size_fe,VA_fe,distance_fe,pval_size,pval_VA,pval_distance,nsubjects);

end

function value = local_coefficient_value(coefficients, termName, variableName)
coefficientNames = string(coefficients.Name);
termIndex = find(coefficientNames == string(termName), 1);
if isempty(termIndex)
    error('Quad_PM_by_task_S_VA_D:MissingCoefficient', ...
        'Model coefficient %s was not found.', termName);
end
value = coefficients.(variableName)(termIndex);
end

function labels = local_format_tick_labels(vals)
labels = strings(size(vals));
for i = 1:numel(vals)
    if abs(vals(i)) > 1000
        labels(i) = sprintf('%.1e', vals(i));
    else
        labels(i) = string(vals(i));
    end
end
end

function [tickPos, tickLabels] = local_adaptive_log_ticks(minVal, maxVal, roundDigits)
if ~isfinite(minVal) || ~isfinite(maxVal) || minVal <= 0 || maxVal <= 0
    tickPos = [];
    tickLabels = strings(0,1);
    return
end

if maxVal < minVal
    tmp = minVal;
    minVal = maxVal;
    maxVal = tmp;
end

if minVal == maxVal
    rawTicks = minVal;
else
    logMin = log2(minVal);
    logMax = log2(maxVal);
    logSpan = logMax - logMin;

    if logSpan < 1
        nTicks = 2;
    elseif logSpan < 2.5
        nTicks = 3;
    elseif logSpan < 4.5
        nTicks = 4;
    else
        nTicks = 2;
    end

    rawTicks = 2.^linspace(logMin, logMax, nTicks);
    rawTicks(1) = minVal;
    rawTicks(end) = maxVal;
end

rawTicks = unique(rawTicks, 'stable');
tickPos = log2(rawTicks);
tickLabels = local_format_tick_labels(round(rawTicks, roundDigits));
end
