% Input
close all; clear all;

% add code path
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir))
% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/';

datafile='FullMoonDataLong821.csv'; % all data
basename = [erase( datafile,'s.csv')] ; % for saving

T=readtable(fullfile(dataDir,datafile));
%%
% Normalize key columns
sess = string(T.Session);    % 'Lower'/'Higher'
task = string(T.Task);       % 'Adjusted'/'Perceptual'

% Date key (keep datetime if already datetime)
if isdatetime(T.Date)
    dkey = T.Date;
else
    dkey = string(T.Date);
end

% ---- Detect outliers within Adjusted task ----
isAdj  = (task == "Adjusted");
ratio  = T.Ratio_Visual_Angle;

outAdj = false(height(T),1);
adjVals = ratio(isAdj);
nonmiss = ~isnan(adjVals);

if any(nonmiss)
    % Choose method: default (MAD) or 'quartiles'/'mean'
    outLocal = false(size(adjVals));
    outLocal(nonmiss) = isoutlier(adjVals(nonmiss));  % e.g., isoutlier(...,'quartiles')
    outAdj(isAdj) = outLocal;
end

% ---- Find (ID, Date) groups where both Lower & Higher in Adjusted are outliers ----
[G, gid, gdate] = findgroups(T.ID, dkey);

bothAdjOutSameDate = splitapply(@(s,tk,out) ...
    (any(out & tk=="Adjusted" & s=="Lower")) & ...
    (any(out & tk=="Adjusted" & s=="Higher")), ...
    sess, task, outAdj, G);

% IDs to drop entirely (if condition holds on any date)
badIDs = unique(gid(bothAdjOutSameDate));

% ---- Remove those IDs from the entire table (both tasks) ----
keepMask   = ~ismember(T.ID, badIDs);
clean_data = T(keepMask, :);

% ---- Reporting ----
fprintf('Removed %d participant(s): ', numel(badIDs));
if ~isempty(badIDs), disp(badIDs(:)'); else, fprintf('none\n'); end
fprintf('Clean table has %d rows (from %d originally).\n', height(clean_data), height(T));

% Optional: show triggering (ID, Date) pairs
if any(bothAdjOutSameDate)
    trig = unique(table(gid(bothAdjOutSameDate), gdate(bothAdjOutSameDate), ...
                        'VariableNames', {'ID','Date'}));
    disp('ID–Date pairs triggering removal (both Adjusted sessions outliers):');
    disp(trig);
end


%Optional: save result
savefile=fullfile(dataDir, ['ExcludingOutliers_Adjusted_' datafile])
writetable(clean_data, savefile);