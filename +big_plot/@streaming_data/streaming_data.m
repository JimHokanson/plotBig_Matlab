classdef streaming_data < handle
    %
    %   Class:
    %   big_plot.streaming_data
    
    
    %{
        dt = 0.01;
        t = 0:0.01:30;
        y = 10*sin(t) + t.*rand(1,length(t));
        t2 = 30+dt:dt:40;
        y2 = 10*sin(t2) + t2.*rand(1,length(t2));

        xy = big_plot.streaming_data(dt,2*length(y),'initial_data',y);

        xy.addData(y2);
    
        plotBig(xy)
    %}
    
    properties
        y
        dt
        t0
        n_samples = 0
        growth_rate
    end
    
    methods
        function obj = streaming_data(dt,n_samples_init,varargin)
            in.t0 = 0;
            in.initial_data = [];
            in.data_type = 'double';
            in.growth_rate = 2;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            obj.dt = dt;
            obj.t0 = in.t0;
            obj.growth_rate = in.growth_rate;
            
            if ~isempty(in.initial_data)
                in.data_type = class(in.initial_data);
            end
            
            obj.y = zeros(n_samples_init,1,in.data_type);
            
            if ~isempty(in.initial_data)
                n_samples = length(in.initial_data);
                if n_samples > n_samples_init
                    error('Initial data is larger than the # of samples to initialize')
                end
                obj.y(1:n_samples) = in.initial_data;
                obj.n_samples = n_samples;
            end
        end
        function addData(obj,new_data)
            n_samples_new = length(new_data);
            n_samples_total = n_samples_new + obj.n_samples;
            if n_samples_total > length(obj.y)
                n_samples_add = ceil((obj.growth_rate-1)*length(obj.y));
                if length(obj.y) + n_samples_add < n_samples_total
                    n_samples_add = n_samples_total - length(obj.y);
                end
                obj.y = [obj.y; zeros(n_samples_add,1)];
            end
            start_I = obj.n_samples+1;
            end_I = n_samples_total;
            obj.y(start_I:end_I) = new_data;
            obj.n_samples = end_I;
        end
    end
    
end

