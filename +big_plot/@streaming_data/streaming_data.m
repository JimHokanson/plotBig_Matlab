classdef streaming_data < handle
    %
    %   Class:
    %   big_plot.streaming_data
    
    
    %{
        dt = 0.0004;
        t = 0:dt:30;
        y = t.*sin(t) + rand(1,length(t));
        t2 = 30+dt:dt:40;
        y2 = t2.*sin(t2) + rand(1,length(t2));

        xy = big_plot.streaming_data(dt,2*length(y),'initial_data',y);

        xy.addData(y2);
  
        t3 = 40+dt:dt:500;
        y3 = t3.*sin(t3) + rand(1,length(t3));
    
        xy.addData(y3);
    
        plotBig(xy)
    %}
    
        %{
    subplot(1,2,1)
    plot(xy.y(1:xy.n_samples))
    subplot(1,2,2)
    plot(xy.y_small(1:xy.I_small_all))
    
    %}
    
    properties
        y
        y_small
        dt
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

    DOWNSAMPLE_AMOUNT = 1000;
    n_samples_small_total = ceil(obj.n_samples/DOWNSAMPLE_AMOUNT)*2;
    
    %Resize if necessary ...
    %-----------------------------
    if n_samples_small_total > length(obj.y_small)
        n_samples_add = ceil((obj.growth_rate-1)*length(obj.y_small));
        if length(obj.y_small) + n_samples_add < n_samples_small_total
            n_samples_add = n_samples_total - length(obj.y_small);
        end
        obj.y_small = [obj.y_small; zeros(n_samples_add,1,class(obj.y_small))];
    end
    
    %n_extra_process = obj.n_samples - obj.n_samples_processed;
    
    start_I = obj.n_samples_processed+1;
    end_I = obj.n_samples;
    min_max_data = big_plot.reduceToWidth_mex(obj.y,DOWNSAMPLE_AMOUNT,start_I,end_I);
    
    out_start_I = obj.I_small_complete + 1;    
    out_end_I = ceil(end_I/DOWNSAMPLE_AMOUNT)*2;
    
    %For right now anytime we get a subset of the data the mex code pads
    %with the first and the last sample. Thus we ignore those values
    %when doing the assigment.
    obj.y_small(out_start_I:out_end_I) = min_max_data(2:end-1); 
    
    obj.I_small_all = out_end_I;
    
    obj.n_samples_processed = floor(obj.n_samples/DOWNSAMPLE_AMOUNT)*DOWNSAMPLE_AMOUNT;
    obj.I_small_complete = 2*floor(obj.n_samples/DOWNSAMPLE_AMOUNT);

    %{
    subplot(1,2,1)
    plot(obj.y(1:obj.n_samples))
    subplot(1,2,2)
    plot(obj.y_small(1:out_end_I))
    
    %}
    
end

