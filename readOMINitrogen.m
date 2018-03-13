% Copyright (C) 2017 The HDF Group
%   All Rights Reserved 
%
%  This example code illustrates how to access and visualize OMI Grid file
% in MATLAB. 
%
%  If you have any questions, suggestions, comments on this example, please 
% use the HDF-EOS Forum (http://hdfeos.org/forums). 
% 
%  If you would like to see an  example of any other NASA HDF/HDF-EOS data 
% product that is not listed in the HDF-EOS Comprehensive Examples page 
% (http://hdfeos.org/zoo), feel free to contact us at eoshelp@hdfgroup.org 
% or post it at the HDF-EOS Forum (http://hdfeos.org/forums).
%
% Usage:save this script and run (without .m at the end)
%                                   
% https://acdisc.gesdisc.eosdis.nasa.gov/data/Aura_OMI_Level3/OMNO2d.003/2016/
% $matlab -nosplash -nodesktop -r OMI_Aura_L2G_OMSO2G_2017m0123_v003_2017m0124t071057_he5
%
% Tested under: MATLAB R2017a
% Last updated: 2017-12-19

clear
% Open the HDF5 File.
FILE_NAME = 'OMI-Aura_L3-OMNO2d_2004m1001_v003-2016m0824t140317.he5';

file_id = H5F.open (FILE_NAME, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');

% Open the dataset.
DATAFIELD_NAME = ...
'/HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2';
data_id = H5D.open (file_id, DATAFIELD_NAME);


% Read the dataset.
data=H5D.read (data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', ...
    'H5P_DEFAULT');


% Read the Title.
ATTRIBUTE = 'Title';
attr_id = H5A.open_name (data_id, ATTRIBUTE);
long_name = H5A.read(attr_id, 'H5ML_DEFAULT');

% Read the units.
ATTRIBUTE = 'Units';
attr_id = H5A.open_name (data_id, ATTRIBUTE);
units = H5A.read(attr_id, 'H5ML_DEFAULT');

% Read the offset.
ATTRIBUTE = 'Offset';
attr_id = H5A.open_name (data_id, ATTRIBUTE);
offset = H5A.read(attr_id, 'H5ML_DEFAULT');

% Read the scale.
ATTRIBUTE = 'ScaleFactor';
attr_id = H5A.open_name (data_id, ATTRIBUTE);
scale = H5A.read(attr_id, 'H5ML_DEFAULT');

% Read the fillvalue.
ATTRIBUTE = '_FillValue';
attr_id = H5A.open_name (data_id, ATTRIBUTE);
fillvalue=H5A.read (attr_id, 'H5T_NATIVE_DOUBLE');

% Read the missingvalue.
ATTRIBUTE = 'MissingValue';
attr_id = H5A.open_name (data_id, ATTRIBUTE);
missingvalue=H5A.read (attr_id, 'H5T_NATIVE_DOUBLE');


% Close and release resources.
H5A.close (attr_id)
H5D.close (data_id);
H5F.close (file_id);

% Replace the fill value with NaN
data(data==fillvalue) = NaN;

% Apply scale and offset, the equation is scale *(data-offset).
data = scale*(data-offset);

% convert to DU,
% The Dobson Unit is the most common unit for measuring ozone concentration. 
% One Dobson Unit is the number of molecules of ozone that would be required 
% to create a layer of pure ozone 0.01 millimeters thick at a temperature of 
% 0 degrees Celsius and a pressure of 1 atmosphere (the air pressure at the 
% surface of the Earth). Expressed another way, a column of air with an ozone 
% concentration of 1 Dobson Unit would contain about 2.69x1016ozone molecules 
% for every square centimeter of area at the base of the column. Over the Earth’s
% surface, the ozone layer’s average thickness is about 300 Dobson Units or a 
% layer that is 3 millimeters thick. https://ozonewatch.gsfc.nasa.gov/facts/dobson.html
data=data./2.69E16; %mol.cm-2 to DU
data=data./1000; %DU to cm
units='atm-cm';

% lats and lons
lats=-90+0.25/2:0.25:90-0.25/2;
lons=-180+0.25/2:0.25:180-0.25/2;
[lon,lat]=meshgrid(lons,lats);

% rotate the data
data=data';
% 
% f = figure('Name', FILE_NAME, 'visible', 'on');
% 
% axesm('MapProjection','eqdcylin', 'Grid', 'on', 'MeridianLabel', ...
%       'on','ParallelLabel','on', 'MLabelParallel','south', ... 
%       'FontSize', 7);
% coast = load('coast.mat');
% cm = colormap('summer');
% 
% % Surfacem is not good for data with many fill values.
% % surfacem(lat, lon, data);
% 
% % Use scatterm instead.
% lat = lat(:);
% lon = lon(:);
% data = data(:);
% scatterm(lat, lon, 1, data);
% h = colorbar();
% 
% unit = sprintf('%s', units);
% set(get(h, 'title'), 'string', unit, 'FontSize', 7);
% 
% plotm(coast.lat,coast.long,'k');
% tightmap;

% References
% [1] https://disc.gsfc.nasa.gov/datasets/OMSO2G_V003/summary