classdef (Hidden) line_data_pointer < handle
    %
    %   Class:
    %   big_plot.line_data_pointer
    %
    %   This class is meant to facilitate retrieval of the actual data that
    %   is in a figure, given that we are only plotting a subset of the
    %   data available. The typical approach to getting data would be to
    %   get it from the figure directly, but in that case only a subset
    %   would be available (the min/max data plotted).
    %
    %   The class constructor is called in big_plot.data during initial
    %   rendering.
    
    properties
        big_plot_ref %big_plot
        %This will most likely be kept in place as it allows us to 
        %access everything about the plot, not just the data
        
        group_I
        line_I
    end
    
    methods
        function obj = line_data_pointer(big_plot_ref,group_I,line_I)
            %
            %   obj = big_plot.line_data_pointer(big_plot_ref,group_I,line_I)
            %
            %   Inputs
            %   ------
            %   group_I
            %   line_I
            
            obj.big_plot_ref = big_plot_ref;
            obj.group_I = group_I;
            obj.line_I = line_I;
        end
        function setCalibration(obj,calibration)
            data = obj.big_plot_ref.data;
            data.setCalibration(calibration,obj.group_I,obj.line_I)
        end
        function s = getRawLineData(obj,in)    
            %
            %   Output
            %   ------
            %   s : big_plot.raw_line_data
            
            data = obj.big_plot_ref.data;
            s = data.getRawLineData(obj.group_I,obj.line_I,in);
        end
    end
    
end

