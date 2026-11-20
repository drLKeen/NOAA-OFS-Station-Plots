function [dataStruct] = OFS_nc_retrieve(filename)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Create a structure to store imported netCDF data
dataStruct = struct();

%filename = "C:\Users\MathWorks\Downloads\cbofs.t00z.20260829.fields.f001(3).nc";

dataStruct.Attributes(1).Name = "file";
dataStruct.Attributes(1).Value = ncreadatt(filename, "/", ...
    "file");

dataStruct.Variables(1).Name = "lon_rho";
dataStruct.Variables(1).Value = ncread(filename, "/lon_rho");

dataStruct.Variables(2).Name = "lat_rho";
dataStruct.Variables(2).Value = ncread(filename, "/lat_rho");

dataStruct.Variables(3).Name = "lon_u";
dataStruct.Variables(3).Value = ncread(filename, "/lon_u");

dataStruct.Variables(4).Name = "lat_u";
dataStruct.Variables(4).Value = ncread(filename, "/lat_u");

dataStruct.Variables(5).Name = "lon_v";
dataStruct.Variables(5).Value = ncread(filename, "/lon_v");

dataStruct.Variables(6).Name = "lat_v";
dataStruct.Variables(6).Value = ncread(filename, "/lat_v");

% dataStruct.Variables(7).Name = "lon_psi";
% dataStruct.Variables(7).Value = ncread(filename, "/lon_psi");
% 
% dataStruct.Variables(8).Name = "lat_psi";
% dataStruct.Variables(8).Value = ncread(filename, "/lat_psi");

dataStruct.Variables(9).Name = "temp";
dataStruct.Variables(9).Value = ncread(filename, "/temp");

dataStruct.Variables(10).Name = "salt";
dataStruct.Variables(10).Value = ncread(filename, "/salt");

dataStruct.Variables(11).Name = "oxygen";
dataStruct.Variables(11).Value = ncread(filename, "/oxygen");

dataStruct.Variables(12).Name = "Pair";
dataStruct.Variables(12).Value = ncread(filename, "/Pair");

dataStruct.Variables(13).Name = "Uwind";
dataStruct.Variables(13).Value = ncread(filename, "/Uwind");

dataStruct.Variables(14).Name = "Vwind";
dataStruct.Variables(14).Value = ncread(filename, "/Vwind");

% dataStruct.Variables(1).Attributes(1).Name = "standard_name";
% dataStruct.Variables(1).Attributes(1).Value = ncreadatt(filename, "/lon_rho", ...
%     "standard_name");
% 
% dataStruct.Variables(1).Attributes(2).Name = "long_name";
% dataStruct.Variables(1).Attributes(2).Value = ncreadatt(filename, "/lon_rho", ...
%     "long_name");
% 
% dataStruct.Variables(1).Attributes(3).Name = "units";
% dataStruct.Variables(1).Attributes(3).Value = ncreadatt(filename, "/lon_rho", ...
%     "units");


end