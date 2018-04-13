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
%  | Rel. Humidity   NCEP                N               BSRN            |
%  | Temperature     NCEP                N               BSRN            |
%  | AOD             MODIS               Y(Complex)      AERONET         |
%  | Ozone           MODIS, OMI          Y               AERONET         |
%  | Nitrgen di.     OMI                 Y               x               |
%  | Precip. Water   MODIS, NCEP         Y               AERONET/BSRN    |
%  +---------------------------------------------------------------------+
%
%
% ========================================================================
%                          Where to download?
% ========================================================================
%                                 MODIS
% MODIS Aqua and Terra images can be obtaind from the ladsweb ftp and http
% server. A programatic approach is to use the DownloadWithWget.m function
% provided in the utility functions.
%   WEBSITE:
% https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MOD08_D3/
% https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MYD08_D3/
%   URL STRUCTURE:
% https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MOD08_D3/...
%                        2018/001/MOD08_D3.A2018001.006.2018002085456.hdf
% This is difficult to programatically download due to the
% non-predictability of the url end. An FTP connection is ideal. This tool
% assumes the native file structure of the MOD08_D3 and MYD08_D3 setup.
%
%                                 NCEP
% NCEP has the simplest file structure and the download capability is
% provided programatically within this tool. Firstly, however, cygwin must
% be installed and activating the web wget options on install and then
% adding wget to the system environments. The instructions for this are
% more detailed within the DownloadWithWget.m comments. The NCEP reanalysis
% data is found at an ftp server by NOAA:
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/pres.sfc.2017.nc
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface_gauss/air.2m.gauss.1948.nc
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/pr_wtr.eatm.1948.nc
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/rhum.sig995.1948.nc
% The function DownloadAllReanalysisData.m is provided and encouraged to be
% used as it defines the directory structure on the local machine using the
% store variable to locate it. This requires the aforementioned wget
% requisite.
% The NCEP variables must be within the store varaible defined directory
% and placed inside the appropriate directories called "precipitable_water"
% "pressure", "relative_humidity" and "temperature_2m". The files must be
% called "pwat-yyyy.nc", "rh3-yyyy.nc", "pres.sfc.yyyy.nc" and
% "tamb-yyyy.nc" respectively for each should the
% DownloadAllReanalysisData.m script not be utilised.
% This can be modified, however, would require some debugging.
%
%                                  OMI
% The OMI data can be programatically downloaded using the cygwin and wget
% operability as mentioned before. Firstly, however, the user must register
% with the NNASA GES DISC https://disc.gsfc.nasa.gov/data-access to obtain
% permissions to download the data and then approve the use of the GESDISC
% DATA ARCHIVE in your accoutn settings.
% Once the account has been set up, a proprietry step is to create a
% cookies and permissions file entering the following into the Cygwin
% terminal and replacing USERNAME and PASSWORD with your details:
%    cd ~
%    touch .netrc
%    echo "machine urs.earthdata.nasa.gov login USERNAME password PASSWORD" >> .netrc
%    chmod 0600 .netrc
%    touch .urs_cookies
% After this, the following commands will download all the appropriate
% files to the same directory for NO2 and O3:
%
%    wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies
%      --keep-session-cookies -r --level=2 -c -nH -nd -np -P F:/AURA/  ...
%      --accept *.he5 --no-host-directories --cut-dirs=2   ...
%      "https://acdisc.gesdisc.eosdis.nasa.gov/data/Aura_OMI_Level3/OMNO2d.003/"

%    wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies
%      --keep-session-cookies -r --level=2 -c -nH -nd -np -P F:/AURA/  ...
%      --accept *.he5 --no-host-directories --cut-dirs=2   ...
%      "https://acdisc.gsfc.nasa.gov/data/Aura_OMI_Level3/OMDOAO3e.003/"
%
% Where F:/AURA/ is the location the same as set in the store variable. The
% file structure locally is all located inside the same directory, the
% above commands will satisfy this and place them all in F:/AURA/.
% This is not programatically called within the code, and so is a
% prepriotroy step before this extraction can be performed.
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
%
%                Potential to include these?
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

%% Set time requirements
% A fundamental component to the main function is the year that is
% required. The output format of each of the listed output variables is a
% 3D matrix of longitude*latitude*time for a whole year.
% years=2002:2018;
y1=input('Start year: ');
y2=input('End years: ');
years=y1:y2;

%% Specify the overwrite flag
% The yearly variable files will be overwritten if the flag is set to true,
% should the flag be false, the tool will skip this year and variable, with
% the exception of the current year, whereby new data will be checked for.
overwrite_flag=input('Overwrite? (true/false): ');
current_year=year(now);

%% Setup the jave based netcdf toolbox
% NOTE: this is not the author's work, see the documentation in
% nctoolbox-master for more information:
% Copyright 2013 B.Schlining, A.Crosby, R.Signell
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
% OMI, NCEP, MODIS
MODIS_vars={'aerosol_optical_depth','ozone','precipitable_water'};
NCEP_vars={'pressure','temperature_2m','precipitable_water','relative_humidity'};
OMI_vars={'ozone','nitrogen_dioxide'};
blended_vars={'ozone','precipitable_water'};
blended_weight=[0.75,0.25;0.6,0.4];

%% Output variables
out_variables={'pressure','relative_humidity','temperature_2m','angstrom_turbidity_b1','angstrom_turbidity_b2','angstrom_exponent_b1','angstrom_exponent_b2','AOD700','ozone','nitrogen_dioxide','precipitable_water'};%,'AOD_broadband','AOD_b1','AOD_b2','lambda_b1','lambda_b2','ground_albedo'};
% initialise an output directory for each of the raw variables.
for v=1:length(out_variables)
    directory=[store.raw_outputs_store,filesep,out_variables{v},filesep];
    init_directory(directory);
end
MODIS_prefix='MODIS';
NCEP_prefix='NCEP';
OMI_prefix='OMI';
blended_prefix='blended';


%% Trigger the main part of the function
% This function loops through each of the raw data from the satellite and
% NWP sources and extracts the usable data that we require.
% The raw data will then enter a processing stage?

for y = 1:length(years)
    
    % run the calibration for this year. This will check for existing files
    % and return process flag indicating whether or not some raw data
    % should be processed. The binary outputs correspond to the *_vars
    % variable that lists the type of data needed
    [MODIS_raw_process,NCEP_raw_process,OMI_raw_process,blended_raw_process]=ProcessRawDataCalibration(overwrite_flag,current_year,years(y),MODIS_vars,NCEP_vars,OMI_vars,blended_vars,store,MODIS_prefix,NCEP_prefix,OMI_prefix,blended_prefix);
    
    %% MODIS extraction
    % MODIS files store a large amount of variables per file, this differes
    % from NCEP where each variable has its own file. This means that all
    % variables must all be extracted in a single loading of the files.
    MODISextraction(MODIS_vars,MODIS_raw_process,MODIS_prefix,years,y,store)
    
    %% NCEP extraction
    % NCEP is stored natively in a single year per file, however, it is not
    % in the appropriate structure, units, or resolution. Firstly, download
    % all the native files. Secondly, extract the data and reshape and
    % interpolate it. Lastly, convert the data to required units before
    % saving to disk.
    NCEPextraction(NCEP_vars,NCEP_raw_process,NCEP_prefix,years,y,store)
    
    %% OMI extraction
    % OMI is stored as a single file per year. It is also much finer
    % resolution then either NCEP or MODIS. The OMI is saved into its
    % native resolution and will have an additional reference latitude and
    % longitude with which to be able to use the OMI
    OMIextraction(OMI_vars,OMI_raw_process,OMI_prefix,years,y,store)
    
    %% Assimilate data of same variable from different sources
    % ozone and precipitable water have two different input sources. For
    % this reason, they will both be used to find a blended variable with
    % certain weigthings. The OMI is given more precedent than MODIS where
    % available due to superior spatial coverage, however, MODIS will be
    % interpolated to matching resolution and given a 25% weighting. A
    % similar principle is assigned to the precipitable water between NCEP
    % and MODIS. MODIS is allowed a 40% weighting due to its decent spatial
    % resolution in comparison to the NCEP, however, NCEP still gets a
    % dominant weighting due to its complexity and gap free spatial
    % coverage.
    if blended_raw_process(1)==1
        DataAssimilation(store,'ozone',years(y),OMI_prefix,MODIS_prefix,blended_prefix,0.75,0.25);
    end
    if blended_raw_process(2)==1
        DataAssimilation(store,'precipitable_water',years(y),NCEP_prefix,MODIS_prefix,blended_prefix,0.6,0.4);
    end
    
end

