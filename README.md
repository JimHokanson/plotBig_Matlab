# Introduction

This code:
1) Speeds up time to plot data.
2) Speeds up time to plot after zooming.
3) Has support for plotting streaming data. (documentation needed)

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

# Example Code

```Matlab
n = 1e8;
t = linspace(0,1,n);
y = sin(25*(2*pi).*t) + t.*rand(1,n);

y = y';

%Normal plotting, try resizing ...
plot(t,y)

%This code
plotBig(t,y)

%Even better
plotBig(y,'dt',t(2)-t(1),'t0',0);
```
# Streaming Data

TODO: Add documentation


# Current Limitations

* Does not support non-evenly sampled data. This is currently low priority. (https://github.com/JimHokanson/plotBig_Matlab/issues/7)
* Only supports standard numerical times, not datetimes and the like.

# Speed comparisons

The following is the time it took to render random data using 1) default Matlab, 2) Using the matlab-plot-big repo (mpb) and 3) this repo.

The speedups are perhaps a bit hard to really appreciate (for me at least). The main point of interest is that using this library render times are reasonable for a large number of points, rather than taking many seconds to render.

<p align="center"><img src="/documentation/speed1_double.png" alt="speed1_double" width="600"/></p>

The code also supports multiple data types. Smaller data types fit better into SIMD registers so you can get better speedups with smaller data types. This example shows int16 which could be useful for plotting DAQ data. (JAH TODO: Support scaling after down-sampling the data - i.e. determining what to plot based on int16 but plotting of scaled data)

<p align="center"><img src="/documentation/speed1_int16.png" alt="speed1_int16" width="600"/></p>
