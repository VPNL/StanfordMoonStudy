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
% Load data

% Require needed columns
reqVars = {'Date','Task','Reported_Visual_Angle','Real_Visual_Angle'};
assert(all(ismember(reqVars, T.Properties.VariableNames)), ...
    'Table must contain: %s', strjoin(reqVars, ', '));

% Convert Date to datetime
T.Date = datetime(T.Date, 'InputFormat','M/d/yy');  % adjust if needed
taskStr = string(T.Task);

% Tasks to plot as two subplots (Adjusted, Perceptual)
tasksWanted = ["Adjusted","Perceptual"];
present = ismember(tasksWanted, unique(taskStr));
tasks = tasksWanted(present);

% -------- Shared bins across ALL data --------
allAngles = T.Reported_Visual_Angle;
[~, edgesFD] = histcounts(allAngles, 'BinMethod','fd');
if numel(edgesFD) < 5
    edgesFD = linspace(min(allAngles,[],'omitnan'), max(allAngles,[],'omitnan'), 21);
end
edges   = edgesFD;
centers = edges(1:end-1) + diff(edges)/2;

% -------- Gaussian smoothing kernel --------
smoothBins = 3;
xk    = -3*smoothBins : 3*smoothBins;
sigma = smoothBins;
gk    = exp(-(xk.^2)/(2*sigma^2));
gk    = gk / sum(gk);

% -------- Figure with two subplots --------
figure('Color',[ 1 1 1],'Name','Distributions of moon sizes'); 
t = tiledlayout(1, max(2,numel(tasks)), 'TileSpacing','compact', 'Padding','compact');

for ti = 1:numel(tasks)
    nexttile; hold on; box on;
    thisTask = tasks(ti);

    % Dates for this task
    idxTask = (taskStr == thisTask);
    uDates  = unique(T.Date(idxTask));

    % --- Sort by month of year (Jan → Dec) ---
    [~, sortIdx] = sort(month(uDates));
    uDates = uDates(sortIdx);

    % Colormap jet, ordered by month
    cmap = turbo(numel(uDates));

    for di = 1:numel(uDates)
        thisDate = uDates(di);

        % Angles for this (task, date)
        idxTD = idxTask & (T.Date == thisDate);
        ang = T.Reported_Visual_Angle(idxTD);
        uid = unique(T.ID(idxTD));
        nID = numel(uid); % number of participants in histogram
        %legends(di) 
        legends{di}= sprintf('%s  (IDs: %d)', datestr(thisDate,'mmm dd, yy'), nID);

        % Histogram with shared edges
        counts = histcounts(ang, edges);

        % Normalize
        total = sum(counts);
        if total > 0
            probs = counts / total;
        else
            probs = counts;
        end

        % Smooth & renormalize
        probs_smooth = conv(probs, gk, 'same');
        s = sum(probs_smooth);
        if s > 0, probs_smooth = probs_smooth / s; end

        % Plot

       
        % plot(centers, probs_smooth, 'LineWidth', 2, ...
        %     'Color', cmap(di,:), 'DisplayName', datestr(thisDate,'mmm dd, yy'));
        plot(centers, probs_smooth, 'LineWidth', 2, ...
            'Color', cmap(di,:), 'DisplayName', legends{di});


        % Vertical lines for Real_Visual_Angle
        rva_vals = unique(T.Real_Visual_Angle(idxTD));
        rva_vals = rva_vals(~isnan(rva_vals));
        for rv = rva_vals.'
             xline(rv, ':', 'Color', cmap(di,:), 'LineWidth', 1.5);
        end
    end

    
    xlabel('Reported Visual Angle');
    ylabel('Probability (sums to 1 per date)');
    title(sprintf('%s', thisTask));
    legend('Location','best');
    hold off;
end

title(t, 'Smoothed, Normalized Histograms by Date (ordered by Month of Year, Jet Colors)');
