function visualize_real_perceived_predicted(data_tbl,lme_logPM_by_logAngleNDistanceNElevation,ResultsDir,FigName,VAmax, distance_mm,elevationTransform)

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
if ~exist('FigName','var') || isempty(FigName)
   FigName='Visualize';
end

if ~exist('distance_mm','var')
    distance_mm=500; % 50 cm typical screen distance
end
if ~exist('VAmax','var')
    VAmax=1; % 1 degree
end
if ~exist('elevationTransform','var') || isempty(elevationTransform)
    elevationTransform = 1;
end
% lets visualize  real, predicted, perceived visual angle
 jj=find(data_tbl.Real_Visual_Angle<VAmax);
 tbl2plot=data_tbl(jj,:);
 all_VA=sort(unique(tbl2plot.Real_Visual_Angle));
 for i=1:numel(all_VA)
    mm=find(tbl2plot.Real_Visual_Angle==all_VA(i));
    temp_data=tbl2plot(mm,:);
    measurementLabel = local_get_measurement_label(temp_data, i);
    realVA=mean(temp_data.Real_Visual_Angle);
    perceivedVA=realVA*mean(temp_data.Ratio_Visual_Angle);
    perceivedPM=mean(temp_data.Ratio_Visual_Angle);
    D=mean(temp_data.Distance);
    E=mean(temp_data.Elevation);
    E_for_model = local_transform_elevation_for_prediction(E, elevationTransform);
    PM=evaluatePMbyVisualAngleDistanceElevation(lme_logPM_by_logAngleNDistanceNElevation,realVA,D,E_for_model);
    predictedVA= realVA*PM;
    textstring=sprintf('VA=%.1f[{\\circ}] D=%.1f[m] E=%.1f[{\\circ}] perceivedPM=%.1f predictedPM=%.1f',realVA,D,E, perceivedPM, PM);
   
    realRadius_mm=visualangle2height(realVA,distance_mm);
    perceivedRadius_mm=visualangle2height(perceivedVA,distance_mm);
    predictedRadius_mm=visualangle2height(predictedVA,distance_mm);
    saveFlag=1;
    saveFilename=fullfile(ResultsDir,sprintf('%s_%s_VA%.1fD%.1fE%.1fPMperceived%.1fpredicted%.1f.png', FigName,measurementLabel,realVA,D,E,perceivedPM,PM));
    if contains(lower(string(measurementLabel)), "stick")
        drawRealPerceivedPredictedVA_VertRects(realRadius_mm, perceivedRadius_mm, predictedRadius_mm, textstring, saveFlag, saveFilename);
    else
        drawRealPerceivedPredictedVA(realRadius_mm, perceivedRadius_mm, predictedRadius_mm, textstring, saveFlag,saveFilename);
    end
 end

close all; % close figures to remove clutter
end

function E_out = local_transform_elevation_for_prediction(E_in, elevationTransform)
switch elevationTransform
    case 0
        E_out = E_in;
    case 1
        % Legacy ObserverFlag=true behavior: use absolute elevation.
        E_out = abs(E_in);
    case 2
        E_out = abs(E_in);
    case 3
        E_out = pi * E_in / 180;
    case 4
        E_out = pi * abs(E_in) / 180;
    case 5
        E_out = E_in / 90;
    case 6
        E_out = abs(E_in) / 90;
    otherwise
        error('Unsupported elevation transform %d.', elevationTransform);
end
end

function measurementLabel = local_get_measurement_label(temp_data, idx)
measurementLabel = sprintf('measurement%02d', idx);
if ~ismember('Measurement', temp_data.Properties.VariableNames)
    return
end

measurementValues = unique(string(temp_data.Measurement));
measurementValues = measurementValues(measurementValues ~= "");
if isempty(measurementValues)
    return
end

measurementLabel = char(measurementValues(1));
measurementLabel = regexprep(measurementLabel, '[^A-Za-z0-9]+', '_');
measurementLabel = regexprep(measurementLabel, '_+', '_');
measurementLabel = regexprep(measurementLabel, '^_|_$', '');
if isempty(measurementLabel)
    measurementLabel = sprintf('measurement%02d', idx);
end
end
