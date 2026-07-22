function quadFinalizeAnalysis()
%QUADFINALIZEANALYSIS Close figures and file handles after an analysis run.

quadCloseFigures();
fclose('all');
end
