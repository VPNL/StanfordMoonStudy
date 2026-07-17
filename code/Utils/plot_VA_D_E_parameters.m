function [figh] = plot_VA_D_E_parameters(tbl,tblBasename,ResultsDir)
% plot_VA_D_E_parameters(tbl,tblBasename,ResultsDir)
% plots relations between visual_angle (VA), distance (D), Elevation (E)
% for data in table tbl


figh=figure('color','w','name', tblBasename, 'Units','normalized','Position',[0 0 1 .5]);
subplot(1,3,1); scatter(tbl.Distance,tbl.Elevation,'k','filled');
xlabel('Distance [m]'); ylabel('Elevation [degrees]'); set(gca,'FontName','Avenir','FontSize',16);
subplot(1,3,2); scatter(tbl.Distance,tbl.Real_Visual_Angle,'k','filled');
xlabel('Distance [m]'); ylabel('Visual Angle [degrees]'); set(gca,'FontName','Avenir','FontSize',16);
subplot(1,3,3); scatter(tbl.Elevation,tbl.Real_Visual_Angle,'k','filled');
xlabel('Elevation [degree]'); ylabel('Visual Angle [degrees]'); set(gca,'FontName','Avenir','FontSize',16);

filenamePNG=fullfile(ResultsDir, [tblBasename '_parameters.png']);
print(figh, filenamePNG, '-dpng', '-r600');

figh=figure('color','w','name', tblBasename, 'Units','normalized','Position',[0 0 .5 1])
scatter3(tbl.Distance,tbl.Real_Visual_Angle, tbl.Elevation,'k','filled','o');
xlabel('Distance [m]'); ylabel('Visual Angle [degrees]');zlabel('Elevation [degrees]');
az=45; el=35;
view (az,el)
set(gca,'FontSize',14,'FontName','Avenir')
filenamePNG=fullfile(ResultsDir, [tblBasename '_parameters_3D.png']);
print(figh, filenamePNG, '-dpng', '-r600');
