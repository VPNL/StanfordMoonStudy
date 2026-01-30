%% count how many nights each participant came to the experiment
close all; clear all;

% data loading and setting up some basic information
dataDir='/Users/kalanit/Projects/PerceptualMagnification/Data/MoonExperiments/';
datafile='FullMoonDataLong.csv'; % all data
basename = [erase( datafile,'s.csv')] ; % for saving
cd(dataDir)
all_data=readtable(datafile);

uniqueID=unique(all_data.ID);
nsubjects=length(uniqueID);
for i=1:nsubjects
    ii=find(all_data.ID==uniqueID(i));
    counttimes(i)=length(ii)/4; % each night there are 4 observations
    if counttimes(i)>1
        disp(all_data.Date(ii)); % check dates for multiple night participants
    end
end

ntimes=unique(counttimes);
for i =1:length(ntimes)
    nn(i)=length(find(counttimes==ntimes(i)));
   fprintf(1,'%d subjects %d nights\n', nn(i), ntimes(i))
end