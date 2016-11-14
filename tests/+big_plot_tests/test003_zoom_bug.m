function test003_zoom_bug()
%
%  This has been fixed ...
%

N = 1e7;
y = zeros(N,1);
step = 1/(N/10);
data = [0:step:1 1:-step:0];
mid_I = round(N/2);
min_I = mid_I - round(length(data)/2);
max_I = min_I + length(data)-1;
y(min_I:max_I) = data;

close all
figure(1)
ax = gca;
temp = plotBig(y,'dt',1,'t0',0);
% temp.id
hold(ax,'on')
temp = plotBig(y,'dt',1,'t0',round(5*N/10),'axes',ax);
% temp.id
temp = plotBig(y,'dt',1,'t0',round(10*N/10),'axes',ax);
% temp.id
temp = plotBig(y,'dt',1,'t0',round(15*N/10),'axes',ax);
% temp.id
hold(ax,'off')
set(ax,'ylim',[0 2])
% pause(2)
%We will have some extra figures from the axis enlarging, close these
% set(ax,'xlim',[0.8*N 2.3*N])

end