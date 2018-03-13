% function to plot a global image with boundaries
%plot_type can be 'surfm' or 'contourfm'. Surfm is considerably faster

function plotOnMap(latitudes,longitudes,data,plot_type,units,name)
%% safety
plot_types={'surfm','contourfm'};
if ~exist('plot_type','var')
    plot_type='surfm';
end
if strcmpi(plot_types,plot_type)==0
    error('Plot type must either be ''surfm'' or ''contourfm''')
end

if ~exist('name','var')
    name='';
end
if ~exist('units','var')
    units='';
end
if ~ischar(name)
    error('name must be a string')
end
if ~ischar(units)
    error('units must be a string')
end
if ~isnumeric(latitudes)
    error('latitude must be numeric')
end
if ~isnumeric(longitudes)
    error('longitude must be numeric')
end
if ~isnumeric(data)
    error('data must be numeric')
end
if [length(latitudes),length(longitudes)]~=[size(data,1),size(data,2)]
    disp('data must be of same dimensions as [latitude,longitude]')
    disp('Possible that the data needs rotating!')
    disp(['  ...skipping ',name])
    return
end
   
switch length(size(data))
    
    case 1
        return
    case 3
        data=squeeze(data(:,:,1));
    case 4
        data=squeeze(data(:,:,1,1));
end

%% create figure
f=figure('Name',name);
% Plot the data using contourfm and axesm.
latlim=[floor(min(min(latitudes))),ceil(max(max(latitudes)))];
lonlim=[floor(min(min(longitudes))),ceil(max(max(longitudes)))];
axesm('MapProjection','eqdcylin','MapLatLimit',latlim,'MapLonLimit',lonlim, ...
    'Frame','on','Grid','on', ...
    'MeridianLabel','on','ParallelLabel','on');

switch plot_type
    case 'surfm'
        surfm(latitudes,longitudes,data)
    case 'contourfm'
        contourfm(latitudes,longitudes,data,15,'LineStyle','none');
end

% Load the coastlines data file
coast = load('coast.mat');
% Draw the coastlines in color black ('k').
plotm(coast.lat,coast.long,'k')
% Put color bar.
h=colorbar();
set(get(h, 'title'), 'string', units);
title(f.Name, 'Interpreter', 'none', 'FontSize', 12, ...
    'FontWeight','bold');
end