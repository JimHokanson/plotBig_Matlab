classdef raw_line_data < handle
    %
    %   Class:
    %   big_plot.raw_line_data
    %
    %   See Also
    %   --------
    %   big_plot.raw_line_data_options
    
    properties
        x
        y_raw
        y_cal
        y_final
        final_is_calibrated = false
    end
    
    %Constructors
    %----------------------------------------------------------------------
    methods (Static)
        function obj = fromStandardLine(h_plot,varargin)
            %
            %   obj = big_plot.raw_line_data.fromStandardLine(h_plot,varargin)
            %
            %   A standard line is a standard Matlab line that contains
            %   the entirety of the data.
            
            in = big_plot.raw_line_data_options();
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            obj = big_plot.raw_line_data();
            obj.y_raw = h_plot.YData;
            if in.get_x_data
                obj.x = h_plot.XData;
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
            in = big_plot.sl.in.processVarargin(in,varargin{:});
            
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

