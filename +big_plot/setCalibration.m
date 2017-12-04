function setCalibration(h_plot,calibration)
%
%
%   big_plot.setCalibration(h_plot,calibration)

ptr = getappdata(h_plot,'BigDataPointer');

if isempty(ptr)
    y = get(h_plot,'YData');
    y2 = y*calibration.m + calibration.b;
    set(h_plot,'YData',y2);
    
else
    ptr.setCalibration(calibration);
end


end