%% ------ Download from the internet using command line and wget --------
% Function that employs the wget function when given a download filepath
% location and the url from where to download the file from
%
%                  ----------- Disclaimer ---------
% Requires the Cygwin download with the added wget package, then the
% filepath must be added to the windows environment.
%
%                  ------------- Inputs ------------
% destination_path_and_filename:
%          the directory where we want to save the downloaded file
%
% source_url:
%          the source url where the download will be triggered from
%
% An optional third and fourth input are the user and password strings for
% servers that require a login feature
%
%  Created by: Jamie Bright
%  Created on: 12/09/2017
%
%% ----- How to use wget and make it system operable ------------
% 
% 1) Cygwin can be downloaded from : https://www.cygwin.com/install.html
%
% 2) On installation, you will be asked which features to include. Cygwin
% has over 200gb of features and so by default they are all turned off so 
% that you can select only the ones you are interested in. Ensure that the
% download option of wget is selected on installation.
%
% 3) Ensure that the windows environment is able to use Cygwin, this is 
% because Matlab calls the system command line to trigger the download.
%   Windows Key -> Type "Environment" -> Select "Edit Environment Variables 
%       for your account" -> Double click of variable "Path" -> 
%       Add path to Cygwin install directory + `\bin`
%
% 4) Now you'll need to reboot or at very least restart MatLab
%
%----------------------------------------------------------------------
function status = download_with_wget(destination_path_and_filename,source_url,user,password)
%% input checks
switch nargin
    case 2
         user_pass_flag=0;
    case 4
        user_pass_flag=1;
        if sum([ischar(user),ischar(password)])~=2
            error('Error in "download_with_wget.m": Inputs must be string format. See " help download_with_wget" for instruction')
        end
        
        
    otherwise
        error('Error in "download_with_wget.m": Invalid number of inputs. See " help download_with_wget" for instruction')
        
end
number_of_attempts=1; %default
class_1=class(destination_path_and_filename);
class_2=class(source_url);
if (strcmp(class_1,'char')==01  && strcmp(class_2,'char')==0)
    error('Error in "download_with_wget.m": Inputs must be string format. See " help download_with_wget" for instruction')
end

%% perform the wget
if user_pass_flag==1
    [status, output] = system (['wget -O ',destination_path_and_filename,' "',source_url,'" --ftp-user=',user,' --ftp-password=',password]);
elseif user_pass_flag==0
    [status, output] = system (['wget -O ',destination_path_and_filename,' "',source_url,'"']);
end
counter=1;
%% check status. 0 = success. >0 = failure
while status ~= 0
    disp(['download_with_wget.m : Attempt ',num2str(counter),' failed to retrieve download'])
    
    pause(3); %pause for 3 seconds incase there was a network connection issue, then try again
    
    if user_pass_flag==1
        [status, output] = system (['wget -O ',destination_path_and_filename,' "',source_url,'" --ftp-user=',user,' --ftp-password=',password]);
    elseif user_pass_flag==0
        [status, output] = system (['wget -O ',destination_path_and_filename,' "',source_url,'"']);
    end
    counter = counter+1;
    
    if counter>number_of_attempts %once we have hit specified default attempts, break the while loop
        break
    end
end

if status~=0
    disp('download_with_wget.m : Final attempt failed to retrieve download')
end


end
