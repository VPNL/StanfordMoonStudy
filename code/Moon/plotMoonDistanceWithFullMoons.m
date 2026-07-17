function [dailyTbl, fullMoonTbl] = plotMoonDistanceWithFullMoons(locationPath, startDate, endDate)
% plotMoonDistanceWithFullMoons
% 
% Draw Moon-Earth distance from startDate to endDate using timeanddate.com,
% mark each full moon with a yellow circle scaled by apparent angular size,
% and annotate each full moon with its visual diameter in degrees.
%
% INPUTS
%   locationPath : string or char
%       Example: "usa/los-angeles"
%   startDate    : datetime
%       Example: datetime(2024,6,1)
%   endDate      : datetime
%       Example: datetime(2025,9,30)
%
% OUTPUTS
%   dailyTbl     : table with columns Date, Distance_km
%   fullMoonTbl  : table with columns Date, Distance_km, VisualDeg, MarkerSize
%
% EXAMPLE
%   plotMoonDistanceWithFullMoons("usa/los-angeles", datetime(2024,6,1), datetime(2025,9,30));

    if nargin < 1 || isempty(locationPath)
        locationPath = "usa/san-francisco";
    end
    if nargin < 2 || isempty(startDate)
        startDate = datetime(2024,5,1);
    end
    if nargin < 3 || isempty(endDate)
        endDate = datetime(2025,9,30);
    end

    moonRadiusKm = 1737.4;

    % Build monthly list
    monthStarts = dateshift(startDate, 'start', 'month'):calmonths(1):dateshift(endDate, 'start', 'month');

    % -----------------------------
    % Fetch daily distance tables
    % -----------------------------
    allDates = datetime.empty(0,1);
    allDistKm = [];

    for i = 1:numel(monthStarts)
        d = monthStarts(i);
        [monthDates, monthDistKm] = fetchMoonMonth(locationPath, year(d), month(d));
        allDates = [allDates; monthDates(:)]; %#ok<AGROW>
        allDistKm = [allDistKm; monthDistKm(:)]; %#ok<AGROW>
    end

    dailyTbl = table(allDates, allDistKm, 'VariableNames', {'Date','Distance_km'});

    % Drop duplicates and clip date range
    [~, ia] = unique(dailyTbl.Date);
    dailyTbl = dailyTbl(sort(ia), :);
    keep = dailyTbl.Date >= startDate & dailyTbl.Date <= endDate;
    dailyTbl = dailyTbl(keep, :);
    dailyTbl = sortrows(dailyTbl, 'Date');

    % -----------------------------
    % Fetch full moon dates
    % -----------------------------
    yearsNeeded = year(startDate):year(endDate);
    fullMoonDates = datetime.empty(0,1);

    for y = yearsNeeded
        yearFullMoons = fetchFullMoonsForYear(locationPath, y);
        fullMoonDates = [fullMoonDates; yearFullMoons(:)]; %#ok<AGROW>
    end

    fullMoonDates = unique(fullMoonDates);
    keep = fullMoonDates >= dateshift(startDate,'start','day') & ...
           fullMoonDates <= dateshift(endDate,'start','day');
    fullMoonDates = fullMoonDates(keep);

    % Match full moon dates to daily distance
    fullMoonDistKm = interp1(datenum(dailyTbl.Date), dailyTbl.Distance_km, ...
                             datenum(fullMoonDates), 'linear', 'extrap');

    % Apparent angular diameter in degrees
    visualDeg = rad2deg(2 * atan(moonRadiusKm ./ fullMoonDistKm));

    % Scale marker size by visual angle
    if max(visualDeg) > min(visualDeg)
        markerSize = 120 + 120 * (visualDeg - min(visualDeg)) ./ (max(visualDeg) - min(visualDeg));
    else
        markerSize = 300 * ones(size(visualDeg));
    end

    fullMoonTbl = table(fullMoonDates, fullMoonDistKm, visualDeg, markerSize, ...
        'VariableNames', {'Date','Distance_km','VisualDeg','MarkerSize'});

    % -----------------------------
    % Plot
    % -----------------------------
    figh=figure('Color',[1 1 1],'Name','Moon Distance from earth','Units','normalized','Position',[ 0 0 1 .5]);
    plot(dailyTbl.Date, dailyTbl.Distance_km, 'LineWidth', 1.8);
    hold on;

    scatter(fullMoonTbl.Date, fullMoonTbl.Distance_km, fullMoonTbl.MarkerSize, ...
        'o', 'MarkerFaceColor', [ 1 .7 0]); %, 'MarkerEdgeColor', 'k', 'LineWidth', 0.8

    ySpan = max(dailyTbl.Distance_km) - min(dailyTbl.Distance_km);
    yOffset = 0.025 * ySpan;

    for i = 1:height(fullMoonTbl)
        text(fullMoonTbl.Date(i), fullMoonTbl.Distance_km(i) + yOffset, ...
            sprintf('%.2f%c', fullMoonTbl.VisualDeg(i), char(176)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'cap', ...
            'FontSize', 8);
    end
    set(gca,'FontName','Avenir','FontSize',14)
    xlabel('Date','Fontsize',18);
    ylabel('Moon distance from Earth (km)','FontSize',18);
    % title(sprintf('Moon distance from Earth (%s to %s)', ...
    %     datestr(startDate, 'yyyy-mm-dd'), datestr(endDate, 'yyyy-mm-dd')));
 
    %grid on;
    box off;

    % Monthly ticks
    ax = gca;
    ax.XTick = monthStarts;
    xtickformat('MMM yyyy');
    xtickangle(45);

    legend({'Moon distance from Earth', 'Full moon'}, 'Location', 'best','box','off','FontSize',12);
    hold off;
    filenamePNG=fullfile('.','MoonDistancefromEarth.png');
    exportgraphics(figh,filenamePNG,'Resolution',600);

end


% =====================================================================
function [datesOut, distKmOut] = fetchMoonMonth(locationPath, yyyy, mm)
% Parse daily distance data from monthly moon page

    url = sprintf('https://www.timeanddate.com/moon/%s?month=%d&year=%d', locationPath, mm, yyyy);
    html = webread(url);

    % Convert HTML into plain text-ish form
    txt = regexprep(html, '<[^>]+>', ' ');
    txt = regexprep(txt, '&nbsp;|&#160;', ' ');
    txt = regexprep(txt, '\s+', ' ');

    % Find chunks that look like:
    % "1 ... 234,567 45.6%"
    %
    % We look for:
    %   day number at start of a row-like segment
    %   then later a 3-digit comma-separated distance
    %   then illumination percentage
    %
    % This is intentionally permissive because the page is not an API.
    pattern = '(^|[^\d])(\d{1,2})\s.*?(\d{3},\d{3})\s+\d{1,3}\.?\d*%';
    tokens = regexp(txt, pattern, 'tokens');

    dayVals = [];
    distKmVals = [];

    seenDays = false(31,1);

    for k = 1:numel(tokens)
        t = tokens{k};
        dayNum = str2double(t{2});
        distMi = str2double(strrep(t{3}, ',', ''));

        if ~isnan(dayNum) && dayNum >= 1 && dayNum <= eomday(yyyy, mm)
            if ~seenDays(dayNum)
                seenDays(dayNum) = true;
                dayVals(end+1,1) = dayNum; %#ok<AGROW>
                distKmVals(end+1,1) = distMi * 1.609344; %#ok<AGROW>
            end
        end
    end

    if isempty(dayVals)
        error('Could not parse monthly moon-distance data for %04d-%02d.', yyyy, mm);
    end

    datesOut = datetime(yyyy, mm, dayVals);
    distKmOut = distKmVals;

    % Sort by date
    [datesOut, idx] = sort(datesOut);
    distKmOut = distKmOut(idx);
end

% =====================================================================
function fullMoonDates = fetchFullMoonsForYear(locationPath, yyyy)
% Parse full moon dates from yearly phases page

    url = sprintf('https://www.timeanddate.com/moon/phases/%s?year=%d', locationPath, yyyy);
    html = webread(url);

    txt = regexprep(html, '<[^>]+>', ' ');
    txt = regexprep(txt, '&nbsp;|&#160;', ' ');
    txt = regexprep(txt, '\s+', ' ');

    % The phases page lists month/day entries for each phase in order.
    % We capture repeating rows that contain:
    %   New Moon, First Quarter, Full Moon, Third Quarter
    % and keep the 3rd date = Full Moon.
    %
    % Example structure:
    % <lunation> Jun 6 5:38 am Jun 14 10:18 pm Jun 22 6:07 pm Jun 28 2:54 pm
    %
    pattern = ['\d+\s+' ...
               '([A-Z][a-z]{2})\s+(\d{1,2})\s+\d{1,2}:\d{2}\s+[ap]m\s+' ...
               '([A-Z][a-z]{2})\s+(\d{1,2})\s+\d{1,2}:\d{2}\s+[ap]m\s+' ...
               '([A-Z][a-z]{2})\s+(\d{1,2})\s+\d{1,2}:\d{2}\s+[ap]m\s+' ...
               '([A-Z][a-z]{2})\s+(\d{1,2})\s+\d{1,2}:\d{2}\s+[ap]m'];

    tokens = regexp(txt, pattern, 'tokens');

    fullMoonDates = datetime.empty(0,1);

    for k = 1:numel(tokens)
        t = tokens{k};
        fullMon = t{5};
        fullDay = str2double(t{6});
        dt = datetime(sprintf('%s %d %d', fullMon, fullDay, yyyy), ...
            'InputFormat', 'MMM d yyyy');
        fullMoonDates(end+1,1) = dateshift(dt, 'start', 'day'); %#ok<AGROW>
    end

    if isempty(fullMoonDates)
        error('Could not parse full moon data for year %d.', yyyy);
    end

    fullMoonDates = unique(fullMoonDates);
    fullMoonDates = sort(fullMoonDates);
end

