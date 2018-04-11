function filled_data=REST2FillMissing(land_mask,longitudes_HDF,latitudes_HDF,data_main)

%initial check for gaps
if nansum(nansum(nansum(isnan(data_main))))>=1
    
    % update for 3D matrixes
    dimensions=length(size(data_main));
    if dimensions==3
        loops=size(data_main,3);
    else
        loops=1;
    end
    
    %pre allocate ouput
    filled_data=zeros(size(data_main)).*NaN;
    
    % Establish lat lons
    [LON,LAT]=meshgrid(longitudes_HDF,latitudes_HDF);
    LAT=reshape(LAT,numel(LAT),1);
    LON=reshape(LON,numel(LON),1);
    
    %loop through each of 3rd dimension (note only 1 loop if 2D matrix)
    for i=1:loops
        
        %isolate a single 2D matrix
        if dimensions==3
            data=squeeze(data_main(:,:,i));
        else
            data=data_main;
        end
        
        if nansum(nansum(isnan(data)))>=1
            %find inds for nan and notnan values
            data_nan_inds=find(isnan(data) & land_mask==1);
            data_notnan_inds=find(~isnan(data) & land_mask==1);
            %combine a single list of all not nan inds, and query with nan inds
            a=[LAT(data_notnan_inds),LON(data_notnan_inds)];
            b=[LAT(data_nan_inds),LON(data_nan_inds)];
            %find nearest neighbour
            [nearest_inds,dis]=knnsearch(a,b,'k',10);
            % remove data that is too far to influence. The distance is in
            % the native spatial resolution in pixels, so 180x360 deg
            % resolution (1deg res) will consider values within 4deg if
            % dis>4 is considered.
            desired_res=4;
            data_res=longitudes_HDF(2)-longitudes_HDF(1);
            dis(dis>(desired_res/data_res))=NaN;
            % IDW weightings
            weighting=1./(dis.^3);
            nan_fill=data(data_notnan_inds(nearest_inds));
            % apply IDW
            missing_data=nansum(nan_fill.*weighting,2)./nansum(weighting,2);
            data_raw=data;
            data_filled=data_raw;
            data_filled(data_nan_inds)=missing_data;
            %     data_step_2=data_filled;
            % repeat the process, but ignore the land mask.
            data_nan_inds=find(isnan(data_filled));
            data_notnan_inds=find(~isnan(data_filled));
            %combine a single list of all not nan inds, and query with nan inds
            a=[LAT(data_notnan_inds),LON(data_notnan_inds)];
            b=[LAT(data_nan_inds),LON(data_nan_inds)];
            %find nearest neighbour
            [nearest_inds,dis]=knnsearch(a,b,'k',10);
            dis(dis>5)=NaN;
            % IDW weightings
            weighting=1./(dis.^1.4);
            nan_fill=data_filled(data_notnan_inds(nearest_inds));
            % apply IDW
            missing_data=nansum(nan_fill.*weighting,2)./nansum(weighting,2);
            data_filled(data_nan_inds)=missing_data;
            %     data_step_3=data_filled;
            % fill the remaining missing data (which is almost exclusively the northern and southern poles) with a constanat taken as a
            % lower percentile of the distribution of sea only (land_mask==0)
            fill_value=prctile(data_filled(land_mask==0),40); %25th prcentile seems legit? there are small islands that cause large AOD that will feature in the 75+ category, then there are high values around equator and off the coasts of Africa, Asia and North America, these will dominate the values around 50.
            data_filled=fillmissing(data_filled,'constant',fill_value);
            
            % fill output
            if dimensions==3
                filled_data(:,:,i)=data_filled;
            else
                filled_data=data_filled;
            end
            
            % else there are no gaps
        else
            % fill output
            if dimensions==3
                filled_data(:,:,i)=data;
            else
                filled_data=data;
            end
            %             %% THIS WILL PLOT A PROGRESSION OF THE METHOD THAT FILLS
            %             data NEED TO REINTRODUCE data_step_2 and 3 before
            %             figure('Name','Progression of gap filling')
            %             latlim=[floor(min(min(latitudes_HDF))),ceil(max(max(latitudes_HDF)))];
            %             lonlim=[floor(min(min(longitudes_HDF))),ceil(max(max(longitudes_HDF)))];
            %             coast = load('coast.mat');
            %                         subplot(2,2,1)
            %             axesm('MapProjection','eqdcylin','MapLatLimit',latlim,'MapLonLimit',lonlim,'Frame','on','Grid','on','MeridianLabel','on','ParallelLabel','on');
            %             surfm(latitudes_HDF,longitudes_HDF,data_raw,30,'LineStyle','none');
            %             plotm(coast.lat,coast.long,'k')
            %             h=colorbar();
            %             title('Raw Angstrom Exponent')
            %                         subplot(2,2,2)
            %             axesm('MapProjection','eqdcylin','MapLatLimit',latlim,'MapLonLimit',lonlim,'Frame','on','Grid','on','MeridianLabel','on','ParallelLabel','on');
            %             surfm(latitudes_HDF,longitudes_HDF,data_step_2,30,'LineStyle','none');
            %             plotm(coast.lat,coast.long,'k')
            %             h=colorbar();
            %             title('Land mask IDW (1.4)')
            %                         subplot(2,2,3)
            %             axesm('MapProjection','eqdcylin','MapLatLimit',latlim,'MapLonLimit',lonlim,'Frame','on','Grid','on','MeridianLabel','on','ParallelLabel','on');
            %             surfm(latitudes_HDF,longitudes_HDF,data_step_3,30,'LineStyle','none');
            %             plotm(coast.lat,coast.long,'k')
            %             h=colorbar();
            %             title('Ocean expansion IDW (5)')
            %                         subplot(2,2,4)
            %             axesm('MapProjection','eqdcylin','MapLatLimit',latlim,'MapLonLimit',lonlim,'Frame','on','Grid','on','MeridianLabel','on','ParallelLabel','on');
            %             surfm(latitudes_HDF,longitudes_HDF,data_filled,30,'LineStyle','none');
            %             plotm(coast.lat,coast.long,'k')
            %             h=colorbar();
            %             title('Resulting Angstrom Exponent')
            %
        end
    end
   
else
    filled_data=data_main;
end
end