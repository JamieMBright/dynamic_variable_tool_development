% Help to open the OMI type data was found at
% https://disc.gsfc.nasa.gov/datasets/OMSO2G_V003/summary
% https://acdisc.gsfc.nasa.gov/data/Aura_OMI_Level3/OMDOAO3e.003/2004/OMI-Aura_L3-OMDOAO3e_2004m1001_v003-2011m1109t084506.he5


% Vars from OMI (1) ozone (2)nitrogen
% set upper bands
c_upper=[0.6 0.03];
c_lower=[0 0];
% lats and lons
lats=flip(-90+0.25/2:0.25:90-0.25/2);
lons=-180+0.25/2:0.25:180-0.25/2;
[lon,lat]=meshgrid(lons,lats);
            
%set file names
file_prefixes={'OMI-Aura_L3-OMDOAO3e_','OMI-Aura_L3-OMNO2d_'};

data_field_extraction={'/HDFEOS/GRIDS/ColumnAmountO3/Data Fields/ColumnAmountO3','/HDFEOS/GRIDS/ColumnAmountNO2/Data Fields/ColumnAmountNO2'};

% loop through each variable required from OMI
for var=1:length(OMI_vars)
    % check to see whether this process needs to be performed
    if OMI_raw_process(var)==1
        %set the time logic in datenums and datevecs. It is a single
        %time per day for the whole year
        time_datenum_daily=datenum(num2str(years(y)),'yyyy'):datenum(num2str(years(y)+1),'yyyy')-1;
        time_dayvecs=datevec(time_datenum_daily);
        
        %make blank array for whole year
        OMI_data=zeros(720,1440,365).*NaN;
        OMI_confidence=int8(zeros(size(OMI_data)));
        
        %loop through each day of the year
        for d=1:length(time_datenum_daily)
            % report to console the current year
            disp(datestr(time_datenum_daily(d),'dd-mm-yyyy'))            
            
            % extract the appropriate filename
            filename_search=[store.AURA_store,file_prefixes{var},datestr(time_datenum_daily(d),'yyyy'),'m',datestr(time_datenum_daily(d),'mm'),datestr(time_datenum_daily(d),'dd'),'*.he5'];
            filename=dir(filename_search);
            filename=[filename.name];
            filepath=[store.AURA_store,filename];
            
            try
            % get the file id
            fid=H5F.open(filepath,'H5F_ACC_RDONLY','H5P_DEFAULT');
            % Open the dataset.
            data_field_name=data_field_extraction{var};
            % get the data field id
            data_id=H5D.open(fid,data_field_name);
            % Read the dataset.
            data=H5D.read(data_id,'H5T_NATIVE_DOUBLE','H5S_ALL','H5S_ALL','H5P_DEFAULT');
            % Read the Title.
            title_attribute='Title';
            title_attribute_id=H5A.open_name(data_id,title_attribute);
            long_name=H5A.read(title_attribute_id,'H5ML_DEFAULT');
            % Read the units.
            units_attribute= 'Units';
            units_attribute_id=H5A.open_name(data_id,units_attribute);
            units=H5A.read(units_attribute_id,'H5ML_DEFAULT');
            % Read the offset.
            offset_attribute= 'Offset';
            offset_attribute_id=H5A.open_name(data_id,offset_attribute);
            offset = H5A.read(offset_attribute_id, 'H5ML_DEFAULT');
            % Read the scale.
            scale_attribute='ScaleFactor';
            scale_attribute_id=H5A.open_name(data_id,scale_attribute);
            scale=H5A.read(scale_attribute_id, 'H5ML_DEFAULT');
            % Read the fillvalue.
            fill_attribute= '_FillValue';
            fill_attribute_id=H5A.open_name(data_id,fill_attribute);
            fill_value=H5A.read(fill_attribute_id,'H5T_NATIVE_DOUBLE');
            % Read the missingvalue.
            missing_attribute='MissingValue';
            missing_attribute_id=H5A.open_name(data_id,missing_attribute);
            missingvalue=H5A.read(missing_attribute_id,'H5T_NATIVE_DOUBLE');
            % Close and release resources.
            H5A.close (title_attribute_id)
            H5D.close (data_id);
            H5F.close (fid);
            % Replace the fill value with NaN
            data(data==fill_value) = NaN;
            % Apply scale and offset, the equation is scale *(data-offset).
            data = scale*(data-offset);
            % convert to double
            data=double(data);
            
            % convert to DU,
            % The Dobson Unit is the most common unit for measuring ozone concentration.
            % One Dobson Unit is the number of molecules of ozone that would be required
            % to create a layer of pure ozone 0.01 millimeters thick at a temperature of
            % 0 degrees Celsius and a pressure of 1 atmosphere (the air pressure at the
            % surface of the Earth). Expressed another way, a column of air with an ozone
            % concentration of 1 Dobson Unit would contain about 2.69x1016ozone molecules
            % for every square centimeter of area at the base of the column. Over the Earth’s
            % surface, the ozone layer’s average thickness is about 300 Dobson Units or a
            % layer that is 3 millimeters thick. https://ozonewatch.gsfc.nasa.gov/facts/dobson.html
            
            switch OMI_vars{var}
                case 'ozone'
                    data=data./1000; %DU to cm
                    units='atm-cm';
                case 'nitrogen_dioxide'
                    data=data./2.69E16; %mol.cm-2 to DU
                    data=data./1000; %DU to cm
                    units='atm-cm';
            end
            
            % rotate the data
            data=flip(data');
            
            % fill gaps
            % build a land_mask of the same dimensions of the NO2 data
            if ~exist('land_mask','var')
                try % this will fail if loadHDFEOS fails, however will not be attempted upon first successful completion.
                    LAT=reshape(lat,numel(lat),1);
                    LON=reshape(lon,numel(lon),1);
                    land_mask=reshape(landmask(LAT,LON),[length(lats),length(lons)]);
                catch err
                end
            end
            
            data_confidence=zeros(size(data));
            data_confidence(~isnan(data))=1;
            data=REST2FillMissing(land_mask,lons,lats,data);
            
            % apply REST2 limmitations of 0<u_n<0.03 atm-cm
            data(data<c_lower(var))=c_lower(var);
            data(data>c_upper(var))=c_upper(var);
            
            catch err%if thhe file doesn't exist or is corrupt, we cannot extract the data and so that day shall be filled with NaN values.
                % permit file open errors, as this indicates non existent
                % files or corrupt ones, neither can be managed. Other
                % errors should be logged.
                if strcmp(err.identifier,'MATLAB:imagesci:hdf5lib:fileOpenErr')
                    data=zeros(720,1440).*NaN;
                else                    
                    getReport(err,'extended')
                end
            end
            
            %populate the main struct with this data
            OMI_data(:,:,d)=data;
            OMI_confidence(:,:,d)=data_confidence;
            
        end
        
        % save the data
        filename=GetFilename(store,OMI_vars{var},years(y),OMI_prefix);
        save(filename,'OMI_data','-v7.3');
        % save the confidence
        filename=GetFilename(store,OMI_vars{var},years(y),OMI_prefix,true);
        save(filename,'OMI_confidence','-v7.3');
        clear OMI_confidence
        
        % Make a gif of a single year
        gif_file = [store.raw_outputs_store,OMI_vars{var},filesep,OMI_prefix,'_',OMI_vars{var},'_',num2str(years(y)),'.gif'];
        if strcmp(OMI_vars{var},'nitrogen_dioxide')
            SaveMapToGIF(gif_file,OMI_data,lats,lons,OMI_vars{var},units,time_datenum_daily,0.001,c_lower(var))
        else
            SaveMapToGIF(gif_file,OMI_data,lats,lons,OMI_vars{var},units,time_datenum_daily,c_upper(var),c_lower(var))
        end
        % clear unwanted data for space save
        clear OMI_data land_mask data
    end
end