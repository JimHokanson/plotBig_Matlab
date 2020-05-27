classdef datetime < big_plot.time
    %
    %   Class:
    %   big_plot.datetime
    
    
    %{
    dt = 0.01;
    n = 1e7;
    %n = 5000; %Test short plotting
    x = 0:dt:(n-1)*dt;
    y = sin(2*pi*x)+rand(1,length(x));
    t = big_plot.datetime(dt,n,'start_datetime',datetime);
    plotBig(t,y)
    
    %Making sure my original code works!
    plotBig(x,y)
    
    %How this would look without my code ...
    t2 = datetime + duration(0,0,x);
    plot(t2,y)
    %}
    
    properties
        
    end
    
    methods
        %TODO: Create constructor that calls parent
        %then check for start_datetime and for start offset to not
        %be valid
        function obj = datetime(varargin)
            obj@big_plot.time(varargin{:});
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
                                
            %duration(h,m,s)
            times = obj.start_datetime + duration(0,0,(indices-1)*obj.dt);
            
            %TODO: Is this going to be datetime values or numeric values?
            
            %TODO: Throw an error if any of the indices are out of range
            %Assume ordered ????
            %This will slow things down ... :/
            
            %times = obj.start_offset + (indices-1)*obj.dt;
            %times = h__getTimeScaled(obj,times);
        end       
        function time_array = getTimeArray(obj,varargin)
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
            
            %keyboard
            %return datetime elements instead ...
            
            in.start_index = 1;
            in.end_index = obj.n_samples;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            indices = (in.start_index-1):(in.end_index-1);
            
            time_array = obj.start_datetime + duration(0,0,(indices)*obj.dt);
            
%             time_array = ((I1:I2)*obj.dt + obj.start_offset)';
%             time_array = h__getTimeScaled(obj,time_array); 
        end
    end
end

