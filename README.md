# Introduction

This code makes plotting line plots in Matlab much faster.
Zooming is also much faster. This code is based on 
[matlab-plot-big](https://github.com/tuckermcclure/matlab-plot-big)

"matlab-plot-big" was the best FEX submission on this topic. This code
was written to be faster and more memory efficient.

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

#Approach

This code resamples the data such that only a maxima and minima are chosen
within a given window. Given a limited # of pixels, it is the local maxima
and minima that are visible. By plotting only a few thousand values, the 
speed of plotting is sped up significantly. When the axis limits are 
changed the code replots the data so that any fine details are not lost
when zooming.

#Current Limitations

* Supports double data only (https://github.com/JimHokanson/plotBig_Matlab/issues/6)
* Does not support non-evenly sampled data (https://github.com/JimHokanson/plotBig_Matlab/issues/7)
