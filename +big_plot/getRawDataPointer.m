function ptr = getRawDataPointer(h_line)
%
%   ptr = big_plot.getRawDataPointer(h_line)
%
%   Inputs
%   ------
%   h_line : Matlab line handle
%
%   Outputs
%   -------
%   ptr : [] OR big_plot.line_data_pointer
%

ptr = getappdata(h_line,'BigDataPointer');

end