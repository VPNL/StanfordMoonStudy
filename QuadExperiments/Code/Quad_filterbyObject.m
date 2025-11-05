function [stickNlamp_data,ballNlamp_data, ballNlamp_data_v2] = Quad_filterbyObject(dataDir,datafile,ResultsDir,task)
%  s[stickNlamp_data,ballNlamp_data] = Quad_filterbyObject(dataDir,datafile,ResultsDir,task)
%  This function reads the quad data and filters it by task
%  Then returns two tables:
%  stickNlamp_data: data of participants that have measurements on both stick and lamp
%  allNlamp_data: data of participants that have measurements on both ball and lamp

%%
cd(dataDir)
all_data=readtable(datafile);
basename = [erase( datafile,'.csv')] ; % for saving

% get the relevant data 
task_i=find(strcmp(all_data.Task,task));
all_data_by_task=all_data(task_i,:);

% find all the data that contains one of the objects

maskStick = contains(string(all_data_by_task.Measurement), 'Stick', 'IgnoreCase', true);
maskBall=contains(string(all_data_by_task.Measurement), 'Ball', 'IgnoreCase', true);
maskLamp=contains(string(all_data_by_task.Measurement), 'Lamp', 'IgnoreCase', true);
idxBall=find(maskBall);  idxStick=find(maskStick); idxLamp=find(maskLamp);
% get table subsets by object type
ball_data=all_data_by_task(idxBall,:);
ball_data.Object = repmat("ball", height(ball_data), 1);
%% 

stick_data=all_data_by_task(idxStick,:); 
stick_data.Object = repmat("stick", height(stick_data), 1);

lamp_data=all_data_by_task(idxLamp,:);
lamp_data.Object = repmat("lamp", height(lamp_data), 1);


% find unique participants that have each of the object types
ballID=unique(ball_data.ID); 
stickID=unique(stick_data.ID);
lampID=unique(lamp_data.ID);
% find IDs that have both lamp and ball & make a table ballNlamp_data with this data only
ballNlamp=intersect(ballID,lampID);
rowsBall = find(ismember(ball_data.ID, ballNlamp));
ball_data_s  = ball_data(rowsBall, :);
rowsLamp = find(ismember(lamp_data.ID, ballNlamp));
lamp_data_s  = lamp_data(rowsLamp, :);
ballNlamp_data=[ball_data_s; lamp_data_s]; 
fprintf(1,'%d subjects with ball & lamp\n',length(unique(ballNlamp_data.ID)));
disp(unique(ballNlamp_data.Object))

ballNlampfilename=fullfile(dataDir, ResultsDir,[task '_' basename '_ballNlamp.csv']);
writetable(ballNlamp_data,ballNlampfilename);

% now only include participants from summer 2024 to have the ones who did 4
% balls and 4 moons at similar distances
startDate = datetime(2024, 7, 1);  % Define the start date
endDate = datetime(2024, 12, 31);    % Define the end date

% Create a logical index for rows within the date range
idx = find((ballNlamp_data.Date >= startDate) & (ballNlamp_data.Date <= endDate));

% Use the logical index to filter the table
ballNlamp_data_v2 = ballNlamp_data(idx, :);
ballNlampfilename_v2=fullfile(dataDir, ResultsDir,[task '_' basename '_ballNlamp_v2.csv']);
writetable(ballNlamp_data_v2,ballNlampfilename_v2);

% find IDs that have both lamp and stick & make a table stickNlamp_data with this data only

stickNlamp=intersect(stickID,lampID);
rowsStick = find(ismember(stick_data.ID, stickNlamp));
stick_data_s  = stick_data(rowsStick, :);
rowsLamp = find(ismember(lamp_data.ID, stickNlamp));
lamp_data_s  = lamp_data(rowsLamp, :);
stickNlamp_data=[stick_data_s; lamp_data_s]; 
fprintf(1,'%d subjects with stick & lamp \n',length(unique(stickNlamp_data.ID)));
disp(unique(stickNlamp_data.Object))

stickNlampfilename=fullfile(dataDir, ResultsDir, [task  '_' basename '_stickNlamp.csv']);
writetable(stickNlamp_data,stickNlampfilename);

end