function compareTbl = compare_lmes_by_transform(lmeStore, taskOrder, transformOrder, saveCsvFile)
% compare_lmes_by_transform Pairwise compare fitted LMEs across transforms.

if nargin < 2 || isempty(taskOrder)
    taskOrder = fieldnames(lmeStore);
end
if ischar(taskOrder) || isstring(taskOrder)
    taskOrder = cellstr(taskOrder);
end
if nargin < 3 || isempty(transformOrder)
    transformOrder = {};
    for t = 1:numel(taskOrder)
        taskName = taskOrder{t};
        transformOrder = union(transformOrder, fieldnames(lmeStore.(taskName)), 'stable');
    end
end

rows = {};
for t = 1:numel(taskOrder)
    taskName = taskOrder{t};
    for i = 1:numel(transformOrder)-1
        for j = i+1:numel(transformOrder)
            tf1 = transformOrder{i};
            tf2 = transformOrder{j};
            if ~isfield(lmeStore.(taskName), tf1) || ~isfield(lmeStore.(taskName), tf2)
                continue;
            end

            lme1 = lmeStore.(taskName).(tf1);
            lme2 = lmeStore.(taskName).(tf2);
            cmpP = NaN;
            cmpStat = NaN;
            cmpDF = NaN;
            try
                cmp = compare(lme1, lme2);
                if isa(cmp, 'table')
                    if ismember('pValue', cmp.Properties.VariableNames)
                        cmpP = cmp.pValue(end);
                    end
                    if ismember('LRStat', cmp.Properties.VariableNames)
                        cmpStat = cmp.LRStat(end);
                    end
                    if ismember('deltaDF', cmp.Properties.VariableNames)
                        cmpDF = cmp.deltaDF(end);
                    end
                end
            catch
            end

            aic1 = lme1.ModelCriterion.AIC;
            aic2 = lme2.ModelCriterion.AIC;
            bic1 = lme1.ModelCriterion.BIC;
            bic2 = lme2.ModelCriterion.BIC;

            if aic1 <= aic2
                bestAIC = string(tf1);
            else
                bestAIC = string(tf2);
            end
            if bic1 <= bic2
                bestBIC = string(tf1);
            else
                bestBIC = string(tf2);
            end

            rows(end+1,:) = {string(taskName), string(tf1), string(tf2), ...
                aic1, aic2, bic1, bic2, bestAIC, bestBIC, cmpStat, cmpDF, cmpP}; %#ok<AGROW>
        end
    end
end

compareTbl = cell2table(rows, 'VariableNames', ...
    {'Task','Transform1','Transform2','AIC1','AIC2','BIC1','BIC2','BestByAIC','BestByBIC','LRStat','deltaDF','pValue'});

if nargin >= 4 && ~isempty(saveCsvFile)
    writetable(compareTbl, saveCsvFile);
end
end
