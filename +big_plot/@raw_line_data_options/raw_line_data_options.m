classdef raw_line_data_options
    %
    %   Class:
    %   big_plot.raw_line_data_options
    %
    %   Options for processing big_plot.raw_line_data
    %
    %   See Also
    %   --------
    %   big_plot.raw_line_data
    
    properties
        get_x_data = true
        %Populates the 'x' property in raw_line_data. Note this might be an
        %expensive memory operation which is why we have the option to
        %disable it
        
        
        xlim = []
        %Range over which to retrieve the data.
        
        get_calibrated = true
        %If a calibration is present, this will return the calibrated data
        %when true. Calibration is generally only present (I think) with
        %streaming data.
        
        get_raw = false
        %Retrieves the uncalibrated data. In conjunction with
        %get_calibrated this allows us to potentially get both raw and
        %calibrated data.
    end
    
    methods
    end
    
end
