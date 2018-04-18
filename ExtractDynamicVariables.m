% Function to produce dynamic time series for a user defined latitude and
% longitude location for specified time range. The raw data is interpolated
% using a shape preserving piecewise cupic interpolation between the
% desired time_series input and the time indexing of the raw dynamic
% variables.
%
% ------------------------------------------------------------------------
%                              Inputs
% ------------------------------------------------------------------------
% latitude - single or many latitudes (90=N -90=S)
%
% longitude - single or many longitudes (0=London, -180=W 180=E)
%
% time_series - time series of required output same for all in datenum.
%
% extraction_variables - a cell array of strings of the varaible desired.
%                         default is all variables. The full list is below
%
% dynamic_variables_store - this is the file path of where the variables
%                    are all stored. If the DynamicVariableProductionTool
%                    was used, this should be 'F:\dynamic_data_summaries\';
%
% ------------------------------------------------------------------------
%                     Variables for extraction
% ------------------------------------------------------------------------
% Selected variables can be input, or leave blank to default to all
% e.g. selected_extraction_variables={'pressure','ozone'};
%
%  'angstrom_exponent_b1'
%  'angstrom_exponent_b2'
%  'angstrom_turbidity_b1'
%  'angstrom_turbidity_b2'
%  'nitrogen_dioxide'
%  'ozone'
%  'precipitable_water'
%  'pressure'
%  'relative_humidity'
%  'temperature_2m'
%
% ------------------------------------------------------------------------
%                           Example usage
% ------------------------------------------------------------------------
% latitudes=[-35.5151,65,0.04848];
% longitudes=[-70.545,5.3,140.07];
% % a 10-minute resolution time series from 01/01/2002 to 01/05/2004
% time_series=datenum('20020101','yyyymmdd'):1/144:datenum('20040501','yyyymmdd');
% dynamic_variables_store=['F:',filesep,'dynamic_data_summaries',filesep];
% % note that the extraction_variables will default to all if not entered
% % extraction_variables={'nitrogen_dioxide'};
% if exist('extraction_variables','var')
%     dynamic_variables_struct=ExtractDynamicVariables(latitudes,longitudes,time_series,dynamic_variables_store,extraction_variables);
% else
%     dynamic_variables_struct=ExtractDynamicVariables(latitudes,longitudes,time_series,dynamic_variables_store);
% end
%
%
%
%
%

function dynamic_variables_struct=ExtractDynamicVariables(latitudes,longitudes,time_series,dynamic_variables_store,extraction_variables)
% safety checks
list_of_variables={'angstrom_exponent_b1','angstrom_exponent_b2','angstrom_turbidity_b1','angstrom_turbidity_b2','nitrogen_dioxide','ozone','precipitable_water','pressure','relative_humidity','temperature_2m','AOD700'};
raw_data_source_prefixes={'MODIS','MODIS','MODIS','MODIS','OMI','blended','blended','NCEP','NCEP','NCEP','MODIS'};

if ~exist('extraction_variables','var')
    extraction_variables=list_of_variables;
elseif ~iscell(extraction_variables)
    error('Input extraction_variable must be a string within a cell, e.g. {''ozone''}')
end

if sum(strcmpi(list_of_variables,extraction_variables))~=length(extraction_variables)
    error('One or more inputs in extraction_variable are not compatible, check spelling.')
end

if length(latitudes)~=length(longitudes)
    error('There must be an equal number of latitudes and longitudes to form a location')
end

if max(longitudes)>180
    error('Longitudes must strictly adhere to -180W:180E format')
end

%ensure lats and lons are column vectors
latitudes=reshape(latitudes,[length(latitudes),1]);
longitudes=reshape(longitudes,[length(longitudes),1]);
time_series=reshape(time_series,[length(time_series),1]);


% set time logic
time_datevecs=datevec(time_series);
unique_years=unique(time_datevecs(:,1));

% create output arrays
for var=1:length(extraction_variables)
    eval(['dynamic_variables_struct.',extraction_variables{var},'=zeros(length(time_series),length(latitudes)).*NaN;']);
end


% each variable is a reasonably memory intensive and so cannot be processed
% in parallel. Must loop through each
for var=1:length(extraction_variables)
    % define the data file prefix
    prefix=raw_data_source_prefixes(strcmp(list_of_variables,extraction_variables{var}));
    
    % each variable has a single file per year and must also be looped.
    for y=1:length(unique_years)
        try
            
            % report progress to console
            disp(['Extracting ',extraction_variables{var},' data for ',num2str(unique_years(y))])
            
            % define the file names
            dat_filename=GetFilename(dynamic_variables_store,extraction_variables{var},unique_years(y),prefix{1});
            %         conf_filename=GetFilename(dynamic_variables_store,extraction_variables{var},unique_years(y),prefix{1},'confidence');
            time_filename=GetFilename(dynamic_variables_store,extraction_variables{var},unique_years(y),prefix{1},'times_datevec');
            lat_filename=GetFilename(dynamic_variables_store,extraction_variables{var},unique_years(y),prefix{1},'latitudes');
            lon_filename=GetFilename(dynamic_variables_store,extraction_variables{var},unique_years(y),prefix{1},'longitudes');
            
            % load the data. load will produce a struct, fieldnames will enable
            % the extraction of that variable
            datas=load(dat_filename);
            field=fieldnames(datas);
            data=eval(['datas.',field{1}]);
            %         confs=load(conf_filename);
            %         field=fieldnames(confs);
            %         conf=eval(['confs.',field]);
            times=load(time_filename);
            field=fieldnames(times);
            time=eval(['times.',field{1}]);
            time=datenum(time);
            time=reshape(time,[length(time),1]);
            latss=load(lat_filename);
            field=fieldnames(latss);
            lats=eval(['latss.',field{1}]);
            lonss=load(lon_filename);
            field=fieldnames(lonss);
            lons=eval(['lonss.',field{1}]);
            
            % find the appropriate time inds
            this_years_times=time_series(time_datevecs(:,1)==unique_years(y));
            
            % find the appropriate 2D location of the latitudes
            [LON,LAT]=meshgrid(lons,lats);
            LON=reshape(LON,[numel(LON),1]);
            LAT=reshape(LAT,[numel(LAT),1]);
            a=[LON,LAT];
            b=[longitudes,latitudes];
            [spatial_inds,~]=knnsearch(a,b);
            
            % extract the whole time series for these spatial inds.
            col=1:length(lons);
            row=1:length(lats);
            [COL,ROW]=meshgrid(col,row);
            col_ind=COL(spatial_inds);
            row_ind=ROW(spatial_inds);
            % it would be nice to vectorise this, but cannot think of a way to
            % index data using the spatial inds (which is a single value for a
            % 2D lookup) to reference entire time series.
            var_data=zeros(length(this_years_times),length(latitudes)).*NaN;
            for loc=1:length(latitudes)
                % perform an interpolation as well as the row,col,time ind
                % extraction.
                %supress NaN warnings by wrapping inside an evalc
                data_for_interp=squeeze(data(row_ind(loc),col_ind(loc),:));
                nan_inds=isnan(data_for_interp);
                nan_inds_interp=round(interp1(time,single(nan_inds),this_years_times,'pchip'));
                % there must be at least 2 datapoints to perform an interp
                if sum(nan_inds)+2<length(data_for_interp)
                    evalc('var_data(:,loc)=interp1(time,data_for_interp,this_years_times,''pchip'');');
                end
                var_data(nan_inds_interp==1,loc)=NaN;
            end
            
            % populate the output struct
            eval(['dynamic_variables_struct.',extraction_variables{var},'(find(time_datevecs(:,1)==unique_years(y)),:)=var_data;']);
            dynamic_variables_struct=dynamic_variables_struct;
            
        catch err
            getReport(err,'extended')
            
        end
    end
end

end

