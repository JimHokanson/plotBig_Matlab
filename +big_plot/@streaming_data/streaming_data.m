classdef streaming_data < handle
    %
    %   Class:
    %   big_plot.streaming_data
    %
    %   Public Functions
    %   -------------------------
    %   setCalibration(calibration)
    %   addData(new_data)
    %   getRawLineData()
    
    
    
    %{
        profile on
        
        %I create the data up front because rand() is a bit slow and
        %I want to disentangle data creation versus plotting
        fh = @(t) 0.0005.*t.*sin(0.01*t) + rand(1,length(t));
        dt = 1/10000;
        t = 0:dt:30;
        y = fh(t);
        t2 = 30+dt:dt:40;
        y2 = fh(t2);
        t3 = 40+dt:dt:500;
        y3 = fh(t3);
        t4 = 500+dt:dt:2000;
        y4 = fh(t4);
        t5 = 2000+dt:dt:10000;
        y5 = fh(t5);
    
        %This buffer size is a bit small but it works for now ...
        init_buffer_size = 2*length(y);
        xy = big_plot.streaming_data(dt,init_buffer_size,'initial_data',y);

        %Evaluate these manually
        xy.addData(y2);
 
        xy.addData(y3);
    
        %The actual plotting
        plotBig(xy)

        %Adding more data to the plot
        xy.addData(y4);
    
        %For now this is manual ...
        set(gca,'xlim',[0 2000])

        %Adding more data
        xy.addData(y5);
        set(gca,'xlim',[0 10000])
    
        %====================================================
        %A better example of streaming ...
        %====================================================
        clf
        %Options -------------
        fs = 10000;
        n_seconds_plot = 2000
        win_width_s = 200;
    
        dt = 1/fs;
    
        %was 1e6 and 20000
        %xy = big_plot.streaming_data(dt,32000000);
        xy = big_plot.streaming_data(dt,1e6);
        
        fh = @(t) 0.002.*t.*sin(0.2*t);

        o = plotBig(xy,'obj',true)
        
        %Generally with streaming we'll use a fixed y-limit
        set(gca,'ylim',[-5 5])
        set(gca,'xlim',[0 win_width_s])
    
        %Generating random data is slow so we'll add the same random data
        %to all chunks. This allows us to zoom in and see the individual
        %samples
        r = 0.1*rand(1,fs);
        t1 = tic;
        t_draw = 0;
        for i = 0:n_seconds_plot-1
            t3 = tic;
            t = i:dt:(i+1-dt);
            
            y = fh(t)+r;
            xy.addData(y');
            if i > win_width_s
                set(gca,'xlim',[i-win_width_s i])
            end
            h_tic2 = tic;
            drawnow
            t_draw = t_draw + toc(h_tic2);
        end
        toc(t1)
    
        %drawing is taking about 90% of the time
    
        %Animated Line for comparison
        %-----------------------------------
        clf
        %Animated line requires preallocating everything
        h = animatedline('MaximumNumPoints',n_seconds_plot*fs);
    	set(gca,'ylim',[-5 5])
        set(gca,'xlim',[0 win_width_s])
    
        t1 = tic;
        t_add = 0;
        t_draw = 0;
        for i = 0:n_seconds_plot-1
            t = i:dt:(i+1-dt);
            
            y = fh(t)+r;
            addpoints(h,t,y);
            if i > win_width_s
                set(gca,'xlim',[i-win_width_s i])
            end
            h_tic2 = tic;
            drawnow
            t_draw = t_draw + toc(h_tic2);
        end
        toc(t1)
    

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
        name
        
        %This is a property that any class wishing to contain both x and y
        %data for big_plot should have.
        is_xy = true
        
        %Values for calibration - output = m*input + b
        m
        b
        
        
        y %raw data, overallocated
        dt %dt of the raw data
        
        y_small %downsampled data, also overallocated
        %Data is downsampled by taking min and max of a chunk of data
        dt_small %dt of the downsampled data
        
        t0 %start time
        
        downsample_amount
        
        n_samples = 0
        
        growth_rate
        
        %This is the # of samples in complete chunks. Anything not complete
        %will be reprocessed. This is the # of samples in the raw data.
        n_samples_processed = 0
        
        %The # of small values that are set and that will not be
        %overwritten when we get more data
        I_small_complete = 0
        
        %This is the # of small values that have been populated. It is
        %either I_small_complete or 2 greater (when an incomplete chunk 
        %has been processed)
        I_small_all
        
        %Populated by big_plot.
        %These callbacks get called by this class when:
        data_added_callback %data has been added to this class
        calibration_callback %the data has been calibrated
    end
    
    properties (Dependent)
        t_max
        calibrated_available
    end
    
    methods
        function value = get.t_max(obj)
            value = obj.getTimesFromIndices(obj.n_samples);
        end
        function value = get.calibrated_available(obj)
            value = ~isempty(obj.m);
        end
    end
    
    %---------  Debugging -------------
    properties
        n_add_events = 0
        n_grow_events = 0
        
        t_add = 0 %For some reason this can be really really high ...
        
        t_reduce = 0
    end
    
    methods
        function obj = streaming_data(dt,n_samples_init,varargin)
            %
            %   obj = big_plot.streaming_data(dt,n_samples_init,varargin)
            %
            %   Optional Inputs
            %   ---------------
            %   m :
            %       Slope for calibration
            %   b :
            %       Offset for calibration
            %   t0 : default 0
            %       Start time of the time-series
            %   initial_data : default []
            %       Data that has already been collected.
            %   data_type : default 'double'
            %       If initial_data is passed in, then the data type
            %       is based on the initial data. Otherwise this can be
            %       used to preallocate data of the correct type.
            %   growth_rate : default 2
            %   downsample_amount : default 200
            %       Number of samples to use when generating a pair of
            %       min-max values in the "small" dataset. In other words
            %       the default value means that every 200 samples we
            %       generate a single min-max pair.
            %
            %   Examples
            %   --------
            %   xy = big_plot.streaming_data(1/1000,1e6);
            %   plotBig(xy)
            
            in.m = [];
            in.b = [];
            in.name = '';
            in.t0 = 0;
            in.initial_data = [];
            in.data_type = 'double';
            in.growth_rate = 2;
            in.downsample_amount = 200;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            obj.name = in.name;
            obj.downsample_amount = in.downsample_amount;
            obj.dt = dt;
            %2 samples per downsample_amount so our dt is half as long as
            %we think
            %x       x       x
            %min max min max min max
            
            obj.dt_small = 0.5*dt*obj.downsample_amount;
            obj.t0 = in.t0;
            obj.growth_rate = in.growth_rate;
            
            if ~isempty(in.initial_data)
                in.data_type = class(in.initial_data);
            end
            
            obj.y = zeros(n_samples_init,1,in.data_type);
            
            %TODO: Base this on above and downsampling ...
            n_samples_small = ceil(n_samples_init/in.downsample_amount*2);
            obj.y_small = zeros(n_samples_small,1,in.data_type);
            
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
    end
    
    %----------------------------------------------------------------------
    %                       Public methods for users
    %----------------------------------------------------------------------
    methods
        function setCalibration(obj,calibration)
            %
            %   Inputs
            %   ------
            %   calibration : struct or object with fields:
            %       - m
            %       - b
            
            obj.m = calibration.m;
            obj.b = calibration.b;
            
            %Notify the renderer that the data has been calibrated.
            obj.calibration_callback();
        end
        function s = getRawLineData(obj,varargin)
            %
            %   s = getRawLineData(obj,varargin)
            %
            %   Optional Inputs
            %   ---------------
            %   Fields from big_plot.raw_line_data_options
            %       .
            %   Outputs
            %   -------
            %   s : big_plot.raw_line_data
            %
            %   See Also
            %   --------
            %   big_plot.getRawLineData
            %
            %   Example
            %   -------
            %   %Get the raw data from 10 to 20 seconds
            %   s = obj.getRawLineData('xlim',[10 20])
            
            %Push creation to the raw_line_data class
            s = big_plot.raw_line_data.fromStreamingData(obj,varargin{:});
        end
        function addData(obj,new_data)
            %
            %   addData(obj,new_data)
            %
            
            I = obj.n_add_events + 1;
            obj.n_add_events = I;
            h_tic = tic;
            
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
                obj.n_grow_events = obj.n_grow_events + 1;
            end
            
            start_I = obj.n_samples+1;
            start_time = obj.getTimesFromIndices(start_I);
            end_I = n_samples_total;
            
            obj.y(start_I:end_I) = new_data;
            
            obj.n_samples = end_I;
            
            h__processSmall(obj)
            
            %The callback isn't valid until the data has
            %been added to the big_plot class.
            if ~isempty(obj.data_added_callback)
                obj.data_added_callback(start_time);
            end
            obj.t_add = obj.t_add + toc(h_tic);
        end
    end
    
    %----------------------------------------------------------------------
    %              Methods called by other parts of the package
    %----------------------------------------------------------------------
    methods
        function r = getDataReduction(obj,x_limits,axis_width_in_pixels)
            %
            %   r = getDataReduction(obj,x_limits,axis_width_in_pixels)
            %
            %   This method is called by the renderer to get the data to
            %   actually plot.
            
            h_tic = tic;
            t_end = obj.getTimesFromIndices(obj.n_samples);
            
            %Get x indices
            %-----------------------------------------
            if any(isinf(x_limits))
                x1 = 1;
                x2 = obj.n_samples;
                x1_small = 1;
                x2_small = obj.I_small_all;
            else
                %Get samples from times ------------
                t1 = x_limits(1);
                t2 = x_limits(2);
                x1 = obj.getIndicesFromTimes(t1);
                x2 = obj.getIndicesFromTimes(t2);
                
                %Limit samples based on the data --------------
                if x1 < 1
                    x1 = 1;
                end
                if x2 > obj.n_samples
                    x2 = obj.n_samples;
                end
                
                %Get the corresonding small samples ---------------
                x1_small = obj.getIndicesFromTimes(t1,true);
                x2_small = obj.getIndicesFromTimes(t2,true);
                
                if x1_small < 1
                    x1_small = 1;
                end
                if x2_small > obj.I_small_all
                    x2_small = obj.I_small_all;
                end
            end
            
            %Get info for data retrieval
            %----------------------------------------------------
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
            
            %The actual data reduction
            %-------------------------------------------------------
            n_y_samples = end_I - start_I + 1;
            samples_per_chunk = ceil(n_y_samples/axis_width_in_pixels);
            
            h_tic2 = tic;
            y_reduced = big_plot.reduceToWidth_mex(data,samples_per_chunk,start_I,end_I);
            mex_time = toc(h_tic2);
            
            if ~isempty(obj.m)
                y_reduced = h__calibrateData(y_reduced,obj);
            end
            
            n_y_reduced = length(y_reduced);
            x_reduced = [0 linspace(t1,t2,n_y_reduced-2) t_end]';
            
            %Population of the output
            %--------------------------------------------------------
            r = big_plot.xy_reduction;
            r.y_reduced = y_reduced(2:end-1);
            r.x_reduced = x_reduced(2:end-1);
            
            %This is needed for performance monitoring
            r.range_I  = [x1 x2];
            r.mex_time = mex_time;
            
            obj.t_reduce = obj.t_reduce + toc(h_tic);
            
        end
        function [data,info] = getRawData(obj,varargin)
            %
            %   [data,info] = getRawData(obj,varargin)
            %
            %   Optional Inputs
            %   ---------------
            %   xlim : [min_time max_time]
            %   get_calibrated : logical (default true)
            %       If true, returns calibrated data when available. The 
            %       raw data are returned when false or when no calibration
            %       has been set.
            %
            %   Outputs
            %   -------
            %   data :
            %   info : struct
            %       .x1
            %       .x2
            %       .is_calibrated
            %       .calibrated_available
            
            in.xlim = [];
            in.get_calibrated = true;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            if isempty(in.xlim)
                data = obj.y(1:obj.n_samples);
                I = [1 obj.n_samples];
            else
                I = obj.getIndicesFromTimes(xlim);
                if I(1) < 1
                    I = 1;
                end
                if I(2) > obj.n_samples
                    I(2) = obj.n_samples;
                end
                data = obj.y(I(1):I(2));
            end
            
            if obj.calibrated_available && in.get_calibrated
            	used_calibrated = true;
             	data = h__calibrateData(data,obj);
            else
                used_calibrated = false;
            end
            
            if nargout == 2
               info = struct;
               info.x1 = I(1);
               info.x2 = I(2);
               info.is_calibrated = used_calibrated;
               info.calibrated_available = obj.calibrated_available;
            end
        end
        function min_time_duration = getMinDurationSmall(obj,axis_width_in_pixels)
            %
            %   min_time_duration = getMinDurationSmall(obj,axis_width_in_pixels)
            %
            %  TODO: Add documentation
            
            if nargin == 1
                axis_width_in_pixels = 4000;
            end
            
            n_samples_small_min = 2*axis_width_in_pixels;
            min_time_duration = n_samples_small_min*obj.dt_small;
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
        function time_array = getTimeArray(obj,varargin)
            
            in.start_index = 1;
            in.end_index = obj.n_samples;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            I1 = in.start_index - 1;
            I2 = in.end_index - 1;
            
            time_array = ((I1:I2)*obj.dt)';
            %time_array = h__getTimeScaled(obj,time_array);
        end
        
    end
end

function calibrated_data = h__calibrateData(data,obj)
    calibrated_data = double(data).*obj.m + obj.b;
end

function h__processSmall(obj)


n_samples_small_total = ceil(obj.n_samples/obj.downsample_amount)*2;

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
min_max_data = big_plot.reduceToWidth_mex(obj.y,obj.downsample_amount,start_I,end_I);

out_start_I = obj.I_small_complete + 1;
out_end_I = ceil(end_I/obj.downsample_amount)*2;

%For right now anytime we get a subset of the data the mex code pads
%with the first and the last sample. Thus we ignore those values
%when doing the assigment.
obj.y_small(out_start_I:out_end_I) = min_max_data(2:end-1);

obj.I_small_all = out_end_I;

obj.n_samples_processed = floor(obj.n_samples/obj.downsample_amount)*obj.downsample_amount;
obj.I_small_complete = 2*floor(obj.n_samples/obj.downsample_amount);

%{
    subplot(1,2,1)
    plot(obj.y(1:obj.n_samples))
    subplot(1,2,2)
    plot(obj.y_small(1:out_end_I))
    
%}

end

