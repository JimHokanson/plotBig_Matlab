classdef xy_interface
    %
    %   Class:
    %   big_plot.interfaces.xy_interface
    %
    %   This is meant to be a place that documents how we expect a xy
    %   class to behave. This is not yet completed.
    %
    %   XY classes contain both X and Y data. In other words, they include 
    %   samples over time, as well as an abstraction of that time.
    
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

