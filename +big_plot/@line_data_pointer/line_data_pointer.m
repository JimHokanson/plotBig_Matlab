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
    %
    %   See Also
    %   --------
    %   big_plot.getRawLineData
    %   big_plot.data.initRawDataPointers
    
    
    properties
        big_plot_ref %big_plot
        %This will most likely be kept in place as it allows us to 
        %access everything about the plot, not just the data
        
        group_I
        line_I
    end
    
    methods (Static)
        function ptr = retrieveFromLineHandle(h_line)
            %
            %   ptr = big_plot.line_data_pointer.retrieveFromLineHandle(h_line);
            
            %This is the "magic", we've stored the class instance
            %in the line handle using setappdata. Now we retrieve it
            ptr = getappdata(h_line,'big_plot__data_pointer');
        end
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
            %
            %   See Also
            %   --------
            %   big_plot.getRawLineData
            
            %data : big_plot.data
            data = obj.big_plot_ref.data;
            
            %big_plot.data.getRawLineData
            s = data.getRawLineData(obj.group_I,obj.line_I,in);
        end
        function storeObjectInLineHandle(obj,h_line)
            setappdata(h_line,'big_plot__data_pointer',obj);
        end
    end
    
end

