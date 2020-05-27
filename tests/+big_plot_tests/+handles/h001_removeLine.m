function h001_removeLine()
%
%   Testing line removal ...
%
%   big_plot_tests.handles.h001_removeLine()

y = big_plot.example_data.getSinWithNoise(1e6,0.001,0.01,'double');

y2 = [y y+1 y+2];

p = plotBig(y2,'obj',true);

hl = p.h_and_l;

h_lines = hl.h_lines_array;

%Removal of the second plot
delete(h_lines(2));

%Does the listener work????

if hl.n_lines_active == 2
    fprintf('big_plot_tests.handles.h001_removeLine passed\n')
else
    error('line removal failed')
end

end