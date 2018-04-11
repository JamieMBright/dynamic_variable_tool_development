% function to plot a global image with boundaries
%plot_type can be 'surfm' or 'contourfm'. Surfm is considerably faster

function plotOnMap(latitudes,longitudes,data,plot_type,units,name,figure_handle,clims)
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
if ~exist('clims','var')
    clims='auto';
end
   

if ~exist('figure_handle','var')
 figure_handle=figure('Name',name);
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
% Plot the data using contourfm and axesm.
latlim=[floor(min(min(latitudes))),ceil(max(max(latitudes)))];
lonlim=[floor(min(min(longitudes))),ceil(max(max(longitudes)))];
axesm('MapProjection','eqdcylin','MapLatLimit',latlim,'MapLonLimit',lonlim, ...
    'Frame','on','Grid','on', ...
    'MeridianLabel','on','ParallelLabel','on');
% Put color bar.
colours=[255,247,251;...
% 236,231,242;...
% 208,209,230;...
% 166,189,219;...
% 116,169,207;...
54,144,192;...
5,112,176;...
4,90,141;...
2,56,88]./255;
c_x=1:length(colours);
colours_interped=interp1(c_x,colours,linspace(c_x(1),c_x(end),30));

switch plot_type
    case 'surfm'
        surfm(latitudes,longitudes,data)        
    case 'contourfm'
        contourfm(latitudes,longitudes,data,15,'LineStyle','none');
end

colormap(colours_interped);
% Load the coastlines data file
coast = load('coast.mat');
% Draw the coastlines in color black ('k').
plotm(coast.lat,coast.long,'k')

h=colorbar();
caxis(clims)
set(get(h, 'title'), 'string', units);
title(name, 'Interpreter', 'none', 'FontSize', 12, ...
    'FontWeight','bold');
end