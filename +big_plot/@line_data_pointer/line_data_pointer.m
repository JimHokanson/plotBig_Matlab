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
        
        %These values are essentially used as an ID to work with other
        %classes. Ideally I'd like to get rid of this format and just hold
        %onto the line handle
        group_I
        line_I
    end
    
%     properties (Dependent)
%        h_line 
%     end
%     
%     methods
%         function value = get.h_line(obj)
%             
%         end
%     end
    
    methods (Static)
%         function clearPointer(h_line)
%             setappdata(h_line,'big_plot__data_pointer');
%         end
    
        function ptr = retrieveFromLineHandle(h_line)
            %
            %   ptr = big_plot.line_data_pointer.retrieveFromLineHandle(h_line);
            %
            %   Inputs
            %   ------
            %   h_line : Matlab line handle
            %
            %   Outputs
            %   -------
            %   ptr : big_plot.line_data_pointer or []
            
            %This is the "magic", we've stored the class instance
            %in the line handle using setappdata. Now we retrieve it
            ptr = getappdata(h_line,'big_plot__data_pointer');
        end
    end
    
    %Constructor
    %----------------------------------------------------------------------
    methods
        function obj = line_data_pointer(big_plot_ref,group_I,line_I)
            %
            %   obj = big_plot.line_data_pointer(big_plot_ref,group_I,line_I)
            %
            %   Created By
            %   ----------
            %   big_plot.data>initRawDataPointers
            %
            %   Inputs
            %   ------
            %   group_I :
            %   line_I : 
            %
            %
            
            obj.big_plot_ref = big_plot_ref;
            obj.group_I = group_I;
            obj.line_I = line_I;
        end
    end
    
    methods
        function setCalibration(obj,calibration)
            data = obj.big_plot_ref.data;
            data.setCalibration(calibration,obj.group_I,obj.line_I)
        end
        function disconnectFromFigure(obj)
            %
            
            %big_plot.handles_and_listeners
            obj.big_plot_ref.h_and_l.clearLine(obj.line_I,obj.group_I);
        end
        function s = getRawLineData(obj,in)    
            %
            %   Inputs
            %   ------
            %   in : big_plot.raw_line_data_options
            %   
            %
            %   Output
            %   ------
            %   s : big_plot.raw_line_data
            %
            %   See Also
            %   --------
            %   big_plot.getRawLineData
            
            if nargin == 1
                in = big_plot.raw_line_data_options;
            end
            
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

