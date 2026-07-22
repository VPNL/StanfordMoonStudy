function analysisSpecs = quadBuildDisparityAnalysisSpecs( ...
    allQuadData, versionLabels, version3DiskOnly)
%QUADBUILDDISPARITYANALYSISSPECS Build version-specific disparity subsets.

if nargin < 3 || isempty(version3DiskOnly)
    version3DiskOnly = false;
end

analysisSpecs = repmat(struct('Label', "", 'Table', table()), ...
    numel(versionLabels), 1);

for versionIdx = 1:numel(versionLabels)
    versionLabel = string(versionLabels(versionIdx));

    switch versionLabel
        case "AllVersions"
            tableSubset = allQuadData;
            if version3DiskOnly && ...
                    ismember('Version', tableSubset.Properties.VariableNames) && ...
                    ismember('Measurement', tableSubset.Properties.VariableNames)
                measurementText = lower(string(tableSubset.Measurement));
                keepRows = tableSubset.Version ~= 3 | contains(measurementText, "disk");
                tableSubset = tableSubset(keepRows, :);
            end

        case "Versions1and2"
            tableSubset = allQuadData(ismember(allQuadData.Version, [1 2]), :);

        case "Version3Lamp5"
            tableSubset = allQuadData(allQuadData.Version == 3, :);
            measurementText = lower(string(tableSubset.Measurement));
            tableSubset = tableSubset(contains(measurementText, "lamp5disk"), :);

        case "Version3Lamp7"
            tableSubset = allQuadData(allQuadData.Version == 3, :);
            measurementText = lower(string(tableSubset.Measurement));
            tableSubset = tableSubset(contains(measurementText, "lamp7"), :);

        otherwise
            versionNumber = sscanf(char(versionLabel), 'Version%d');
            tableSubset = allQuadData(allQuadData.Version == versionNumber, :);
            if versionLabel == "Version3" && ...
                    ismember('Measurement', tableSubset.Properties.VariableNames)
                measurementText = lower(string(tableSubset.Measurement));
                if version3DiskOnly
                    keepRows = contains(measurementText, "disk");
                else
                    keepRows = contains(measurementText, "lamp5disk") | ...
                        contains(measurementText, "lamp7");
                end
                tableSubset = tableSubset(keepRows, :);
            end
    end

    analysisSpecs(versionIdx).Label = versionLabel;
    analysisSpecs(versionIdx).Table = tableSubset;
end
end
