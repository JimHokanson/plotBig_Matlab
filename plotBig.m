function varargout = plotBig(y,varargin)
%
%   Inputs
%   ------
%   y : [samples x chans]
%       The data to plot.
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
%   n = 1e8;
%   t = linspace(0,100,n);    
%   y = (cos(0.43 * t) + 0.001 * t .* randn(1, n));
%   y = y';
%   plotBig(y,'x',t)

in.x = [];
in.dt = [];
in.t0 = 0;
in = big_plot.sl.in.processVarargin(in,varargin);

if ~isempty(in.dt)
    n_samples = size(y,1);
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