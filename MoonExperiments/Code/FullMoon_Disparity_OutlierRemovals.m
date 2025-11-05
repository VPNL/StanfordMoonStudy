% remove outlier subjects in the adjusted task

%% FullMoon_Disparity_OutlierRemovals (Adjusted task) 
close all; clear all;

% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/'
cd(dataDir)
datafile='Disparity_BothElevations_FullMoonDataLong821.csv'; % all data
basename = [erase( datafile,'.csv')] ; % for saving


%% read data 
all_data=readtable(datafile);
T = all_data;

%%
% Normalize columns for grouping/tests
sess = string(T.Session);        % 'Lower'/'Higher'
task = string(T.Task);           % 'Adjusted'/'Perceptual'

% Normalize Date key (keep datetime if already datetime)
if isdatetime(T.Date)
    dkey = T.Date;
else
    dkey = string(T.Date);
end

% --- 1) Find outliers only within Adjusted task ---
isAdj = (task == "Adjusted");
ratioAdj = T.Ratio_Visual_Angle(isAdj);

% Outlier detection (MAD by default; change method if desired)
outAdj = false(height(T),1);
outAdj(isAdj) = isoutlier(ratioAdj);   % mark outliers within Adjusted only

% --- 2) Find ID–Date groups where BOTH Lower & Higher in Adjusted are outliers ---
[G, gid, gdate] = findgroups(T.ID, dkey);

% For each (ID, Date) group, check if BOTH sessions in Adjusted are outliers
hasBothOutlierAdj = splitapply(@(s,tk,out) ...
    (any(out & tk=="Adjusted" & s=="Lower")) & ...
    (any(out & tk=="Adjusted" & s=="Higher")), ...
    sess, task, outAdj, G);

% Participants (IDs) that satisfy the criterion on ANY date
badIDs = unique(gid(hasBothOutlierAdj));

% --- 3) Remove these participants from ALL tasks (Adjusted + Perceptual) ---
keepMask = ~ismember(T.ID, badIDs);
clean_data = T(keepMask, :);

% --- Reporting ---
fprintf('Removed %d participant(s): ', numel(badIDs));
if ~isempty(badIDs), disp(badIDs(:)'); else, fprintf('none\n'); end
fprintf('Clean table has %d rows (from %d originally).\n', height(clean_data), height(T));

% Optional: show the (ID, Date) pairs that triggered removal
if any(hasBothOutlierAdj)
    trig = table(gid(hasBothOutlierAdj), gdate(hasBothOutlierAdj), ...
                 'VariableNames', {'ID','Date'});
    trig = unique(trig);
    disp('ID–Date pairs with BOTH Lower & Higher Adjusted outliers:');
    disp(trig);
end

% Optional: save

savefile=fullfile(dataDir, ['Excluding_AdjustedOutliers_Disparity_BothElevations_' datafile]);
writetable(clean_data, savefile);
