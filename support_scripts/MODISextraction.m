function MODISextraction(MODIS_vars,MODIS_raw_process,MODIS_prefix,years,y,store)


for var=1:length(MODIS_vars)
    % if the flag says this variable must be processed, then process.
    if MODIS_raw_process(var)==1
        % Convert time into apprpriate format for MODIS - daily files
        time_datenum_daily=datenum(num2str(years(y)),'yyyy'):datenum(num2str(years(y)+1),'yyyy')-1;
        time_dayvecs=datevec(time_datenum_daily);
        
        % Set the MODIS data fields for extraction from each file
        switch MODIS_vars{var}
            case 'aerosol_optical_depth'
                MODIS_datafields={...
                    'Aerosol_Optical_Depth_Land_Ocean_Mean',...
                    'Aerosol_Optical_Depth_Land_Mean',...
                    'Aerosol_Optical_Depth_Average_Ocean_Mean',...
                    'Corrected_Optical_Depth_Land_Micron_Levels',...
                    'Effective_Optical_Depth_Average_Ocean_Micron_Levels',...
                    'Deep_Blue_Single_Scattering_Albedo_Land_Mean',...
                    'Deep_Blue_Aerosol_Optical_Depth_Land_Micron_Levels',...
                    'Deep_Blue_Aerosol_Optical_Depth_Land_Mean',...
                    };
                angstrom_exponent_b1_confidence=int8(zeros(180,360,length(time_datenum_daily)));
                angstrom_exponent_b2_confidence=int8(zeros(180,360,length(time_datenum_daily)));
                angstrom_turbidity_b1_confidence=int8(zeros(180,360,length(time_datenum_daily)));
                angstrom_turbidity_b2_confidence=int8(zeros(180,360,length(time_datenum_daily)));
                AOD700_confidence=int8(zeros(180,360,length(time_datenum_daily)));
                angstrom_exponent_b1=zeros(180,360,length(time_datenum_daily)).*NaN;
                angstrom_exponent_b2=zeros(180,360,length(time_datenum_daily)).*NaN;
                angstrom_turbidity_b1=zeros(180,360,length(time_datenum_daily)).*NaN;
                angstrom_turbidity_b2=zeros(180,360,length(time_datenum_daily)).*NaN;
                AOD700=zeros(180,360,length(time_datenum_daily)).*NaN;
                
                units={'','','','',''};
                c_lower=[0 0 0 0 0];
                c_upper=[2.5 2.5 1.1 1.1 5];
                % set the save string
                save_str={'angstrom_exponent_b1','angstrom_exponent_b2','angstrom_turbidity_b1','angstrom_turbidity_b2','AOD700'};
                
            case 'ozone'
                MODIS_datafields={'Total_Ozone_Mean'};
                ozone=zeros(180,360,length(time_datenum_daily)).*NaN;
                ozone_confidence=int8(zeros(180,360,length(time_datenum_daily)));
                units={'atm-cm'};
                long_name='Total Ozone Burden: Mean';
                c_upper=0.6;
                c_lower=0;
                % set the save string
                save_str={MODIS_vars{var}};
                
            case 'precipitable_water'
                MODIS_datafields={'Atmospheric_Water_Vapor_Mean'};
                %                         'Water_Vapor_Near_Infrared_Clear_Mean',...
                %                         'Water_Vapor_Near_Infrared_Cloud_Mean',...
                precipitable_water=zeros(180,360,length(time_datenum_daily)).*NaN;
                precipitable_water_confidence=int8(zeros(180,360,length(time_datenum_daily)));
                units={'cm'};
                long_name='Precipitable Water Vapor (IR Retrieval) Total Column: Mean';
                c_upper=8;
                c_lower=0;
                % set the save string
                save_str={MODIS_vars{var}};
        end
        
        % trigger loadHDFEOS and extract the necessary data to get Angstrom
        % Loop through each day within the year
        for d = 1:length(time_datenum_daily)
            disp(['Processing MODIS: ',MODIS_vars{var},' for ',datestr(time_datenum_daily(d))])
            % make a a string of the current day
            datestr_yyyymmdd=datestr(time_datenum_daily(d),'yyyymmdd');
            
            % extract the data from MODIS using the date and the datafields
            [data,latitudes_HDF,longitudes_HDF,~,~]=loadHDFEOS(datestr_yyyymmdd,MODIS_datafields,store.MODIS_store);
            
            %persist the latitudes and longitudes to a separate varaible
            %for saving. This is because, should the last d iteration fail,
            %there is no data in latitudes_ or longitudes_HDF to store, and
            %therefore, an empty variable will be saved\
            if (~exist('longitudes_for_save','var') && ~isempty(longitudes_HDF))
                longitudes_for_save=longitudes_HDF;
            end
            if (~exist('latitudes_for_save','var') && ~isempty(latitudes_HDF))
                latitudes_for_save=latitudes_HDF;
            end
            
            %% Gap filling
            % Gap filling is performed first over land, and then over sea. A land mask
            % is loaded first for indications of where the land is.
            % load up a land_mask should it not already be in memory.
            if ~exist('land_mask','var')
                try % this will fail if loadHDFEOS fails, however will not be attempted upon first successful completion.
                    [LON,LAT]=meshgrid(longitudes_HDF,latitudes_HDF);
                    LAT=reshape(LAT,numel(LAT),1);
                    LON=reshape(LON,numel(LON),1);
                    land_mask=reshape(landmask(LAT,LON),[length(latitudes_HDF),length(longitudes_HDF)]);
                catch err
                end
            end
            % perform the appropriate processing for the MODIS variables
            switch MODIS_vars{var}
                case 'aerosol_optical_depth'
                    % derivations for Angstrom and AOD are calculated
                    % inside the PostProcessing function. Also within
                    % there are the gapfilling methods
                    if ~isempty(data)
                        [a_b1,a_b2,b_b1,b_b2,a_b1_c,a_b2_c,b_b1_c,b_b2_c,aod700,aod700_c]=PostProcessingOfModisAOD(data,latitudes_HDF,longitudes_HDF,land_mask);
                        angstrom_exponent_b1(:,:,d)=a_b1;
                        angstrom_exponent_b2(:,:,d)=a_b2;
                        angstrom_turbidity_b1(:,:,d)=b_b1;
                        angstrom_turbidity_b2(:,:,d)=b_b2;
                        AOD700(:,:,d)=aod700;
                        angstrom_exponent_b1_confidence(:,:,d)=a_b1_c;
                        angstrom_exponent_b2_confidence(:,:,d)=a_b2_c;
                        angstrom_turbidity_b1_confidence(:,:,d)=b_b1_c;
                        angstrom_turbidity_b2_confidence(:,:,d)=b_b2_c;
                        AOD700_confidence(:,:,d)=aod700_c;
                    end
                    
                case 'ozone'
                    %ozone in its raw state is in Dobson Units (DU). This
                    %is a unit measurement of trace gas in a vertical
                    %column through the Earth;s atmosphere. 1 DU is equal
                    %to the number of molecules needed to create a pure
                    %layer of ozone 0.1 mm thick at standard pressure.
                    %Therefore, 300 DU would form 3 mm of pure gas
                    %(atm-mm).
                    % The desired format is in atm-cm and so only a simple
                    % conversion needs to be performed
                    % 1 atm-cm = 1000 DU
                    if ~isempty(data)
                        % fill gaps
                        data.Total_Ozone_Mean=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,data.Total_Ozone_Mean);
                        %allocate to main variable
                        ozone(:,:,d)=data.Total_Ozone_Mean./1000;
                        ozone_confidence(:,:,d)=~isnan(data.Total_Ozone_Mean);
                    end
                    
                case 'precipitable_water'
                    % The precipitable water from MODIS is already in
                    % the desired units of cm, and so no futher
                    % conversion is required. There is still the
                    % decision to be made of how to account for the
                    % different measurements of infrared as well as
                    % standard atmospheric data. There is the option to
                    % have the sunglint near IR and also clouded IR.
                    if ~isempty(data)
                        pwat_availability=fieldnames(data);
                        precipitable_water_all=zeros(length(latitudes_HDF),length(longitudes_HDF),length(pwat_availability)).*NaN;
                        for p=1:length(pwat_availability)
                            precipitable_water_all(:,:,p)=eval(['data.',pwat_availability{p}]);
                        end
                        
                        % populate the precipitable water variable
                        if length(size(precipitable_water_all))==3
                            
                            precipitable_water_gap_filled=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,nanmean(precipitable_water_all,3));
                        else
                            precipitable_water_gap_filled=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,precipitable_water_all);
                        end
                        
                        precipitable_water(:,:,d)=precipitable_water_gap_filled;
                        precipitable_water_confidence(:,:,d)=~isnan(precipitable_water_gap_filled);
                        
                    end
                    
            end
            
            
        end
        
        
        % Save the data to file
        for s=1:length(save_str)
            filename=GetFilename(store,save_str{s},years(y),MODIS_prefix);
            save(filename,save_str{s},'-v7.3');
            filename=GetFilename(store,save_str{s},years(y),MODIS_prefix,'confidence');
            save(filename,[save_str{s},'_confidence'],'-v7.3');
            filename=GetFilename(store,save_str{s},years(y),MODIS_prefix,'times_datevec');
            save(filename,'time_dayvecs','-v7.3');
            % save the one time latitudes and longitudes
            filename=GetFilename(store,save_str{s},years(y),MODIS_prefix,'latitudes');
            save(filename,'latitudes_for_save','-v7.3');
            filename=GetFilename(store,save_str{s},years(y),MODIS_prefix,'longitudes');
            save(filename,'longitudes_for_save','-v7.3');
            
            if y==(length(years)-1)
                % Make a gif of a single year
                gif_file = [store.raw_outputs_store,save_str{s},filesep,'MODIS_',save_str{s},'_',num2str(years(y)),'.gif'];
                SaveMapToGIF(gif_file,eval(save_str{s}),latitudes_HDF,longitudes_HDF,save_str{s},units{s},time_datenum_daily,c_upper(s),c_lower(s))
            end
        end
        % clear the excess data for memory conservation
        clear data ozone angstrom_exponent_b1 angstrom_exponent_b2 angstrom_turbidity_b1 angstrom_turbidity_b2 precipitable_water precipitable_water_all precipitable_water_gap_filled land_mask AOD700
    end
end


end