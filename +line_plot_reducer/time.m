classdef time < sl.obj.display_class
    %
    %   Class:
    %   sci.time_series.time
    %
    %   obj = sci.time_series.time(dt,n_samples)
    %
    %   This was initially created for plotting where I don't want to plot
    %   the entire data set so instead of holding onto a full time series
    %   I'm holding onto "instructions" as to how to construct the full
    %   time series.
    %
    %   I'm slowly working this into functions where I really only
    %   need some of the instructions on the time series, not the whole
    %   thing.
    %
    %   See Also:
    %   sci.time_series.data
    
    properties
        start_datetime %
        %This can be used for real dates to identify the
        %actual time of the first sample. No support for time zones is in
        %place.
        
        %These will always be in seconds, regardless of the output units
        start_offset = 0 %(s)
        dt %seconds
        
        n_samples
        
        output_units = 's'
        %This requires A LOT of work still
        %Options:
        %-   s: seconds
        %-  ms: milliseconds
        %- min: minutes
        %-   h: hours
        %
        %   See:
        %   h__getTimeScaled
    end
    
    properties (Dependent)
        fs
        
        %These values are relative, they don't include the 'start_datetime'
        %property. They DO however take into account the 'output_units'
        %property.
        end_time
        start_time
        elapsed_time
    end
    
    %Dependent Methods ----------------------------------------------------
    methods
        function set.output_units(obj,value)
           if ismember(value,{'h','hours','milliseconds','min','minutes','ms','s','seconds'})
              obj.output_units = value; 
           else
              error('Unable to change time to given units') 
           end 
        end
        function value = get.fs(obj)
            value = 1/obj.dt;
        end
        function value = get.end_time(obj)
            value = obj.start_offset + (obj.n_samples-1)*obj.dt;
            value = h__getTimeScaled(obj,value);
        end
        function value = get.start_time(obj)
            value = obj.start_offset;
            value = h__getTimeScaled(obj,value);
        end
        function value = get.elapsed_time(obj)
           value = obj.end_time - obj.start_time; 
        end
    end
    
    %Constructor Methods --------------------------------------------------
    methods
        function obj = time(dt,n_samples,varargin)
            %
            %   obj = sci.time_series.time(dt,n_samples)
            %
            %   Inputs:
            %   -------
            %   dt :
            %       Time between sample points.
            %   n_samples :
            %       # of samples in the data.
            %
            %   Optional Inputs:
            %   ----------------
            %   start_datetime : datenum
            %      Start of the data collection with date and time
            %      information.
            %   start_offset : (default 0)
            %       Normally this will be 0.
            %   sample_offset :
            %       This can be specified instead of "start_offset" in
            %       cases in which it is more natural to specify which
            %       sample is being used.
            %
            %   See Also:
            %   sci.time_series.time.getNewTimeForDataSubset
            
            if nargin == 0
                return
            end
            
            in.start_datetime = 0;
            in.start_offset   = [];
            in.sample_offset  = [];
            in = sl.in.processVarargin(in,varargin);
            
            if ~isempty(in.sample_offset)
                if ~isempty(in.start_offset)
                    error('Incorrect function usage, only start_offset or sample_offset may be specified, not both')
                end
                obj.start_offset = dt*(in.sample_offset-1);
            elseif ~isempty(in.start_offset)
                obj.start_offset = in.start_offset;
            else
                obj.start_offset = 0;
            end
            
            obj.start_datetime = in.start_datetime;
            obj.dt = dt;
            obj.n_samples = n_samples;
        end
        function new_objs = copy(objs,varargin)
            %
            %
            %   Optional Inputs:
            %   ----------------
            %   new_start_offset :
            
            in.new_start_offset = [];
            in = sl.in.processVarargin(in,varargin);
            
            if isempty(in.new_start_offset)
                start_offsets = [objs.start_offset];
            elseif length(in.new_start_offset) == 1
                start_offsets = repmat(in.new_start_offset,1,length(objs));
            else
                start_offsets = in.new_start_offset;
            end
                
            
            %x Creates a deep copy
            n_objs = length(objs);
            temp_ca = cell(1,n_objs);
            for iObj = 1:n_objs
                obj = objs(iObj);
                new_obj = sci.time_series.time(obj.dt,...
                    obj.n_samples,...
                    'start_datetime',obj.start_datetime,...
                    'start_offset',start_offsets(iObj));
                new_obj.output_units = obj.output_units;
                temp_ca{iObj} = new_obj;
            end
            new_objs = [temp_ca{:}];
        end
        function new_time_object = getNewTimeObjectForDataSubset(obj,start_sample,n_samples,varargin)
            %x Returns a new time object that only encompasses a subset of the original time
            %
            %   new_time_object = obj.getNewTimeObjectForDataSubset(start_sample,n_samples,varargin)
            %
            %   This can be used
            %
            %   Inputs:
            %   -------
            %   start_sample :
            %   n_samples :
            %
            %   Optional Inputs:
            %   ----------------
            %   first_sample_time : default (no change)
            %       The default behavior is to keep the time offset of the
            %       sample. For example, with a sampling rate of 1 and a
            %       start offset of 0, the 1st sample occurs at time 0 and
            %       the 2nd sample occurs at time 1. If we get a subset of
            %       data starting with the 2nd sample, the new start offset
            %       will be 1, such that the 2nd sample (now 1st) still
            %       occurs at time t = 1.
            %           We can however redefine the first_sample_time so
            %       that it occurs at any given time. The start_datetime
            %       property of the class is adjusted so that the actual
            %       absolute start time is maintained.
            
            in.first_sample_time = [];
            in = sl.in.processVarargin(in,varargin);
            
            first_sample_real_time = (start_sample-1)*obj.dt + obj.start_offset;
            
            if isempty(in.first_sample_time)
                start_offset   = first_sample_real_time; %#ok<PROP>
                start_datetime = obj.start_datetime; %#ok<PROP>
            else
                
                start_offset   = in.first_sample_time; %#ok<PROP>
                time_change    = first_sample_real_time - start_offset;%#ok<PROP>
                
                start_datetime = obj.start_datetime + h__secondsToDays(time_change);%#ok<PROP>
            end
            
            new_time_object = sci.time_series.time(...
                obj.dt,n_samples,...
                'start_offset',start_offset,... %#ok<PROP>
                'start_datetime',start_datetime);%#ok<PROP>
            new_time_object.output_units = obj.output_units;
        end
        function s_objs = export(objs)
           s_objs = sl.obj.toStruct(objs); 
        end
    end
    
    methods (Static)
    	function objs = fromStruct(s_objs)
            %
            %   objs = sci.time_series.time.fromStruct(s_objs)
            %
            %   Example:
            %       
            %      
            
            n_objs  = length(s_objs);
            temp_ca = cell(1,n_objs);
            
            for iObj = 1:n_objs
                obj = sci.time_series.time;
                sl.struct.toObject(obj,s_objs(iObj));
                temp_ca{iObj} = obj;
            end
            objs = [temp_ca{:}];
        end 
    end
    
    methods
% %         function n_samples = samplesPerTimeDuration(obj,time_duration)
% %            %
% %            %
% %            %
% %            
% %            n_samples = round(time_duration*obj.fs);
% %            
% %            
% %         end
        function changeOutputUnits(objs,new_units_value)
           %TODO: I don't know that this triggers the set function :/
           %So we should do the check here as well
           % => call the same function for both
           for iObj = 1:length(objs)
              objs(iObj).output_units = new_units_value; 
           end
        end
        function shiftStartTime(obj,start_dt)
           %x Shifts the start time
           %
           %    shiftStartTime(obj,start_dt)
           %
           %    This function also changes the start_datetime so that
           %    absolute time doesn't actually change, only the 
           %    'start_offset' (relative) time changes.
           %
           %    Inputs:
           %    -------
           %    start_dt : scalar
           %        Get's added to the start_offset.
           %    
           %        obj.start_offset = obj.start_offset + start_dt;
           
           obj.start_offset   = obj.start_offset + start_dt;
           
           %
           %
           %    Samples:
           %    
           %    1 2 3 4 5 <= samples
           %    0 1 2 3 4 <= time
           %
           
           %TODO: Do we want + or - ????
           obj.start_datetime = obj.start_datetime + h__secondsToDays(start_dt);
        end
    end
    
    %Raw data and index methods -------------------------------------------
    methods
        function time_array = getTimeArray(obj)
            %x Creates the full time array.
            %
            %    In general this should be avoided if possible.
            %
            %   Outputs:
            %   --------
            %   time_array : array
            %       Size is [n x 1].
            %
            %   See Also:
            %   getTimesFromIndices
            
            time_array = ((0:obj.n_samples-1)*obj.dt + obj.start_offset)';
            time_array = h__getTimeScaled(obj,time_array);
        end
        function times = getTimesFromIndices(obj,indices)
            %x Given sample indices return times of these indices (in seconds)
            %
            %    This is useful for plotting when we need to go from an
            %    abstract representation of the time to actual time values
            %    that are associated with each data point. NOTE: Ideally
            %    plotting functions would actually support this abstract
            %    notion of time as well.
            %
            %    Outputs:
            %    --------
            %    times : array
            %       Time taking into account:
            %           - start_offset
            %           - dt
            %
            %    Inputs:
            %    -------
            %    indices:
            %        Indices into the "time array". An input value of 1 will
            %        return a value of the start_offset and a value of 2
            %        will represent a value of the start_offset + dt.
            %
            %
            times = obj.start_offset + (indices-1)*obj.dt;
            times = h__getTimeScaled(obj,times);
        end        
        function [indices,time_errors] = getNearestIndices(obj,times)
            %x Given a set of times, return the closest indices
            %
            %   TODO: Document ...
            %
            %   Inputs:
            %   -------
            %   times:
            %
            %   Outputs:
            %   --------
            %   indices :
            %   time_errors :
            %
            %   Improvements:
            %   -------------
            %   1) Handle out of range data - somehow
            %   2) Provide rounding options - expansive, contractive, or
            %   nearest
            
            
            times = h__unscaleTime(obj,times);
            
            raw_indices = (times - obj.start_offset)./obj.dt;
            indices = round(raw_indices)+1;
            if nargout == 2
                time_errors = (indices - (raw_indices + 1))*obj.dt;
            end
        end
    end
    
end

function days = h__secondsToDays(seconds)
   days = seconds/86400;
end

%TODO: Document these functions
%This should all be moved to sci.units ...
function times_scaled = h__getTimeScaled(obj,times)
scale_factor = h__getTimeScaleFactor(obj.output_units,true);
if scale_factor == 1
    times_scaled = times;
else
    times_scaled = times*scale_factor;
end
end

function unscaled_times = h__unscaleTime(obj,times)
scale_factor = h__getTimeScaleFactor(obj.output_units,false);
if scale_factor == 1
    unscaled_times = times;
else
    unscaled_times = times*scale_factor;
end
end

function scale_factor = h__getTimeScaleFactor(unit_name,for_output)
switch unit_name
    case {'s','seconds'}
        scale_factor = 1;
    case {'ms','milliseconds'}
        scale_factor = 1000;
    case {'min','minutes'}
        scale_factor = 1/60;
    case {'h','hours'}
        scale_factor = 1/3600;
    otherwise
        error('Unrecognized time unit: %s',unit_name)
end
if ~for_output
    scale_factor = 1/scale_factor;
end
end

