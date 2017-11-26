classdef time_interface
    %
    %   Class:
    %   big_plot.interfaces.time_interface
    
    %What must time clases do ...
    properties (Abstract)
        n_samples
    end
    
    methods (Abstract)
        getTimeArray(obj)
    end
end

