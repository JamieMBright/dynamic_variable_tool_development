% Function to get the filename.
% this is called many times within the main script, and so it is worth
% having a single definition so that it can change overtime with different
% formats.

function filename=GetFilename(store,raw_data_source_var,year,prefix,suffix)

% if confidence is not an input
if ~exist('suffix','var')
    % default to the assumption that the filename required is not related
    % to confidence flags
    suffix_flag=false;
end

% if this is a confidence flag
if suffix_flag==true
    % the filename will have confidence within it
    filename=[store.raw_outputs_store,raw_data_source_var,filesep,prefix,'_',raw_data_source_var,'_',num2str(year),'_',suffix,'.mat'];
else
    % else it will be titled just as the raw_data_source_var
    filename=[store.raw_outputs_store,raw_data_source_var,filesep,prefix,'_',raw_data_source_var,'_',num2str(year),'.mat'];
end

end