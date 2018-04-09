% Function to download all the required NCEP Reanalysis data from the NOAA
% ftp server.
%
% The function will build missing directories and download missing files
% for the specified list of years.
%
% This function requires the use of 'wget'. See the documentation of
% 'DownloadWithWget.m' for how to install this download function.
%
% It is possible to replace DownloadWithWget for mget, thought it is
% slower: https://au.mathworks.com/help/matlab/ref/ftp.mget.html
% % ncep = ftp('ftp.cdc.noaa.gov');
% % filename='/Datasets/ncep.reanalysis/other_gauss/tcdc.eatm.gauss.2017.nc';
% % mget(ncep,filename);
% % close(ncep);
%
% Inputs are a numerical vector of years
% e.g. list_of_years=1993:2018;
%
% There are no outputs.
%
% File roots:
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/pres.sfc.2017.nc
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface_gauss/air.2m.gauss.1948.nc
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/pr_wtr.eatm.1948.nc
% ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/surface/rhum.sig995.1948.nc

% Example usage:
% downloadAllReanalysisData(2017)

function []=DownloadAllReanalysisData(list_of_years,NCEP_dirs,store)
%determine current year for re-download of this current year's file;
this_year=year(now);

% initialise the url paths, directory paths and file names
%pressure temperature precipitable_water relative_humididy
url_root='ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis/';
var_root={'surface/','surface_gauss/','surface/','surface/'};
var_file={'pres.sfc.','air.2m.gauss.','pr_wtr.eatm.','rhum.sig995.'};
var_save_name={'pres.sfc.','tamb-','pwat-','rh3-'};
url_end='.nc';
file_save_dir=store.NCEP_store;
var_dirs=NCEP_dirs;
reporting_flags=NCEP_dirs;

% create the directories should they not already exist
for i=1:length(var_dirs)
    dir_path=[file_save_dir,var_dirs{i}];
    if ~exist(dir_path,'dir')
        disp(['Making directory for reanalysis downloads: ',dir_path])
        mkdir(dir_path)
    end
end

% loop each year required and download the appropriate reanalysis file
for i=1:length(list_of_years)
    % loop each variable
    for var=1:length(var_file)
        % make the url name
        url = [url_root,var_root{var},var_file{var},num2str(list_of_years(i)),url_end];
        % make the file save name
        filename = [file_save_dir,var_dirs{var},'\',var_save_name{var},num2str(list_of_years(i)),url_end];
        % check whether the requested year is not the current year
        if list_of_years(i)~=this_year
            %check if the file already exists
            if ~exist(filename,'file')
                % if not, download the file
                status=DownloadWithWget(filename,url);
                if status==0
                    disp([' ... downloaded ',reporting_flags{var},' for ',num2str(list_of_years(i))])
                else
                    disp([' ... Failed to download ',reporting_flags{var},' for ',num2str(list_of_years(i))])
                end
            end
        else
            if ~exist(filename,'file')
                % if not, download the file
                status=DownloadWithWget(filename,url);
                if status==0
                    disp([' ... downloaded ',reporting_flags{var},' for ',num2str(list_of_years(i))])
                else
                    disp([' ... Failed to download ',reporting_flags{var},' for ',num2str(list_of_years(i))])
                end
            else
                % Get the file's date
                FileInfo = dir(filename);
                % if the file is 5 days old
                if datenum(FileInfo.date)<now-5
                    status=DownloadWithWget(filename,url);
                    if status==0
                        disp([' ... downloaded ',reporting_flags{var},' for ',num2str(list_of_years(i))])
                    else
                        disp([' ... Failed to download ',reporting_flags{var},' for ',num2str(list_of_years(i))])
                    end
                end
            end
        end
        
    end
    
end
end