function [modelLabel] = modelList2modelLabel(modelList)
% function [modelLabel] = modelList2modelLabel(modelList)
% takes a list of 7 model lme labels and returns shorter modelLabels for
% figures
% modelList                         modelLabel
% logPM_by_logAngle                    VA
% logPM_by_logDistance                  D
% logPM_by_logDistance                  E
% logPM_by_logAngleNDistance            VA,D
% logPM_by_logAngleNElevation           VA,E
% logPM_by_logDistanceNElevation        D,E
% logPM_by_logAngleNDistanceNElevation VA,D,E 


% lets make shorter labels for plot
for i = 1:numel(modelList)
    switch modelList{i}
        case 'logPM_by_logAngle'
            modelLabel{i} = 'VA';

        case 'logPM_by_logDistance'
            modelLabel{i} = 'D';

        case 'logPM_by_logElevation'
            modelLabel{i} = 'E';

         case 'logPM_by_logAngleNDistance'
            modelLabel{i} = 'VA,D';
         
        case 'logPM_by_logAngleNElevation'
            modelLabel{i} = 'VA,E';

        case 'logPM_by_logDistanceNElevation'
             modelLabel{i} = 'D,E';

        case 'logPM_by_logAngleNDistanceNElevation'
            modelLabel{i} = 'VA,D,E';
        
        otherwise
            modelLabel{i} = modelList{i}; % or '' if you prefer
    end
end
