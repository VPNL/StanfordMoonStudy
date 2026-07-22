function pString = Quad_format_pvalue(pValue)
%QUAD_FORMAT_PVALUE Consistent compact p-value formatting for figures.

if isnan(pValue)
    pString = 'NaN';
elseif pValue >= 0.01
    pString = sprintf('%.2f', pValue);
else
    pString = sprintf('%.2e', pValue);
end
end
