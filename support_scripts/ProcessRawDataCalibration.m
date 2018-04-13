% Check the store to ascertain whether this year's variables already exist.
%
% The overwrite_flag specifies whether or not to overwrite the old data. If
% it is True, then return ones for all raw process flags. This will tell
% the main function to remake all the data, else if it is false, then a
% check is made to ensure all data exists. If the processed year is the
% same as the current year, then a value of 2 is returned so that a load
% and append can occur.
%
% Outputs:
% A list of flags for each variable for each raw data source (3).
% MODIS_raw_process has three variables for extraction, as specified by
% MODIS_vars. This function will return [0,1,0] if the first and thrid
% variables already exist, but the second variable does not for this year.
% A return of 2 occurs for an append mode. This is faster than re-making
% the whole of the current year, as it will make a check for new data.
%% MODIS
% Decision about whether to perform this year or not
function [MODIS_raw_process,NCEP_raw_process,OMI_raw_process,blended_raw_process]=ProcessRawDataCalibration(overwrite_flag,current_year,year,MODIS_vars,NCEP_vars,OMI_vars,blended_vars,store,MODIS_prefix,NCEP_prefix,OMI_prefix,blended_prefix)

% if an overwrite is not requested
if overwrite_flag==false
    %should this year be the year of analysis, then a process must occur
    if current_year==year
        MODIS_raw_process=ones(1,length(MODIS_vars)).*2;
        NCEP_raw_process=ones(1,length(NCEP_vars)).*2;
        OMI_raw_process=ones(1,length(OMI_vars)).*2;
        blended_raw_process=ones(1,length(blended_vars)).*2;
        
    else % else the year is in the past and so the store should be consulted to check for existance
        %% MODIS
        MODIS_raw_process=zeros(1,length(MODIS_vars));
        for i=1:length(MODIS_vars)
            
            if strcmp(MODIS_vars{i},'aerosol_optical_depth')
                AOD_vars={'angstrom_exponent_b1','angstrom_exponent_b2','angstrom_turbidity_b1','angstrom_turbidity_b2'};
                AOD_test=zeros(length(AOD_vars),1);
                for j=1:length(AOD_vars)
                    filename=GetFilename(store,AOD_vars{j},year,MODIS_prefix);
                    % check whether the file exists.
                    if ~exist(filename,'file')
                        %if the file doesnt exist, add a marker in the flag variable.
                        AOD_test(j)=1;
                    end
                    
                end
                
                if sum(AOD_test)==length(AOD_test)
                   MODIS_raw_process(i)=1; 
                end
                
            else
                filename=GetFilename(store,MODIS_vars{i},year,MODIS_prefix);
                % check whether the file exists.
                if ~exist(filename,'file')
                    %if the file doesnt exist, add a marker in the flag variable.
                    MODIS_raw_process(i)=1;
                end
            end
        end
        
        %% NCEP
        NCEP_raw_process=zeros(1,length(NCEP_vars));
        for i=1:length(NCEP_vars)
            filename=GetFilename(store,NCEP_vars{i},year,NCEP_prefix);
            % check whether the file exists.
            if ~exist(filename,'file')
                %if the file doesnt exist, add a marker in the flag variable.
                NCEP_raw_process(i)=1;
            end
        end
        
        %% OMI
        OMI_raw_process=zeros(1,length(OMI_vars));
        for i=1:length(OMI_vars)
            filename=GetFilename(store,OMI_vars{i},year,OMI_prefix);
            % check whether the file exists.
            if ~exist(filename,'file')
                %if the file doesnt exist, add a marker in the flag variable.
                OMI_raw_process(i)=1;
            end
        end
        
        %% Blended
        %there are only two variables being blended. Ozone and Precipitable Water
        blended_raw_process=zeros(1,length(blended_vars));
        for i=1:length(blended_vars)
            filename=GetFilename(store,blended_vars{i},year,blended_prefix);
            % check whether the file exists.
            if ~exist(filename,'file')
                %if the file doesnt exist, add a marker in the flag variable.
                blended_raw_process(i)=1;
            end
        end
        
    end
else
    MODIS_raw_process=ones(1,length(MODIS_vars));
    NCEP_raw_process=ones(1,length(NCEP_vars));
    OMI_raw_process=ones(1,length(OMI_vars));
    blended_raw_process=ones(1,length(OMI_vars));
end
end