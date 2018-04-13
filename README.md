# dynamic_variable_tool_development
This tool is a method to gather raw satellite and renalysis data and 
convert it into easy to use spatio-temporal variables with intended use 
in solar clear-sky irradiance modelling.

The dynamic production tool creates annual files of gridded data with 
at least 1 deg and 1 day spatio-temporal resolution.

The dynmaic variable extraction tool takes a given group of longitude and
latitude pairs and a time-series, then returns the data in a struct.

========================================================================
                              Information
========================================================================
Started: 13/03/2018
Author: Dr Jamie M. Bright

Affiliation: The Australian National University, Fenner School.

Licensing:
Copyright 2018 Dr Jamie M. Bright

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Prefered Citation: Bright, J.M. et al. 2018. Global clear-sky irradiance
model validation using dynamic variables from NCEP, MODIS and OMI.
Solar Energy. xx pp xxx-xxx.

========================================================================
                Raw variables from satellite and NWP
========================================================================

 +---------------------------------------------------------------------+
 | Variable        Source              Conversion      Validation      |
 +---------------------------------------------------------------------+
 | Pressure        NCEP                Y               BSRN            |
 | Rel. Humidity   NCEP                N               BSRN            |
 | Temperature     NCEP                N               BSRN            |
 | AOD             MODIS               Y(Complex)      AERONET         |
 | Ozone           MODIS, OMI          Y               AERONET         |
 | Nitrgen di.     OMI                 Y               x               |
 | Precip. Water   MODIS, NCEP         Y               AERONET/BSRN    |
 +---------------------------------------------------------------------+


========================================================================
                         Where to download?
========================================================================
                                MODIS
MODIS Aqua and Terra images can be obtaind from the ladsweb ftp and http
server. A programatic approach is to use the DownloadWithWget.m function
provided in the utility functions.
  WEBSITE:
https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MOD08_D3/
https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MYD08_D3/
  URL STRUCTURE:
https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/6/MOD08_D3/...
                       2018/001/MOD08_D3.A2018001.006.2018002085456.hdf
This is difficult to programatically download due to the
non-predictability of the url end. An FTP connection is ideal. This tool
assumes the native file structure of the MOD08_D3 and MYD08_D3 setup.

                                NCEP
NCEP has the simplest file structure and the download capability is
provided programatically within this tool. Firstly, however, cygwin must
be installed and activating the web wget options on install and then
adding wget to the system environments. The instructions for this are
more detailed within the DownloadWithWget.m comments. The NCEP reanalysis
data is found at an ftp server by NOAA:
ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/pres.sfc.2017.nc
ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface_gauss/air.2m.gauss.1948.nc
ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/pr_wtr.eatm.1948.nc
ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/rhum.sig995.1948.nc
The function DownloadAllReanalysisData.m is provided and encouraged to be
used as it defines the directory structure on the local machine using the
store variable to locate it. This requires the aforementioned wget
requisite.
The NCEP variables must be within the store varaible defined directory
and placed inside the appropriate directories called "precipitable_water"
"pressure", "relative_humidity" and "temperature_2m". The files must be
called "pwat-yyyy.nc", "rh3-yyyy.nc", "pres.sfc.yyyy.nc" and
"tamb-yyyy.nc" respectively for each should the
DownloadAllReanalysisData.m script not be utilised.
This can be modified, however, would require some debugging.

                                 OMI
The OMI data can be programatically downloaded using the cygwin and wget
operability as mentioned before. Firstly, however, the user must register
with the NNASA GES DISC https://disc.gsfc.nasa.gov/data-access to obtain
permissions to download the data and then approve the use of the GESDISC
DATA ARCHIVE in your accoutn settings.
Once the account has been set up, a proprietry step is to create a
cookies and permissions file entering the following into the Cygwin
terminal and replacing USERNAME and PASSWORD with your details:
   cd ~
   touch .netrc
   echo "machine urs.earthdata.nasa.gov login USERNAME password PASSWORD" >> .netrc
   chmod 0600 .netrc
   touch .urs_cookies
After this, the following commands will download all the appropriate
files to the same directory for NO2 and O3:

   wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies
     --keep-session-cookies -r --level=2 -c -nH -nd -np -P F:/AURA/  ...
     --accept *.he5 --no-host-directories --cut-dirs=2   ...
     "https://acdisc.gesdisc.eosdis.nasa.gov/data/Aura_OMI_Level3/OMNO2d.003/"

   wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies
     --keep-session-cookies -r --level=2 -c -nH -nd -np -P F:/AURA/  ...
     --accept *.he5 --no-host-directories --cut-dirs=2   ...
     "https://acdisc.gsfc.nasa.gov/data/Aura_OMI_Level3/OMDOAO3e.003/"

Where F:/AURA/ is the location the same as set in the store variable. The
file structure locally is all located inside the same directory, the
above commands will satisfy this and place them all in F:/AURA/.
This is not programatically called within the code, and so is a
prepriotroy step before this extraction can be performed.

========================================================================
                          Input user requirements
========================================================================
The user must define the directories of where all the raw data is stored.
Firstly by setting the drive root, and then by ensuring the pathing.
The user must also specify the years that will be produced.
The user must also specify an overwirte flag, a default assumption is
that only unique years will be produced, with exception of the current
year, the function will check for new data and then -append the new.

========================================================================
                          Output data sets
========================================================================
There are many clear-sky irradiance models that can be used. The
intention is to provide a dynamic variable for each of their inputs.

Angstrom_turbidity_b1     - the Angstrom Turbidity at band 1(beta)
Angstrom_turbidity_b2     - the Angstrom Turbidity at band 2(beta)
Angstrom_exponent_b1      - the Angtstrom exponent at band 1 (alpha)
Angstrom_exponent_b2      - the Angtstrom exponent at band 2 (alpha)
Pressure                  - the surface level pressure (hPa)
Relative_humidity         - the relative humidity at surface
Precipitable_water        - the precipitable water column (cm)
Ozone                     - the column ozone amount (atm-cm)
Nitrogen Dioxide          - the column nitrogen amount (atm-cm)
AOD700                    - the aeorosol optical depth at 700nm (dim.) 

Each variable comes with a X_confidence matrix which indicates which
values are spatially interpolated and which are derived from measurements.
Furthermore, each variable comes with a latitude, longitude and time 
indexing for easy use.

Each variable has a set of data, confidence, lat, lon, time for each year.

========================================================================
