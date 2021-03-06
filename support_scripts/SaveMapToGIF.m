% convert 3D map to a gif

function SaveMapToGIF(filename,data,latitudes,longitudes,var_str,units,time,c_upper,c_lower)


h=figure('Name','GIF','color',[1,1,1],...
    'units','centimeters',... %A4 units are 20.0x29.7cm
    'position',[1 1 29.7*0.95 20.0*0.95]... %[left bottom width height] location and size of drawable area LANDSCAPE
    );
% axis tight manual % this ensures that getframe() returns a consistent size
for t=1:length(time)
    disp([num2str(round(1000*t/length(time))/10),' % complete'])
    plotOnMap(latitudes,longitudes,squeeze(data(:,:,t)),'surfm',units,[var_str,': ',datestr(time(t))],h,[c_lower c_upper])
    
%     drawnow 
      % Capture the plot as an image 
      frame = getframe(h); 
      im = frame2im(frame); 
      [imind,cm] = rgb2ind(im,256); 
      % Write to the GIF File 
      if t == 1 
          imwrite(imind,cm,filename,'gif', 'Loopcount',inf,'DelayTime',1/20); 
      else 
          imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',1/20); 
      end 
      cla(h)
end
end
