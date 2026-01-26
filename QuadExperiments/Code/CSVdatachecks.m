% data checks
% set dirs
expDir='/Users/kalanit/Projects/PerceptualMagnification/QuadExperiments/';
cd(expDir)
%csvfile='QuadDataLongPX520.csv'; % all data
csvfileKD='QuadDataLong32ManuallyComputed.csv';
csvfilePX='QuadDataLongNewPX520.csv';
datafileKD=fullfile(expDir,'Data',csvfileKD);
basenameKD = erase(csvfileKD,'.csv'); % for saving
all_dataKD=readtable(datafileKD);

datafilePX=fullfile(expDir,'Data',csvfilePX);
basenamePX = erase(csvfilePX,'.csv'); % for saving
all_dataPX=readtable(datafilePX);

saveLME=1;

nameVars=all_dataKD.Properties.VariableNames;
disp(nameVars)
nVars=length(all_dataKD.Properties.VariableNames);
allTasks =unique(all_dataKD.Task);disp(allTasks)
nTasks=length(allTasks);
uniqueID=unique(all_dataKD.ID);
uniqueObject=unique(all_dataKD.Measurement_Type);
nObjects=length(uniqueObject);

filterKD=all_dataKD(find(~isnan(all_dataKD.Reported_Visual_Angle)),:);
filterPX=all_dataPX(find(~isnan(all_dataPX.Reported_Visual_Angle)),:);

for i=length(uniqueID)
    oidx=find((filterKD.ID==uniqueID(i)));
    KD=filterKD(oidx,:)
    oidx=find((filterKD.ID==uniqueID(i)));
    PX=filterKD(oidx,:)
    jj=find(KD.Reported_Visual_Angle~=PX.Reported_Visual_Angle); 
    if ~isempty(jj)
       fprintf('%d not matching,n',uniqueID(i));
       KD(jj,:)
       PX(jj,:)
    end
    
   jj=find(KD.Disparity_VA~=PX.Disparity_VA); 
 
   if ~isempty(jj)
       fprintf('%d not matching,n',uniqueID(i));
       KD(jj,:)
       PX(jj,:)
    end
end
