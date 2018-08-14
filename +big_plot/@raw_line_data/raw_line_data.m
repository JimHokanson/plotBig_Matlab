classdef (Hidden) raw_line_data < handle
    %
    %   Class:
    %   big_plot.raw_line_data
    %
    %   See Also
    %   --------
    %   big_plot.getRawLineData
    %   big_plot.raw_line_data_options
    %   big_plot.data.getRawLineData
    
    properties
        %time or x data
        x
        
        %Raw y data, without any calibration
        y_raw
        
        %Data after calibration
        y_cal
        
        %Output data for plotting, this is either:
        %1) raw data (when no calibration is present)
        %2) calibrated data (when calibration is present)
        y_final
        
        %Indicates source of y_final
        %True - calibrated
        %False - raw
        final_is_calibrated = false
    end
    
    %Constructors
    %----------------------------------------------------------------------
    methods (Static)
        function obj = fromStandardLine(h_line,varargin)
            %
            %   obj = big_plot.raw_line_data.fromStandardLine(h_plot,varargin)
            %
            %   A standard line is a standard Matlab line that contains
            %   the entirety of the data.
            
            
            %Yikes - this is for something else ...
            %
            %   This is useful in cases where the original data is not
            %   accessible and you only have a handle to the plotted data.
            %   Since we downsample when plotting, you can't do the
            %   following to get data:
            %
            %       my_data = h_line.YData; %Not valid, only gives
            %                               %downsampled data
            %
            %   Inputs
            %   ------
            %   h_plot : Matlab line handle?
            %
            %   Example
            %   -------
            %   my_data = rand(1,1e7);
            %   h_line = plotBig(my_data)
            %   %Later on, you have the line handle, but not the data.
            %   %For example ...
            %   h_axes = gca();
            %   h_line = h_axes.Children(1)
            %   my_data2 = h_line.YData; %Incorrect
            %   s = big_plot.raw_line_data.fromStandardLine(h_line)
            %   my_data3 = s.y_final;
            %   fprint('Does line YData match the original data\n');
            %   isequal(my_data,my_data2)  %No
            %   fprint('Does fetched y_data match the original data\n');
            %   isequal(my_data,my_data3)  %Yes
            %
            %   JAH TODO: Should input name be h_line not h_plot?
            
            in = big_plot.raw_line_data_options();
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            obj = big_plot.raw_line_data();
            obj.y_raw = h_line.YData;
            
            if in.get_x_data || ~isempty(in.xlim)
                obj.x = h_line.XData;
            end
            
            %If we want a subset, get it now
            if ~isempty(in.xlim)
                I1 = find(obj.x >= in.xlim(1),1);
                I2 = find(obj.x <= in.xlim(2),1,'last');
                if in.get_x_data
                    obj.x = obj.x(I1:I2);
                end
                obj.y_raw = obj.y_raw(I1:I2);
            end
            
            obj.y_final = obj.y_raw;
        end
        function obj = fromStreamingData(data_obj,varargin)
            %
            %   obj = big_plot.raw_line_data.fromStreamingData(data_obj,in)
            %
            %   Inputs
            %   ------
            %   data_obj : big_plot.streaming_data
            
            in = big_plot.raw_line_data_options();
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            obj = big_plot.raw_line_data();
                        
            [data,info] = data_obj.getRawData('xlim',in.xlim,...
                'get_calibrated',in.get_calibrated);
                        
            if in.get_calibrated && info.calibrated_available
                obj.final_is_calibrated = true;
                obj.y_cal = data;
                obj.y_final = data;
                if in.get_raw
                    data = data_obj.getRawData('xlim',in.xlim,...
                        'get_calibrated',false);
                    obj.y_raw = data;
                end
            else
                obj.y_raw = data;
                obj.y_final = data;
                obj.final_is_calibrated = false;
            end

            if in.get_x_data
                obj.x = data_obj.getTimeArray('start_index',info.x1,...
                    'end_index',info.x2);
            end
        end
    end
    
    methods
    end
    
end

