classdef streaming_data < handle
    %
    %   Class:
    %   big_plot.streaming_data
    
    
    %{
        profile on
        fh = @(t) 0.0005.*t.*sin(0.01*t) + rand(1,length(t));
        dt = 1/10000;
        t = 0:dt:30;
        y = fh(t);
        t2 = 30+dt:dt:40;
        y2 = fh(t2);

        xy = big_plot.streaming_data(dt,2*length(y),'initial_data',y);

        xy.addData(y2);
  
        t3 = 40+dt:dt:500;
        y3 = fh(t3);
    
        xy.addData(y3);
    
        plotBig(xy)
    
        t4 = 500+dt:dt:2000;
        y4 = fh(t4);
    
        xy.addData(y4);
        set(gca,'xlim',[0 2000])
    
        t5 = 2000+dt:dt:10000;
        y5 = fh(t5);
        xy.addData(y5);
        set(gca,'xlim',[0 10000])
        profile off
    
        profile viewer
    %}
    
    %{
        subplot(1,2,1)
        plot(xy.y(1:xy.n_samples))
        subplot(1,2,2)
        plot(xy.y_small(1:xy.I_small_all))
    %}
    
    properties 
        DOWNSAMPLE_AMOUNT = 1000
    end
    properties
        is_xy = true
        y
        y_small
        dt
        dt_small
        t0
        n_samples = 0
        
        growth_rate
        
        %This is the # of samples in complete chunks. Anything not complete
        %will be reprocessed.
        n_samples_processed = 0
        
        %The # of small values that are set and that will not be
        %overwritten when we get more data
        I_small_complete = 0        
        I_small_all
    end
    
    methods
        function obj = streaming_data(dt,n_samples_init,varargin)
            in.t0 = 0;
            in.initial_data = [];
            in.data_type = 'double';
            in.growth_rate = 2;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            obj.dt = dt;
            %2 samples per DOWNSAMPLE_AMOUNT so multiply by 0.5
            obj.dt_small = 0.5*dt*obj.DOWNSAMPLE_AMOUNT;
            obj.t0 = in.t0;
            obj.growth_rate = in.growth_rate;
            
            if ~isempty(in.initial_data)
                in.data_type = class(in.initial_data);
            end
            
            obj.y = zeros(n_samples_init,1,in.data_type);
            obj.y_small = zeros(20000,1,in.data_type);
            
            if ~isempty(in.initial_data)
                n_samples = length(in.initial_data);
                if n_samples > n_samples_init
                    error('Initial data is larger than the # of samples to initialize')
                end
                obj.y(1:n_samples) = in.initial_data;
                obj.n_samples = n_samples;
                h__processSmall(obj)
            end
        end
        function r = getDataReduction(obj,x_limits,axis_width_in_pixels)
            
            t_end = obj.getTimesFromIndices(obj.n_samples);
            
            if isinf(x_limits)
                t1 = obj.getTimesFromIndices(1);
                t2 = t_end;
                x1 = 1;
                x2 = obj.n_samples;
                x1_small = 1;
                x2_small = obj.I_small_all;
            else
                t1 = x_limits(1);
                t2 = x_limits(2);
                x1 = obj.getIndicesFromTimes(t1);
                if x1 < 1
                    x1 = 1;
                end
                x2 = obj.getIndicesFromTimes(t2);
                if x2 > obj.n_samples
                    x2 = obj.n_samples;
                end
                x1_small = obj.getIndicesFromTimes(t1,true);
                if x1_small < 1
                    x1_small = 1;
                end
                x2_small = obj.getIndicesFromTimes(t2,true);
                if x2_small > obj.I_small_all
                    x2_small = obj.I_small_all;
                end
                
            end
            
            if x2_small - x1_small > 2*axis_width_in_pixels
                start_I = x1_small;
                end_I = x2_small;
                data = obj.y_small;
                %Note we need to update time as we might have zoomed
                %past our data ...
                t1 = obj.getTimesFromIndices(x1_small,true);
                t2 = obj.getTimesFromIndices(x2_small,true);
            else
                start_I = x1;
                end_I = x2;
                data = obj.y;
              	t1 = obj.getTimesFromIndices(x1);
                t2 = obj.getTimesFromIndices(x2);
            end
                            
            n_y_samples = end_I - start_I + 1;
            samples_per_chunk = ceil(n_y_samples/axis_width_in_pixels);    
            
            t = tic;
            y_reduced = big_plot.reduceToWidth_mex(data,samples_per_chunk,start_I,end_I);
            mex_time = toc(t);
            n_y_reduced = length(y_reduced);
            x_reduced = [0 linspace(t1,t2,n_y_reduced-2) t_end]';
            
            r = big_plot.xy_reduction;
            r.y_reduced = y_reduced;
            r.x_reduced = x_reduced;
            r.mex_time = mex_time;
            
        end
        function data = getRawData(obj)
            data = obj.y(1:obj.n_samples);
        end
        function indices = getIndicesFromTimes(obj,times,use_small)
            if nargin == 2
                use_small = false;
            end
            if use_small
                indices = times/obj.dt_small + 1;
            else
                indices = times/obj.dt + 1;
            end
            
        end
        function times = getTimesFromIndices(obj,indices,use_small)
            if nargin == 2
                use_small = false;
            end
            if use_small
                times = (indices-1)*obj.dt_small;
            else
                times = (indices-1)*obj.dt;
            end

        end
        function time_array = getTimeArray(obj)
            time_array = ((0:obj.n_samples-1)*obj.dt)';
            %time_array = h__getTimeScaled(obj,time_array);
        end
        function addData(obj,new_data)
            n_samples_new = length(new_data);
            n_samples_total = n_samples_new + obj.n_samples;
            
            %Resize if necessary ...
            %-----------------------------
            if n_samples_total > length(obj.y)
                n_samples_add = ceil((obj.growth_rate-1)*length(obj.y));
                if length(obj.y) + n_samples_add < n_samples_total
                    n_samples_add = n_samples_total - length(obj.y);
                end
                obj.y = [obj.y; zeros(n_samples_add,1,class(obj.y))];
            end
            start_I = obj.n_samples+1;
            end_I = n_samples_total;
            obj.y(start_I:end_I) = new_data;
            obj.n_samples = end_I;
            
            h__processSmall(obj)
        end
    end
end

function h__processSmall(obj)

    
    n_samples_small_total = ceil(obj.n_samples/obj.DOWNSAMPLE_AMOUNT)*2;
    
    %Resize if necessary ...
    %-----------------------------
    if n_samples_small_total > length(obj.y_small)
        n_samples_add = ceil((obj.growth_rate-1)*length(obj.y_small));
        if length(obj.y_small) + n_samples_add < n_samples_small_total
            n_samples_add = n_samples_small_total - length(obj.y_small);
        end
        obj.y_small = [obj.y_small; zeros(n_samples_add,1,class(obj.y_small))];
    end
    
    %n_extra_process = obj.n_samples - obj.n_samples_processed;
    
    start_I = obj.n_samples_processed+1;
    end_I = obj.n_samples;
    min_max_data = big_plot.reduceToWidth_mex(obj.y,obj.DOWNSAMPLE_AMOUNT,start_I,end_I);
    
    out_start_I = obj.I_small_complete + 1;    
    out_end_I = ceil(end_I/obj.DOWNSAMPLE_AMOUNT)*2;
    
    %For right now anytime we get a subset of the data the mex code pads
    %with the first and the last sample. Thus we ignore those values
    %when doing the assigment.
    obj.y_small(out_start_I:out_end_I) = min_max_data(2:end-1); 
    
    obj.I_small_all = out_end_I;
    
    obj.n_samples_processed = floor(obj.n_samples/obj.DOWNSAMPLE_AMOUNT)*obj.DOWNSAMPLE_AMOUNT;
    obj.I_small_complete = 2*floor(obj.n_samples/obj.DOWNSAMPLE_AMOUNT);

    %{
    subplot(1,2,1)
    plot(obj.y(1:obj.n_samples))
    subplot(1,2,2)
    plot(obj.y_small(1:out_end_I))
    
    %}
    
end

