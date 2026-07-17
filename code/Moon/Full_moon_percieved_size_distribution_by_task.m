close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/'
addpath(genpath(codeDir))
% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';
datafile='FullMoonDataLong090225.csv'; % all data
ResultsDir='PaperFig1_100225'
basename = [erase( datafile,'s.csv')] ; % for saving
readfile=fullfile(dataDir,datafile);

% Load the data
T = readtable(readfile);
%%
% Ensure required columns
reqVars = {'Task','Date','Reported_Visual_Angle','Real_Visual_Angle'};
assert(all(ismember(reqVars, T.Properties.VariableNames)), ...
    'Table must contain: %s', strjoin(reqVars, ', '));

% Parse types
T.Task = string(T.Task);
T.Date = datetime(T.Date, 'InputFormat','M/d/yy');  % adjust if needed

% Tasks to plot
tasksWanted = ["Adjusted","Perceptual"];
present = ismember(tasksWanted, unique(T.Task));
tasks = tasksWanted(present);
assert(~isempty(tasks), 'Requested tasks not found.');

% Shared bins across ALL data (for comparability)
allAngles = T.Reported_Visual_Angle;
[~, edgesFD] = histcounts(allAngles, 'BinMethod','fd');
if numel(edgesFD) < 3
    edgesFD = linspace(min(allAngles,[],'omitnan'), max(allAngles,[],'omitnan'), 21);
end
edges   = edgesFD;
centers = edges(1:end-1) + diff(edges)/2;

% Colors for each task curve
taskColors = [0.8 .8 .8; 0 0 0];

% Month→color mapping using jet
monthCmap = jet(12);           % 1..12 -> rows of jet


% -------- Gaussian smoothing kernel --------
smoothBins = 0.5;
xk    = -3*smoothBins : 3*smoothBins;
sigma = smoothBins;
gk    = exp(-(xk.^2)/(2*sigma^2));
gk    = gk / sum(gk);

smoothflag=1;

figure('Color',[ 1 1 1])
hold on; box off;

maxY = 0;  % track max y to place triangles nicely
for i = 1:numel(tasks)
    thisTask = tasks(i);
    maskTask = (T.Task == thisTask);

    % Single normalized histogram for this task
    ang = T.Reported_Visual_Angle(maskTask);
    counts = histcounts(ang, edges);
    probs  = counts / max(1, sum(counts));   % normalize to sum=1

    % Plot the task's histogram curve
    if smoothflag
         % Smooth & renormalize
        probs_smooth = conv(probs, gk, 'same');
        s = sum(probs_smooth);
        if s > 0, probs_smooth = probs_smooth / s; end

         plot(centers, probs_smooth, 'LineWidth',3, 'Color', taskColors(i,:), ...
            'DisplayName', char(thisTask));
    else
        plot(centers, probs, 'LineWidth', 3, 'Color', taskColors(i,:), ...
            'DisplayName', char(thisTask));
    end

    maxY = max(maxY, max(probs));

    % Draw per-date vertical lines colored by *month* (jet colormap)
    uDates = unique(T.Date(maskTask));
    % Sort by month-of-year so color progression is logical
    [~, ord] = sort(month(uDates));
    uDates = uDates(ord);

    for d = 1:numel(uDates)
        m = month(uDates(d));                 % 1..12
        idx = maskTask & (T.Date == uDates(d));
        rva_vals = unique(T.Real_Visual_Angle(idx));
        rva_vals = rva_vals(~isnan(rva_vals));
        for rv = rva_vals.'
            xline(rv, ':', 'Color', monthCmap(m,:), 'LineWidth', 1);
        end
    end

    % Triangle at the median of the histogram (task color), placed above curve
    medVal = median(ang, 'omitnan');
    
end
for i = 1:numel(tasks)
    thisTask = tasks(i);
    maskTask = (T.Task == thisTask);

    % Single normalized histogram for this task
    ang = T.Reported_Visual_Angle(maskTask);
    medVal = median(ang, 'omitnan');
    yTri   =  1.05*maxY;              % just above the peak
    plot(medVal, yTri, 'v', 'MarkerSize', 7, ...
        'MarkerFaceColor', taskColors(i,:), 'MarkerEdgeColor', taskColors(i,:));

    %xline(medVal, '-', 'Color', taskColors(i,:), 'LineWidth', 2);
end

xlabel('Reported Visual Angle [degrees]');
ylabel('Proportion of trials');
set(gca,'FontName','Avenir','FontSize',20)

legend('Location','bestoutside','box','off','FontSize',12);

% Give some headroom for triangles
ylim([0, max(0.1, 1.15*maxY)]);
hold off;

