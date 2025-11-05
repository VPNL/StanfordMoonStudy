%% FullMoon_Disparity_DataChecks 
% generate clean data csv that only includes participants that have both
% higher and lower elevation disparity data

close all; clear all;

% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/'
cd(dataDir)
%datafile='FullMoonDataLong821.csv'; % all data
datafile='FullMoonDataLong090225.csv'; % all data
basename = [erase( datafile,'.csv')] ; % for saving


%% read data 
all_data=readtable(datafile);
nameVars=all_data.Properties.VariableNames;
disp(nameVars);
nVars=length(all_data.Properties.VariableNames);
allTasks =unique(all_data.Task);disp(allTasks);
nTasks=length(allTasks);



%% only include the participants who have disparity data

jj=~isnan(all_data.Disparity_VA);
NotNaN=find(jj);
length(NotNaN);
all_data=all_data(NotNaN,:);
uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);
fprintf(1, '%d subjects with disparity data\n ',nsubjects)

uniqueDate=unique(all_data.Date)

% Normalize Session and Date for grouping
sess = lower(string(all_data.Session));

% Keep Date as datetime if it already is; otherwise use string
if isdatetime(all_data.Date)
    dkey = all_data.Date;
else
    dkey = string(all_data.Date);
end

% Group by (ID, Date)
[G, idU, dateU] = findgroups(all_data.ID, dkey);

% For each (ID, Date) group, check if both 'lower' and 'higher' are present
hasBoth = splitapply(@(s) any(s=="lower") & any(s=="higher"), sess, G);

% Keep only rows that has groups with both sessions
keepRows = hasBoth(G);
clean_sameDateLH = all_data(keepRows, :);

% Save to file
savefile=fullfile(dataDir, ['Disparity_BothElevations_' datafile]);
writetable(clean_sameDateLH, savefile);

clean_uniqueID=unique(clean_sameDateLH.ID);
clean_nsubjects=length(clean_uniqueID);


% Display summary
fprintf('Kept %d of %d subjects (subjects with BOTH Lower & Higher on the same date).\n', ...
        clean_nsubjects, nsubjects);
uniqueDates=unique(clean_sameDateLH.Date);
clean_subjectsID=unique(clean_sameDateLH.ID);
excludedIDs=setxor(uniqueID,clean_subjectsID);
% Find logical index of rows in all_data whose ID is in excludedIDs
excludedRows = ismember(all_data.ID, excludedIDs);

% Extract those rows into a new table
excluded_data = all_data(excludedRows, :);

% Print them to the command window
disp(excluded_data);
disp('Unique dates of the kept data:');
disp(uniqueDates);
%% Let's calculate demographics of Moon Disparity participants that are included in the analyses
RawDataFile='FullMoonRawData090225';
all_raw_data=readtable(fullfile(dataDir,RawDataFile));
subset_data = all_raw_data(ismember(all_raw_data.IDNumber, clean_uniqueID), :);
% Deduplicate IDs
[uniqueIDs, ia] = unique(subset_data.IDNumber, 'stable');
unique_participants = subset_data(ia,:);

% Gender counts
gender_counts = groupsummary(unique_participants, "Gender");
disp(gender_counts)


%% find subjects without perceptual magnification

% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/MoonExperiments/'
cd(dataDir)
basename = [erase( datafile,'.csv')] ; % for saving


% read data 
all_data=readtable(datafile);

task_i=find(strcmp(all_data.Task,'Perceptual'));
perceptual_data=all_data(task_i,:);
jj=find(perceptual_data.Ratio_Visual_Angle<1.1);
IDnoPM=perceptual_data.ID(jj);
subset_data_noPM=[];
for j=1:length(IDnoPM)
    mm=find(all_data.ID==IDnoPM(j));
    subset_data_noPM=[subset_data_noPM;all_data(mm,:)];
end

savefile=fullfile(dataDir, ['Disparity_noPM_' datafile]);
writetable(subset_data_noPM, savefile);

