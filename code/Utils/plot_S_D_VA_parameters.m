function [figh] = plot_S_D_VA_parameters(tbl,tblBasename,ResultsDir)
% plot_S_D_VA_parameters(tbl,tblBasename,ResultsDir)
% plots relations between Size (S), Distance (D), Elevation (E)
% for data in table tbl


figh=figure('color','w','name', tblBasename, 'Units','normalized','Position',[0 0 1 .5]);
subplot(1,3,1); scatter(tbl.Distance,tbl.Size,'k','filled');
xlabel('Distance [m]'); ylabel('Size [m]'); set(gca,'FontName','Avenir','FontSize',16);
subplot(1,3,2); scatter(tbl.Distance,tbl.Real_Visual_Angle,'k','filled');
xlabel('Distance [m]'); ylabel('Visual Angle [degrees]'); set(gca,'FontName','Avenir','FontSize',16);
subplot(1,3,3); scatter(tbl.Size,tbl.Real_Visual_Angle,'k','filled');
xlabel('Size[m]'); ylabel('Visual Angle [degree]'); set(gca,'FontName','Avenir','FontSize',16);

filenamePNG=fullfile(ResultsDir, [tblBasename '_parameters.png']);
print(figh, filenamePNG, '-dpng', '-r600');

figh=figure('color','w','name', tblBasename, 'Units','normalized','Position',[0 0 .5 1])
scatter3(tbl.Distance,tbl.Size, tbl.Real_Visual_Angle,'k','filled','o');
xlabel('Distance [m]'); ylabel('Size [m]');zlabel('Visual Angle [degrees]');
az=45; el=35;
view (az,el)
set(gca,'FontSize',14,'FontName','Avenir')
filenamePNG=fullfile(ResultsDir, [tblBasename '_parameters_3D.png']);
print(figh, filenamePNG, '-dpng', '-r600');
