classdef raw_line_data < handle
    %
    %   Class:
    %   big_plot.raw_line_data
    
    
    %.xlim
    %.get_x_data = true;
    
    properties
        x
        y_raw
        y_cal
        y_final
        final_is_calibrated = false
    end
    
    methods (Static)
        function obj = fromStandardLine(h_plot,in)
            %
            %   obj = big_plot.raw_line_data.fromStandardLine(h_plot,in)
            
            obj = big_plot.raw_line_data();
            obj.y_raw = h_plot.YData;
            if in.get_x_data
                obj.x = h_plot.XData;
            end
            I1 = find(obj.x >= in.xlim(1),1);
            I2 = find(obj.x <= in.xlim(2),1,'last');

            if ~isempty(in.xlim)
                obj.x = obj.x(I1:I2);
                obj.y_raw = obj.y_raw(I1:I2);
            end
            
            obj.y_final = obj.y_raw;
        end
        function obj = fromStreamingData(data_obj,in)
            %
            %   obj = big_plot.raw_line_data.fromStreamingData(data_obj,in)
            %
            %   Inputs
            %   ------
            %   data_obj : big_plot.streaming_data
            
            obj = big_plot.raw_line_data();
                        
            [data,info] = data_obj.getRawData('xlim',in.xlim,...
                'get_calibrated',in.get_calibrated);
            
            %       .x_indices
            %       .is_calibrated
            %       .calibrated_available
            
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

            obj.x = data_obj.getTimeArray(obj,'start_index',info.x1,...
                'end_index',info.x2);            
        end
    end
    
    methods
        function obj = raw_line_data()
            
        end
    end
    
end

