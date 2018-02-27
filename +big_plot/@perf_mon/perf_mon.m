classdef (Hidden) perf_mon < handle
    %
    %   Class:
    %   big_plot.perf_mon
    %
    %   See Also:
    %   big_plot>renderData
    %
    %   We time two types of things here:
    %   1) Renders - calls to rerender the data
    %   2) Reductions - subsampling of the data
    
    properties
        log_performance %logical
        %Used to specify whethere or not this class actually logs
        %performance. By default logging is disabled.
        
        %Elapsed time initializing differenct classes
        %--------------------------------------------
        %- See big_plot constructor
        init_h_and_l
        init_data
        init_render
        
        n_calls_all = 0 %This will be the highest. Incremented every time
        %we rerender. See in big_plot>renderData
        
        %Render performance data
        %--------------------------------------
        d1 = '--------  Render performance  -------'
        n_render_calls = 0 %# of times the figure detected a resize
        
        render_cb_times %array
        %Time spent in renderData
        
        render_types %array
        %1 - init
        %2 - no change
        %3 - reset to global
        %4 - new render
        xlim_min
        xlim_max
        xlim_forced
        
        %Reduce performance data
        %--------------------------------------
        d2 = '-------- Reduce performance ---------'
        n_reduce_calls = 0 %Calls to reduceToWidth ...
        reduce_mex_times %array
        reduce_fcn_times
        n_samples_reduce %array
        
        %This is mex specific, normalized
        ms_reduce_per_million_samples %array
        %--------------------------------------
        
        d3 = '-------- Other Props --------'
        n_render_no_ops = 0 %No change needed since limits have expanded
        %not contracted
        n_render_resets = 0 %Reset to original data
    end
    
    methods
        function obj = perf_mon(log_performance)
            %
            %   obj = perf_mon(*log_performance)
            
            %TODO: I haven't exposed enabling logging to the user
            %now that I've disabled it by default
            
            if nargin == 0
                obj.log_performance = false;
            else
                obj.log_performance = log_performance;
            end
            
            %TODO: We might want to eventually not allow any growing ...
            if obj.log_performance
                obj.extendReduceArrays(100);
                obj.extendRenderArrays(100);
            end
        end
        function logRenderPerformance(obj,elapsed_time,render_type,xlim,forced)
            %
            %   logRenderPerformance(obj,elapsed_time,render_type,xlim,forced)
            %
            %   Inputs
            %   ------
            %   elapsed_time :
            %   render_type :
            %   xlim :
            %   forced : 
            %
            %   See Also
            %   --------
            %   big_plot>renderData
            
            if obj.log_performance
                obj.n_render_calls = obj.n_render_calls + 1;
                if obj.n_render_calls > length(obj.render_cb_times)
                    obj.extendRenderArrays(2*length(obj.render_cb_times));
                end
                I = obj.n_render_calls;
                obj.render_cb_times(I) = elapsed_time;
                obj.render_types(I) = render_type;
                obj.xlim_min(I) = xlim(1);
                obj.xlim_max(I) = xlim(2);
                obj.xlim_forced(I) = forced;
            end
        end
        function logReducePerformance(obj,s,fcn_time)
            if obj.log_performance
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
            obj.xlim_min = [obj.xlim_min zeros(1,n_samples_add)];
            obj.xlim_max = [obj.xlim_max zeros(1,n_samples_add)];
            obj.xlim_forced = [obj.xlim_forced false(1,n_samples_add)];
            
        end
        function truncate(obj)
            I = obj.n_reduce_calls + 1;
            obj.reduce_mex_times(I:end) = [];
            obj.reduce_fcn_times(I:end) = [];
            obj.n_samples_reduce(I:end) = [];
            obj.ms_reduce_per_million_samples(I:end) = [];
            
            I = obj.n_render_calls + 1;
            obj.render_cb_times(I:end) = [];
            obj.render_types(I:end) = [];
            obj.xlim_min(I:end) = [];
            obj.xlim_max(I:end) = [];
            obj.xlim_forced(I:end) = [];
        end
        function plot(obj)
            %1) boxplot of various times
            
            %render_cb_times
            %reduce_mex_times
            %reduce_fcn_times
            %ms_reduce_per_million_samples
            
            x_temp = cell(1,4);
            g_temp = cell(1,4);
            x_temp{1} = 1000*obj.render_cb_times(1:obj.n_render_calls);
            g_temp{1} = ones(1,length(x_temp{1}));
            x_temp{2} = 1000*obj.reduce_mex_times(1:obj.n_reduce_calls);
            g_temp{2} = 3*ones(1,length(x_temp{2}));
            x_temp{3} = 1000*obj.reduce_fcn_times(1:obj.n_reduce_calls);
            g_temp{3} = 2*ones(1,length(x_temp{2}));
            x_temp{4} = obj.ms_reduce_per_million_samples(1:obj.n_reduce_calls);
            g_temp{4} = 4*ones(1,length(x_temp{2}));
            
            x = [x_temp{:}]';
            g = [g_temp{:}]';
            
            figure
            boxplot(x,g);
            set(gca,'FontSize',16);
            ylabel('Elapsed time (ms)')
            set(gca,'XTickLabel',{'Render','Reduce','Reduce-Mex portion','Mex per million samples'})
        end
    end
    
end
