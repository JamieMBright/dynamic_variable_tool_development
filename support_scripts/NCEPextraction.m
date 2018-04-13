function NCEPextraction(NCEP_vars,NCEP_raw_process,NCEP_prefix,years,y,store)

DownloadAllReanalysisData(years,NCEP_vars,store);
NCEP_var_root={'pres.sfc.','tamb-','pwat-','rh3-'};
NCEP_var_name={'pres','air','pr_wtr','rhum'};
%set the colorbar limits for each variable
c_upper=[1100 400 10 100];
c_lower=[300 150 0 0];

% make new grid to interpolate the reanalysis data to. Use the MODIS
% 180x360 format for this
lat_new=flip(-88.5:88.5)';
lon_new=linspace(0,357.5,360);
lon_real=(-179.5:179.5)';
%make a meshed version of the new lon/lat for 2D interp
[lon_new_meshed,lat_new_meshed] = meshgrid(lon_new,lat_new);

%loop through each variable to be extracted from NCEP
for var=1:length(NCEP_vars)
    % check whether this variable must be performed
    if NCEP_raw_process(var)==1
        % report to console
        disp(['Processing NCEP: ',NCEP_vars{var},' for ',num2str(years(y))])
        %define the filepath
        filepath=[store.NCEP_store,NCEP_vars{var},filesep,NCEP_var_root{var},num2str(years(y)),'.nc'];
        
        if exist(filepath,'file')
            try
                %load NCEP var
                % extract the appropriate data from the NetCDF file
                %get the reference file using the input date year
                evalc('nc=ncgeodataset(filepath);');
                %extract the precipitable water column data
                evalc('data=nc{NCEP_var_name{var}};');
                %remove from object to make matrix workspace
                data=double(data(:));
                %repeat for lat, lon and time
                evalc('lat=nc{''lat''};');
                lat=double(lat(:));
                evalc('lon=nc{''lon''};');
                lon=double(lon(:));
                % take a look at time.attributes - it's hours since 1/1/1800 00:00
                evalc('time=nc{''time''};');
                time=time(:);
                %create datenums of the time
                time=datenum('1800-1-1 00:00')+time./24;
                time_dayvecs=datevec(time);
                
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
                        units='hPa';
                        
                    case 'temperature_2m'
                        % pressure is natively in Kelvin from NCEP. This is a
                        % satisfactory unit for temperature
                        units='K';
                        
                    case 'precipitable_water'
                        % precipitable water is in kg/m^2. The desired format is
                        % cm-atm
                        % 1kg of water at STP = 1 litre = 1000cubic cm.
                        % 1 m^2 is 10,000cm^2, therefore 1kg water=0.1cm;
                        NCEP_data=NCEP_data.*0.1;
                        units='atm-cm';
                        
                    case 'relative_humidity'
                        % Relative humidity is in % which is the satisfactory unit.
                        units='%';
                end
                
                %create a confidence variable
                NCEP_confidence=zeros(size(NCEP_data));
                NCEP_confidence(~isnan(NCEP_data))=1;
                
                % load the land mask for gap filling
                if ~exist('land_mask','var')
                    [LON_lm,LAT_lm]=meshgrid(lon_new-180,lat_new);
                    LAT_lm=reshape(LAT_lm,numel(LAT_lm),1);
                    LON_lm=reshape(LON_lm,numel(LON_lm),1);
                    land_mask=reshape(landmask(LAT_lm,LON_lm),[length(lat_new),length(lon_new)]);
                end
                
                % fill any gaps.
                NCEP_data=REST2FillMissing(land_mask,lon,lat,NCEP_data);
                
                %save NCEP var
                % Save the data to file
                filename=GetFilename(store,NCEP_vars{var},years(y),NCEP_prefix);
                save(filename,'NCEP_data','-v7.3');
                % Save the confidence to file
                filename=GetFilename(store,NCEP_vars{var},years(y),NCEP_prefix,'confidence');
                save(filename,'NCEP_confidence','-v7.3');
                % save the times
                filename=GetFilename(store,NCEP_vars{var},years(y),NCEP_prefix,'times_datevec');
                save(filename,'time_dayvecs','-v7.3');
                % save the one time latitudes and longitudes
                filename=GetFilename(store,NCEP_vars{var},years(y),NCEP_prefix,'latitudes');
                save(filename,'lat_new','-v7.3');
                filename=GetFilename(store,NCEP_vars{var},years(y),NCEP_prefix,'longitudes');
                save(filename,'lon_real','-v7.3');
                
                % Make a gif of a single year
                
                if y==(length(years)-1)
                    gif_file = [store.raw_outputs_store,NCEP_vars{var},filesep,NCEP_prefix,'_',NCEP_vars{var},'_',num2str(years(y)),'.gif'];
                    if exist(gif_file,'file')
                        delete(gif_file);
                    end
                    SaveMapToGIF(gif_file,NCEP_data,lat_new,lon_real,NCEP_vars{var},units,time,c_upper(var),c_lower(var))
                end
                clear NCEP_data data nc
                
            catch err
                % this will occur should the .nc file not be accessible.
                if strcmp(err.identifier,'MATLAB:imagesci:hdf5lib:fileOpenErr')
                else
                    getReport(err,'extended')
                end
            end
        end
    end
end
end