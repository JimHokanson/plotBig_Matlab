function s = getRawLineData(h_plot,varargin)
%
%   s = big_plot.getRawLineData(h_plot,varargin)
%
%   Inputs
%   ------
%   h_plot
%
%   Optional Inputs (see big_plot.raw_line_data_options)
%   -----------------------------------------------------------
%   get_x_data : default true
%       If false, the corresponding x-data are not returned. This can
%       save on memory if it isn't needed.
%   xlim : [min_time  max_time] (default [])
%       When empty all data are returned.
%   get_calibrated : default true
%       If true, calibration data is returned when available.
%   get_raw : default false
%       If true, raw data is returned. Both raw and calibrated data can be
%       returned.
%
%   Outputs
%   -------
%   s : big_plot.raw_line_data
%
%   Improvements
%   ------------
%   - Allow processing of a vector of handles ...

in = big_plot.raw_line_data_options;
in = big_plot.sl.in.processVarargin(in,varargin);

%Note we might want both raw and calibrated so get_raw is not
%~in.get_calibrated
if ~in.get_calibrated
    in.get_raw = true;
end

%This is populated during line creation. It is a bit awkward which is why
%this function was created.
ptr = getappdata(h_plot,'BigDataPointer');

if isempty(ptr)
    s = big_plot.raw_line_data.fromStandardLine(h_plot,in);
else
    s = ptr.getRawLineData(in);
end


end