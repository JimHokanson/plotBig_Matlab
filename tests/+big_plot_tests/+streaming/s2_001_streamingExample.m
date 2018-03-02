function s2_001_streamingExample()
%{
    big_plot_tests.streaming.s2_001_streamingExample()
%}
clf
%Options -------------
fs = 10000;
n_seconds_plot = 2000
win_width_s = 200;

dt = 1/fs;

%was 1e6 and 20000
%xy = big_plot.streaming_data(dt,32000000);
xy = big_plot.streaming_data(dt,1e6);

fh = @(t) 0.002.*t.*sin(0.2*t);

o = plotBig(xy,'obj',true);

%Generally with streaming we'll use a fixed y-limit
set(gca,'ylim',[-5 5])
set(gca,'xlim',[0 win_width_s])

%Generating random data is slow so we'll add the same random data
%to all chunks. This allows us to zoom in and see the individual
%samples
r = 0.1*rand(1,fs);
t1 = tic;
t_draw = 0;
for i = 0:n_seconds_plot-1
    t3 = tic;
    t = i:dt:(i+1-dt);
    
    y = fh(t)+r;
    xy.addData(y');
    if i > win_width_s
        set(gca,'xlim',[i-win_width_s i])
    end
    h_tic2 = tic;
    drawnow
    t_draw = t_draw + toc(h_tic2);
end
toc(t1)

if false
%Animated Line for comparison
%-----------------------------------
clf
%Animated line requires preallocating everything
h = animatedline('MaximumNumPoints',n_seconds_plot*fs);
set(gca,'ylim',[-5 5])
set(gca,'xlim',[0 win_width_s])

t1 = tic;
t_add = 0;
t_draw = 0;
for i = 0:n_seconds_plot-1
    t = i:dt:(i+1-dt);

    y = fh(t)+r;
    addpoints(h,t,y);
    if i > win_width_s
        set(gca,'xlim',[i-win_width_s i])
    end
    h_tic2 = tic;
    drawnow
    t_draw = t_draw + toc(h_tic2);
end
toc(t1)
end

end