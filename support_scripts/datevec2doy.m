%% Return the Day of Year from an input datevector
% This function takaes a date vector and converts it to the day of the year
% It can handle multiple input date vectors so long as they are in strict
% order of a unique vector per row.
%
% Created by: Jamie Brigh
% Created on: 19/09/2017
%
% ------------- Input Variables --------
%
% datevector - this can be produced using the datevec() function and should
%              be a strict 6-column in length. Each row is assumed to be a
%              separate date vector and will therefore return a vector of
%              same length(rows) as the input with a day of year numeric
%              value per row in date vector.
%
%-------------- Examples -------------
% datevector=datevec(now);
% DOY=datevec2doy(datevector)
% 
% datevectors=[datevec(now-42);datevec(now-98);datevec(now+3);datevec(now+900)];
% DOYs=datevec2doy(datevectors)


function day_of_year=datevec2doy(datevector)
%% safety tests
[rows,cols]=size(datevector);

if cols~=6
    error('datevectors should be produced with datevec() function. This delivers a strict 6 column format. Ensure that the input vectors are as expected.')
end

%% the function

day_of_year=zeros(rows,1); % pre allocate memory

for i = 1:rows %loop through each vector
    begining_of_year=datenum([datevector(i,1),01,01,00,00,00]); %derive the beginning of the queried datevec's year
    time_now=datenum([datevector(i,1:3),00,00,00]); %determine the datenum of the queried datevec
    day_of_year(i)=time_now-begining_of_year+1;   %Calculate the day of year from that datevec and store
end


end


