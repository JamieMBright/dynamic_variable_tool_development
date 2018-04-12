% Reterospective data assimilation for variables with more than one source
% of data.
%
% Namely Ozone and Precipitable water
%
% The principle is that data sources will be assigned a weight depending on
% their performanve at validation sites.

function DataAssimilation(store,raw_data_source_var,year,prefix_1,prefix_2,weight_1,weight_2)

if (~exist('weight_1','var') || ~exist('weight_2','var'))
    weight_1=0.5;
    weight_2=0.5;
end

% load the necessary data
data_1=load(GetFilename(store,raw_data_source_var,year,prefix_1));
data_2=load(GetFilename(store,raw_data_source_var,year,prefix_2));
confidence_1=load(GetFilename(store,raw_data_source_var,year,prefix_1,'confidence'));
confidence_2=load(GetFilename(store,raw_data_source_var,year,prefix_2,'confidence'));
lats_1=load(GetFilename(store,raw_data_source_var,year,prefix_1,'latitudes'));
lats_2=load(GetFilename(store,raw_data_source_var,year,prefix_2,'latitudes'));
lons_1=load(GetFilename(store,raw_data_source_var,year,prefix_1,'longitudes'));
lons_2=load(GetFilename(store,raw_data_source_var,year,prefix_2,'longitudes'));
times_1=load(GetFilename(store,raw_data_source_var,year,prefix_1,'times_datevec'));
times_2=load(GetFilename(store,raw_data_source_var,year,prefix_2,'times_datevec'));

if weight_1==1
    
    filename=GetFilename(store,raw_data_source_var,year,'blended');
    save(filename,'data_1')
    filename=GetFilename(store,raw_data_source_var,year,'blended','confidence');
    save(filename,'confidence_1')
    filename=GetFilename(store,raw_data_source_var,year,'blended','latitudes');
    save(filename,'lats_1')
    filename=GetFilename(store,raw_data_source_var,year,'blended','longitudes');
    save(filename,'lons_1')
    filename=GetFilename(store,raw_data_source_var,year,'blended','times_datevec');
    save(filename,'times_1')
    
elseif weight_2==1
    
    filename=GetFilename(store,raw_data_source_var,year,'blended');
    save(filename,'data_2')
    filename=GetFilename(store,raw_data_source_var,year,'blended','confidence');
    save(filename,'confidence_2')
    filename=GetFilename(store,raw_data_source_var,year,'blended','latitudes');
    save(filename,'lats_2')
    filename=GetFilename(store,raw_data_source_var,year,'blended','longitudes');
    save(filename,'lons_2')
    filename=GetFilename(store,raw_data_source_var,year,'blended','times_datevec');
    save(filename,'times_2')
    
else
    
    
    
    % find the resolutions of lon, lat and time for both data sets
    res_y1=lats_1(2)-lats_1(1);
    res_x1=lons_1(2)-lons_1(1);
    res_z1=24*(datenum(times_1(2))-datenum(times_1(1)));
    res_y2=lats_2(2)-lats_2(1);
    res_x2=lons_2(2)-lons_2(1);
    res_z2=24*(datenum(times_2(2))-datenum(times_2(1)));
    
    % if the temporal resolutions do not align, then apply maximum weighting to
    % the data with the finer resolution.
    if res_z1~=res_z2
        disp('The time resolutions of the two datasets are different...')
        disp(' taking the highest temporal resolution as weighting=1')
        
        if res_z1<res_z2
            filename=GetFilename(store,raw_data_source_var,year,'blended');
            save(filename,'data_1')
            filename=GetFilename(store,raw_data_source_var,year,'blended','confidence');
            save(filename,'confidence_1')
            filename=GetFilename(store,raw_data_source_var,year,'blended','latitudes');
            save(filename,'lats_1')
            filename=GetFilename(store,raw_data_source_var,year,'blended','longitudes');
            save(filename,'lons_1')
            filename=GetFilename(store,raw_data_source_var,year,'blended','times_datevec');
            save(filename,'times_1')
            
        else
            filename=GetFilename(store,raw_data_source_var,year,'blended');
            save(filename,'data_2')
            filename=GetFilename(store,raw_data_source_var,year,'blended','confidence');
            save(filename,'confidence_2')
            filename=GetFilename(store,raw_data_source_var,year,'blended','latitudes');
            save(filename,'lats_2')
            filename=GetFilename(store,raw_data_source_var,year,'blended','longitudes');
            save(filename,'lons_2')
            filename=GetFilename(store,raw_data_source_var,year,'blended','times_datevec');
            save(filename,'times_2')
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
            
            [X,Y,Z]=meshgrid(x,y,z);
            [Xq,Yq,Zq]=meshgrid(xq,yq,zq);
            
            data_2=interp3(X,Y,Z,data_2,Xq,Yq,Zq);
            confidence_2=interp3(X,Y,Z,confidence_2,Xq,Yq,Zq);
            clear X Y Z Xq Yq Zq
            
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
          
            [X,Y,Z]=meshgrid(x,y,z);
            [Xq,Yq,Zq]=meshgrid(xq,yq,zq);
            
            data_1=interp3(X,Y,Z,data_1,Xq,Yq,Zq);
            confidence_1=interp3(X,Y,Z,confidence_1,Xq,Yq,Zq);
            clear X Y Z Xq Yq Zq
            
            lats=lats_2;
            lons=lons_2;
        end
        
        %pre allocate the output
        new_data=zeros(size(data_1)).*NaN;
        
        % blend the data using the confidence (1=exist, 0=empty)
        % introduce the weigthing
        %replace the confidence with the weighting
        confidence_1(confidence_1==1)=weighting_1;
        confidence_2(confidence_2==1)=weighting_2;
        % when there is only 1 value available, that is the value that must
        % be used
        confidence_1(confidence_1~=0 & confidence_2==0)=1;
        confidence_2(confidence_2~=0 & confidence_1==0)=1;
                
        new_data=data_1.*confidence_1+data_2.*confidence_2;
        
        
        
        if ~exist('land_mask','var')
            LAT=reshape(lats,numel(lats),1);
            LON=reshape(lons,numel(lons),1);
            land_mask=reshape(landmask(LAT,LON),[length(lats),length(lons)]);
        end
        
        new_data=REST2FillMissing(land_mask,lons,lats,new_data,'true');       
        
        
    end
    
    
    
end


end