function mask = match_moon_date(dateValues, targetDate)
% match_moon_date Match Moon table date values to a target date.
%
% Handles string/cellstr/date-like values and datetime arrays. Matching first
% tries exact trimmed string equality, then falls back to calendar day matching
% so dates with equivalent month/day/year values compare correctly.

targetDate = string(targetDate);
mask = strcmp(strtrim(string(dateValues)), targetDate);
if any(mask)
    return
end

try
    targetDT = datetime(targetDate, 'InputFormat', 'M/d/yy');
catch
    try
        targetDT = datetime(targetDate);
    catch
        return
    end
end

try
    if isdatetime(dateValues)
        dateDT = dateValues;
    else
        dateDT = datetime(string(dateValues), 'InputFormat', 'M/d/yy');
    end
catch
    try
        dateDT = datetime(string(dateValues));
    catch
        return
    end
end

mask = mod(year(dateDT),100) == mod(year(targetDT),100) & ...
    month(dateDT) == month(targetDT) & day(dateDT) == day(targetDT);
mask(isnat(dateDT)) = false;
end
