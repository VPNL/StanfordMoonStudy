function newtable=Quad_keep_entries(expDir, tablename, newtablename, KeepEntries)

%% Create a new table excluding rows whose Measurement contains 'ball'
if ~exist('expDir','var')   
    expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
end
if ~exist('tablename','var') 
    tablename = 'SQSData106_Table3_053025_to_073125.csv';   % <- if needed, replace with full path
end
if ~exist('newtablename','var')
    newtablename= ['new_' tablename]
end
if ~exist('KeepEntries','var')
    disp('No Entires were given')
    return
end

datafile=fullfile(expDir,'Data',tablename);
basename = erase(tablename,'.csv'); % for saving
saveLME=1;
T = readtable(datafile);

% Filter SQS table to keep only rows whose Measurement contains:
%   lamp5, stick5, lamp6, or ball (case-insensitive),
% then write the filtered table to a new CSV.


% Ensure Measurement is treated as text
if ~ismember('Measurement', T.Properties.VariableNames)
    error('Input table does not contain a column named "Measurement".');
end

mLower = lower(string(T.Measurement));

% Convert KeepEntires to lowercase strings (robust to char/string mixes)
entries = lower(string(KeepEntries(:)));

% Keep row if Measurement contains ANY key
keep = false(size(mLower));
for k = 1:numel(entries)
    keep = keep | contains(mLower, entries(k));
end
newtable= T(keep, :);

outFile=fullfile(expDir,'Data',newtablename);
writetable(newtable, outFile);
disp("Wrote: " + outFile);

