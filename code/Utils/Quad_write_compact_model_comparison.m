function Quad_write_compact_model_comparison(fileID, comparisonLabel, comparisonTbl)
%QUAD_WRITE_COMPACT_MODEL_COMPARISON Write an LME comparison without wrapping.

fprintf(fileID, '%s\n', comparisonLabel);
fprintf(fileID, '%-8s %6s %12s %12s %12s %12s %9s %12s\n', ...
    'Model', 'DF', 'AIC', 'BIC', 'LogLik', 'LRStat', 'deltaDF', 'pValue');
for rowIdx = 1:height(comparisonTbl)
    if rowIdx == 1
        lrStat = NaN;
        deltaDF = NaN;
        pValue = NaN;
    else
        lrStat = comparisonTbl.LRStat(rowIdx);
        deltaDF = comparisonTbl.deltaDF(rowIdx);
        pValue = comparisonTbl.pValue(rowIdx);
    end
    fprintf(fileID, '%-8d %6.0f %12.6g %12.6g %12.6g %12.6g %9.0f %12.6g\n', ...
        rowIdx, comparisonTbl.DF(rowIdx), comparisonTbl.AIC(rowIdx), ...
        comparisonTbl.BIC(rowIdx), comparisonTbl.LogLik(rowIdx), ...
        lrStat, deltaDF, pValue);
end
fprintf(fileID, '\n');
end
