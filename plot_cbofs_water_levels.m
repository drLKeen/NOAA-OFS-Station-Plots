%plot_cbofs_water_levels - Plot dotted CBOFS station water-level guidance
%   plot_cbofs_water_levels creates a Choptank water-level figure and
%   exports an HTML web canvas. Numeric elapsed hours support HTML pan
%   and zoom. The station data retains its original datetime values.
%
%   See also plotCBOFSStationProduct, exportgraphics

% Resolve the script location and add the shared functions folder.
scriptFolder = fileparts(mfilename("fullpath"));
projectFolder = fileparts(scriptFolder);
addpath(fullfile(projectFolder,"functions"));

% Use the same sample station and forecast cycle as the wind example.
runDate = datetime(2026,8,29);
cycle = "t00z";
stationName = "Choptank River Entrance";
stationLatitude = 38.7535;
stationLongitude = -76.4340;

% Download station data files for the requested run date and cycle.
stationFiles = downloadCBOFSStationData(runDate,cycle,fullfile(projectFolder,"data"));

% Split returned table into nowcast and forecast file paths.
nowcastFile = stationFiles.LocalFile(stationFiles.Product == "nowcast");
forecastFile = stationFiles.LocalFile(stationFiles.Product == "forecast");

% Extract plotted series and align them to the shared time origin.
[waterLevelFigure,waterLevelData] = plotCBOFSStationProduct( ...
    nowcastFile,forecastFile,stationName,stationLatitude,stationLongitude,"water levels");
waterLevelAxes = waterLevelFigure.CurrentAxes;
nowcastLine = findobj(waterLevelAxes,Type="line",DisplayName="Nowcast");
forecastLine = findobj(waterLevelAxes,Type="line",DisplayName="Forecast guidance");

% Convert datetime x-data to elapsed hours for numeric plotting.
timeOrigin = min(waterLevelData.Time);
nowcastHours = hours(nowcastLine.XData-timeOrigin);
forecastHours = hours(forecastLine.XData-timeOrigin);
nowcastLevel = nowcastLine.YData;
forecastLevel = forecastLine.YData;

% Rebuild this example's axes with numeric time for HTML interactions.
delete(waterLevelAxes);
waterLevelAxes = axes(waterLevelFigure);
hold(waterLevelAxes,"on");
plot(waterLevelAxes,nowcastHours,nowcastLevel,LineStyle=":",Marker="none",LineWidth=1.8,Color=[0 .25 .95],DisplayName="Nowcast");
plot(waterLevelAxes,forecastHours,forecastLevel,LineStyle=":",Marker="none",LineWidth=1.8,Color=[0 .65 0],DisplayName="Forecast guidance");

xline(waterLevelAxes,min(forecastHours),"--",Color=[.3 .3 .3],HandleVisibility="off");
xlim(waterLevelAxes,[0 max(hours(waterLevelData.Time-timeOrigin))]);

% Place timestamp strings at local 08:00 and 20:00 on the numeric axis.
% Build daily ticks, then map each day to two local timestamps.
tickDays = (dateshift(timeOrigin,"start","day"):caldays(1):dateshift(max(waterLevelData.Time),"start","day")).';
tickTimes = sort([datetime(year(tickDays),month(tickDays),day(tickDays),...
    8,0,0, TimeZone=timeOrigin.TimeZone); ...
    datetime(year(tickDays),month(tickDays),day(tickDays),20,0,0, ...
    TimeZone=timeOrigin.TimeZone)]);

% Keep only timestamps within the plotted interval.
tickTimes = tickTimes(tickTimes >= timeOrigin & ...
    tickTimes <= max(waterLevelData.Time));

% Format numeric hours while preserving readable datetime labels.
xticks(waterLevelAxes,hours(tickTimes-timeOrigin));
xticklabels(waterLevelAxes,string(tickTimes,"dd-MMM HH:mm"));
xtickangle(waterLevelAxes,0);
xlabel(waterLevelAxes,"Time (" + string(timeOrigin.TimeZone) + ")");
ylabel(waterLevelAxes,"Water level (m)");
title(waterLevelAxes,stationName + " water levels");
subtitle(waterLevelAxes,"CBOFS | Model datum | Dotted hourly guidance");
grid(waterLevelAxes,"on");
box(waterLevelAxes,"on");
waterLevelAxes.FontSize = 11;
legend(waterLevelAxes,Location="northwest");
waterLevelFigure.Name = "CBOFS water levels - dotted example";