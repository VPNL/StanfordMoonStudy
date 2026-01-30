function checkbinning(SummaryItrParam,Param,minID)

fprintf('Binning by %s minID=%1d\n',Param,minID )
% check binning
ngroups=numel(unique(SummaryItrParam.NewParamGroup));
for j=1:ngroups
    jj=find(SummaryItrParam.NewParamGroup==j);
    fprintf('group %1d, VA=[%.2f %.2f], D=[%.1f %.1f] E=[%.1f %.1f]\n',j,...
        SummaryItrParam(jj(1),:).Real_Visual_Angle_Min ,SummaryItrParam(jj(1),:).Real_Visual_Angle_Max,...
        SummaryItrParam(jj(1),:).Distance_Min, SummaryItrParam(jj(1),:).Distance_Max, ...
        SummaryItrParam(jj(1),:).Elevation_Min,  SummaryItrParam(jj(1),:).Elevation_Max)
end

fprintf('\n \n');