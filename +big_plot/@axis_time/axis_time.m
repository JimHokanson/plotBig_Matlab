classdef axis_time < handle
    %
    %   Class:
    %   big_plot.axis_time
    %
    %   This class manages data that we hold onto regarding the
    %   interpretation of plotted time.
    %
    %   See Also
    %   --------
    %   big_plot.setAxisAbsoluteStartTime
    %   big_plot.getAxisAbsoluteStartTime
    
    properties
        %start_time - for multiple plots what start time we are
        %working with - is this absolute???? TODO: Improve documentation
        %   => see plot(method) in sci.time_series.data
        %
        %zero_time - when zeroing time what value was subtracted before
        %   plotting
    end
    methods (Static)
%         function setZeroedTime(h_axes,zero_time)
%             setappdata(h_axes,'big_plot__zero_time',zero_time);
%         end
%         function zero_time = getZeroedTime(h_axes)
%             zero_time = getappdata(h_axes,'big_plot__zero_time');
%             if isempty(zero_time)
%                 zero_time = 0;
%             end
%         end
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

