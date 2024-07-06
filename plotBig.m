function varargout = plotBig(varargin)
%x Wrapper for big_plot class
%
%   Provides simple access to the most common usage of the big_plot class.
%
%   Calling Forms
%   -------------
%   1) As a replacement for plot()
%   
%       h = plotBig(x,y)
%       h = plotBig(y)
%       h = plotBig(ax,...)
%       etc.
%
%   2) Build time from options
%
%       h = plotBig(y,'x',x_data)
%       h = plotBig(y,'dt',0.01,varargin)
%
%   Inputs
%   ------
%   y : [samples x chans]
%       The data to plot.
%
%   Outputs
%   -------
%   h : [line handles]
%   p : big_plot object
%
%
%   Optional Inputs
%   ---------------
%   axes : 
%       Specify which axes to plot into. This is only needed for the 
%       calling form in which the time is built bas
%       
%   x : [samples x 1] or [1 x samples]
%       Currently differing times for each y input are not supported.
%   dt : scalar
%       The time difference between two samples, i.e. 1/(sampling_rate)
%   fs : scalar
%       Sampling rate
%   t0 : numeric
%       Starting time.
%   obj: logical (default false)
%       If true the underlying big_plot class is returned
%
%   Examples
%   --------
%   1)
%       n = 1e8;
%       t_end = 100;
%       dt = t_end/(n-1);
%       t = 0:dt:t_end;
%       y = (cos(0.43 * t) + 0.001 * t .* randn(1, n));
%       y = y';
%       plotBig(y,'x',t)
%
%   2)  This is a quicker version 
%       plotBig(y,'dt',dt)
%
%   3)  Move the start time to 5
%       plotBig(y,'dt',dt,'t0',5)
%
%   4)  Plotting with datetime units ...
%       plotBig(y,'dt',seconds(dt),'t0',datetime('now'))
%
%   5)  Plotting with duration only
%       plotBig(y,'dt',seconds(dt))
%       
%   See Also
%   --------
%   big_plot

%Varargin parsing
%-------------------
direct_inputs_to_big_plot = true;
delete_mask = false(1,nargin);
s_in = struct;
for i = 1:(nargin-1)
    if ischar(varargin{i})
        option_string = varargin{i};
        if any(strcmp(option_string,{'axes','debug','x','dt','t0','obj','fs'}))
            direct_inputs_to_big_plot = false;
            s_in.(option_string) = varargin{i+1};
            delete_mask(i:i+1) = true;
        end
    end
end

%Shortcut exit for direct call to big_plot
%------------------------------------------
%i.e. we had no optional inputs that are pertinent to this function
if direct_inputs_to_big_plot
    temp = big_plot(varargin{:});
    temp.renderData();
    if nargout
        varargout{1} = temp.h_and_l.h_lines_array;
        %varargout{1} = vertcat(all_lines{:});
    end
    return
end

%Processing of alternative call method
%--------------------------------------
varargin(delete_mask) = [];

%I don't know when we will have 2+ elemements
%and not have a numeric #2 but I'll leave this in place for now
if length(varargin) > 1 && isnumeric(varargin{2})
    x_temp = varargin{1};
    y = varargin{2};
    varargin(1:2) = [];
else
    x_temp = [];
    y = varargin{1};
    varargin(1) = [];
end

in.axes = [];
in.debug = false;
in.x = x_temp;
in.dt = [];
in.fs = [];
in.t0 = 0;
in.obj = false;
in = big_plot.sl.in.processVarargin(in,s_in);


if ~isempty(in.fs)
    in.dt = 1./in.fs;
end

%Calling forms to support
%---------------------------------------------------------
%TODO: Enumerate and discuss how they are covered below


%This is a mess and should be cleaned up
%-----------------------------------------
if isobject(y)
    if ~isempty(in.axes)
        temp = big_plot(in.axes,y);
    else
        temp = big_plot(y);
    end
    if in.debug
        temp.enableDebugging();
    end
    temp.renderData();
    if nargout
        if in.obj
            varargout{1} = temp;
        else
            all_lines = temp.h_and_l.h_plot;
            varargout{1} = vertcat(all_lines{:});
        end
    end
    return
end

%Define x based on time specs (if necessary)
%-------------------------------------------------------------------
n_samples = size(y,1);

%This may occur when the data should be transposed i.e. plotting y'
%When 'x' is provided, we can adjust y accordingly, but when only
%time info is provided, we can't resolve between 1 channel with many
%samples and many channels with 1 sample each.
if n_samples == 1 && isempty(in.x)
    error('Currently 1 sample per channel is not supported')
end

if ~isempty(in.dt)
    %If dt specified, assume no 'x' variable, create object
    if isa(in.t0,'datetime')
        x = big_plot.datetime(in.dt,n_samples,'start_datetime',in.t0);
    elseif isa(in.dt,'duration')
        x = big_plot.datetime(in.dt,n_samples,'start_offset',in.t0);
    else
        x = big_plot.time(in.dt,n_samples,'start_offset',in.t0);
    end
else
    %no x specified, use default of 1, like plot(y) => x  becomes 1:x
    x = in.x;
    if isempty(x)
        if isa(in.t0,'datetime')
            in.dt = 1;
            x = big_plot.datetime(in.dt,n_samples,'start_datetime',in.t0);
        else
            in.t0 = 1;
            in.dt = 1;
            x = big_plot.time(in.dt,n_samples,'start_offset',in.t0);
        end
    elseif isobject(x)
        if ~any(size(y) == x.n_samples)
            error('Mismatch in # of elements between x and y')
        end
    elseif ~any(size(y) == length(x))
        error('Mismatch in # of elements between x and y')
    end
end

%Setup of the big_plot class
%-----------------------------------------------------
if ~isempty(in.axes)
    temp = big_plot(in.axes,x,y,varargin{:});
else
    temp = big_plot(x,y,varargin{:});
end

%By calling plotBig (this function) we expect rendering to happen
%so we call it manually
if in.debug
    temp.enableDebugging();
end
temp.renderData();


%Output handling
%-------------------------------------------------------
if nargout
    if in.obj
        varargout{1} = temp;
    else
        all_lines = temp.h_and_l.h_line;
        varargout{1} = vertcat(all_lines{:});
    end
end

end