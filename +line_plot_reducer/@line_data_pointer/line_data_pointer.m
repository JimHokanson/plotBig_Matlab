classdef (Hidden) line_data_pointer
    %
    %   Class:
    %   sl.plot.big_data.line_plot_reducer.line_data_pointer
    %
    %   This class is meant to facilitate retrieval of the actual data that
    %   is in a figure, given that we are only plotting a subset of the
    %   data available. The typical approach to getting data would be to
    %   get it from the figure directly, but in that case only a subset
    %   would be available (the min/max data plotted).
    %
    %   This class is returned from 
    
    properties
       line_plot_reducer_ref
       group_I
       line_I
    end
    
    methods
        function obj = line_data_pointer(plot_ref,group_I,line_I)
            %
            %   obj = sl.plot.big_data.line_plot_reducer.line_data_pointer(plot_ref,group_I,line_I)
           obj.line_plot_reducer_ref = plot_ref;
           obj.group_I = group_I;
           obj.line_I = line_I;
        end
        function y_data = getYData(obj)
           %
           %
           %    Some thoughts:
           %    1) We might want to have a method in LinePlotReducer
           %    2) If we ever add or delete lines and shift y, the indices
           %    could be off
           
           y_data = obj.line_plot_reducer_ref.y{obj.group_I}(:,obj.line_I);
        end
    end
    
end

