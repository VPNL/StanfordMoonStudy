%%
% 
%  Split csv file into 3 tables by date ranges corresponding to the 3
%  versions of the experiment
close all; clear all
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
cd(expDir)
%csvfile='AllQuadDataLong916.csv'
csvfile = 'SQSData106.csv';   % <- if needed, replace with full path

datafile=fullfile(expDir,'Data',csvfile);
basename = erase(csvfile,'.csv'); % for saving
saveLME=1;
ResultsDir='Results/010626/'
if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
   cd Results
end
T = readtable(datafile);
%%

% ---- Parse Date column robustly ----
% Your table appears to have Date values like "02/17/0025" (MM/dd/yyyy).
% If your Date variable name differs, update 'Date' below.
if ~ismember('Date', T.Properties.VariableNames)
    error('Could not find a variable named "Date" in the table.');
end

% Convert to datetime (handle if Date is char/cell/string already)
try
    T.Date_dt = datetime(T.Date, 'InputFormat','MM/dd/yyyy');
catch
    % Fallback: convert to string then datetime
    T.Date_dt = datetime(string(T.Date), 'InputFormat','MM/dd/yyyy');
end

%%
% ---- Define date ranges (inclusive) ----
ranges = struct( ...
    'name', {'Version1','Version2','Version3'}, ...
    'start', {datetime(2024,2,16), datetime(2024,7,25),  datetime(2025,5,30)}, ...
    'end',   {datetime(2024,5,31), datetime(2024,11,8), datetime(2025,7,31)} ...
);
%%
% Helper to ensure start <= end
orderRange = @(a,b) deal(min(a,b), max(a,b));

% ---- Split tables ----
T1 = T([],:); T2 = T([],:); T3 = T([],:);  % initialize with same vars

for i = 1:numel(ranges)
    [d1, d2] = orderRange(ranges(i).start, ranges(i).end);
    idx = (T.Date_dt >= d1) & (T.Date_dt <= d2);

    switch ranges(i).name
        case 'Version1', T1 = T(idx,:);
        case 'Version2', T2 = T(idx,:);
        case 'Version3', T3 = T(idx,:);
    end
end



% ---- Save new tables 
datafile1=fullfile(expDir,'Data','SQSData106_Table1_021624_to_053124.csv');
writetable(T1, datafile1);
datafile2=fullfile(expDir,'Data','SQSData106_Table2_072524_to_110824.csv');
writetable(T2, datafile2);
datafile3=fullfile(expDir,'Data','SQSData106_Table3_053025_to_073125.csv');
writetable(T3, datafile3);