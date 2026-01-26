function visualize_PM_VA_DS_EL(expDir,DataDir,QuadFile,task,saveLME,orientation,ResultsDir,logscale)
% function visualize_PM_VA_DS_EL(expDir,DataDir,QuadFile,task,saveLME,orientation)visualize_PM_VA_DS_EL
% This function visualizes the effect of perceptual magnification by
% visual_angle (VA), distance (DS), and elevation (EL)
% for the perceptual and adjusted tasks
% PM is estimated for the binocular perceptual task using this function:
% PM_perceptual = 0.42 .* (VA.^(-0.083)) .* (DS.^0.368) .* ((1 + EL).^0.12);
% PM is estimated for the monocular adjusted task using this function:
% PM_adjusted = 0.52 .* (VA.^(-0.07)) .* (DS.^0.14) .* ((1 + EL).^0.17);
% see results of Quad_PM_Fig3_angle_distance_elevation for the constants on
% which the functions are evaluated on.
% 
% KGS
% Nov 2025

% set vars if don't exist
if ~exist('expDir')
    expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
end
if ~exist('QuadFile')
    QuadFile='AllQuadDataLong916.csv'
end
if ~exist('task')
    task='Perceptual'; %perceptual or % adjusted
end  
if ~exist('saveLME')
    saveLME=0; % 1 save files; 0 don't save 
end
if ~exist('orientation')
    orientation='horizontal'; % or 'vertical'
end
if ~exist('ResultsDir')
    ResultsDir=fullfile(expDir,'Results',QuadBasename);
end
if ~exist('logscale')
    logscale=1;
end


DataDir=fullfile(expDir,'Data');
cd(DataDir)
all_quad_data=readtable(QuadFile);
QuadBasename = [erase(QuadFile,'.csv')] ;


% Define ranges
minVA = 0.25; maxVA = 8;
minEL = 1;    maxEL = 16;
minDS = 8;    maxDS = 256;

% Sample uniformly in log2 space
VA = 2.^(linspace(log2(minVA), log2(maxVA), 200));   % Visual Angle
EL = 2.^(linspace(log2(minEL), log2(maxEL), 200));   % Elevation
DS = 2.^(linspace(log2(minDS), log2(maxDS), 200));   % Distance

% Helper for power-of-2 ticks and labels
pow2ticks = @(mn, mx) 2.^(ceil(log2(mn)) : floor(log2(mx)));
fmt = @(v) arrayfun(@num2str, v, 'UniformOutput', false);

% --- Subplot 1: PM across Distance (x) and Visual Angle (y); Elevation = 1 ---
%[DS1, VA1] = meshgrid(DS, VA);
[VA1, DS1] = meshgrid(VA, DS);
E1 = 2.5;
if strcmp(task,'Perceptual')
    PM1 = 0.42 .* (VA1.^(-0.083)) .* (DS1.^0.368) .* ((1 + E1).^0.12);
else
    PM1 = 0.52 .* (VA1.^(-0.07)) .* (DS1.^0.14) .* ((1 + E1).^0.17);
end

% --- Subplot 2: PM across Distance (x) and Elevation (y); Visual Angle = 0.5 ---
% [DS2, EL2] = meshgrid(DS, EL);
[EL2, DS2] = meshgrid( EL, DS);
V2 = 0.5;
if strcmp(task,'Perceptual')
    PM2 = 0.42 .* (V2.^(-0.083)) .* (DS2.^0.368) .* ((1 + EL2).^0.12);
else
    PM2 = 0.52 .* (V2.^(-0.07)) .* (DS2.^0.14) .* ((1 + EL2).^0.17);
end

% --- Subplot 3: PM across Visual Angle (x) and Elevation (y); Distance = 100 
D3 = 100;
% [VA3, EL3] = meshgrid(VA, EL); 
[ EL3,VA3] = meshgrid( EL, VA);
if strcmp(task,'Perceptual')
    PM3 = 0.42 .* (VA3.^(-0.083)) .* (D3.^0.368) .* ((1 + EL3).^0.12);
else
    PM3 = 0.52 .* (VA3.^(-0.07)) .* (D3.^0.14) .* ((1 + EL3).^0.17); 
end




% Consistent color scaling
% pm_min = min([min(PM1(:)), min(PM2(:)), min(PM3(:))]);
% pm_max = max([max(PM1(:)), max(PM2(:)), max(PM3(:))]);
pm_min=0.5
pm_max=4;

%% plot vertical orientation
if strcmp(orientation,'vertical')
    figure('Color','w','Name',[QuadBasename ' ' task],'Units','normalized','Position',[0 0 .3 1]); 
else
    figure('Color','w','Name',[QuadBasename ' ' task],'Units','normalized','Position',[0 0 1 .3]); 
end

colormap(cool);

% --- Panel 1: x=Distance, y=Visual Angle (Elevation=1) ---
if strcmp(orientation,'vertical')
    subplot(3,1,1);
else
    subplot(1,3,1);
end


surf(VA1, DS1, PM1, 'EdgeColor','none'); %view(2);
caxis([pm_min pm_max]); shading interp;

axis tight; box off;%axis square;
yt = pow2ticks(minDS, maxDS);
xt = pow2ticks(minVA, maxVA);
set(gca,'XTick',xt,'XTickLabel',fmt(xt),...
        'YTick',yt,'YTickLabel',fmt(yt),'FontName','Avenir');
if logscale
    set(gca,'XScale','log','YScale','log');
end
xlabel('Visual Angle (°)'); ylabel('Distance [m]'); zlabel('Perceptual magnification')
titlestr=sprintf('E = %.2f',E1);
title(titlestr); 


% --- Panel 2: x=Distance, y=Elevation (Visual Angle = 0.5) ---
if strcmp(orientation,'vertical')
    subplot(3,1,2);
else
    subplot(1,3,2);
end

surf(EL2, DS2, PM2, 'EdgeColor','none'); 
caxis([pm_min pm_max]); shading interp;
axis tight; box off;
xlabel('Elevation (°)'); ylabel('Distance [m]');zlabel('Perceptual magnification');
titlestr=sprintf('VA = %.2f',V2); 
title(titlestr)
xt = pow2ticks(minEL, maxEL);
yt = pow2ticks(minDS, maxDS);
set(gca,'XTick',xt,'XTickLabel',fmt(xt),...
        'YTick',yt,'YTickLabel',fmt(yt),'FontName','Avenir');
if logscale
    set(gca,'XScale','log','YScale','log');
end
%--- Panel 3: x=Visual Angle, y=Elevation (Distance = 100) ---
if strcmp(orientation,'vertical')
    subplot(3,1,3);
else
    subplot(1,3,3);
end


surf(EL3, VA3, PM3, 'EdgeColor','none'); 
shading interp; caxis([pm_min pm_max]); 
axis tight; box off;
xt = pow2ticks(minEL, maxEL);
yt = pow2ticks(minVA, maxVA);
set(gca,'XTick',xt,'XTickLabel',fmt(xt),...
        'YTick',yt,'YTickLabel',fmt(yt));
if logscale
    set(gca,'XScale','log','YScale','log');
end
xlabel('Elevation (°)'); ylabel('Visual Angle (°)'); zlabel('Perceptual magnification')
titlestr=sprintf('D = %d',D3);
title(titlestr)


set(findall(gcf,'Type','axes'),'FontSize',10,'FontName','Avenir');


% save figure
figName=sprintf('%s_%s_visualize_PMbyVA_DS_EL_%s_%1f.png',QuadBasename, task, orientation, E1);
filenamePNG=fullfile(ResultsDir, figName);
exportgraphics(gcf,filenamePNG,'Resolution',600);
%% another way of plotting

Npoints = 15;   % number of samples per dimension
VA = linspace(minVA,maxVA,  Npoints);    % X axis
DS = linspace(10,   150, Npoints);   % Y axis
EL = linspace(minEL,    maxEL,  Npoints);   % Z axis
[DSgrid, VAgrid, ELgrid] = meshgrid(DS, VA, EL);

% Compute PM_perceptual
if strcmp(task,'Perceptual')
    PM = 0.42 .* (VAgrid.^(-0.083)) .* ...
                        (DSgrid.^0.368) .* ...
                        ((1 + ELgrid).^0.12);
else
    PM = 0.52 .* (VAgrid.^(-0.07)) .* (DSgrid.^0.14) .* ((1 + ELgrid).^0.17);
end

% Turn into vectors for scatter3
x = DSgrid(:);
y = VAgrid(:);
z = ELgrid(:);
c = PM(:);

% 3D scatter plot
figure ('Color',[ 1 1 1],'Name','Visualizing Perceptual Magnification','Units','normalized','Position',[ 0 0 .6 1])
markerSize = 30;   % adjust point size if you likeget
% alpha proportional to PM 
minAlpha = .7;     % faintest points
maxAlpha = 1.0;     % fully opaque


addalpha=0
if addalpha
   cNorm = (c - min(c)) ./ (max(c) - min(c));  % normalized 0–1
   alphaVal = minAlpha + cNorm * (maxAlpha - minAlpha);
   s = scatter3(x, y, z, markerSize*c, c, 'filled', ...
         'MarkerFaceAlpha','flat', ...
         'MarkerEdgeAlpha','flat');
   s.AlphaData = alphaVal;       % per-point alpha
   s.MarkerFaceAlpha = 'flat';
   s.MarkerEdgeAlpha = 'flat';
else
    s = scatter3(x, y, z, markerSize*c, c, 'filled')
end

% set(gca,'XDir','reverse');
hx=xlabel({'Distance [m] '});
hy=ylabel({'Visual Angle    ', '  [degree] '});
hz=zlabel({'Elevation [degree]'});
if strcmp(task,'Perceptual')
  title([ task ' $PM = 0.42 \cdot VA^{-0.083} \cdot DS^{0.368} \cdot (1+EL)^{0.12}$'], ...
      'Interpreter','latex','FontWeight','bold')
else

    title([task ' $PM = 0.52 \cdot VA^{-0.07} \cdot DS^{0.14} \cdot (1+EL)^{0.17}$'], ...
      'Interpreter','latex','FontWeight','bold')
end


hx.Rotation = -10;     % rotate X label by 20 degrees
hy.Rotation = 0;    % rotate Y label by -30 degrees
hz.Rotation = 90;      % Z usually vertical; can adjust if needed

grid on; box on;
colormap turbo  

caxis([pm_min pm_max]); % use conistent coloraxis across tasks
cb = colorbar;
cb.Label.String = 'Perceptual Magnification';
cb.Label.FontSize = 24;        % optional
%set(gca, 'XScale', 'log', 'YScale', 'log', 'ZScale', 'log');
view( 36.8594  , 22.3437);
set(gca,'FontName','Avenir','FontSize',24)

% save figure
figName=sprintf('%s_%s_visualize_PMbyVA_DS_EL.png',QuadBasename, task);
filenamePNG=fullfile(ResultsDir, figName);
exportgraphics(gcf,filenamePNG,'Resolution',600);



%% more colormaps
% cmap=slanCM('gnuplot',256)
% colormap(cmap);
