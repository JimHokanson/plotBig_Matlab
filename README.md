# Introduction

This code:
1) Speeds up time to plot data.
2) Speeds up time to plot after zooming.
3) Has support for plotting streaming data. See https://jimhokanson.com/blog/2019/2019_07_stream_plotting_matlab/

This code is based on an approach which I originally saw in the following code:
[matlab-plot-big](https://github.com/tuckermcclure/matlab-plot-big)

This code was written to be:
1) Faster than matlab-plot-big (see speed section below)
2) More memory efficient than matlab-plot-big (by supporting a time vector as t0 and dt)

## Speedup Approach

This code resamples the data such that only a maxima and minima are chosen within a given window. Given a limited # of pixels, it is the local maxima and minima that are visible. By plotting only a few thousand values, the speed of plotting is sped up significantly. When the axis limits are changed the code replots the data so that any fine details are not lost when zooming.

Speedups specific to this code:

1) For evenly sampled data we can downsample without looking at the x-data.
2) The code is written in C for speed.
3) The code uses OpenMP to run across multiple processors.
4) The code used SIMD intrinsics to further speedup computing within the processor.

A detailed examination of the speed of plotting for this code can be found at:
https://jimhokanson.com/blog/2018/2018_01_PlotBig_Matlab/

# Example Code

`plotBig` is the main access function. It should largely work the same as plot, but make plotting faster. Plotting with points instead of lines however will look funny.

```Matlab
n = 1e8;
t = linspace(0,1,n);
y = sin(25*(2*pi).*t) + t.*rand(1,n);

y = y'; %Note, 'y' must be a column vector or matrix where # of samples = # of rows

%Normal plotting, try resizing ...
tic
plot(t,y)
drawnow
toc

%This code, zoom in until the random data points are visible
tic
plotBig(t,y)
drawnow
toc

%Even better, in this case we don't even need the time array
%- this saves on memory!
%dt : time between samples
%t0 : start time
%NOTE: This version currently requires a column vector (i.e. samples per row)
plotBig(y,'dt',t(2)-t(1),'t0',0);

%Plotting with options
plotBig(t,y,'r','Linewidth',2);

plotBig(y,'dt',t(2)-t(1),'t0',0,'Color','r');

%Abstract time
dt = t(2)-t(1);
n_samples = n;
x = big_plot.time(dt,n_samples);

%Plotting but with abstract time
plotBig(x,y,'Color','r');

%Datetime support now available as well
%Note, datetime only supported with a special datetime object ...
(dt,n,'start_datetime',datetime);
dt = 10; %10 seconds
dt = minutes(0.1) % 0.1 minutes
cur_time = datetime(); %now as datetime
plotBig(y,'dt',dt,'t0',cur_time)



%TimeTable now supported:
%Note, this is all just to setup a timetable, but if you have one
%then you just need the last line
fprintf('\nCreating data\n')
n_samples = 1e8;
dt = 1/1e6;
sin_freq = 0.1;
data_type = 'single';
y = big_plot.example_data.getSinWithNoise(n_samples,dt,sin_freq,data_type);
sample_rate = 1/dt;
tt = timetable(y,'SampleRate', sample_rate);
fprintf('Done creating data, plotting\n')
h = tic;
plotBig(tt,'r');
drawnow()
fprintf('Done plotting, %0.2fs\n',toc(h));

h = tic;
plot(tt.Time,tt.Variables)
drawnow()
fprintf('Done plotting slow way, %0.2fs\n',toc(h));

```
# Streaming Data

This library also supports the ability to continuously add on data to a line plot, such as when data are being collected from a DAQ. This can be considered to be similar to Matlab's [animatedline](https://www.mathworks.com/help/matlab/ref/animatedline.html), but with much better performance.

The basic usage is as such:

```
fs = 20000;
n_samples_init = 1e7;
xy = big_plot.streaming_data(1/fs,n_samples_init);

%Setting up of the plot
subplot(2,1,2)
plotBig(xy)

%In a loop where we are getting more data ...
%This will update the plot with the new data
xy.addData(new_data)
```

More information can be found [here](documentation/streaming_data.md)

# Current Limitations

* Does not support non-evenly sampled data. This is currently low priority. (https://github.com/JimHokanson/plotBig_Matlab/issues/7)
* Will likely not work on older machines. The code needs to be recompiled for machines from around 2010 and before. 
* Does not properly render markers or NaN values. 

# Speed comparisons

The following is the time it took to render random data using 1) default Matlab, 2) Using the matlab-plot-big repo (mpb) and 3) this repo.

The speedups are perhaps a bit hard to really appreciate (for me at least). The main point of interest is that using this library render times are reasonable for a large number of points, rather than taking many seconds to render.

<p align="center"><img src="/documentation/speed1_double.png" alt="speed1_double" width="600"/></p>

The code also supports multiple data types. Smaller data types fit better into SIMD registers so you can get better speedups with smaller data types. This example shows int16 which could be useful for plotting DAQ data.

<p align="center"><img src="/documentation/speed1_int16.png" alt="speed1_int16" width="600"/></p>
