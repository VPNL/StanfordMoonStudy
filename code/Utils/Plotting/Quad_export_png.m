function Quad_export_png(figHandle, outFile, dpi)
%QUAD_EXPORT_PNG Export a Quad figure as a PNG at a consistent resolution.

if nargin < 3 || isempty(dpi)
    dpi = 600;
end
set(figHandle, 'PaperPositionMode', 'auto');
print(figHandle, outFile, '-dpng', sprintf('-r%d', dpi));
end
