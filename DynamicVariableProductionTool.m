% Dynamic Variable Production Wrapper
%
% ========================================================================
%                               Author Information
% ========================================================================
% Started: 13/03/2018
% Author: Dr Jamie M. Bright
%
% Affiliation: The Australian National University, Fenner School.
%
% License: 
% Copyright 2018 Dr. Jamie M. Bright
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Prefered Citation: Bright, J.M. et al. 2018. Global clear-sky irradiance
% model validation using dynamic variables from NCEP, MODIS and OMI.
% Solar Energy. xx pp xxx-xxx.

% ========================================================================
%                            Description
% ========================================================================
% This tool shows how to collate the data from MERRA2 and OMI in order to
% extract appropriate variables for clear-sky irradiance performance.

%
%
% ========================================================================
%                 Raw variables from satellite and NWP
% ========================================================================
%
%  +---------------------------------------------------------------------+
%  | Variable        Source              Conversion      Validation      |
%  +---------------------------------------------------------------------+
%  | Pressure        MERRA2              Y               BSRN            |
%  | Rel. Humidity   MERRA2              N               BSRN            |
%  | Temperature     MERRA2              N               BSRN            |
%  | AOD             MERRA2              Y               AERONET         |
%  | Angstrom alpha  MERRA2              Y               AERONET         |
%  | Aerosol extinc. MERRA2              Y               AERONET         |
%  | Ozone           MERRA2              Y               AERONET         |
%  | Nitrgen di.     OMI                 Y               x               |
%  | Precip. Water   MERRA2              Y               AERONET/BSRN    |
%  +---------------------------------------------------------------------+
%
%
% ========================================================================
%                          Where to download?
% ========================================================================
%                                 MERRA2
% The latest update brings usability for the MERRA2. The MERRA2 data can be
% programatically downloaded using the cygwin terminal and wget.
% irstly, however, the user must register with the NNASA GES DISC at 
% https://disc.gsfc.nasa.gov/data-access 
% to obtain permissions to download the data and then approve the use of 
% the GESDISC DATA ARCHIVE in your accoutn settings.
% Once the account has been set up, a proprietry step is to create a
% cookies and permissions file entering the following into the Cygwin
% terminal and replacing USERNAME and PASSWORD with your details:
%    cd ~
%    touch .netrc
%    echo "machine urs.earthdata.nasa.gov login USERNAME password PASSWORD" >> .netrc
%    chmod 0600 .netrc
%    touch .urs_cookies
%
% After this, the following commands will download the data for Albedo,
% total column ozone, temperature, pressure, precipitable water, angstrom
% parameter, total aerosol optical depth (AOT), and total aerosol
% extinction. Note that there are many more variables contained within
% these files and it would be a simple case of adding additional var names
% to extract them
% The following lines of code will download the three repsoitories required

% wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies -r --level=2 -c -nH -nd -np -P <LOCAL FILE PATH> --accept *.nc4 --no-host-directories --cut-dirs=2 "https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2/<REPOSITORY>.5.12.4/<YEAR>/"
% where <LOCAL FILE PATH> is the file path on your machine (care for OS
% slash requirements). <REPOSITORY> is the repo name for the files that you
% want to download, for this script, we use M2I1NXASM, M2T1NXRAD & M2T1NXAER 
% <YEAR> is the year of download. For the paper, we only used 2015, 2016
% and 2017. This is because the stored data is significantly memory 
% intensive as there are multiple variables per file, and hourly
% resolution.
% 
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

% Angstrom_exponent         - the Angtstrom exponent, alpha (470-870nm) 
% AOD at 550nm              - the Aerosol Optical Depth (dimensionless)
% aerosol_scattering 550nm  - the Aerosol Scattering (dimensionless)
% Pressure                  - the surface level pressure (hPa)
% Relative_humidity         - the relative humidity at surface (%)
% Precipitable_water        - the precipitable water column (cm)
% Ozone                     - the column ozone amount (atm-cm)
% Nitrogen Dioxide          - the column nitrogen amount (atm-cm)
% Albedo                    - the surface albedo (frac.)
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
years=2015:2017;

%% Specify the overwrite flag
% The yearly variable files will be overwritten if the flag is set to true,
% should the flag be false, the tool will skip this year and variable, with
% the exception of the current year, whereby new data will be checked for.
overwrite_flag='true';%input('Overwrite? (true/false): ');
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
% AURA store is the dir that contains the OMI_Aura_L3-OMNO2d*.he5 files.
store.AURA_store=[store.data_drive_root,filesep,'AURA',filesep];
% MERRA2 store must be the dir that contains sub-dirs of M2I1NXASM, M2T1NXRAD & M2T1NXAER
store.MERRA2_store=[store.data_drive_root,filesep,'MERRA2',filesep];
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
OMI_vars={'nitrogen_dioxide'};
MERRA2_vars={'albedo','aerosol_optical_depth','ozone','precipitable_water','pressure','temperature_2m','relative_humidity','angstrom_exponent','aerosol_scattering'};

%% Output variables
out_variables={'nitrogen_dioxide','albedo','aerosol_optical_depth','ozone','precipitable_water','pressure','temperature_2m','precipitable_water','relative_humidity','ozone','angstrom_exponent','aerosol_scattering'};
% initialise an output directory for each of the raw variables.
for v=1:length(out_variables)
    directory=[store.raw_outputs_store,filesep,out_variables{v},filesep];
    init_directory(directory);
end
OMI_prefix='OMI';
MERRA2_prefix='MERRA2';

%% Trigger the main part of the function
% This function loops through each of the raw data from the satellite and
% NWP sources and extracts the usable data that we require.
% The raw data will then enter a processing stage?

for y = 1:length(years)
    
    %% Test to see whether this needs to be performed
    % run the calibration for this year. This will check for existing files
    % and return process flag indicating whether or not some raw data
    % should be processed. The binary outputs correspond to the *_vars
    % variable that lists the type of data needed
    [MERRA2_raw_process,OMI_raw_process] = ProcessRawDataCalibration(overwrite_flag,current_year,years,MERRA2_vars,OMI_vars,store,MERRA2_prefix,OMI_prefix);

    %% MERRA2 extraction
    % MERRA2 is stored as a single file per day. It is also of high spatial
    % and temporal resolution. The MERRA2 is saved as its native
    % resolution both spatially and temporally.
    MERRA2extraction(MERRA2_vars,MERRA2_raw_process,MERRA2_prefix,years,y,store)
    
    %% OMI extraction
    % OMI is stored as a single file per year. The OMI is saved into its
    % native resolution and will have an additional reference latitude and
    % longitude with which to be able to use the OMI
    OMIextraction(OMI_vars,OMI_raw_process,OMI_prefix,years,y,store)
    
end

