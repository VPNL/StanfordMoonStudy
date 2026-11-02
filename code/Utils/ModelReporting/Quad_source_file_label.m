function sourceCsv = Quad_source_file_label(tbl, tblName)
%QUAD_SOURCE_FILE_LABEL Resolve the source CSV recorded on a table.

sourceCsv = char(string(tblName));
try
    if isstruct(tbl.Properties.UserData) && ...
            isfield(tbl.Properties.UserData, 'SourceFile')
        sourceCsv = char(string(tbl.Properties.UserData.SourceFile));
    end
catch
end

if ~endsWith(string(sourceCsv), ".csv", "IgnoreCase", true)
    sourceCsv = sprintf( ...
        '%s.csv (inferred from tblName; function input is a table)', ...
        sourceCsv);
end
end
