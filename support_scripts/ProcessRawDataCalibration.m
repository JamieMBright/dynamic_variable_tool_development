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
% A list of flags for each variable for each raw data source.
% MERRA2_raw_process has three variables for extraction, as specified by
% MERRA2_vars. This function will return [0,1,0] if the first and thrid
% variables already exist, but the second variable does not for this year.
% A return of 2 occurs for an append mode. This is faster than re-making
% the whole of the current year, as it will make a check for new data.

% Decision about whether to perform this year or not
function [MERRA2_raw_process,OMI_raw_process]=ProcessRawDataCalibration(overwrite_flag,current_year,year,MERRA2_vars,OMI_vars,store,MERRA2_prefix,OMI_prefix)

% if an overwrite is not requested
if overwrite_flag==false
    %should this year be the year of analysis, then a process must occur
    if current_year==year
        MERRA2_raw_process=ones(1,length(MERRA2_vars)).*2;
        OMI_raw_process=ones(1,length(OMI_vars)).*2;
        
        
    else % else the year is in the past and so the store should be consulted to check for existance
        %% MERRA2
        MERRA2_raw_process=zeros(1,length(MERRA2_vars));
        for i=1:length(MERRA2_vars)
            filename=GetFilename(store,MERRA2_vars{i},year,MERRA2_prefix);
            % check whether the file exists.
            if ~exist(filename,'file')
                %if the file doesnt exist, add a marker in the flag variable.
                MERRA2_raw_process(i)=1;
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
        
    end
else
    MERRA2_raw_process=ones(1,length(MERRA2_vars));
    OMI_raw_process=ones(1,length(OMI_vars));
end
end