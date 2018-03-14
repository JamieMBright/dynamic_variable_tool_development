% Function to get the filename.
% this is called many times within the main script, and so it is worth
% having a single definition so that it can change overtime with different
% formats.

function filename=GetFilename(store,raw_data_source_var,year)


filename=[store.raw_outputs_store,filesep,raw_data_source_var,filesep,raw_data_source_var,'_',num2str(year),'.mat'];


end