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
    %   This class is returned from
    
    properties
        big_plot_ref %big_plot
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
        function y_data = getYData(obj,xlim)
            %
            %
                        
            y_data = obj.big_plot_ref.data.getYData(xlim,obj.group_I,obj.line_I);
            
        end
        function x_data = getXData(obj,xlim)
            x_data = obj.big_plot_ref.data.getXData(xlim,obj.group_I,obj.line_I);
        end
    end
    
end

