classdef perf_mon < handle
    %
    %   Class:
    %   big_plot.perf_mon
    
    properties
        init_h_and_l
        init_data
        init_render
        
        n_calls_all = 0 %This will be the highest. Incremented every time
        %we rerender.
        
        n_render_calls = 0 %# of times the figure detected a resize
        render_cb_times %array
        render_types %array
        %1 - init
        %2 - no change
        %3 - reset to global
        %4 - new render
        
        %Reduce ...
        %------------------------
        n_reduce_calls = 0 %Calls to reduceToWidth ...
        reduce_mex_times %array
        reduce_fcn_times
        n_samples_reduce %array
        ms_reduce_per_million_samples %array

        n_render_busy_calls = 0 %If busy rendering, we increment this
        %   No plotting actually occurs ...
        
        n_render_no_ops = 0 %No change needed since limits have expanded
        %not contracts
        n_render_resets = 0 %Reset to original data
        
        t_size1
        t_size2
    end
    
    methods
        function obj = perf_mon()
            %TODO: We might want to eventually not allow any growing ...
            obj.extendReduceArrays(100);
            obj.extendRenderArrays(100);
        end
        function logRenderPerformance(obj,elapsed_time,render_type)
            obj.n_render_calls = obj.n_render_calls + 1;
            if obj.n_render_calls > length(obj.render_cb_times)
                obj.extendRenderArrays(2*length(obj.render_cb_times));
            end
            I = obj.n_render_calls;
            obj.render_cb_times(I) = elapsed_time;
            obj.render_types(I) = render_type;
        end
        function logReducePerformance(obj,s,fcn_time)
            obj.n_reduce_calls = obj.n_reduce_calls + 1;
            if obj.n_reduce_calls > length(obj.reduce_mex_times)
                obj.extendReduceArrays(2*length(obj.reduce_mex_times));
            end
            I = obj.n_reduce_calls;
            obj.reduce_fcn_times(I) = fcn_time;
            obj.reduce_mex_times(I) = s.mex_time;
            obj.n_samples_reduce(I) = s.range_I(2) - s.range_I(1);
            obj.ms_reduce_per_million_samples(I) = obj.reduce_mex_times(I)*1000/(obj.n_samples_reduce(I)/1e6);
            
        end
        function extendReduceArrays(obj,n_samples_add)
            obj.reduce_mex_times = [obj.reduce_mex_times zeros(1,n_samples_add)];
            obj.reduce_fcn_times = [obj.reduce_fcn_times zeros(1,n_samples_add)];
            obj.n_samples_reduce = [obj.n_samples_reduce zeros(1,n_samples_add)];
            obj.ms_reduce_per_million_samples = [obj.ms_reduce_per_million_samples zeros(1,n_samples_add)];
        end
        function extendRenderArrays(obj,n_samples_add)
            obj.render_cb_times = [obj.render_cb_times zeros(1,n_samples_add)];
            obj.render_types = [obj.render_types zeros(1,n_samples_add)];
        end
        function truncate(obj)
            I = obj.n_reduce_calls + 1;
            obj.t_size1 = I;
            obj.reduce_mex_times(I:end) = [];
            obj.reduce_fcn_times(I:end) = [];
            obj.n_samples_reduce(I:end) = [];
            obj.ms_reduce_per_million_samples(I:end) = [];
            
            I = obj.n_render_calls + 1;
            obj.t_size2 = I;
            obj.render_cb_times(I:end) = [];
            obj.render_types(I:end) = [];
        end
    end
    
end
