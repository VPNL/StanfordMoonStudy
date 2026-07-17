function [modelLabel] = predCols2modelLabel(predCols)
% function [modelLabel] = predCols2modelLabel(predCols)
% takes a list of 7 model lme labels and returns shorter modelLabels for
% figures
% predCols                                       modelLabel
% predicted_PM_logPM_by_logAngle                    VA
% predicted_PM_logPM_by_logDistance                  D
% predicted_PM_logPM_by_logDistance                  E
% predicted_PM_logPM_by_logAngleNDistance            VA,D
% predicted_PM_logPM_by_logAngleNElevation           VA,E
% predicted_PM_logPM_by_logDistanceNElevation        D,E
% predicted_PM_logPM_by_logAngleNDistanceNElevation VA,D,E 


% lets make shorter labels for plot
for i = 1:numel(predCols)
    switch predCols{i}
        case 'predicted_PM_logPM_by_logAngle'
            modelLabel{i} = 'VA';

        case 'predicted_PM_logPM_by_logDistance'
            modelLabel{i} = 'D';

        case 'predicted_PM_logPM_by_logElevation'
            modelLabel{i} = 'E';

         case 'predicted_PM_logPM_by_logAngleNDistance'
            modelLabel{i} = 'VA,D';
         
        case 'predicted_PM_logPM_by_logAngleNElevation'
            modelLabel{i} = 'VA,E';

        case 'predicted_PM_logPM_by_logDistanceNElevation'
             modelLabel{i} = 'D,E';

        case 'predicted_PM_logPM_by_logAngleNDistanceNElevation'
            modelLabel{i} = 'VA,D,E';
        
        otherwise
            modelLabel{i} = predCols{i}; % or '' if you prefer
    end
end
