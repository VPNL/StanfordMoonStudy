% Quad_PerceivedDisparity_angle_distance_elevation_032626

close all; clear all;
set(groot,'defaultFigureVisible','off');

codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir))
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/Data'

QuadFileName='QuadProcessedDisparityData032626_11pm_6001cleaned.csv';
QuadBaseName=erase(QuadFileName,'.csv')
DataDir=fullfile(expDir,'Data');
elevationVarName='Observer_Elevation';
distanceVarName='Observer_Distance';

ResultsDir=fullfile(expDir,['PerceivedDisparity_' QuadBaseName '_allTransforms']);
%   transformId : integer transform code
%                 1 = Elevation
%                 2 = absElevation
%                 3 = ElevationRAD
%                 4 = absElevationRAD
%                 5 = ElevationD90
%                 6 = absElevationD90
%
ElevationTransforms=[2 5 6];
saveLME=1;
recomputeColorIndex=1;
removeOutlierParticipants=1;
removeZScoreOutliers=1;
zScoreThreshold=3;
version3DiskOnly=1;

if ~exist(ResultsDir,'dir')
    mkdir(ResultsDir)
end

all_quad_data = readtable(fullfile(DataDir, QuadFileName));
[~, QuadBasename, ~] = fileparts(QuadFileName);

if ~ismember('Elevation', all_quad_data.Properties.VariableNames)
    if ismember(elevationVarName, all_quad_data.Properties.VariableNames)
        all_quad_data.Elevation = all_quad_data.(elevationVarName);
    else
        error('Missing elevation variable "%s" and no standard Elevation column found.', elevationVarName);
    end
end

if ~ismember('Distance', all_quad_data.Properties.VariableNames)
    if ismember(distanceVarName, all_quad_data.Properties.VariableNames)
        all_quad_data.Distance = all_quad_data.(distanceVarName);
    else
        error('Missing distance variable "%s" and no standard Distance column found.', distanceVarName);
    end
end

[prepBaseTbl, ~] = apply_quad_elevation_transform(all_quad_data, ElevationTransforms(1));
prepTbl = Quad_prepare_perceived_disparity_table(prepBaseTbl, ElevationTransforms(1), removeOutlierParticipants);
[sorted_color_idx, mean_disparity_by_id, uniqueID, cmap] = ...
    Quad_compute_mean_disparity_color_idx(prepTbl, ResultsDir, QuadBasename, recomputeColorIndex);

summaryStore = struct();
lmeStore = struct();
versionLabels = [ "Versions1and2" "Version3" "Version3Lamp5" "Version3Lamp7"];
analysisSpecs = local_build_analysis_specs(all_quad_data, versionLabels, version3DiskOnly);

for transformId = ElevationTransforms
    [~, transformInfo] = apply_quad_elevation_transform(all_quad_data(1,:), transformId);
    sfx = char(transformInfo.sfx);
    TransformResultsDir = fullfile(ResultsDir, sfx);
    if ~exist(TransformResultsDir,'dir')
        mkdir(TransformResultsDir)
    end

    for iVersion = 1:numel(analysisSpecs)
        versionLabel = analysisSpecs(iVersion).label;
        tblSubset = analysisSpecs(iVersion).tbl;
        [tblSubset, ~] = apply_quad_elevation_transform(tblSubset, transformId);
        prepSubset = Quad_prepare_perceived_disparity_table(tblSubset, transformId, removeOutlierParticipants);

        outlierIDs = strings(0,1);
        outlierStatsTbl = table();
        if removeZScoreOutliers
            [outlierIDs, outlierStatsTbl] = find_subject_outliers_by_zscore(prepSubset, 'MeanDisparity', 'ID', zScoreThreshold);
            if ~isempty(outlierIDs)
                fprintf('Removing z-score outlier IDs for %s %s: %s\n', char(versionLabel), sfx, strjoin(cellstr(outlierIDs), ', '));
                keepRows = ~ismember(string(tblSubset.ID), string(outlierIDs));
                tblSubset = tblSubset(keepRows, :);
                prepSubset = Quad_prepare_perceived_disparity_table(tblSubset, transformId, removeOutlierParticipants);
            else
                fprintf('No z-score outlier IDs for %s %s at threshold %.2f\n', char(versionLabel), sfx, zScoreThreshold);
            end
        end

        VersionResultsDir = fullfile(TransformResultsDir, char(versionLabel));
        if ~exist(VersionResultsDir, 'dir')
            mkdir(VersionResultsDir)
        end

        if removeZScoreOutliers
            writetable(outlierStatsTbl, fullfile(VersionResultsDir, [QuadBasename '_' char(versionLabel) '_' sfx '_outlier_zscores.csv']));
            fid = fopen(fullfile(VersionResultsDir, [QuadBasename '_' char(versionLabel) '_' sfx '_outlier_IDs.txt']), 'w');
            if fid >= 0
                if isempty(outlierIDs)
                    fprintf(fid, 'No outlier IDs removed.\n');
                else
                    fprintf(fid, 'Removed outlier IDs (|z| > %.2f):\n', zScoreThreshold);
                    for iOut = 1:numel(outlierIDs)
                        fprintf(fid, '%s\n', outlierIDs{iOut});
                    end
                end
                fclose(fid);
            end
        end

        tblName = [QuadBasename '_' char(versionLabel) '_' sfx];
        [lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logDistanceNElevation, lme_logPM_by_logAngleNDistanceNElevation, ...
            lme_logPM_by_logAngleNElevation, lme_logPM_by_logAngleNDistance, ...
            lme_logPM_by_logAngle] = ...
            Quad_PerceivedOffset_by_VADistanceElevation(tblSubset, tblName, ...
            VersionResultsDir, saveLME, cmap, sorted_color_idx, transformId, ...
            1, uniqueID, removeOutlierParticipants);

        outCsvFile = fullfile(VersionResultsDir, [tblName '_lme_summary.csv']);
        summaryTbl = Quad_export_PercievedDisparity_LME_summary_csv(QuadBasename, ...
            lme_logPM_by_logAngle, lme_logPM_by_logDistance, lme_logPM_by_logElevation, ...
            lme_logPM_by_logAngleNDistance, lme_logPM_by_logAngleNElevation, lme_logPM_by_logDistanceNElevation, ...
            lme_logPM_by_logAngleNDistanceNElevation, outCsvFile);

        lme_full = fit_PerceivedDisparity_lme_wMax(tblSubset, [tblName '_fullmodel_fit'], VersionResultsDir, saveLME, cmap, sorted_color_idx, transformId, uniqueID, removeOutlierParticipants);

        summaryStore.(sfx).(char(versionLabel)) = summaryTbl;
        lmeStore.(sfx).(char(versionLabel)) = lme_full;
    end
end

save(fullfile(ResultsDir, [QuadBasename '_perceived_disparity_results.mat']), ...
    'summaryStore', 'lmeStore', 'sorted_color_idx', 'mean_disparity_by_id', 'uniqueID', 'removeOutlierParticipants', 'ElevationTransforms', 'version3DiskOnly');

function analysisSpecs = local_build_analysis_specs(all_quad_data, versionLabels, version3DiskOnly)
analysisSpecs = struct('label', {}, 'tbl', {});

for iVersion = 1:numel(versionLabels)
    versionLabel = versionLabels(iVersion);
    if versionLabel == "AllVersions"
        tblSubset = all_quad_data;
        if version3DiskOnly && ismember('Version', tblSubset.Properties.VariableNames) && ismember('Measurement', tblSubset.Properties.VariableNames)
            measLower = lower(string(tblSubset.Measurement));
            keepRows = tblSubset.Version ~= 3 | contains(measLower, "disk");
            tblSubset = tblSubset(keepRows, :);
        end
    elseif versionLabel == "Versions1and2"
        tblSubset = all_quad_data(ismember(all_quad_data.Version, [1 2]), :);
    elseif versionLabel == "Version3Lamp5"
        tblSubset = all_quad_data(all_quad_data.Version == 3, :);
        measLower = lower(string(tblSubset.Measurement));
        tblSubset = tblSubset(contains(measLower, "lamp5"), :);
    elseif versionLabel == "Version3Lamp7"
        tblSubset = all_quad_data(all_quad_data.Version == 3, :);
        measLower = lower(string(tblSubset.Measurement));
        tblSubset = tblSubset(contains(measLower, "lamp7"), :);
    else
        versionNum = sscanf(char(versionLabel), 'Version%d');
        tblSubset = all_quad_data(all_quad_data.Version == versionNum, :);
        if versionLabel == "Version3" && version3DiskOnly && ismember('Measurement', tblSubset.Properties.VariableNames)
            measLower = lower(string(tblSubset.Measurement));
            tblSubset = tblSubset(contains(measLower, "disk"), :);
        end
    end
    analysisSpecs(end+1).label = versionLabel; %#ok<AGROW>
    analysisSpecs(end).tbl = tblSubset;
end
end
