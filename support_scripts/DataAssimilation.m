% Reterospective data assimilation for variables with more than one source
% of data.
%
% Namely Ozone and Precipitable water
%
% The principle is that data sources will be assigned a weight depending on
% their performanve at validation sites.

function DataAssimilation(store,raw_data_source_var,year,prefix_1,prefix_2,blended_prefix,weight_1,weight_2)
disp(['Assimilating ',num2str(year),' data for ',raw_data_source_var,' between ',prefix_1,' and ',prefix_2])

if (~exist('weight_1','var') || ~exist('weight_2','var'))
    weight_1=0.5;
    weight_2=0.5;
end

% load the necessary data
data_1s=load(GetFilename(store,raw_data_source_var,year,prefix_1));
f=fieldnames(data_1s);
data_1=eval(['data_1s.',f{1}]);
clear data_1s
data_2s=load(GetFilename(store,raw_data_source_var,year,prefix_2));
f=fieldnames(data_2s);
data_2=eval(['data_2s.',f{1}]);
clear data_2s
confidence_1s=load(GetFilename(store,raw_data_source_var,year,prefix_1,'confidence'));
f=fieldnames(confidence_1s);
confidence_1=eval(['confidence_1s.',f{1}]);
clear confidence_1s
confidence_2s=load(GetFilename(store,raw_data_source_var,year,prefix_2,'confidence'));
f=fieldnames(confidence_2s);
confidence_2=eval(['confidence_2s.',f{1}]);
clear confidence_2s
lats_1s=load(GetFilename(store,raw_data_source_var,year,prefix_1,'latitudes'));
f=fieldnames(lats_1s);
lats_1=eval(['lats_1s.',f{1}]);
clear lats_1s
lats_2s=load(GetFilename(store,raw_data_source_var,year,prefix_2,'latitudes'));
f=fieldnames(lats_2s);
lats_2=eval(['lats_2s.',f{1}]);
clear lats_2s
lons_1s=load(GetFilename(store,raw_data_source_var,year,prefix_1,'longitudes'));
f=fieldnames(lons_1s);
lons_1=eval(['lons_1s.',f{1}]);
clear lons_1s
lons_2s=load(GetFilename(store,raw_data_source_var,year,prefix_2,'longitudes'));
f=fieldnames(lons_2s);
lons_2=eval(['lons_2s.',f{1}]);
clear lons_2s
times_1s=load(GetFilename(store,raw_data_source_var,year,prefix_1,'times_datevec'));
f=fieldnames(times_1s);
times_1=eval(['times_1s.',f{1}]);
times_1=datenum(times_1);
clear times_1s
times_2s=load(GetFilename(store,raw_data_source_var,year,prefix_2,'times_datevec'));
f=fieldnames(times_2s);
times_2=eval(['times_2s.',f{1}]);
times_2=datenum(times_2);
clear times_2s

if weight_1==1
    
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix);
    save(filename,'data_1','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'confidence');
    save(filename,'confidence_1','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'latitudes');
    save(filename,'lats_1','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'longitudes');
    save(filename,'lons_1','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'times_datevec');
    save(filename,'times_1','-v7.3')
    
elseif weight_2==1
    
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix);
    save(filename,'data_2','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'confidence');
    save(filename,'confidence_2','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'latitudes');
    save(filename,'lats_2','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'longitudes');
    save(filename,'lons_2','-v7.3')
    filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'times_datevec');
    save(filename,'times_2','-v7.3')
    
else
    
    
    
    % find the resolutions of lon, lat and time for both data sets
    res_y1=abs(lats_1(2)-lats_1(1));
    res_x1=abs(lons_1(2)-lons_1(1));
    res_z1=24*(datenum(times_1(2))-datenum(times_1(1)));
    res_y2=abs(lats_2(2)-lats_2(1));
    res_x2=abs(lons_2(2)-lons_2(1));
    res_z2=24*(datenum(times_2(2))-datenum(times_2(1)));
    
    % if the temporal resolutions do not align, then apply maximum weighting to
    % the data with the finer resolution.
    if res_z1~=res_z2
        disp('The time resolutions of the two datasets are different...')
        disp(' taking the highest temporal resolution as weighting=1')
        
        if res_z1<res_z2
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix);
            save(filename,'data_1','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'confidence');
            save(filename,'confidence_1','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'latitudes');
            save(filename,'lats_1','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'longitudes');
            save(filename,'lons_1','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'times_datevec');
            save(filename,'times_1','-v7.3')
            
        else
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix);
            save(filename,'data_2','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'confidence');
            save(filename,'confidence_2','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'latitudes');
            save(filename,'lats_2','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'longitudes');
            save(filename,'lons_2','-v7.3')
            filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'times_datevec');
            save(filename,'times_2','-v7.3')
        end
    else
        
        %else the temporal resolutions do align, though the spatial may not
        
        % determine the spatial resolutions. Assumptions that the resolution in
        % degrees is consistent in bot lat and lon
        if (res_x1==res_x2  && res_y1==res_y2)
            % no interpolation needed
            lats=lats_2;
            lons=lons_2;
            
        elseif res_x1<res_x2
            % then dataset 1 has finer resolution, and dataset2 must be interped
            x=lons_2;
            xq=lons_1;
            y=lats_2;
            yq=lats_1;
            z=times_1;
            zq=z;
            
            [X,Y]=meshgrid(x,y);
            [Xq,Yq]=meshgrid(xq,yq);
            
            data_2_interped=zeros(size(data_1)).*NaN;
            confidence_2_interped=zeros(size(data_1)).*NaN;
            
            for i=1:length(zq)
                data_2_interped(:,:,i)=interp2(X,Y,squeeze(data_2(:,:,i)),Xq,Yq);
                confidence_2_interped(:,:,i)=interp2(X,Y,single(squeeze(confidence_2(:,:,i))),Xq,Yq);
            end
            data_2=data_2_interped;
            confidence_2=confidence_2_interped;
            confidence_1=double(confidence_1);
            clear X Y Xq Yq data_2_interped confidence_2_interped
            
            lats=lats_1;
            lons=lons_1;
            
        else
            % dataset 2 has finer resolution, and dataset1 must be interped
            x=lons_1;
            xq=lons_2;
            y=lats_1;
            yq=lats_2;
            z=times_2;
            zq=z;
            
            [X,Y]=meshgrid(x,y);
            [Xq,Yq]=meshgrid(xq,yq);
            
            data_1_interped=zeros(size(data_2)).*NaN;
            confidence_1_interped=zeros(size(data_2)).*NaN;
            
            for i=1:length(zq)
                data_1_interped(:,:,i)=interp2(X,Y,squeeze(data_1(:,:,i)),Xq,Yq);
                confidence_1_interped(:,:,i)=interp2(X,Y,single(squeeze(confidence_1(:,:,i))),Xq,Yq);
            end
            data_1=data_1_interped;
            confidence_1=confidence_1_interped;
            confidence_2=confidence_2;
            clear X Y Xq Yq data_1_interped confidence_1_interped
            
            lats=lats_2;
            lons=lons_2;
        end
        
        %pre allocate the output
        new_data=zeros(size(data_1)).*NaN;
        
        % blend the data using the confidence (1=exist, 0=empty)
        % pre process the confidence for consistent format. Sometimes NaN
        % and sometimes 0.
        confidence_1(isnan(confidence_1))=0;
        confidence_2(isnan(confidence_2))=0;
        
        %replace the confidence with the weighting
        confidence_1(confidence_1==1)=weight_1;
        confidence_2(confidence_2==1)=weight_2;
        
        % when there is only 1 value available (e.g. MODIS is available for
        % that pixel but NCEP is not), only that value that must be used
        % and so a weight of 1 must be given.
        confidence_1(confidence_1~=0 & confidence_2==0)=1;
        confidence_2(confidence_2~=0 & confidence_1==0)=1;
        
        % As confidence value of 0 is a place holder for NaN values in data
        % 1 and data 2, we can remove them for simple multiplcation and sum
        data_1(isnan(data_1))=0;
        data_2(isnan(data_2))=0;
        %apply the weigthings stored in the confidence vars to the data
        % stored in data vars. then return previous NaNs back to Nan value
        new_data=data_1.*confidence_1+data_2.*confidence_2;
        clear data_1 data_2
        new_data_confidence=confidence_1+confidence_2;
        clear confidence_1 confidence_2
        new_data_confidence(new_data_confidence>0)=1;
        new_data_confidence=int8(new_data_confidence);
        new_data(new_data_confidence==0)=NaN;
        
        % perform the gap filling
        if ~exist('land_mask','var')
            [LON,LAT]=meshgrid(lons,lats);
            LAT=reshape(LAT,numel(LAT),1);
            LON=reshape(LON,numel(LON),1);
            land_mask=reshape(landmask(LAT,LON),[length(lats),length(lons)]);
        end
        
        new_data=REST2FillMissing(land_mask,lons,lats,new_data,false);
        
        % save the data to file
        filename=GetFilename(store,raw_data_source_var,year,blended_prefix);
        save(filename,'new_data','-v7.3')
        filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'confidence');
        save(filename,'new_data_confidence','-v7.3')
        filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'latitudes');
        save(filename,'lats','-v7.3')
        filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'longitudes');
        save(filename,'lons','-v7.3')
        time=datevec(times_1);
        filename=GetFilename(store,raw_data_source_var,year,blended_prefix,'times_datevec');
        save(filename,'time','-v7.3')
        
    end
    
    
    
    
end


end