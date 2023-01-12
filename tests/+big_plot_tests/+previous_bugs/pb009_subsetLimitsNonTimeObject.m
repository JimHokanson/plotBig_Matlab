function pb009_subsetLimitsNonTimeObject()
%
%   big_plot_tests.previous_bugs.pb009_subsetLimitsNonTimeObject

%big_plot.reduceToWidth.h__getSampleMinMax
%
%How is x not an object, when does this occur?
%
%   Note sure how we got to the line in question without directly
%   calling the function.
%
%   https://github.com/JimHokanson/plotBig_Matlab/issues/30
%
%   Status: changed code as recommended to fix bug

%x = [1:0.001:500 1000:0.001:2000];
x = 1:0.001:1000;
y = x';

plotBig(x,y);

[x_reduced, y_reduced, s] = big_plot.reduceToWidth(x', y, 10000, [10 900],[1 10000]);


end