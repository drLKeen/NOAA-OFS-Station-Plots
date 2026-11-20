function files = downloadCBOFSStationData(runDate, cycle, outputFolder, options)
%DOWNLOADCBOFSSTATIONDATA Download one CBOFS run's station time series.
%
% files = downloadCBOFSStationData(datetime(2026,8,29), "t00z")
% downloads the nowcast and forecast station NetCDF files from NOAA's public
% Open Data bucket. These compact station-series files are preferable to
% downloading every gridded fields.f###.nc file when making station plots.

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

dateFolder = string(runDate, "yyyy/MM/dd");
dateToken = string(runDate, "yyyyMMdd");
baseUrl = "https://noaa-nos-ofs-pds.s3.amazonaws.com/cbofs/netcdf/" + ...
    dateFolder + "/";
baseName = "cbofs." + cycle + "." + dateToken + ".stations.";
productTypes = ["nowcast", "forecast"];

files = table(Size = [2, 3], ...
    VariableTypes = ["string", "string", "string"], ...
    VariableNames = ["Product", "URL", "LocalFile"]);

for productIndex = 1:numel(productTypes)
    product = productTypes(productIndex);
    fileName = baseName + product + ".nc";
    url = baseUrl + fileName;
    localFile = fullfile(outputFolder, fileName);

    if options.Overwrite || ~isfile(localFile)
        fprintf("Downloading %s ...\n", url);
        websave(localFile, url);
    else
        fprintf("Using existing file %s\n", localFile);
    end

    assert(isfile(localFile), "Download did not create %s.", localFile);
    assert(dir(localFile).bytes > 0, "Downloaded file %s is empty.", localFile);
    files(productIndex, :) = {product, url, string(localFile)};
end
end
