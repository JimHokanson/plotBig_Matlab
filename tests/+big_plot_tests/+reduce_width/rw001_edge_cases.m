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




