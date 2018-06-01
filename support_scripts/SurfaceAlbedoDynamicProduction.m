%% open and extract the albedo for lat lons and timestamps;
function [] = SurfaceAlbedoDynamicProduction(store,this_year)
if ~exist([store.raw_outputs_store,'albedo'],'dir')
    init_directory([store.raw_outputs_store,'albedo'])
end
% extract data from netcdf
raw_data_filename=[store.raw_outputs_store,'albedo.day.ltm.nc'];
nc=ncgeodataset(raw_data_filename);
data=nc{'albedo'}(:);
lat=nc{'lat'}(:);
lon=nc{'lon'}(:);
time=linspace(datenum([num2str(this_year),'010112'],'yyyymmddHH'),datenum([num2str(this_year),'123112'],'yyyymmddHH'),size(data,1));
time_dayvecs=datevec(time);

% convert to appropriate lat lon.

% 180x360 format for this
lat_new=flip(-88.5:88.5)';
lon_new=linspace(0,357.5,360);
lon_real=(-179.5:179.5)';
%make a meshed version of the new lon/lat for 2D interp
[lon_new_meshed,lat_new_meshed] = meshgrid(lon_new,lat_new);

% data must be in 180x360 latxlon format and the 3rd dim is time
%make a mesh grid of the world in original resolution
[LON,LAT]=meshgrid(lon,lat);
NCEP_data=zeros(length(lat_new),length(lon_new),length(time)).*NaN;
%loop through each time step and extract the interpolated data
for t=1:length(time)
    interped_data=interp2(LON,LAT,squeeze(data(t,:,:)),lon_new_meshed,lat_new_meshed);
    % reshape the data so that prime meridian=180, not 360;
    % due to the nature of the linspace to define lon_new, the
    % closest value to 180deg is the 182nd entry in interped_data.
    NCEP_data(:,:,t)=[interped_data(:,182:end),interped_data(:,1:181)];
end

NCEP_confidence=zeros(size(NCEP_data));
NCEP_confidence(~isnan(NCEP_data))=1;

%save NCEP var
% Save the data to file
filename=GetFilename(store,'albedo',this_year,'');
save(filename,'NCEP_data','-v7.3');
% Save the confidence to file
filename=GetFilename(store,'albedo',this_year,'','confidence');
save(filename,'NCEP_confidence','-v7.3');
% save the times
filename=GetFilename(store,'albedo',this_year,'','times_datevec');
save(filename,'time_dayvecs','-v7.3');
% save the one time latitudes and longitudes
filename=GetFilename(store,'albedo',this_year,'','latitudes');
save(filename,'lat_new','-v7.3');
filename=GetFilename(store,'albedo',this_year,'','longitudes');
save(filename,'lon_real','-v7.3');


end
