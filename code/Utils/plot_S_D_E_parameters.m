function [figh] = plot_S_D_E_parameters(tbl,tblBasename,ResultsDir)
% plot_S_D_E_parameters(tbl,tblBasename,ResultsDir)
% plots relations between Size (S), Distance (D), Elevation (E)
% for data in table tbl


figh=figure('color','w','name', tblBasename, 'Units','normalized','Position',[0 0 1 .5]);
subplot(1,3,1); scatter(tbl.Distance,tbl.Elevation,'k','filled');
xlabel('Distance [m]'); ylabel('Elevation [degrees]'); set(gca,'FontName','Avenir','FontSize',16);
subplot(1,3,2); scatter(tbl.Distance,tbl.Size,'k','filled');
xlabel('Distance [m]'); ylabel('Size [m]'); set(gca,'FontName','Avenir','FontSize',16);
subplot(1,3,3); scatter(tbl.Elevation,tbl.Size,'k','filled');
xlabel('Elevation [degree]'); ylabel('Size[m]'); set(gca,'FontName','Avenir','FontSize',16);

filenamePNG=fullfile(ResultsDir, [tblBasename '_parameters.png']);
print(figh, filenamePNG, '-dpng', '-r600');

figh=figure('color','w','name', tblBasename, 'Units','normalized','Position',[0 0 .5 1])
scatter3(tbl.Distance,tbl.Size, tbl.Elevation,'k','filled','o');
xlabel('Distance [m]'); ylabel('Size [m]');zlabel('Elevation [degrees]');
az=45; el=35;
view (az,el)
set(gca,'FontSize',14,'FontName','Avenir')
filenamePNG=fullfile(ResultsDir, [tblBasename '_parameters_3D.png']);
print(figh, filenamePNG, '-dpng', '-r600');
