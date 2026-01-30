function FullMoon_ReportedVisualAngle_Violin(dataDir,datafile,ResultsDir)
% function FullMoon_ReportedVisualAngle_Violin(dataDir,datafile,ResultsDir)
% plots violin plots of Reported Visual Angle by ascending Real Visual
% Angle values with separate violin plots for the adjusted and perceptual
% tasks

basename = erase( datafile,'.csv') ; % for saving
readfile=fullfile(dataDir,datafile);

% Load the data
T = readtable(readfile);


% --- SETTINGS ---
datafile = 'FullMoonDataLong090225.csv';   % update path if needed
angleVar = 'Real_Visual_Angle';
respVar  = 'Reported_Visual_Angle';
taskVar  = 'Task';
tasks    = ["Perceptual","Adjusted"];      % row 1 = Perceptual, row 2 = Adjusted
colors   = [0.35 0.45 0.85; 0.70 0.45 0.8]; % [Perceptual; Adjusted] RGB

% Ensure needed variables exist
assert(all(ismember({angleVar, respVar, taskVar}, T.Properties.VariableNames)), ...
    'One or more required variables are missing from the table.');
%%
% --- UNIQUE ANGLES (ascending) ---
T.(angleVar)=round(T.(angleVar),2);
angles = unique(T.(angleVar));
angles = angles(~isnan(angles));
angles = sort(angles, 'ascend');
nA = numel(angles);
%
max(T.(respVar))
% --- BUILD 2 x nAngles CELL ARRAY OF Reported_Visual_Angle ---
VA_cells = cell(2, nA); % row 1: Perceptual, row 2: Adjusted
for a = 1:nA
    thisA = angles(a);
    for r = 1:2
        Ti = T(strcmpi(string(T.(taskVar)), tasks(r)) & T.(angleVar)==thisA, :);
        yi = Ti.(respVar);
        yi = yi(~isnan(yi));
        VA_cells{r,a} = yi;
    end
end


f1=figure('color', [ 1 1 1],'Units','normalized','Position',[ 0 0 0.6 .8])
hold on;

% Here the x positions are category indices (1..nA), with two side-by-side violins
baseX2 = 1:nA;
baseOffset2 = 0.2;       % fixed offset in "category index" units
offsets2 = [-baseOffset2, +baseOffset2];
violinWidth2 = baseOffset2;

for a = 1:nA
    x0 = baseX2(a);
    % Draw the short horizontal line at y = Real_Visual_Angle (benchmark)
    line([x0 - 1.75*violinWidth2, x0 + 1.75*violinWidth2], [angles(a), angles(a)], ...
        'Color',[0.6 0.6 0.6], 'LineWidth',7);

    % Pair of violins
    for r = 1:2
        y = VA_cells{r,a};
        if isempty(y), continue; end
        simpleViolin(x0 + offsets2(r), y, violinWidth2, colors(r,:), 0.6);
        if r==1
            plot ((x0 - baseOffset2)*ones(length(y),1),y,'b.','MarkerSize',10); % plot individual dots
        else
             plot ((x0 + baseOffset2)*ones(length(y),1),y,'m.','MarkerSize',10); % plot individual dots
        end
    end
end
ylim([0 round(max(T.(respVar)))])
% Make the x axis categorical-style by labeling each tick with the angle value
xticks(baseX2);
  % shows each angle as a category label
xticklabelsnames=string(round(angles,3));
ll=length(xticklabelsnames);
xticklabelsnames(ll)=string(round(angles(ll),4));% set the last label to have 4 decimal points
set(gca,'XTickLabel',xticklabelsnames)
xtickangle(0);
set(gca,'Fontsize',26,'FontName','Avenir')

xlabel('Real Visual Angle [degrees]','Fontsize',32,'FontName','Avenir');
ylabel('Reported Visual Angle [degrees]','Fontsize',32,'FontName','Avenir');
box off;
xlim([0.5, nA + 0.5]);
legend(makeLegendProxies(colors), cellstr(tasks), 'Location','best','Box','off','FontSize',26);

% save figure
filenamePNG=fullfile('.', ResultsDir,[basename,'_' 'ReportedVisualAngle_ViolinPlots.png']);
exportgraphics(f1,filenamePNG,'Resolution',600);
end

% ========================= HELPERS =========================
function simpleViolin(x, y, width, faceColor, faceAlpha)
% x         : center position on x-axis
% y         : data vector
% width     : half-width scaling of the violin
% faceColor : RGB
% faceAlpha : 0..1

    y = y(~isnan(y));
    if numel(y) < 2
        plot(x, y, 'o', 'MarkerFaceColor', faceColor, 'MarkerEdgeColor','k');
        return;
    end

    % Kernel density
    try
        [f, yi] = ksdensity(y, 'Support','positive');
    catch
        [f, yi] = ksdensity(y);
    end
    % if all(~isfinite(f)) || all(f==0)
    %     plot(x, y, 'o', 'MarkerFaceColor', faceColor, 'MarkerEdgeColor','k');
    %       plot(x, y, '.', 'k', faceColor, 'MarkerEdgeColor','k');
    %     return;
    % end

    f = f / max(f);           % normalize to peak = 1
    half = f * width;         % horizontal half-width

    % Build polygon (left side down, right side up)
    xv = [x - half, fliplr(x + half)];
    yv = [yi,      fliplr(yi)];

     patch(xv, yv, faceColor, 'FaceAlpha', faceAlpha, ... %
      'EdgeColor',[1 1 1], 'LineWidth',0.5);

    
    % Median line
    med = median(y);
    line([x - width*0.9, x + width*0.9], [med, med], 'Color',[0.5 0.5 0.5], 'LineWidth',3);
end

%%
function hp = makeLegendProxies(colors)
    hp = gobjects(1, size(colors,1));
    for i = 1:size(colors,1)
        hp(i) = patch(NaN,NaN,colors(i,:), 'FaceAlpha',0.6, 'EdgeColor','none');
    end
end


%%

