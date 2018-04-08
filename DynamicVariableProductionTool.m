% Dynamic Variable Production Wrapper
%
% ========================================================================
%                               Information
% ========================================================================
% Started: 13/03/2018
% Author: Dr Jamie M. Bright
%
% Affiliation: The Australian National University, Fenner School.
% License: Open source, must cite.
%
% Prefered Citation: Bright, J.M. et al. 2018. Global clear-sky irradiance
% model validation using dynamic variables from NCEP, MODIS and OMI.
% Solar Energy. xx pp xxx-xxx.
%
% ========================================================================
%                 Raw variables from satellite and NWP
% ========================================================================
%
%  +---------------------------------------------------------------------+
%  | Variable        Source              Conversion      Validation      |
%  +---------------------------------------------------------------------+
%  | Pressure        NCEP                Y               BSRN            |
%  | Rel. Humidity   NCEP                Y               BSRN            |
%  | Temperature     NCEP                Y               BSRN            |
%  | AOD             MODIS               Y(Complex)      AERONET         |
%  | Ozone           MODIS, NCEP, OMI    Y               AERONET         |
%  | Nitrgen di.     OMI                 Y               x               |
%  | Precip. Water   MODIS, NCEP         Y               AERONET/BSRN    |
%  +---------------------------------------------------------------------+
%

% ========================================================================
%                           Input user requirements
% ========================================================================
% The user must define the directories of where all the raw data is stored.
% Firstly by setting the drive root, and then by ensuring the pathing.
% The user must also specify the years that will be produced.
% The user must also specify an overwirte flag, a default assumption is
% that only unique years will be produced, with exception of the current
% year, the function will check for new data and then -append the new.
%
% ========================================================================
%                           Output data sets
% ========================================================================
% There are many clear-sky irradiance models that can be used. The
% intention is to provide a dynamic variable for each of their inputs.

% Angstrom_turbidity_b1     - the Angstrom Turbidity at band 1(beta)
% Angstrom_turbidity_b2     - the Angstrom Turbidity at band 2(beta)
% Angstrom_exponent_b1      - the Angtstrom exponent at band 1 (alpha)
% Angstrom_exponent_b2      - the Angtstrom exponent at band 2 (alpha)
% Pressure                  - the surface level pressure (hPa)
% Relative_humidity         - the relative humidity at surface
% Precipitable_water        - the precipitable water column (cm)
% Ozone                     - the column ozone amount (atm-cm)
% Nitrogen Dioxide          - the column nitrogen amount (atm-cm)
% Ground_albedo             - the ground albedo for X km radius
% AOD_broadband             - the aerosol optical depth for broadband irad.
% AOD_b1                    - the aerosol optical depth for band 1
% AOD_b2                    - the aerosol optical depth for band 2
% lambda_b1                 - the corresponding wavelength of AOD_b1 (nm)
% lambda_b2                 - the corresponding wavelength of AOD_b2 (nm)
%
% Each variable comes with a X_confidence matrix which indicates which
% values are derived, and which are raw data.
%
% ========================================================================
%% Preamble
% Add the directory with all supporting scripts
clearvars
root_dir=pwd;
addpath([root_dir,filesep,'support_scripts'])
addpath([root_dir,filesep,'nctoolbox-master'])
setup_nctoolbox

%% Define the directories
% specify the drive
store.data_drive_root=root_dir(1:2);
% All stores must close with a filesep
% MODIS store must be a dir that contains MOD08_D3 and MYD08_D3 dirs.
store.MODIS_store=[store.data_drive_root,filesep];
% AURA store is the dir that contains the OMI_Aura_L3-OMNO2d*.he5 files.
store.AURA_store=[store.data_drive_root,filesep,'AURA',filesep];
% NCEP store must be the dir that contains sub-dirs of pres, tamb etc.
store.NCEP_store=[store.data_drive_root,filesep,'reanalysis_data',filesep];
% The output directory is where the data will be saved where each variable
% will have its own directory
store.raw_outputs_store=[store.data_drive_root,filesep,'dynamic_data_summaries',filesep];
init_directory(store.raw_outputs_store);

%% Extraction variables
% each variable will have a slightly unique extraction and conversion
% technique. These variable names will be called upon within the main
% function using a switch(variables) and so this naming convention should
% not be modified away from 'pressure','relative_humidity', 'temperature',
% 'aerosol_optical_depth','ozone','nitrogen_dioxide', 'precipitable_water'.
in_variables={'pressure','relative_humidity','temperature','aerosol_optical_depth','ozone','nitrogen_dioxide','precipitable_water','ground_albedo'};
% OMI, NCEP, MODIS
num_of_data_sources=3;
MODIS_vars={'aerosol_optical_depth','ozone','precipitable_water'};
NCEP_vars={'pressure','temperature','ozone','precipitable_water','relative_humidity'};
OMI_vars={'ozone','nitrogen_dioxide'};

%% Output variables
out_variables={'pressure','relative_humidity','temperature','angstrom_turbidity_b1','angstrom_turbidity_b2','angstrom_exponent_b1','angstrom_exponent_b2','ozone','nitrogen_dioxide','precipitable_water'};%,'AOD_broadband','AOD_b1','AOD_b2','lambda_b1','lambda_b2','ground_albedo'};
% initialise an output directory for each of the raw variables.
for v=1:length(out_variables)
    directory=[store.raw_outputs_store,filesep,out_variables{v},filesep];
    init_directory(directory);
end
MODIS_prefix='MODIS';
NCEP_prefix='NCEP';
OMI_prefix='OMI';

%% Set time requirements
% A fundamental component to the main function is the year that is
% required. The output format of each of the listed output variables is a
% 3D matrix of longitude*latitude*time for a whole year.
years=2002:2018;

%% Specify the overwrite flag
% The yearly variable files will be overwritten if the flag is set to true,
% should the flag be false, the tool will skip this year and variable, with
% the exception of the current year, whereby new data will be checked for.
overwrite_flag=false;
current_year=year(now);

%% Trigger the main part of the function
% This function loops through each of the raw data from the satellite and
% NWP sources and extracts the usable data that we require.
% The raw data will then enter a processing stage?

for y = 1:length(years)
    
    % run the calibration for this year. This will check for existing files
    % and return process flag indicating whether or not some raw data
    % should be processed. The binary outputs correspond to the *_vars
    % variable that lists the type of data needed
    [MODIS_raw_process,NCEP_raw_process,OMI_raw_process]=ProcessRawDataCalibration(overwrite_flag,current_year,years(y),MODIS_vars,NCEP_vars,OMI_vars,store,MODIS_prefix,NCEP_prefix,OMI_prefix);
    
    %% MODIS extraction
    % MODIS files store a large amount of variables per file, this differes
    % from NCEP where each variable has its own file. This means that the
    % variables must all be extracted in a single loading of the files.
    for var=1:length(MODIS_vars)
        % if the flag says this variable must be processed, then process.
        if MODIS_raw_process(var)==1
            disp(['Processing ',MODIS_vars{var}]),
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
                    
                    angstrom_exponent_b1=zeros(180,360,length(time_datenum_daily)).*NaN;
                    angstrom_exponent_b2=zeros(180,360,length(time_datenum_daily)).*NaN;
                    angstrom_turbidity_b1=zeros(180,360,length(time_datenum_daily)).*NaN;
                    angstrom_turbidity_b2=zeros(180,360,length(time_datenum_daily)).*NaN;
                    units={'','','',''};
                    c_lower=[0 0 0 0];
                    c_upper=[2.5 2.5 1.1 1.1];                        
                    % set the save string
                    save_str={'angstrom_exponent_b1','angstrom_exponent_b2','angstrom_turbidity_b1','angstrom_turbidity_b2'};
                    
                case 'ozone'
                    MODIS_datafields={'Total_Ozone_Mean'};
                    ozone=zeros(180,360,length(time_datenum_daily)).*NaN;
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
                disp(datestr(time_datenum_daily(d)))
                % make a a string of the current day
                datestr_yyyymmdd=datestr(time_datenum_daily(d),'yyyymmdd');
                
                % extract the data from MODIS using the date and the datafields
                [data,latitudes_HDF,longitudes_HDF,~,~]=loadHDFEOS(datestr_yyyymmdd,MODIS_datafields,store.MODIS_store);
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
                            [a_b1,a_b2,b_b1,b_b2]=PostProcessingOfModisAOD(data,latitudes_HDF,longitudes_HDF,land_mask);
                            angstrom_exponent_b1(:,:,d)=a_b1;
                            angstrom_exponent_b2(:,:,d)=a_b2;
                            angstrom_turbidity_b1(:,:,d)=b_b1;
                            angstrom_turbidity_b2(:,:,d)=b_b2;
                            
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
                            
                        end
                        
                end
                
                
            end
            
            
            
            % Save the data to file
            for s=1:length(save_str)
                filename=GetFilename(store,save_str{s},years(y),MODIS_prefix);
                save(filename,save_str{s});
                
                % Make a gif of a single year
                gif_file = [store.raw_outputs_store,save_str{s},filesep,'MODIS_',save_str{s},'_',num2str(years(y)),'.gif'];
                SaveMapToGIF(gif_file,eval(save_str{s}),latitudes_HDF,longitudes_HDF,save_str{s},units{s},time_datenum_daily,c_upper(s),c_lower(s))
                
            end
            % clear the excess data for memory conservation
            clear data ozone angstrom_exponent_b1 angstrom_exponent_b2 angstrom_turbidity_b1 angstrom_turbidity_b2 precipitable_water precipitable_water_all precipitable_water_gap_filled
        end
    end
    
    %% NCEP extraction
    for vars=1:length(NCEP_vars)
        
        %load NCEP var
        %save NCEP var
        %clear NCEP var
    end
    
    %% OMI extraction
    %load OMI
    %save OMI
    %clear OMI
    
    
    
    
    %% Save the data file
    %     for s=1:length(out_variables)
    %         filename=[store.raw_outputs_store,filesep,out_variables{s},filesep,out_variables{s},'_',num2str(years(y)),'.mat'];
    %
    %         save(filename,out_variables{s});
    %     end
    %
end






















