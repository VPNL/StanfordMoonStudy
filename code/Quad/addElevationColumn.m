% addElevationColumn
% add elevation info
close all; clear all;

% add path
% add code path
%codeDir='/Users/kalanit/Projects/PerceptualMagnification/code/'
codeDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code/';
addpath(genpath(codeDir))

% set dirs
%expDir='/Users/kalanit/Projects/PerceptualMagnification/Data/QuadExperiments/';
expDir='/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/QuadExperiments/';
dataDir='DataLong082525'
cd(fullfile(expDir, dataDir))

csvfile='AllQuadDataLong825.csv';
dataDir=fullfile(expDir,'Data')
saveLME=1; % 1 save files; 0 don't save 
all_data=readtable(csvfile);
basename = [erase( csvfile,'.csv')] ; % for saving
%%
Objects=unique(all_data.Measurement);
numel(Objects);
disp(Objects)
%all_data.Elevation = repmat({''}, height(all_data), 1);
for i=1:numel(Objects)
    currObject=(Objects{i});
    ii=contains(all_data.Measurement, currObject);
    switch currObject
        case {'BlueBall_Adjusted_VA','BlueBall_Perceptual_VA'}
            all_data.Elevation(ii)=1.0079/2;
        case {'Lamp1_Adjusted_VA', 'Lamp1_Perceptual_VA'}
            all_data.Elevation(ii)=2.3634+0.3710/2;
        case {'Lamp2_Adjusted_VA', 'Lamp2_Perceptual_VA'}
            all_data.Elevation(ii)=7.3386+1.1530/2;
        case {'Lamp3_Adjusted_VA', 'Lamp3_Perceptual_VA'}
            all_data.Elevation(ii)=2.9522+0.4630/2;
        case {'Lamp4_Adjusted_VA', 'Lamp4_Perceptual_VA'}
            all_data.Elevation(ii)=4.3371+0.6810/2;
        case {'Lamp5_Adjusted_VA', 'Lamp5_Perceptual_VA'}
            all_data.Elevation(ii)= 8.7665+1.3777/2;
        case {'Lamp6_Adjusted_VA', 'Lamp6_Perceptual_VA'}
            all_data.Elevation(ii)=4.9782+0.7814/2;
        case {'Lamp7_Adjusted_VA', 'Lamp7_Perceptual_VA'}
            all_data.Elevation(ii)=2.4291+0.3811/2;
        case {'Lamp1a_Adjusted_VA', 'Lamp1a_Perceptual_VA'}
            all_data.Elevation(ii)=2.2252+0.3491/2;
        case {'Lamp2a_Adjusted_VA', 'Lamp2a_Perceptual_VA'}
            all_data.Elevation(ii)=6.5901+1.0349/2;
        case {'Lamp3a_Adjusted_VA', 'Lamp3a_Perceptual_VA'}
            all_data.Elevation(ii)=3.0349+0.4762/2;
        case {'Lamp4a_Adjusted_VA', 'Lamp4a_Perceptual_VA'}
            all_data.Elevation(ii)=4.5933+0.7209/2;
        case {'MoonBall1_Adjusted_VA', 'MoonBall1_Perceptual_VA'}
            all_data.Elevation(ii)=0.5200/2;
        case {'MoonBall2_Adjusted_VA', 'MoonBall2_Perceptual_VA'}
            all_data.Elevation(ii)=1.5149/2;
        case {'MoonBall3_Adjusted_VA', 'MoonBall3_Perceptual_VA'}
            all_data.Elevation(ii)=0.6676/2;
        case {'MoonBall4_Adjusted_VA', 'MoonBall4_Perceptual_VA'}
            all_data.Elevation(ii)=0.9637/2;
        case {'Stick1_Adjusted_VA', 'Stick1_Perceptual_VA'}
            all_data.Elevation(ii)=2.3634/2;
        case {'Stick2_Adjusted_VA', 'Stick2_Perceptual_VA'}
            all_data.Elevation(ii)=7.3386/2;
        case {'Stick3_Adjusted_VA', 'Stick3_Perceptual_VA'}
            all_data.Elevation(ii)=2.9522/2;
        case {'Stick4_Adjusted_VA', 'Stick4_Perceptual_VA'}
            all_data.Elevation(ii)=4.3371/2;
        case {'Stick7_Adjusted_VA', 'Stick7_Perceptual_VA'}
            all_data.Elevation(ii)=2.7148/2;
        case {'Stick8_Adjusted_VA', 'Stick8_Perceptual_VA'}
            all_data.Elevation(ii)=1.5504/2;
        case {'Stick9_Adjusted_VA', 'Stick9_Perceptual_VA'}
            all_data.Elevation(ii)=1.0987/2;
        case {'Stick9a_Adjusted_VA', 'Stick9a_Perceptual_VA'}
            all_data.Elevation(ii)=1.0923/2;
        case {'Stick10_Adjusted_VA', 'Stick10_Perceptual_VA'}
            all_data.Elevation(ii)=7.1480/2;
    end
end
outname=[basename 'withElevation.csv']
writetable(all_data,outname);


