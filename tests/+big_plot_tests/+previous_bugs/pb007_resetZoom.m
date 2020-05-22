function pb007_resetZoom()

%This may need to change ...
%https://github.com/JimHokanson/plotBig_Matlab/issues/26
%
%   Currently I'm testing what might be a different bug ... that datetimes
%   would barf if you went out of bounds on the plot
%
%   

dt = 0.01;
n = 1e7;
%n = 5000; %Test short plotting
x = 0:dt:(n-1)*dt;
y = sin(2*pi*x)+rand(1,length(x));
t = big_plot.datetime(dt,n,'start_datetime',datetime);
plotBig(t,y)
drawnow()

xlim = get(gca,'xlim');

pause(3)

%zoom to the right

set(gca,'xlim',[datetime+days(4) datetime+days(5)]);
title('to the right');
drawnow()

pause(3)

set(gca,'xlim',[datetime-days(5) datetime-days(4)]);
title('to the left');
drawnow()

pause(3)

set(gca,'xlim',xlim)
title('reset')


end