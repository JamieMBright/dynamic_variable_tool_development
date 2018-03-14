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
store.data_drive_root='F:';
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
MODIS_vars={'aerosol_optical_depth','ozone'};
NCEP_vars={'pressure','temperature','ozone','precipitable_water','relative_humidity'};
OMI_vars={'ozone','nitrogen_dioxide'};

%% Output variables
out_variables={'pressure','relative_humidity','temperature','angstrom_turbidity_b1','angstrom_turbidity_b2','angstrom_exponent_b1','angstrom_turbidity_b2','AOD_broadband','AOD_b1','AOD_b2','lambda_b1','lambda_b2','ozone','nitrogen_dioxide','precipitable_water','ground_albedo'};
% initialise an output directory for each of the raw variables.
for v=1:length(out_variables)
    directory=[store.raw_outputs_store,filesep,out_variables{v},filesep];
    init_directory(directory);
end

%% Set time requirements
% A fundamental component to the main function is the year that is
% required. The output format of each of the listed output variables is a
% 3D matrix of longitude*latitude*time for a whole year.
years=2002:2018;

%% Specify the overwrite flag
% The yearly variable files will be overwritten if the flag is set to true,
% should the flag be false, the tool will skip this year and variable, with
% the exception of the current year, whereby new data will be checked for.
overwrite_flag=true;
current_year=year(now);

%% Trigger the main part of the function
% This function loops through each of the raw data from the satellite and
% NWP sources and extracts the usable data that we require.
% The raw data will then enter a processing stage?

for y = 1:length(years)
    
    % run the calibration
    [MODIS_raw_process,NCEP_raw_process,OMI_raw_process]=ProcessRawDataCalibration(overwrite_flag,current_year,years(y),MODIS_vars,NCEP_vars,OMI_vars,store);
    
    raw_year_MODIS=dataExtractionMODIS()
    
    
    
    raw_year_NCEP=dataExtractionNCEP()
    raw_year_OMI=dataExtractionOMI()
    
    
    
    
    
    
    
    
    for v=1:length(out_variables)
        switch out_variables{v}
            
            %out_variables={'pressure','relative_humidity','temperature','angstrom_turbidity_b1','angstrom_turbidity_b2','angstrom_exponent_b1','angstrom_turbidity_b2','AOD_broadband','AOD_b1','AOD_b2','lambda_b1','lambda_b2','ozone','nitrogen_dioxide','precipitable_water','ground_albedo'};
            
            case 'pressure'
                %NCEP
                pressure=1;
            case 'relative_humidity'
                %NCEP
                relative_humidity=1;
            case 'temperature'
                %NCEP
                temperature=1;
            case 'aerosol_optical_depth'
                %MODIS
                angstrom_turbidity_b1=1;
                angstrom_turbidity_b2=1;
                angstrom_exponent_b1=1;
                angstrom_exponent_b2=1;
                AOD_broadband=1;
                AOD_b1=1;
                AOD_b2=1;
                lambda_b1=1;
                lambda_b2=1;
            case 'ozone'
                %OMI, MODIS, NCEP
                ozone=1;
            case 'nitrogen_dioxide'
                %OMI
                nitrogen_dioxide=1;
            case 'precipitable_water'
                %NCEP, MODIS
                precipitable_water=1;
            case 'ground_albedo'
                ground_albedo=0.3;
                
        end
        
    end
    
    
    %% Save the data file
    for s=1:length(out_variables)
        filename=[store.raw_outputs_store,filesep,out_variables{s},filesep,out_variables{s},'_',num2str(years(y)),'.mat'];
        
        save(filename,out_variables{s});
    end
    
end






















