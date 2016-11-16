function e003_simpleLine()
%
%   big_plot_tests.examples.e003_simpleLine
%
%   

   y = 1:1e8+3457;
   x = y;
   x2 = sci.time_series.time(1,length(y));
   y2 = y - 1e7;
   
   tic
   plotBig(x,y,x2,y2);   
   toc

end
