classdef axis_time < handle
    %
    %   Class:
    %   big_plot.axis_time
    %
    %   See Also
    %   --------
    %   big_plot.setAxisAbsoluteStartTime
    %   big_plot.getAxisAbsoluteStartTime
    
    properties
    end
    methods (Static)
        function setStartTime(h_axes,start_time)
            %
            %   big_plot.axis_time.setStartTime(h_axes,start_time)
            setappdata(h_axes,'big_plot__start_time',start_time);
        end
        function start_time = getStartTime(h_axes)
            %
            %   start_time = big_plot.axis_time.getStartTime(h_axes)
            start_time = getappdata(h_axes,'big_plot__start_time');
        end
    end
end

