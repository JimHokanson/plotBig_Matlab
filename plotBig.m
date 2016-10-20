function varagout = plotBig(y,varargin)
%
%   Inputs
%   ------
%   
%   Optional Inputs
%   ---------------
%   
%   

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