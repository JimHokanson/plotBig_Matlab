classdef xy_interface
    %
    %   Class:
    %   big_plot.interfaces.xy_interface
    
    properties (Abstract)
        %The presence of this field is used to indicate that the class
        %should be treated as an xy_interface
        is_xy
        n_samples
    end
    
    methods (Abstract)
        getTimeArray(obj)
        getRawData(obj)
    end
    
end

