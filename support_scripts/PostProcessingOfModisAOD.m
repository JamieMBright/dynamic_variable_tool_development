function [alpha_b1,alpha_b2,beta_b1,beta_b2]=PostProcessingOfModisAOD(data,latitudes_HDF,longitudes_HDF,land_mask)

% Angstrom Exponent (alpha)
% Gueymard 2008, Solar Energy 82 272-285, Table 1 states:
% Alpha for Band 1 from measurements between 415 and 674 nm
% Alpha for Band 2 from measurements between 673 and 870 nm
% alpha=log(AOD1./AOD2)./log(lambda2./lambda1);

% L. Remer, et al. 2008. Journal of Geophisical Research
% Atmospheres. 113 1-18
% alpha=-ln(AOD470/AOD660)/ln(470/660)
% should the minus be included?

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
alpha_b1=log(AOD470./AOD660)./log(660/470);
alpha_b2=log(AOD660./AOD870)./log(870/660);
% Limit the alpha values by the REST2 limitations
% reported as 0<alpha<2.5 (Gueymard, 2008)
alpha_b1(alpha_b1<0)=0;
alpha_b1(alpha_b1>2.5)=2.5;
alpha_b2(alpha_b2<0)=0;
alpha_b2(alpha_b2>2.5)=2.5;

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

% Fill the AOD and lambda bands with the most appropriate AODs
% BAND1 415 and 674 nm. First fill with available 550, 470, 660 and
% then 412 if still absent.
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

% Limit the alpha values by the REST2 limitations
% reported as 0<alpha<2.5 (Gueymard, 2008)
beta_b1(beta_b1<0)=0;
beta_b1(beta_b1>1.1)=1.1;
beta_b2(beta_b2<0)=0;
beta_b2(beta_b2>1.1)=1.1;


%         %% write these images to file
%         %make struct
%         REST2data.latitudes_HDF=latitudes_HDF;
%         REST2data.longitudes_HDF=longitudes_HDF;
%         REST2data.alpha_b1=alpha_b1;
%         REST2data.alpha_b2=alpha_b2;
%         REST2data.alpha_b1_confidence=alpha_b1_confidence;
%         REST2data.alpha_b2_confidence=alpha_b2_confidence;
%         REST2data.beta_b1=beta_b1;
%         REST2data.beta_b2=beta_b2;
%         REST2data.beta_b1_confidence=beta_b1_confidence;
%         REST2data.beta_b2_confidence=beta_b2_confidence;
%         REST2data.lambda_b1=lambda_b1;
%         REST2data.lambda_b2=lambda_b2;
%         REST2data.lambda_b1_confidence=lambda_b1_confidence;
%         REST2data.lambda_b2_confidence=lambda_b2_confidence;
%         REST2data.AOD_b1=AOD_b1;
%         REST2data.AOD_b2=AOD_b2;
%         REST2data.AOD_b1_confidence=AOD_b1_confidence;
%         REST2data.AOD_b2_confidence=AOD_b2_confidence;
%
%         save(preprocessed_day_filename,'-struct','data')
%
%

end
