function visualize_PM_VA_DS_EL(ResultsDir,OutFile,task,Intercept,VAe,De,Ee,VArange,Drange,Erange,logscale)
% function visualize_PM_VA_DS_EL(ResultsDir,OutFile,task,Intercept,VAe,De,Ee,VArange,Drange,Erange,logscale)
% This function visualizes the effect of perceptual magnification by
% visual_angle (VA), distance (D), and elevation (E)
% for the perceptual and adjusted tasks
% PM is estimated for the binocular perceptual task using this function:
% PM_perceptual = 2.^Intercept .* (VA.^(VAe)) .* (D.^De) .* ((1 + E).^Ee);
% on the range of 
% Visual Angle defined by VArange: minVA = min(VArange); maxVA = max(VArange);
% Distance defined by Drange:      minDS = min(Drange);    maxDS = max(Drange);
% Elevation defined by Erange:     minEL = min(Erange);    maxEL = max(Erange);
% KGS
% Jan 2026

% set vars if don't exist
if ~exist('ResultsDir')
    expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/Results/';
end
if ~exist('OutFile')
   OutFile='visualizePM'
end
if ~exist('task')
    task='Perceptual'; %perceptual or % adjusted
end  
if ~exist('orientation')
    orientation='horizontal'; % or 'vertical'
end
if ~exist('logscale')
    logscale=0;
end

% Define ranges
minVA = min(VArange);   maxVA = max(VArange);
minDS = min(Drange);    maxDS = max(Drange);
minEL = min(Erange);    maxEL = max(Erange);

% Helper for power-of-2 ticks and labels
pow2ticks = @(mn, mx) 2.^(ceil(log2(mn)) : floor(log2(mx)));
fmt = @(v) arrayfun(@num2str, v, 'UniformOutput', false);

%% another way of plotting

Npoints = 15;   % number of samples per dimension
if logscale
    VA = logspace(log10(minVA),log10(maxVA),  Npoints);    % X axis
    DS = logspace(log10(minDS),log10(maxDS), Npoints);   % Y axis
    if minEL==0
        EL = logspace(log10(1), log10(maxEL),  Npoints);   % Z axis
    else
        EL = logspace(log10(minEL), log10(maxEL),  Npoints);   % Z axis
    end
else
    VA = linspace(minVA,maxVA,  Npoints);    % X axis
    DS = linspace(minDS,maxDS, Npoints);   % Y axis
    if minEL==0
        EL = linspace(1,    maxEL,  Npoints);   % Z axis
    else
        EL = linspace(minEL,    maxEL,  Npoints);   % Z axis
    end
end

[DSgrid, VAgrid, ELgrid] = meshgrid(DS, VA, EL);

% Compute PM_perceptual
PM = 2.^Intercept .* (VAgrid.^(VAe)) .* (DSgrid.^De) .* ((1 + ELgrid).^Ee);

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
maxAlpha = 1.0;    % fully opaque


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
if logscale
    s = scatter3(x, y, z, markerSize*c, c, 'filled')
    xscale('log'); yscale('log'); zscale('log')
    xlabel(sprintf(['Distance [m] \n logscale']));
    ylabel(sprintf('Visual Angle [degree]\n logscale'));
    hz=zlabel({'Elevation [degree], logscale'});
    axis('tight')
else
    hx=xlabel({'Distance [m]'});
    hy=ylabel({'Visual Angle [degree]'});
    hz=zlabel({'Elevation [degree]'});
   
end
set(gca,'FontName','Avenir','FontSize',24)
hx.Rotation = 15;     % rotate X label by 20 degrees
hx.HorizontalAlignment='center';
hy.Rotation = -25;    % rotate Y label by -30 degrees
hy.HorizontalAlignment='center';
hz.Rotation = 90;      % Z usually vertical; can adjust if needed

grid on; box on;
colormap turbo  

pm_min=0.5;
pm_max=5;

caxis([pm_min pm_max]); % use conistent coloraxis across tasks

cb = colorbar('eastoutside');
cb.FontSize=20;
cb.FontName='Avenir';
cb.Position=[[0.92 0.45 0.01 0.2000]]
cb.Label.String = 'Perceptual Magnification';
cb.Label.FontSize = 20;        % optional
cb.Label.FontName='Avenir';

titlestr=sprintf('%s task PM=%.2f(VA)^{%.2f}D^{%.2f}(1+E)^{%.2f}\n minPM=%.2f maxPM=%.2f', task, 2.^Intercept,VAe,De,Ee, min(c),max(c));
title(titlestr,'FontSize',24,'FontName','Avenir')

% save figure
figName=sprintf('%s_%s_visualize_PMbyVA_DS_EL.png',OutFile, task);
filenamePNG=fullfile(ResultsDir, figName);
exportgraphics(gcf,filenamePNG,'Resolution',600);



%% more colormaps
% cmap=slanCM('gnuplot',256)
% colormap(cmap);
