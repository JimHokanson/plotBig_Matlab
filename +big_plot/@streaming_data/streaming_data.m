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
    %
    %   Documentation at streaming_data.md
    %
    %   Purpose
    %   -------
    %   This class facilitates fast plotting of line data where the number
    %   of samples increases over time. This case was specifically written
    %   to handle plotting of DAQ data as it is acquired over time.
    %
    %   Features
    %   --------
    %   1) Preallocated memory to avoid memory reallocation when acquiring
    %   more data.
    %   2) Data are downsampled on acquisition for faster plotting of large
    %   regions of data, particularly when scrolling.
    %   3) Optional calibration for scaling of acquired data when plotting.
    %
    %   Constructor Info
    %   ---------------------------
    %
    %     Calling Form
    %     ------------
    %
    %     obj = big_plot.streaming_data(dt,n_samples_init,varargin)
    %
    %     Inputs
    %     ------
    %     dt : scalar
    %         Time between samples, inverse of the sampling rate.
    %     n_samples_init :
    %         Number of samples to initialize. This should generally be a
    %         reasonable estimate of the number of samples that will be
    %         collected. Every time the length of data acquired is exceeded
    %         the array is resized.
    %
    %
    %     Optional Inputs
    %     ---------------
    %     m : scalar
    %         Slope for calibration
    %     b :
    %         Offset for calibration
    %     t0 : default 0
    %       Start time of the time-series
    %     initial_data : default []
    %         Data that has already been collected.
    %     data_type : default 'double'
    %         If initial_data is passed in, then the data type
    %         is based on the initial data. Otherwise this can be
    %         used to preallocate data of the correct type.
    %     growth_rate : default 2
    %         When we run out of space for new samples this is specifies
    %         how many more samples we preallocate. '2' means that we
    %         double the amount of preallocated memory.
    %         TODO: Describe behavior when amount to add exceeds size
    %         following growth
    %     downsample_amount : default 200
    %         Number of samples to use when generating a pair of
    %         min-max values in the "small" dataset. Downsampling is done
    %         based on the small dataset at sufficient zoom out levels and
    %         only on the original datset at high zoom levels.
    %           The default value means that every 200 samples we
    %         generate a single min-max pair for the small dataset. This
    %         thus has an overhead of 1% of the original data.
    %
    
    
    
    properties
        name
        
        %This is a property that any class wishing to contain both x and y
        %data for big_plot should have.
        %
        %Note: This design is not well flushed out. The idea was that
        %anyone could implement an xy class.
        is_xy = true
        
        %Values for calibration:
        %
        %   output = m*data + b
        %
        %  By making this dynamic we can change calibrations as needed
        %  without having the original data change.
        m
        b
        
        
        y  %raw data, overallocated
        %JAH: Do we specify row or column shape?
        dt %dt of the raw data
        t0 %start time
        
        %Design Note:
        %------------
        %The idea is that for really large data, we precompute min and max
        %values so that determining what samples to plot is quicker.
        %
        %i.e. Let's say we have the following data:
        %   1 10 3 4 5 8 9 -3 5 2 5 9  3 2 6 8
        %
        %  Then the general idea is that, for example, given 10 and 9
        %  the other values will never be local maxima.
        %
        y_small %downsampled data, also overallocated
        %Data is downsampled by taking min and max of a chunk of data
        dt_small %dt of the downsampled data
        
        
        %How many original samples are required to generate a min/max
        %pair of small data
        downsample_amount
        
        n_samples = 0
        
        %When preallocated data is exceeded, this is a multiplier on how
        %much we expand the data. 1 would mean no growth. 2 would mean
        %that we double the amount of data allocated.
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
        
        %Populated by big_plot when plotting.
        %These callbacks get called by this class when:
        data_added_callback  %data has been added to this class
        calibration_callback %the data has been calibrated
        
        
        calibrated_since_render %flag indicating whether data has been 
        %calibrated since the last render call. This helps us to know
        %that we need to rerender even if the x-limits haven't changed.
        new_data_since_render %another flag that is useful for considering
        %whether or not to rerender. Technically this could be improved
        %to provide a range of added data so that we don't rerender with
        %only old data
        
        rendered_x_I = [NaN NaN]
        last_render_small = false
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
        %TODO: Document this
        n_add_events = 0
        n_grow_events = 0
        
        t_add = 0 %For some reason this can be really really high ...
        
        t_reduce = 0
        
        n_small_reduce = 0
        n_regular_reduce = 0
    end
    
    methods
        function obj = streaming_data(dt,n_samples_init,varargin)
            %
            %   obj = big_plot.streaming_data(dt,n_samples_init,varargin)
            %
            %   See class documentation at top
            %
            %   Improvements
            %   ------------
            %   1) Allow disabling the downsampled array for performance
            %   comparisons
            
            %Optional Input Defaults
            %------------------------
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
                if length(in.initial_data) == n_samples_init
                    obj.y = in.initial_data;
                    if size(obj.y,1) == 1
                        obj.y = obj.y';
                    end
                elseif length(in.initial_data) > n_samples_init
                    error('Initial data is larger than the # of samples to initialize')
                else
                    obj.y = zeros(n_samples_init,1,in.data_type);
                    obj.y(1:length(in.initial_data)) = in.initial_data;
                end
                obj.n_samples = length(in.initial_data);
            else
                obj.y = zeros(n_samples_init,1,in.data_type);
            end
            
            %TODO: Base this on above and downsampling ...
            n_samples_small = ceil(n_samples_init/in.downsample_amount*2);
            obj.y_small = zeros(n_samples_small,1,in.data_type);
            
            if ~isempty(in.initial_data)
                h__processSmall(obj)
            end
        end
    end
    
    %----------------------------------------------------------------------
    %                       Public methods for users
    %----------------------------------------------------------------------
    methods
        function setCalibration(obj,m_or_c,b)
            %
            %   Calling Forms
            %   -------------
            %   setCalibration(obj,calibration)
            %
            %   setCalibration(obj,m,b)
            %
            %   Inputs
            %   ------
            %   calibration : struct or object with fields:
            %       - m
            %       - b
            %   m :
            %   b :
            
            if isstruct(m_or_c)
                calibration = m_or_c;
                obj.m = calibration.m;
                obj.b = calibration.b;
            else
                obj.m = m_or_c;
                obj.b = b;
            end
            
            obj.calibrated_since_render = true;
            
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
            %       Returns a class which has access to the underlying
            %       data. This class returns only the populated data, NOT
            %       the allocated data, so some memory allocation is done
            %       by this call.
            %
            %   See Also
            %   --------
            %   big_plot.getRawLineData
            %
            %   Example
            %   -------
            %   %Get the raw data from 10 to 20 seconds
            %   s = obj.getRawLineData('xlim',[10 20])
            %   => s.y_raw
            
            %Push creation to the raw_line_data class
            s = big_plot.raw_line_data.fromStreamingData(obj,varargin{:});
        end
        function addData(obj,new_data)
            %
            %   addData(obj,new_data)
            %
            
            obj.new_data_since_render = true;
            
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
                
                %This might be better as two steps for timers ...
                %temp = obj.y;
                %obj.y = zeros()
                %obj.y(1:length(temp)) = temp;
                %clear(temp)
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
            %been added to the big_plot class (i.e. until we try and plot
            %it)
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
        function r = checkRedrawCase(obj,new_x_limits)
            
            if obj.new_data_since_render || obj.calibrated_since_render
                r = big_plot.render_info.RECOMPUTE_DATA_FOR_PLOTTING;
            else
                
                I = obj.getClosestIndicesFromTimePair(new_x_limits,obj.last_render_small);
                
                if isequal(obj.rendered_x_I,I)
                    r = big_plot.render_info.NO_CHANGE;
                else
                    r = big_plot.render_info.RECOMPUTE_DATA_FOR_PLOTTING;
                end
            end
            
            
            %calibrated_since_render
            %new_data_since_render
            
            %- we won't reset to original, this is difficult to do
            %- we could decide to do nothing new (use above properties)
            % big_plot.render_info
            %
            %           NO_CHANGE = 0
            %RESET_TO_ORIGINAL = 1
            %RECOMPUTE_DATA_FOR_PLOTTING = 2
            
        end
        function r = getDataReduction(obj,x_limits,axis_width_in_pixels)
            %
            %   r = getDataReduction(obj,x_limits,axis_width_in_pixels)
            %
            %   This method is called by the renderer to get the data to
            %   actually plot.
            
            h_tic = tic;
            
            obj.new_data_since_render = false;
            obj.calibrated_since_render = false;
            
            
            t_end = obj.getTimesFromIndices(obj.n_samples);
            
            xI = obj.getClosestIndicesFromTimePair(x_limits);
            xI_small = obj.getClosestIndicesFromTimePair(x_limits,true);
            
            x1 = xI(1);
            x2 = xI(2);
            x1_small = xI_small(1);
            x2_small = xI_small(2);
            
            
            %Get info for data retrieval
            %----------------------------------------------------
            if x2_small - x1_small > 2*axis_width_in_pixels
                obj.last_render_small = true;
                %If we have a sufficient amount of small data then
                %we reduce the small data, not the original data
                start_I = x1_small;
                end_I = x2_small;
                data = obj.y_small;
                %Note we need to update time as we might have zoomed
                %past our data ...
                t1 = obj.getTimesFromIndices(x1_small,true);
                t2 = obj.getTimesFromIndices(x2_small,true);
                obj.rendered_x_I = xI_small;
                obj.n_small_reduce = obj.n_small_reduce + 1;
            else
                obj.last_render_small = false;
                start_I = x1;
                end_I = x2;
                data = obj.y;
                t1 = obj.getTimesFromIndices(x1);
                t2 = obj.getTimesFromIndices(x2);
                obj.rendered_x_I = xI;
                obj.n_regular_reduce = obj.n_regular_reduce + 1;
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
                I = obj.getIndicesFromTimes(in.xlim);
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
        function I = getClosestIndicesFromTimePair(obj,times,use_small)
            %
            %   I = getClosestIndicesFromTimePair(obj,times,*use_small)
            %
            
            if nargin == 2
                use_small = false;
            end
            
            if length(times) ~= 2
                error('Code error, times input must have length of 2')
            end

            if use_small
                I = obj.getIndicesFromTimes(times,true);
                if I(1) < 1
                    I(1) = 1;
                end
                if I(2) > obj.I_small_all
                    I(2) = obj.I_small_all;
                end
            else
                I = obj.getIndicesFromTimes(times,false);
                if I(1) < 1
                    I(1) = 1;
                end
                if I(2) > obj.n_samples
                    I(2) = obj.n_samples;
                end
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
            %
            %   indices = getIndicesFromTimes(obj,times,use_small)
            %
            
            if nargin == 2
                use_small = false;
            end
            if use_small
                indices = times./obj.dt_small + 1;
            else
                indices = times./obj.dt + 1;
            end
            indices = round(indices);
        end
        function times = getTimesFromIndices(obj,indices,use_small)
            %
            %   times = getTimesFromIndices(obj,indices,use_small)
            %
            %   Inputs
            %   ------
            %   indices : generally of length 2
            %       For the specified indices returns their values as
            %       times. No effort is made to keep the indices in a valid
            %       range.
            %
            %   See Also
            %   --------
            %   getClosestIndicesFromTimePair
            %   getIndicesFromTimes
            
            if nargin == 2
                use_small = false;
            end
            if use_small
                times = (indices-1).*obj.dt_small;
            else
                times = (indices-1).*obj.dt;
            end
        end
        function time_array = getTimeArray(obj,varargin)
            %
            %   time_array = getTimeArray(obj,varargin)
            %
            %   Optional Inputs
            %   ---------------
            %   start_index : (default 1)
            %   end_index : (default n_samples)
            
            in.start_index = 1;
            in.end_index = obj.n_samples;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            I1 = in.start_index - 1;
            I2 = in.end_index - 1;
            
            time_array = (((I1:I2)*obj.dt)') + obj.t0;
        end
    end
end

function calibrated_data = h__calibrateData(data,obj)
calibrated_data = double(data).*obj.m + obj.b;
end

function h__processSmall(obj)
%
%
%


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
try
    obj.y_small(out_start_I:out_end_I) = min_max_data(2:end-1);
catch
    %The above can fail if we allocate the same size as the initial
    %amount of data
    obj.y_small(out_start_I:out_end_I) = min_max_data;
end

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

