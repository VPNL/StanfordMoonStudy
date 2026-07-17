function [Tbl_perceptual,Tbl_adjusted] = splitTablebyTask(Tbl)
%[ Tbl.perceptual,Tbl.adjusted] = splitTablebyTask(Tbl)
%  Separate table by perceptual and adjusted tasks

if ~exist('Tbl','var')
    disp('error no table')
    return
end

task='Perceptual';
task_p=find(strcmp(Tbl.Task,task));
Tbl_perceptual=Tbl(task_p,:);

task='Adjusted';
task_a=find(strcmp(Tbl.Task,task));
Tbl_adjusted=Tbl(task_a,:);

