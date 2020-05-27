classdef axes_state
    %
    %   Class:
    %   big_plot.axes_state
    %
    %   For right now I just want to document anything that is attached to
    %   the axes. Eventually I'd like this to be the place that those
    %   things are stored with other classes referencing this class.
    %
    %   In addition, I think this will be useful because eventually
    %   I want all plots on an object to go through one big_plot instance
    %   and I think this class will help.
    %
    %   Things attached to the axes
    %   ---------------------------
    %   
    %   TODO:
    %   big_plot.axis_time
    %   
    %   In big_plot.line_data_pointer:
    %   
    %       ptr = getappdata(h_line,'big_plot__data_pointer');
    %
    
    properties
        h_axes %NYI
    end
    
    methods
    end
end

