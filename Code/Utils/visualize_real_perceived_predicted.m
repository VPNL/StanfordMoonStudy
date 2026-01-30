function visualize_real_perceived_predicted(data_tbl,lme_logPM_by_logAngleNDistanceNElevation,ResultsDir,FigName,VAmax, distance_mm)

if ~exist('data_tbl','var')
    disp("error no data table")
    return
end
if ~exist('lme_logPM_by_logAngleNDistanceNElevation','var')
    disp("error no lme cannot evaluate PM")
    return
end
if ~exist('ResultsDir','var')
   ResultsDir='.';
end
if ~exist('FileName','var')
   FileName='Visualize';
end

if ~exist('distance_mm','var')
    distance_mm=500; % 50 cm typical screen distance
end
if ~exist('VAmax','var')
    VAmax=1; % 1 degree
end
% lets visualize  real, predicted, perceived visual angle
 jj=find(data_tbl.Real_Visual_Angle<VAmax);
 tbl2plot=data_tbl(jj,:);
 all_VA=sort(unique(tbl2plot.Real_Visual_Angle));
 for i=1:numel(all_VA)
    mm=find(tbl2plot.Real_Visual_Angle==all_VA(i));
    temp_data=tbl2plot(mm,:);
    realVA=mean(temp_data.Real_Visual_Angle);
    perceivedVA=realVA*mean(temp_data.Ratio_Visual_Angle);
    D=mean(temp_data.Distance);
    E=mean(temp_data.Elevation);
    PM=evaluatePMbyVisualAngleDistanceElevation(lme_logPM_by_logAngleNDistanceNElevation,realVA,D,E);
    predictedVA= realVA*PM;
    textstring=sprintf('VA=%.1f[{\\circ}]  D=%.1f[m]  E=%.1f[{\\circ}] ', realVA,D,E);
   
    distance_mm=500;
    realRadius_mm=visualangle2height(realVA,distance_mm);
    perceivedRadius_mm=visualangle2height(perceivedVA,distance_mm);
    predictedRadius_mm=visualangle2height(predictedVA,distance_mm);
    saveFlag=1;
    saveFilename=fullfile(ResultsDir,sprintf('%s_circle_VA%.1fD%.1fE%.1f.png', FigName,realVA,D,E));
    drawRealPerceivedPredictedVA(realRadius_mm, perceivedRadius_mm, predictedRadius_mm, textstring, saveFlag,saveFilename);
    saveFilename=fullfile(ResultsDir,sprintf('%s_Stick_VA%.1fD%.1fE%.1f.png', FigName,realVA,D,E));
    mycolor=[.5 .5 1];
    drawRealPerceivedPredictedVA_VertRects(realRadius_mm, perceivedRadius_mm, predictedRadius_mm, textstring, saveFlag, saveFilename, mycolor)
 end

close all; % close figures to remove clutter
end