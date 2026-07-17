function [summaryTbl, outFile] = build_moon_supplemental_table1(moonInput, outFile)
% build_moon_supplemental_table1
%
% Build a one-row-per-date moon summary table from FullMoonDataLong-style
% data and write a CSV with columns:
%   Date
%   Diameter [km]
%   Distance [km]
%   Visual angle [degrees]
%   N participants
%
% Inputs
%   moonInput : table or CSV file path
%   outFile   : optional output CSV path
%
% Outputs
%   summaryTbl : summary table with valid MATLAB variable names
%   outFile    : output CSV path used
%
% Example
%   dataFile = '/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/FullMoonDataLong090225.csv';
%   [summaryTbl, outFile] = build_moon_supplemental_table1(dataFile);

if nargin < 1 || isempty(moonInput)
    error('moonInput is required.');
end

if istable(moonInput)
    moonTbl = moonInput;
    inputDir = pwd;
else
    moonInput = char(string(moonInput));
    if ~exist(moonInput, 'file')
        error('Could not find input file: %s', moonInput);
    end
    moonTbl = readtable(moonInput);
    inputDir = fileparts(moonInput);
end

requiredVars = {'ID','Date','Distance','Real_Visual_Angle'};
for iVar = 1:numel(requiredVars)
    if ~ismember(requiredVars{iVar}, moonTbl.Properties.VariableNames)
        error('Input moon table is missing required variable "%s".', requiredVars{iVar});
    end
end

if nargin < 2 || isempty(outFile)
    outFile = fullfile(inputDir, 'supplemental_table1.csv');
end

dateStr = moonTbl.Date;
dateStr = erase(string(dateStr),'00');
distanceKm = moonTbl.Distance;
visualAngleDeg = moonTbl.Real_Visual_Angle;

uniqueDates = unique(dateStr, 'stable');
nDates = numel(uniqueDates);

summaryTbl = table('Size', [nDates 5], ...
    'VariableTypes', {'string','double','double','double','double'}, ...
    'VariableNames', {'Date','Diameter_km','Distance_km','Visual_angle_degrees','N_Participants'});

sortDate = NaT(nDates, 1);

for iDate = 1:nDates
    thisDate = uniqueDates(iDate);
    idx = dateStr == thisDate;

    meanDistanceKm = mean(distanceKm(idx), 'omitnan');
    meanVisualAngleDeg = mean(visualAngleDeg(idx), 'omitnan');
    meanDiameterKm = 2 * meanDistanceKm * tand(meanVisualAngleDeg / 2);

    if isnat(sortDate(iDate))
        summaryTbl.Date(iDate) = thisDate;
    else
        summaryTbl.Date(iDate) = string(datestr(sortDate(iDate), 'm/dd/yy'));
    end
    summaryTbl.Diameter_km(iDate) = meanDiameterKm;
    summaryTbl.Distance_km(iDate) = meanDistanceKm;
    summaryTbl.Visual_angle_degrees(iDate) = meanVisualAngleDeg;
    summaryTbl.N_Participants(iDate) = local_count_unique_ids(moonTbl.ID(idx));

    sortDate(iDate) = local_parse_moon_date(thisDate);
end

if any(~isnat(sortDate))
    validSort = ~isnat(sortDate);
    summaryTblValid = summaryTbl(validSort, :);
    [~, orderValid] = sort(sortDate(validSort));
    summaryTblValid = summaryTblValid(orderValid, :);

    if any(~validSort)
        summaryTbl = [summaryTblValid; summaryTbl(~validSort, :)];
    else
        summaryTbl = summaryTblValid;
    end
end

writetable(summaryTbl, outFile);
end

function n = local_count_unique_ids(ids)
if isnumeric(ids)
    ids = ids(~isnan(ids));
elseif iscategorical(ids)
    ids = ids(~isundefined(ids));
end

ids = strtrim(string(ids(:)));
ids = ids(~ismissing(ids) & strlength(ids) > 0 & lower(ids) ~= "nan");
n = numel(unique(ids));
end

function dt = local_parse_moon_date(dateValue)
dateValue = string(dateValue);
try
    dt = datetime(dateValue, 'InputFormat', 'M/d/yy');
catch
    try
        dt = datetime(dateValue, 'InputFormat', 'M/d/yyyy');
    catch
        try
            dt = datetime(dateValue);
        catch
            dt = NaT;
        end
    end
end
end
