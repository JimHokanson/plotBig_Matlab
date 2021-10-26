classdef reduction_summary < handle
    %
    %   Class:
    %   big_plot.reduction_summary

    properties
        mex_time = 0
        plotted_all_samples = false 
        plotted_all_subset = false
        show_everything
        range_I = [NaN,NaN]
        same_range = false
        skip = false %This happens when we zoom too far to the right
        %or to the left ...
        samples_per_chunk = NaN
    end

    methods
        function obj = reduction_summary()
        end
    end
end