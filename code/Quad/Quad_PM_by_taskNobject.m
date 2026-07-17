function Quad_PM_by_taskNobject(tbl,tblName,ResultsDir,saveLME,colormap)


%% find max angle and maxRatio for graphs

maxRealAngle=max(tbl.Real_Visual_Angle);
maxAngle=max(tbl.Reported_Visual_Angle);

maxRatio=max(tbl.Ratio_Visual_Angle);
% transform distances from cm to m 
tbl.Distance=tbl.Distance/100;
maxDistance=max(tbl.Distance);
minDistance=min(tbl.Distance);
%
tbl.log2real_visual_angle=log2(tbl.Real_Visual_Angle);
tbl.log2ratio_visual_angle=log2(tbl.Ratio_Visual_Angle);
tbl.log2distance=log2(tbl.Distance);

lme_logPM_by_logAngle= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle +  (1| ID)')
lme_logPM_by_logAngleNObject= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle+ Object + (1| ID)')

lme_logPM_by_logDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2distance +  (1| ID)')
lme_logPM_by_logDistanceNObject= fitlme(tbl,'log2ratio_visual_angle ~ log2distance+ Object + (1| ID)')

lme_logPM_by_logAngleNDistance= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance +  (1| ID)')
lme_logPM_by_logAngleNDistanceNObject= fitlme(tbl,'log2ratio_visual_angle ~ log2real_visual_angle + log2distance + Object+ (1| ID)')

if saveLME
    savelmefile=fullfile('.',ResultsDir, [tblName '.txt']);
    diary(savelmefile)
    lme_logPM_by_logAngle
    lme_logPM_by_logAngleNObject
    lme_logPM_by_logDistance
    lme_logPM_by_logDistanceNObject
    lme_logPM_by_logAngleNDistance
    lme_logPM_by_logAngleNDistanceNObject
    diary off
end
%%
% plot results
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 .7 .5],'Name',tblName)
markerSize=50;
subplot(1,2,1); % plot PM by visual angle different colors per object
hold on 
Objects=unique(tbl.Object);
for i = 1:numel(Objects)
    currentObj = Objects{i};
    idx = find(strcmp(tbl.Object, currentObj)); % Find indices for current category
    
    scatter(tbl.log2real_visual_angle(idx), tbl.log2ratio_visual_angle(idx), markerSize, colormap(i,:), 'filled', 'DisplayName', currentObj);
end

xlinerange=log2(.25):.05:log2(maxRealAngle); 
ylinerange=zeros(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
 
set(gca,'XTick',log2(.25):1:log2(maxRealAngle),'XTickLabel',2.^[log2(.25):1:log2(maxRealAngle)],'XTickLabelRotation',0);
set(gca,'YTick',log2(.25):1:round(log2(8)),'YTickLabel',2.^[log2(.25):1:round(log2(8))]);
axis([log2(.25) log2(maxRealAngle*1.1) log2(.25) round(log2(8))])
xlabel ('Real Visual Angle (degree) log scale')
ylabel ('Perceptual Magnification log scale')

set(gca,'FontName','Avenir','FontSize',16)
%plot PM by distance different colors per object
subplot(1,2,2); 
hold on 
Objects=unique(tbl.Object);
for i = 1:numel(Objects)
    currentObj = Objects{i};
    idx = find(strcmp(tbl.Object, currentObj)); % Find indices for current category
    scatter(tbl.log2distance(idx), tbl.log2ratio_visual_angle(idx), markerSize, colormap(i,:), 'filled', 'DisplayName', currentObj);
end

xlinerange=log2(minDistance-1):.05:log2(maxDistance+1); 
ylinerange=zeros(size(xlinerange));
plot (xlinerange, ylinerange,'k:','LineWidth',1);% plot no magnification line
 
set(gca,'XTick',log2(minDistance):1:log2(maxDistance),'XTickLabel',2.^[log2(minDistance):1:log2(maxDistance)],'XTickLabelRotation',0);
set(gca,'YTick',log2(.25):1:round(log2(8)),'YTickLabel',2.^[log2(.25):1:round(log2(8))]);
axis([log2(minDistance-1) log2(maxDistance+1) log2(.25) round(log2(8))])
xlabel ('Distance [m], log scale')
ylabel ('Perceptual Magnification, log scale')
set(gca,'FontName','Avenir','FontSize',16)
filenamePNG=fullfile('.',ResultsDir, [tblName '.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);
