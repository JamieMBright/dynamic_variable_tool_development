
DownloadAllReanalysisData(years,NCEP_vars,store);
NCEP_var_root={'pres.sfc.','tamb-','pwat-','rh3-'};
NCEP_var_name={'pres','air','pr_wtr','rhum'};
%set the colorbar limits for each variable
c_upper=[1100 400 10 100];
c_lower=[300 150 0 0];

% make new grid to interpolate the reanalysis data to. Use the MODIS
% 180x360 format for this
lat_new=flip(-89.5:89.5)';
lon_new=linspace(0,357.5,360);
lon_real=(-179.5:179.5)';
%make a meshed version of the new lon/lat for 2D interp
[lon_new_meshed,lat_new_meshed] = meshgrid(lon_new,lat_new);

%loop through each variable to be extracted from NCEP
for var=1:length(NCEP_vars)
    
    % check whether this variable must be performed
    if NCEP_raw_process(var)==1
        
        %define the filepath
        filepath=[store.NCEP_store,NCEP_vars{var},filesep,NCEP_var_root{var},num2str(years(y)),'.nc'];
        
        if exist(filepath,'file')
            try
                %load NCEP var
                % extract the appropriate data from the NetCDF file
                %get the reference file using the input date year
                nc=ncgeodataset(filepath);
                %extract the precipitable water column data
                data=nc{NCEP_var_name{var}};
                %remove from object to make matrix workspace
                data=double(data(:));
                %repeat for lat, lon and time
                lat=nc{'lat'};
                lat=double(lat(:));
                lon=nc{'lon'};
                lon=double(lon(:));
                % take a look at time.attributes - it's hours since 1/1/1800 00:00
                time=nc{'time'};
                time=time(:);
                %create datenums of the time
                time=datenum('1800-1-1 00:00')+time./24;
                
                % data must be in 180x360 latxlon format and the 3rd dim is time
                %make a mesh grid of the world in original resolution
                [LON,LAT]=meshgrid(lon,lat);
                
                %make empty 3d matrix for new data values
                NCEP_data=zeros(length(lat_new),length(lon_new),length(time)).*NaN;
                %loop through each time step and extract the interpolated data
                for t=1:length(time)
                    interped_data=interp2(LON,LAT,squeeze(data(t,:,:)),lon_new_meshed,lat_new_meshed);
                    % reshape the data so that prime meridian=180, not 360;
                    % due to the nature of the linspace to define lon_new, the
                    % closest value to 180deg is the 182nd entry in interped_data.
                    NCEP_data(:,:,t)=[interped_data(:,182:end),interped_data(:,1:181)];
                end
                
                
                % apply unit conversions where appropriate
                switch NCEP_vars{var}
                    case 'pressure'
                        % pressure is natively in pascals from NCEP. The desired
                        % unit for pressure is hPa.
                        % 100pa=1hPa
                        NCEP_data=NCEP_data./100;
                        
                    case 'temperature_2m'
                        % pressure is natively in Kelvin from NCEP. This is a
                        % satisfactory unit for temperature
                        
                    case 'precipitable_water'
                        % precipitable water is in kg/m^2. The desired format is
                        % cm-atm
                        % 1kg of water at STP = 1 litre = 1000cubic cm.
                        % 1 m^2 is 10,000cm^2, therefore 1kg water=0.1cm;
                        NCEP_data=NCEP_data.*0.1;
                        
                    case 'relative_humidity'
                        % Relative humidity is in % which is the satisfactory unit.
                end
                
                %save NCEP var
                % Save the data to file
                filename=GetFilename(store,NCEP_vars{var},years(y),NCEP_prefix);
                save(filename,'NCEP_data');
                
                % Make a gif of a single year
                gif_file = [store.raw_outputs_store,NCEP_var{var},filesep,NCEP_prefix,'_',NCEP_var{var},'_',num2str(years(y)),'.gif'];
                SaveMapToGIF(gif_file,eval(save_str{s}),lat_new,lon_real,save_str{s},units{s},time,c_upper(s),c_lower(s))
                
                clear NCEP_data data nc
                
            catch err
                % this will occur should the .nc file not be accessible.
                getReport(err,'extended');                
            end
        end
    end
end