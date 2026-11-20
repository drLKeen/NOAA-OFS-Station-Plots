function [fig, stationData] = plotCBOFSStationProduct(nowcastFile, forecastFile, stationName, stationLatitude, stationLongitude, dataProduct, outputFile)
%PLOTCBOFSSTATIONPRODUCT Plot a selected CBOFS station time-series product.
% dataProduct: "winds", "water levels", "water temperature",
% "water salinity", or "along-channel".
% Temperature, salinity, and current products use the surface model layer.
% Along-channel velocity is positive in the local CBOFS xi-direction.
% Select arrows in Edit Plot mode, or get their handle with:
% arrows = findobj(fig,Tag="WindArrows");

nowcast = readProduct(nowcastFile, stationLatitude, stationLongitude, dataProduct);
forecast = readProduct(forecastFile, stationLatitude, stationLongitude, dataProduct);
stationData = sortrows([nowcast; forecast], "Time");
[uniqueTime, uniqueIndex] = unique(stationData.Time, "last");
stationData = stationData(uniqueIndex,:);
stationData.Time = uniqueTime;
assert(height(stationData) >= 2 && all(isfinite(stationData.Value)), ...
    "The selected product must contain at least two finite samples.");

fig = figure(Name = "CBOFS " + dataProduct, Color = "white", Position = [100 100 950 575]);
ax = axes(fig);
hold(ax, "on");
hourlyNowcast = nowcast.Time == dateshift(nowcast.Time,"start","hour");

plot(ax, nowcast.Time(hourlyNowcast), nowcast.Value(hourlyNowcast), Color = [0 .25 .95], LineStyle = "none", ...
    Marker = "o", MarkerFaceColor = [0 .25 .95], MarkerSize = 4, DisplayName = "Nowcast");

hourlyForecast = forecast.Time == dateshift(forecast.Time,"start","hour");
plot(ax, forecast.Time(hourlyForecast), forecast.Value(hourlyForecast), Color = [0 .65 0], LineStyle = "none", ...
    Marker = "o", MarkerFaceColor = [0 .65 0], MarkerSize = 4, DisplayName = "Forecast guidance");
if dataProduct == "winds"
    text(ax,1,1.02,"Arrows point toward wind travel",Units="normalized", ...
        HorizontalAlignment="right",FontSize=9);
end
xline(ax, min(forecast.Time), Color = "black", LineWidth = 1.2, HandleVisibility = "off");
text(ax, .51, .98, "Forecast", Units = "normalized", VerticalAlignment = "top", FontSize = 9);
grid(ax, "on"); box(ax, "on");
ax.FontName = "Helvetica"; ax.FontSize = 10; ax.XLim = [min(stationData.Time), max(stationData.Time)];
xlabel(ax, "Time (EDT)");
ylabel(ax, stationData.Properties.VariableUnits{"Value"});
title(ax, stationName + " " + dataProduct, FontWeight = "normal");
legend(ax, Location = "northwest");
text(ax, 0, 1.13, "NOAA/National Ocean Service", Units = "normalized", VerticalAlignment = "bottom", FontSize = 11);
text(ax, 0, 1.07, "Chesapeake Bay Operational Forecast System (CBOFS2)", Units = "normalized", VerticalAlignment = "bottom", FontSize = 11);

if dataProduct == "winds"
    hourlyWind = stationData.Time == dateshift(stationData.Time,"start","hour");
    addWindArrows(ax,stationData(hourlyWind,:));
end

if strlength(outputFile) > 0
    if ~isfolder(fileparts(outputFile)), mkdir(fileparts(outputFile)); end
    exportgraphics(fig, outputFile, Resolution = 180);
end
end

function addWindArrows(ax,data)
% Keep quiver geometry in pixels, independent of datetime/knots scaling.
fig = ancestor(ax,"figure");
drawnow;
overlay = axes(fig,Units="pixels",Color="none",Visible="off", ...
    HandleVisibility="on",HitTest="off",PickableParts="visible", ...
    PositionConstraint="innerposition",NextPlot="add");
disableDefaultInteractivity(overlay);
overlay.Toolbar = [];
arrows = quiver(overlay,NaN,NaN,NaN,NaN,0,Color=[0 .2 1], ...
    LineWidth=1,MaxHeadSize=.5,HitTest="on",PickableParts="visible", ...
    HandleVisibility="on",Tag="WindArrows",DisplayName="Wind direction");
fig.CurrentAxes = ax;
refresh();
% Retain listeners with the figure so zoom, pan and resize stay aligned.
listeners = {addlistener(ax,"XLim","PostSet",@refresh), ...
    addlistener(ax,"YLim","PostSet",@refresh), ...
    addlistener(ax,"Position","PostSet",@refresh)};
fig.SizeChangedFcn = @refresh;
setappdata(overlay,"WindArrowListeners",listeners);

    function refresh(~,~)
        if ~isgraphics(ax) || ~isgraphics(overlay), return; end
        position = getpixelposition(ax);
        overlay.Position = position;
        overlay.XLim = [0 max(1,position(3))];
        overlay.YLim = [0 max(1,position(4))];
        limits = ruler2num(ax.XLim,ax.XAxis);
        x = (ruler2num(data.Time,ax.XAxis)-limits(1))/diff(limits)*position(3);
        y = (data.Value-ax.YLim(1))/diff(ax.YLim)*position(4);
        selected = find(x>=0 & x<=position(3) & y>=0 & y<=position(4) & ...
            data.Value>0 & isfinite(data.DirectionFrom));
        directionTo = data.DirectionFrom(selected)+180;
        set(arrows,XData=x(selected),YData=y(selected), ...
            UData=18*sind(directionTo),VData=18*cosd(directionTo));
    end
end

function stationData = readProduct(ncFile, targetLat, targetLon, product)
names = string({ncinfo(ncFile).Variables.Name});
lon = ncread(ncFile, findVariable(names, ["lon_rho","lon"]));
lat = ncread(ncFile, findVariable(names, ["lat_rho","lat"]));
[distanceSquared, stationIndex] = min((lat-targetLat).^2 + (cosd(targetLat)*(lon-targetLon)).^2);
assert(sqrt(distanceSquared) < .02, "No station point is sufficiently close to the requested coordinates.");
time = readTime(ncFile, findVariable(names, ["ocean_time","time"]));
stationCount = numel(lat);

switch product
    case "winds"
        u = readSeries(ncFile, findVariable(names, ["uwind","u_wind"]), stationIndex, stationCount, numel(time), false);
        v = readSeries(ncFile, findVariable(names, ["vwind","v_wind"]), stationIndex, stationCount, numel(time), false);
        value = 1.94384*hypot(u,v); direction = mod(atan2d(-u,-v),360); units = "Knots";
    case "water levels"
        value = readSeries(ncFile, "zeta", stationIndex, stationCount, numel(time), false);
        direction = nan(size(value)); units = "Water level (m)";
    case "water temperature"
        value = readSeries(ncFile, "temp", stationIndex, stationCount, numel(time), true);
        direction = nan(size(value)); units = "Water temperature (°C)";
    case "water salinity"
        value = readSeries(ncFile, "salt", stationIndex, stationCount, numel(time), true);
        direction = nan(size(value)); units = "Salinity";
    case "along-channel"
        u = readSeries(ncFile, "u", stationIndex, stationCount, numel(time), true);
        v = readSeries(ncFile, "v", stationIndex, stationCount, numel(time), true);
        angle = ncread(ncFile, "angle", stationIndex, 1);
        value = u*cos(angle) + v*sin(angle);
        direction = nan(size(value)); units = "Along-channel velocity (m/s)";
end

time.TimeZone = "UTC"; time.TimeZone = "America/New_York";
stationData = table(time(:), value(:), direction(:), VariableNames = ["Time","Value","DirectionFrom"]);
stationData.Properties.VariableUnits = ["", units, ""];
fprintf("Using station point %.5f°, %.5f° from %s.\n", lat(stationIndex), lon(stationIndex), ncFile);
end

function series = readSeries(ncFile, variableName, stationIndex, stationCount, timeCount, useSurface)
info = ncinfo(ncFile, variableName);
dimensionNames = string({info.Dimensions.Name});
values = ncread(ncFile, variableName);
stationDim = find(dimensionNames == "station", 1);
if isempty(stationDim), stationDim = find(size(values) == stationCount, 1); end
subscripts = repmat({':'},1,ndims(values)); subscripts{stationDim} = stationIndex;
if useSurface
    verticalDim = find(dimensionNames == "s_rho",1);
    assert(~isempty(verticalDim), "%s has no s_rho dimension.", variableName);
    subscripts{verticalDim} = size(values,verticalDim);
end
series = squeeze(values(subscripts{:}));
assert(numel(series) == timeCount, "%s does not have one value per time.", variableName);
end

function name = findVariable(names, candidates)
index = find(ismember(lower(names),candidates),1);
assert(~isempty(index), "Required variable not found: %s.", strjoin(candidates,", "));
name = names(index);
end

function time = readTime(ncFile, variableName)
secondsSinceEpoch = ncread(ncFile,variableName);
attributes = ncinfo(ncFile,variableName).Attributes;
units = string(attributes(strcmp({attributes.Name},"units")).Value);
token = regexp(units,"^seconds since (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})$","tokens","once");
assert(~isempty(token),"Unsupported time units: %s",units);
time = datetime(token{1},InputFormat="yyyy-MM-dd HH:mm:ss",TimeZone="UTC") + seconds(secondsSinceEpoch(:));
end
