% Plot CBOFS wind guidance at Choptank River Entrance.
% Use the bundled station nowcast and forecast for the complete time series.

% Resolve project paths relative to the script location.
scriptFolder = fileparts(mfilename("fullpath"));
projectFolder = fileparts(scriptFolder);
addpath(fullfile(scriptFolder, "functions"));
dataFolder = fullfile(projectFolder, "data");

% Define the target station and the bundled forecast cycle.
stationName = "Choptank River Entrance";
stationLatitude = 38.7535;
stationLongitude = -76.4340;
runName = "cbofs.t00z.20260829.stations.";

% Locate the station files containing the full nowcast and forecast series.
nowcastFile = fullfile(dataFolder, runName + "nowcast.nc");
forecastFile = fullfile(dataFolder, runName + "forecast.nc");

% The shared helper selects the nearest model station, converts wind speed
% to knots, and computes meteorological direction-from angles. It retains
% all samples in stationData and plots the exact hourly samples.
[fig, stationData] = plotCBOFSStationProduct(nowcastFile, forecastFile, ...
    stationName, stationLatitude, stationLongitude, "winds");

% Keep datetime values in the data, but use numeric hours in the figure.
sourceAxes = fig.CurrentAxes;
nowcastLine = findobj(sourceAxes, Type="line", DisplayName="Nowcast");
forecastLine = findobj(sourceAxes, Type="line", DisplayName="Forecast guidance");
timeOrigin = min(stationData.Time);
% Align both plotted series to the same local-time origin.
nowcastHours = hours(nowcastLine.XData - timeOrigin);
forecastHours = hours(forecastLine.XData - timeOrigin);
nowcastSpeed = nowcastLine.YData;
forecastSpeed = forecastLine.YData;
speedLimits = sourceAxes.YLim;

% Replace the datetime axes and callback-driven arrow overlay for HTML.
fig.SizeChangedFcn = [];
clf(fig);
ax = axes(fig);
hold(ax, "on");

% Draw hourly nowcast points in blue and forecast points in green.
plot(ax, nowcastHours, nowcastSpeed, LineStyle="none", ...
    Marker="o", MarkerSize=4, Color=[0 .25 .95],MarkerFaceColor=[0 .25 .95], DisplayName="Nowcast");
plot(ax, forecastHours, forecastSpeed, LineStyle="none", ...
    Marker="o", MarkerSize=4, Color=[0 .65 0], MarkerFaceColor=[0 .65 0], DisplayName="Forecast guidance");

% Mark the first forecast time and preserve the full time and speed ranges.
xline(ax, min(forecastHours), Color="black", LineWidth=1.2,HandleVisibility="off");
xlim(ax, [0 max(hours(stationData.Time - timeOrigin))]);
ylim(ax, speedLimits);

% Match the water-level demo's local 08:00 and 20:00 timestamp labels.
tickDays = (dateshift(timeOrigin,"start","day"):caldays(1): ...
    dateshift(max(stationData.Time),"start","day")).';
tickTimes = sort([datetime(year(tickDays),month(tickDays),day(tickDays),8,0,0, ...
        TimeZone=timeOrigin.TimeZone); ...
    datetime(year(tickDays),month(tickDays),day(tickDays),20,0,0, ...
        TimeZone=timeOrigin.TimeZone)]);

% Keep only timestamps within the plotted interval.
tickTimes = tickTimes(tickTimes >= timeOrigin & tickTimes <= max(stationData.Time));

% Label numeric hours with readable timestamps. The ruler stays numeric
% because HTML figure interactions do not support datetime axes.
xticks(ax, hours(tickTimes - timeOrigin));
xticklabels(ax, string(tickTimes,"dd-MMM HH:mm"));
xtickangle(ax, 0);

% Configure axes appearance and label the wind-speed plot.
xlabel(ax, "Time (" + string(timeOrigin.TimeZone) + ")");
ylabel(ax, "Knots");
title(ax, stationName + " winds", FontWeight="normal");
grid(ax, "on");
box(ax, "on");
ax.FontName = "Helvetica";
ax.FontSize = 10;
legend(ax, Location="northwest");

% Add the NOAA heading, model name, and wind-direction convention.
text(ax, 0, 1.13, "NOAA/National Ocean Service", ...
    Units="normalized", VerticalAlignment="bottom", FontSize=11);
text(ax, 0, 1.07, "Chesapeake Bay Operational Forecast System (CBOFS2)", ...
    Units="normalized", VerticalAlignment="bottom", FontSize=11);
text(ax, 1, 1.02, "Arrows point toward wind travel", ...
    Units="normalized", HorizontalAlignment="right", FontSize=9);

% Plot arrows in numeric data coordinates so they pan with the wind points.
% Use exact hourly samples with nonzero speed and a finite direction.
hourlyWind = stationData.Time == dateshift(stationData.Time,"start","hour");
wind = stationData(hourlyWind & stationData.Value > 0 & ...
    isfinite(stationData.DirectionFrom), :);

% Convert an initial 18-pixel arrow length to hours and knots using the
% rendered axes dimensions. These data-coordinate arrows need no callbacks.
drawnow;
axesPixels = getpixelposition(ax);

% Reverse the meteorological direction-from angle to show wind travel.
directionTo = wind.DirectionFrom + 180;
arrowHours = 18 * diff(ax.XLim) / axesPixels(3);
arrowKnots = 18 * diff(ax.YLim) / axesPixels(4);

% Disable automatic scaling so quiver uses the specified vector components.
quiver(ax, hours(wind.Time - timeOrigin), wind.Value, ...
    arrowHours * sind(directionTo), arrowKnots * cosd(directionTo), 0, ...
    Color=[0 .2 1], LineWidth=1, MaxHeadSize=.5, ...
    Tag="WindArrows", HandleVisibility="off");