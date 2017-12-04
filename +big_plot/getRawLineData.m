function s = getRawLineData(h_plot,varargin)
%
%   s = big_plot.getRawLineData(h_plot,varargin)
%
%   Inputs
%   ------
%   h_plot
%
%   Optional Inputs
%   ---------------
%   get_x_data : default true
%   xlim : [min_time  max_time]
%
%   Outputs
%   -------
%   s : 
%       .x
%       .y
%
%   Improvements
%   ------------
%   - Allow processing of a vector of handles ...

in.get_x_data = true;
in.xlim = [];
in.get_calibrated = true;
in.get_raw = false;
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