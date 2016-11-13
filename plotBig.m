function varargout = plotBig(varargin)
%
%   Calling Forms
%   -------------
%   h = plot(x,y)
%   h = plot(y)
%   h = plot(ax,...)
%   etc.
%   p = 
%   
%   
%   plot_obj = plotBig
%
%   Inputs
%   ------
%   y : [samples x chans]
%       The data to plot.
%
%   Outputs
%   -------
%   h : line handle
%   p : big_plot
%       
%
%   Optional Inputs
%   ---------------
%   x : [samples x 1] or [1 x samples]
%       Currently differing times for each y input are not supported.
%   dt : scalar
%       The time difference between two samples, i.e. 1/(sampling_rate)
%   t0 : starting time
%
%   Examples
%   --------
%   1) 
%   n = 1e8;
%   t_end = 100;
%   dt = t_end/(n-1);
%   t = 0:dt:t_end;   
%   y = (cos(0.43 * t) + 0.001 * t .* randn(1, n));
%   y = y';
%   plotBig(y,'x',t)
%   %or better
%   plotBig(y,'dt',dt)

%Varargin parsing
%-------------------

if nargin == 1
    direct_inputs_to_big_plot = true;
elseif ischar(varargin{2})
    %TODO: Check for fieldnames from below
    direct_inputs_to_big_plot = false;
    y = varargin{1};
    varargin = varargin(2:end);
end

if direct_inputs_to_big_plot
    
end

in.x = [];
in.dt = [];
in.t0 = 0;
in.obj = true;
in = big_plot.sl.in.processVarargin(in,varargin);

if ~isempty(in.dt)
    
    n_samples = size(y,1);
    if n_samples == 1
       error('Currently 1 sample per channel is not supported') 
    end
    
    x = big_plot.time(in.dt,n_samples,'start_offset',in.t0);
else
    %TODO: Check that the length matches ...
    x = in.x;
end

temp = big_plot(x,y);
temp.renderData();

if nargout
   varargout{1} = temp; 
end

end