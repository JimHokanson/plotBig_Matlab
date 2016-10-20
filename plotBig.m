function temp = plotBig(y,varargin)

in.x = [];
in.dt = [];
in.t0 = 0;
in = line_plot_reducer.sl.in.processVarargin(in,varargin);

if ~isempty(in.dt)
    n_samples = size(y,1);
    x = line_plot_reducer.time(in.dt,n_samples,'start_offset',in.t0);
else
    %TODO: Check that the length matches ...
    x = in.x;
end

temp = line_plot_reducer(x,y);
temp.renderData();

end