classdef time_interface
    %
    %   Class:
    %   big_plot.interfaces.time_interface
    %
    %   This is meant to be a place that documents how we expect a time
    %   class to behave. This is not yet completed.
    
    %What must time clases do ...
    properties (Abstract)
        n_samples
    end
    
    methods (Abstract)
        getTimeArray(obj)
    end
end

