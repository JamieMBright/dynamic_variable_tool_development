% Function to return time series of Angstrom data for multiple sites.
% This function makes use of the function loadHDFEOS, which creates a
% gridded map of MODIS Terra and Aqua polar orbiter information.
%
% The MODIS satellites have a native Angstrom Exponent product, however, it
% is often incomplete. This function requests all Aerosol Optical Depth
% (AOD) data that is available of the MODIS satellites, including the
% monthly mean. Using these datasets, the AOD are blended to produce a
% single AOD map with the corresponding measurement wavelength (Lambda).
% Using these, and the logic of Angstrom's Law, it is possible to derive
% Angstrom's Beta, a key component in the Linke Turbidity. Should there be
% no Angstrom Exponent data, it is defaulted to 1.3, which is accepted as
% appropriate for rural settings.
%
% The function loops through each day of the desired time series. The MODIS
% data is then extracted from that day using the Archive (described in
% loadHDFEOS). The gridded data is then probed with a nearest neighbour
% search to extract the appropriate value for the input defined
% latitude:longitude site pair. This daily value is applied to any
% timestamp requested within that day.
%
% The outputs are all contained within the Angstrom_struct, which contains
% the Angstrom exponent (alpha), the Angstrom turbidity coefficient (beta),
% the aerosol optical depth (AOD) which was used to derive it, as well as
% the wavelength that the AOD was recorded at(lambda).
% Missing gaps within the daily dataset are filled using the monthly value,
% then a nearest interpolation is used to fill any gaps therein. It is
% important to note that the poles (or any particular region +-60deg of
% latitude) are typically always empty, values outside these limits should
% be considered highly prone to error.
%
% The only inputs required to produce these Angstrom coefficients are a
% time series of desired timesteps, and the latitudes and longitudes of the
% desired sites.
% It is important to note that the data required is freely available from
% the ftp server defined in loadHDFEOS.
%
% AOD from MODIS has been proven by Zhong & Kleissl 2015 (Solar Energy 116
% 144-164) to be bias over land with a validation uwing aeronet data. This
% means that we apply a correction factor whereby
% AOD_corrected=AOD_MODIS/1.91-0.23;

% -------------------------- INFORMATION ---------------------------------
% Created by: Jamie Bright
% Date: 14/02/2018
% Computational: this function is highly scalable with number of sites
% with only a fractional difference between 3 sites and 30,000 sites.
% However, the time duration is slow but linear, obeying approximately
% duration= 3.8seconds*num_of_days.

% ------------------------------ INPUTS ---------------------------------
% times - a matlab datenum time series of any length in UTC
%
% latitudes/longitudes - respective lat lons that define each site (where
%         +90deg:-90deg latitude is N:S, and -180deg:180deg longitude is
%         W:E centered on prime meridian)
%

% ------------------------------- OUTPUTS -------------------------------
% REST2_struct - a struct containing the following variables:
%
% Angstrom_turbidity_b1    - the Angstrom Turbidity at band 1(beta)
% Angstrom_turbidity_b2    - the Angstrom Turbidity at band 2(beta)
% Angstrom_exponent_b1     - the Angtstrom exponent at band 1 (alpha)
% Angstrom_exponent_b2     - the Angtstrom exponent at band 2 (alpha)
% Pressure              - the surface level pressure (hPa or mb)
% Precipitable_water    - the precipitable water column (cm)
% Ozone                 - the column ozone amount (atm-cm)
% Nitrogen              - the column nitrogen amount (atm-cm)
% Aerosol_single_scattering_albedo - the aerosol single scattering albedo
% Ground_albedo         - the ground albedo
% AOD_b1                - the aerosol optical depth for band 1
% AOD_b2                - the aerosol optical depth for band 2
% lambda_b1             - the corresponding wavelength of AOD_b1 (microns)
% lambda_b2             - the corresponding wavelength of AOD_b2 (microns)
%
% Each variable comes with a X_confidence matrix which indicates which
% values are derived, and which are raw data.

% ------------------------------- EXAMPLE------------------------------
% num_of_days=30;
% num_of_sites=30000;
% times=datenum('20170620','yyyymmdd'):1/144:datenum('20170620','yyyymmdd')+num_of_days-1;
% latitudes=160.*rand(1,num_of_sites)-80;
% longitudes=360.*rand(1,num_of_sites)-180;
% tic
% REST2_struct=getREST2DailyVars(times,latitudes,longitudes);
% toc
% figure(1)
% plot(times,Angstrom_struct_example.AOD(:,1:4),times,Angstrom_struct_example.Alpha(:,1:4),times,Angstrom_struct_example.Beta(:,1:4));
% legend('AOD','Angstrom Exponent','Angstrom Turbidity')

function REST2_struct=getREST2DailyVars(times,latitudes,longitudes)
try
    %% initialise the sd C API for HDF that exists in matlab
    import matlab.io.hdf4.*
    init_paths
    %% Safety Checks
    if length(latitudes)~=length(longitudes)
        error('Latitudes and Longitudes must match in length')
    end
    
    [r,c]=size(latitudes);
    if c>r
        latitudes=latitudes';
    end
    [r,c]=size(longitudes);
    if c>r
        longitudes=longitudes';
    end
    num_of_sites=length(longitudes);
    
    %% Set the logic for MODIS extraction
    MODIS_data_store=['F:',filesep];
    MODIS_data_store_preprocessed=[MODIS_data_store,filesep,'REST2_daily_summaries',filesep];
    init_directory(MODIS_data_store_preprocessed);
    
    MODIS_datafields={...
        'Aerosol_Optical_Depth_Land_Ocean_Mean',...
        'Aerosol_Optical_Depth_Land_Mean',...
        'Aerosol_Optical_Depth_Average_Ocean_Mean',...
        'Water_Vapor_Near_Infrared_Clear_Mean',...
        'Water_Vapor_Near_Infrared_Cloud_Mean',...
        'Atmospheric_Water_Vapor_Mean',...
        'Corrected_Optical_Depth_Land_Micron_Levels',...
        'Effective_Optical_Depth_Average_Ocean_Micron_Levels',...
        'Total_Ozone_Mean',...
        'Pressure_Level',...
        'Deep_Blue_Single_Scattering_Albedo_Land_Mean',...
        'Deep_Blue_Aerosol_Optical_Depth_Land_Micron_Levels',...
        'Deep_Blue_Aerosol_Optical_Depth_Land_Mean',...
        'Retrieved_Temperature_Profile_Mean'...        
        };
    
    %% Set logic for Pressure and nitrogen data extraction
    DATAFIELD_NAME = ...
'/HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2';
    
    %% Convert time into apprpriate format
    dayvecs=datevec(times);
    dayvecs_unique=dayvecs(:,1:3);
    dayvecs_unique=unique(dayvecs_unique,'rows');
    datenums_unique=datenum(dayvecs_unique);
    
    %% Pre-Allocation of outputs;
    % outputs are to be time series of AOD, lambda, Alpha, Beta
    Alpha_day=zeros(length(dayvecs_unique),length(latitudes)).*NaN;
    Beta_day=zeros(length(dayvecs_unique),length(latitudes)).*NaN;
    ozone_day=zeros(length(dayvecs_unique),length(latitudes)).*NaN;
    nitrogen_day=zeros(length(dayvecs_unique),length(latitudes)).*NaN;
    pwat_day=zeros(length(dayvecs_unique),length(latitudes)).*NaN;
    pressure_day=zeros(length(dayvecs_unique),length(latitudes)).*NaN;
    
    %% Loop through each unique day and extract from MODIS
    for t=1:length(datenums_unique)
        datestr_yyyymmdd=datestr(datenums_unique(t),'yyyymmdd');
        preprocessed_day_filename=[MODIS_data_store_preprocessed,datestr_yyyymmdd,'.mat'];
        
        if ~exist(preprocessed_day_filename,'file')
            
            %% trigger loadHDFEOS and extract the necessary data to get Angstrom
            [data,latitudes_HDF,longitudes_HDF,~,~]=loadHDFEOS(datestr_yyyymmdd,MODIS_datafields,MODIS_data_store);
            
            if ~exist('land_mask','var')
                [LON,LAT]=meshgrid(longitudes_HDF,latitudes_HDF);
                LAT=reshape(LAT,numel(LAT),1);
                LON=reshape(LON,numel(LON),1);
                land_mask=reshape(landmask(LAT,LON),[length(latitudes_HDF),length(longitudes_HDF)]);
            end
            
            %% Angstrom Exponent (alpha)
            % Gueymard 2008, Solar Energy 82 272-285, Table 1 states:
            % Alpha for Band 1 from measurements between 415 and 674 nm
            % Alpha for Band 2 from measurements between 673 and 870 nm
            % alpha=log(AOD1./AOD2)./log(lambda2./lambda1);
            
            % Remove negatives else suffer complex doubles in alpha calculation
            data.Aerosol_Optical_Depth_Land_Mean(data.Aerosol_Optical_Depth_Land_Mean<=0)=NaN;
            data.Aerosol_Optical_Depth_Average_Ocean_Mean(data.Aerosol_Optical_Depth_Average_Ocean_Mean<=0)=NaN;
            
            % excract each ocean layer into level 1
            AOD_470(:,:,1)=squeeze(data.Aerosol_Optical_Depth_Average_Ocean_Mean(:,:,1));
            AOD_550(:,:,1)=squeeze(data.Aerosol_Optical_Depth_Average_Ocean_Mean(:,:,2));
            AOD_660(:,:,1)=squeeze(data.Aerosol_Optical_Depth_Average_Ocean_Mean(:,:,3));
            AOD870=squeeze(data.Aerosol_Optical_Depth_Average_Ocean_Mean(:,:,4));
          
            % excract each land layer into level 2
            AOD_470(:,:,2)=squeeze(data.Aerosol_Optical_Depth_Land_Mean(:,:,1));
            AOD_550(:,:,2)=squeeze(data.Aerosol_Optical_Depth_Land_Mean(:,:,2));
            AOD_660(:,:,2)=squeeze(data.Aerosol_Optical_Depth_Land_Mean(:,:,3));
            AOD412=squeeze(data.Deep_Blue_Aerosol_Optical_Depth_Land_Mean(:,:,1));
            % Take a mean of the Aqua and Terra analyses where
            % corresponding measurements exist
            AOD470=nanmean(AOD_470,3);
            AOD550=nanmean(AOD_550,3);
            AOD660=nanmean(AOD_660,3);
            
            % Calculate alpha using the greatest separation of wavelengths
            % possible in the band ranges
            alpha_b1=log(AOD412./AOD660)./log(0.66/0.412);
            alpha_b2=log(AOD660./AOD870)./log(0.87/0.66);
            
            %Perform every possible combination of wavelengths (3 for land, and 21 for sea)
            alpha(:,:,1)=log(AOD470./AOD550)./log(0.550/0.470);
            alpha(:,:,2)=log(AOD470./AOD660)./log(0.660/0.470);
            alpha(:,:,3)=log(AOD550./AOD660)./log(0.660/0.550);
            
            %take the most appropriate alpha value for each band
            alpha_b1=nanmean(alpha,3);
            alpha_b2=squeeze(alpha(:,:,3)); %%% THIS NEEDS DECIDING
            
            %make aconfidence that will indicate raw data
            alpha_b1_confidence=zeros(size(alpha_b1));
            alpha_b2_confidence=zeros(size(alpha_b2));
            alpha_b1_confidence(~isnan(alpha_b1))=1;
            alpha_b2_confidence(~isnan(alpha_b2))=1;
            
            % fill the gaps with the nearest value - THIS METHODOLOGY WILL NEED TO BE PUBLISHED
            alpha_b1=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,alpha_b1);
            alpha_b2=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,alpha_b2);
                                    
            %% Angstrom Turbidity (Beta)
            % Each Beta is derived from associated Angstrom Exponents at a
            % relavent aerosol optical depth at band 1 and 2.
            % Beta=AOD/lambda^alpha;
            % Band 1 AODs from measurements between 415 and 674 nm
            % Band 2 AODs from measurements between 673 and 870 nm
            
            % Preallocate the AOD and lambda arrays
            AOD_b1=zeros(size(alpha_b1)).*NaN;
            AOD_b2=zeros(size(alpha_b1)).*NaN;
            lambda_b1=zeros(size(alpha_b1)).*NaN;
            lambda_b2=zeros(size(alpha_b1)).*NaN;
                        
            % Fill the AOD and lambda bands with the most appropriate AODs BAND1 415 and 674 nm
            AOD_b1(~isnan(AOD550))=AOD550(~isnan(AOD550));
            lambda_b1(~isnan(AOD550))=0.55; 
            AOD_b1(isnan(AOD_b1) & ~isnan(AOD470))=AOD470(isnan(AOD_b1) & ~isnan(AOD470));
            lambda_b1(isnan(AOD_b1) & ~isnan(AOD470))=0.47; 
            AOD_b1(isnan(AOD_b1) & ~isnan(AOD660))=AOD660(isnan(AOD_b1) & ~isnan(AOD660));
            lambda_b1(isnan(AOD_b1) & ~isnan(AOD660))=0.66; 
            AOD_b1(isnan(AOD_b1) & ~isnan(AOD412))=AOD412(isnan(AOD_b1) & ~isnan(AOD412));
            lambda_b1(isnan(AOD_b1) & ~isnan(AOD412))=0.412; 
            % Fill the AOD bands with the most appropriate AODs BAND2 673 and 870 nm
            AOD_b2(~isnan(AOD870))=AOD870(~isnan(AOD870));
            lambda_b2(~isnan(AOD870))=0.87; 
            %interp any missing values to 700nm
            AOD700=exp(log(AOD660)-log(700/660).*alpha_b2);
            AOD_b2(isnan(AOD_b2) & ~isnan(AOD700))=AOD700(isnan(AOD_b2) & ~isnan(AOD700));
            lambda_b2(isnan(AOD_b2) & ~isnan(AOD700))=0.7; 
            
            % make aconfidence that will indicate raw data
            AOD_b1_confidence=zeros(size(AOD_b1));
            AOD_b1_confidence(~isnan(AOD_b1))=1;
            AOD_b2_confidence=zeros(size(AOD_b2));
            AOD_b2_confidence(~isnan(AOD_b2))=1;
            lambda_b1_confidence=zeros(size(lambda_b1));
            lambda_b1_confidence(~isnan(lambda_b1))=1;
            lambda_b2_confidence=zeros(size(lambda_b2));
            lambda_b2_confidence(~isnan(lambda_b2))=1;
            
            % fill missing
            AOD_b1=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,AOD_b1);
            AOD_b2=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,AOD_b2);
            
            % make beta confidences indicating raw data
            beta_b1_confidence=zeros(size(AOD_b1));
            beta_b1_confidence(~isnan(AOD_b1) & alpha_b1_confidence==1)=1;
            beta_b2_confidence=zeros(size(AOD_b2));
            beta_b2_confidence(~isnan(AOD_b2) & alpha_b2_confidence==1)=1;
            
            %calculate the Angstrom turbidity
            beta_b1=AOD_b1./(lambda_b1.^(-alpha_b1));
            beta_b2=AOD_b2./(lambda_b2.^(-alpha_b2));
            
            %% write these images to file
            %make struct 
            REST2data.latitudes_HDF=latitudes_HDF;
            REST2data.longitudes_HDF=longitudes_HDF;
            REST2data.alpha_b1=alpha_b1;
            REST2data.alpha_b2=alpha_b2;
            REST2data.alpha_b1_confidence=alpha_b1_confidence;
            REST2data.alpha_b2_confidence=alpha_b2_confidence;
            REST2data.beta_b1=beta_b1;
            REST2data.beta_b2=beta_b2;
            REST2data.beta_b1_confidence=beta_b1_confidence;
            REST2data.beta_b2_confidence=beta_b2_confidence;           
            REST2data.lambda_b1=lambda_b1;
            REST2data.lambda_b2=lambda_b2;
            REST2data.lambda_b1_confidence=lambda_b1_confidence;
            REST2data.lambda_b2_confidence=lambda_b2_confidence;
            REST2data.AOD_b1=AOD_b1;
            REST2data.AOD_b2=AOD_b2;
            REST2data.AOD_b1_confidence=AOD_b1_confidence;
            REST2data.AOD_b2_confidence=AOD_b2_confidence;
            
            save(preprocessed_day_filename,'-struct','data')
            
        else
            load(preprocessed_day_filename);
            
        end
        longitudes_HDF=REST2data.longitudes_HDF;
        latitudes_HDF=REST2data.latitudes_HDF;
        alpha_b1=REST2data.alpha_b1;
        alpha_b2=REST2data.alpha_b2;
        beta_b1=REST2data.beta_b1;
        beta_b2=REST2data.beta_b2;
        lambda=REST2data.lambda;
        aod=REST2data.AOD;
        
        
        %% Find the grid indices for each site
        
        if ~exist('site_inds','var')
            %safety check on lon so that it is -180W:180E
            if max(longitudes)>180
                longitudes=longitudes-180;
            end
            
            %make a mesh grid of the world in original resolution
            [LON,LAT]=meshgrid(longitudes_HDF,latitudes_HDF);
            a=[reshape(LAT,numel(LAT),1),reshape(LON,numel(LON),1)];
            b=[latitudes, longitudes];
            
            % nearest neighbor search of input lat:lons inside the world lat:lons
            site_inds=knnsearch(a,b);
        end
        
        %% Populate outputs
        Beta_day(t,:)=beta_b1(site_inds)';
        Alpha_day(t,:)=Angstrom_Alpha(site_inds)';
        ozone_day(t,:)=ozone(site_inds)';
        pwat_day(t,:)=pwat(site_inds)';
        
    end
    
    %% Get Nitrogen and Pressure
    
    %% Interpolate to the user input time requirement
    datenums_unique=reshape(datenums_unique,[numel(datenums_unique)*num_of_sites,1]);
    Alpha=interp1(datenums_unique,Alpha_day,times(:,1),'pchip');
    Beta=interp1(datenums_unique,Beta_day,times,'pchip');
    pwat=interp1(datenums_unique,pwat_day,times,'pchip');
    ozone=interp1(datenums_unique,ozone_day,times,'pchip');
    pressure=interp1(datenums_unique,pressure_day,times,'pchip');
    nitrogen=interp1(datenums_unique,nitrogen_day,times,'pchip');
    
    %% Outputs
    REST2_struct.Angstrom_Beta=Beta;
    REST2_struct.Angstrom_exponent=Alpha;
    REST2_struct.Precipitable_Water=pwat;
    REST2_struct.Ozone=ozone;
    REST2_struct.Nitrogen=nitrogen;
    REST2_struct.Pressure=pressure;
    
catch err
    disp(getReport(err,'extended'))
    error('wtf?!')
end
end