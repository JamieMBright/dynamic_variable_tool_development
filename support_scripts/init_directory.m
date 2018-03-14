% This function takes a directory file path, checks if it currently exists.
% Should the directory not exist, it will be made, else nothing will
% happen.
%
function [] = init_directory(file_path)
if ~ischar(file_path)
    error('file_path must be a string')
end
if ~exist(file_path, 'dir')
  mkdir(file_path);
end
