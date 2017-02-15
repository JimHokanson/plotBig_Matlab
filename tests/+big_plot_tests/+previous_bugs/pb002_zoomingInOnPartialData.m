function pb002_zoomingInOnPartialData()
%
%  I had an error where zooming in on partial data caused the extraction
%   of indices that didn't actually exist when going from a time to an
%   index in the time object
%
%   big_plot_tests.previous_bugs.pb002_zoomingInOnPartialData()

N = 1e7;
y = zeros(N,1);
step = 1/(N/10);
data = [0:step:1 1:-step:0];
mid_I = round(N/2);
min_I = mid_I - round(length(data)/2);
max_I = min_I + length(data)-1;
y(min_I:max_I) = data;

temp = cell(1,4);

close all
figure(1)
ax = gca;
temp{1} = plotBig(y,'dt',1,'t0',0);
% temp.id
hold(ax,'on')
temp{2} = plotBig(y,'dt',1,'t0',0.5*N,'axes',ax);
% temp.id
temp{3} = plotBig(y,'dt',1,'t0',1*N,'axes',ax);
% temp.id
temp{4} = plotBig(y,'dt',1,'t0',1.5*N,'axes',ax);
% temp.id
hold(ax,'off')
set(ax,'ylim',[0 2])
set(ax,'xlim',[0.8*N 2.3*N])

%Due to rounding with linspace, this is really hard to get right
%We'll just verify the last one ...
last_x_r_4 = temp{4}.render_info.last_x_r{1};
if last_x_r_4(end-1) > last_x_r_4(end)
   big_plot_tests.errors.ERROR_DETECTED(); 
end

end