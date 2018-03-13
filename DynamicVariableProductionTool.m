% Dynamic Variable Production Wrapper
%
% ========================================================================
%                               Information 
% ========================================================================
% Started: 13/03/2018
% Author: Dr Jamie M. Bright
%
% ========================================================================
%                          Raw variables for REST2 
% ========================================================================
%
%  +---------------------------------------------------------------------+
%  | Variable        Source              Conversion      Validation      |
%  +---------------------------------------------------------------------+
%  | Pressure        NCEP                Y               BSRN            |
%  | Temperature     NCEP                Y               BSRN            |
%  | AOD             MODIS               Y(Complex)      AERONET         |
%  | Ozone           MODIS, NCEP, OMI    Y               AERONET         |
%  | Nitrgen di.     OMI                 Y               x               |
%  | Precip. Water   MODIS, NCEP         Y               AERONET/BSRN    |
%  +---------------------------------------------------------------------+
%
%
% ========================================================================
%                               Output data sets 
% ========================================================================
% Angstrom_turbidity_b1    - the Angstrom Turbidity at band 1(beta)
% Angstrom_turbidity_b2    - the Angstrom Turbidity at band 2(beta)
% Angstrom_exponent_b1     - the Angtstrom exponent at band 1 (alpha)
% Angstrom_exponent_b2     - the Angtstrom exponent at band 2 (alpha)
% Pressure              - the surface level pressure (hPa or mb)
% Precipitable_water    - the precipitable water column (cm)
% Ozone                 - the column ozone amount (atm-cm)
% Nitrogen Dioxide      - the column nitrogen amount (atm-cm)
% Aerosol_single_scattering_albedo - the aerosol single scattering albedo
% Ground_albedo         - the ground albedo
% AOD_b1                - the aerosol optical depth for band 1
% AOD_b2                - the aerosol optical depth for band 2
% lambda_b1             - the corresponding wavelength of AOD_b1 (microns)
% lambda_b2             - the corresponding wavelength of AOD_b2 (microns)
%
% Each variable comes with a X_confidence matrix which indicates which
% values are derived, and which are raw data.
%
% ========================================================================

% Add the directory with all supporting scripts
addpath([pwd,'/support_scripts'])















 