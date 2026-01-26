%% Create a new table excluding rows whose Measurement contains 'ball'
close all; clear all
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/'
cd(expDir)
csvfile = 'SQSData106.csv';   % <- if needed, replace with full path

datafile=fullfile(expDir,'Data',csvfile);
basename = erase(csvfile,'.csv'); % for saving
saveLME=1;
T = readtable(datafile);
%%
% Confirm variable exists
if ~ismember('Measurement', T.Properties.VariableNames)
    error('Could not find a variable named "Measurement" in the table.');
end

% Convert Measurement to string safely (works for cellstr/char/string/categorical)
measStr = string(T.Measurement);

% Exclude any row where Measurement contains 'ball' (case-insensitive)
%idx_keep = ~contains(measStr, "ball", 'IgnoreCase', true);
idx_keep =find(~contains(measStr, "Lamp7", 'IgnoreCase', true));
T_noBall = T(idx_keep, :);
measStr = string(T_noBall.Measurement);
idx_keep= find(~contains(measStr, "Stick7", 'IgnoreCase', true));
T_noBall = T_noBall(idx_keep, :);

% (Optional) sanity check
fprintf('Original rows: %d | Kept rows (no "ball"): %d | Removed: %d\n', ...
    height(T), height(T_noBall), height(T)-height(T_noBall));

% (Optional) write out
newdatafile=fullfile(expDir,'Data','SQSData106_no7.csv');
writetable(T_noBall, newdatafile);
