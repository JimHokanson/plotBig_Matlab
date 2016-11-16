function rw001_edge_cases()
%
%   big_plot_tests.reduce_width.rw001_edge_cases()

%#ok<*TRYNC>  %Ok for no catches on try statements

%Incorrect # of arguments
%------------------------
try 
    big_plot.reduceToWidth()
    big_plot_tests.errors.ERROR_NOT_THROWN()
end

%XY mismatch
%-------------------------
%TODO: Need to throw an error - this shouldn't work ...
[xr,yr] = big_plot.reduceToWidth((5:100)',(1:1e7)',4000,[0 Inf]);

% r = rand(11000,4);
% big_plot.reduce_to_width()
% t = sci.time_series.time(0.01,11000);
% tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

