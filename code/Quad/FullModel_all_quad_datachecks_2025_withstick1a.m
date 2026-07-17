
%% load data
load_all_quad_data_2025_withstick1a

%change large values >30000 to 100s 
 mm=find(uniqueID>30000)
 highIDs=uniqueID(mm);

 for i=1:length(mm)
    idx=find(all_data.ID==highIDs(i));
    all_data.ID(idx)=100+i;
 end

 uniqueID=unique(all_data.ID);
%% Plot results by task also calculate magnification vs perceived angle and task on a log-log axis
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename])
   
for i=1:nObjects
    % set figure
    %idx=find(contains(all_data.Measurement_Type,uniqueObject(i) ));
    idx=find(contains(all_data.Measurement,uniqueObject(i) ));
    if ~isempty(idx) 
        filtered_data=all_data(idx,:);
        clear subjectcolor;
        ID=filtered_data.ID;
        for c=1:length(ID)
            cindex=find(uniqueID==ID(c));
            subjectcolor(c,:)=cmap(cindex,:);
        end
    end
    % Mean_Reported_Visual_Angle(i)=mean(all_data.Reported_Visual_Angle(idx));
    % SD_Reported_Visual_Angle(i)=std(all_data.Reported_Visual_Angle(idx));
    % % fprintf('%s: reported visual angle %5.2f+/- %5.2f\n',...
    %     string(uniqueObject(i)),Mean_Reported_Visual_Angle(i),SD_Reported_Visual_Angle(i) );
    subplot(5,nObjects/5,i)  
    hold on 
    scatter(filtered_data.ID, filtered_data.Ratio_Visual_Angle,markerScale,subjectcolor,'o','filled');  
    xlabel('ID')
    ylabel('Magnification')
    ylim([0 maxRatio])
    xlim([1 max(uniqueID)])
    titlestr=sprintf('%s \n n=%d',string(uniqueObject(i)),length(ID));
    title(titlestr,'Interpreter', 'none')

end

 % save figure
ResultsDir=fullfile(expDir,'DataChecks');

if ~exist('ResultsDir','dir')
   mkdir(ResultsDir)
end

filenamePNG=fullfile(ResultsDir, [basename,'_ratio_by_id_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);

   
%% boxplots + means + SD
figh=figure('Color',[1 1 1],'Units','normalized','Position',[0 0 1 1],'Name',[basename])
maxAngle=max(all_data.Reported_Visual_Angle);
%     real_visual_angle=all_data.Real_Visual_Angle(task_i);
filenameTXT=fullfile(ResultsDir,'QuadLongMeanData.txt')
fileID = fopen(filenameTXT,'w')
for t=1:nTasks
    task_i=find(strcmp(all_data.Task,allTasks(t)));
    subplot(1,2,2-t+1); hold on   
    set(gca,'FontSize',18)
    counter=1;
    for i=1:nObjects
        task_data=all_data(task_i,:); % filter data by task
        idx=find(contains(task_data.Measurement,uniqueObject(i) ));
        if ~isempty(idx)
           counter=counter+1;
            Mean_Reported_Visual_Angle(i)=mean(task_data.Reported_Visual_Angle(idx));
            SD_Reported_Visual_Angle(i)=std(task_data.Reported_Visual_Angle(idx));
            Mean_Real_Visual_Angle(i)=mean(task_data.Real_Visual_Angle(idx));
             diffA=Mean_Reported_Visual_Angle(i)-mean(task_data.Real_Visual_Angle(idx));
           
            fprintf(fileID,'%s: reported visual angle:%5.2f +/- %5.2f, real visual angle:%5.2f reported-real:%5.2f\n',...
                string(uniqueObject(i)),Mean_Reported_Visual_Angle(i),SD_Reported_Visual_Angle(i) ,Mean_Real_Visual_Angle(i),diffA);
            boxchart(task_data.Real_Visual_Angle(idx), task_data.Reported_Visual_Angle(idx), ...
                     'BoxFaceColor', 'b');
            text(mean(task_data.Real_Visual_Angle(idx)),Mean_Reported_Visual_Angle(i),num2str(round(diffA,1)),'FontSize',8)
        
        end 
    end
   
     xlabel('Real Visual Angle','FontSize',18)
     ylabel('Reported Visual Angle','FontSize',18)
     plot([0 max(all_data.Reported_Visual_Angle)], [0 max(all_data.Reported_Visual_Angle)],'k--')
     axis('equal')
     ylim([0 maxAngle])
     xlim([0 max(all_data.Real_Visual_Angle)+2])  
     titlestr=sprintf('%s \n',string(allTasks(t)));
     title(titlestr,'FontSize',18)
   
 end
 % save figure

filenamePNG=fullfile(ResultsDir, [basename,'_boxplots_by_task_', num2str(nsubjects),'.png']);
exportgraphics(figh,filenamePNG,'Resolution',600);
fclose(fileID)

