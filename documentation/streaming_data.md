# Streaming data

Functionality for streaming data is incapsulated in the `big_plot.streaming_data` class.

This class facilitates fast plotting of line data where the number of samples increases over time. This case was specifically written to handle plotting of DAQ data as it is acquired over time. 

For simplicity this class holds all data in memory, rather than reading data as necessary from disk. A data array is preallocated ahead of time and grows at a defined rate when added data exceeds the preallocated length.

# Benefits of Using

Matlab's main function for streaming data is called `animatedline`. Relative to that function, this codebase has the following advantages:

1. Speed - Plotting speed should be much faster than `animatedline` for this use case
2. Memory - Currently `animatedline` doesn't have a memory model which supports allocating what should be a sufficient number of points but that is open to the possibility of adding more. Instead you either specify a fixed # of points or an infinite number, at which point any memory allocation is managed internally by Matlab.

# Example Usage

```matlab
sin_freq = 1/60; %1 minute repeat
fs = 100000; %100 kHz sampling rate
dt = 1/fs;

%This is data that is received dynamically. In this case we
%just allocate it all at once and then "stream" it to our plotter
    
n_seconds_max = 900; %15 minutes of data
      
%Create semi-interesting signal
n_samples = n_seconds_max*fs + 1;
source_data = big_plot.example_data.getSinWithNoise(n_samples,1/fs,sin_freq,'double');    
    
%- This is low, but it shows we can reallocate if we add more data 
%than we initially allocated. Note plotting might pause noticeably 
%during memory  reallocation
n_samples_init = 5e7;
xy = big_plot.streaming_data(dt,n_samples_init);

%Note this only initialize the plot, no data has been added yet
plotBig(xy)
title('Plotting using this repo')
      
%- We'll plot the entire range, but you could plot a subset and scroll
%  using set(gca,'xlim',[min_x max_x])
%- We also fix the ylim so that it doesn't jump around
set(gca,'xlim',[0 n_seconds_max],'ylim',[-2 3])
    
%Plotting data as it is "collected"
%----------------------------------------
end_I = 0;
tic
for i = 1:n_seconds_max
	start_I = end_I + 1;
 	end_I = start_I + fs - 1;
 	new_data = source_data(start_I:end_I);
 	xy.addData(new_data)
	drawnow
end
toc
    
%On my laptop this takes 40 seconds. 40 seconds to plot 900 seconds of data. %Although not tested directly this implies a rate of about 22.5 Hz for plotting 1 channel %at 100kHz

%Now how about animated line??
%----------------------------
cla
clear xy
set(gca,'xlim',[0 n_seconds_max],'ylim',[-2 3])
h = animatedline('MaximumNumPoints',floor(length(source_data)/4)+1)
title('Plotting using animatedline')
end_I = 0;
tic
%Only run 1/4 as this is slow
for i = 1:n_seconds_max/4
	start_I = end_I + 1;
 	end_I = start_I + fs - 1;
 	new_data = source_data(start_I:end_I);
  	x = (start_I*dt):dt:(end_I*dt);
 	addpoints(h,x,source_data(start_I:end_I))
   	drawnow
end
toc
    
%I get 141 seconds for 1/4 of the plotting. Assuming this trend continues it would take 564 seconds to plot what this code base does in 40s.
```

# Public Functions

## setCalibration

The function `setCalibration` can be used to scale the data. The data are only scaled on plotting, the underlying data are not changed.

```
fs = 50000;
init_data = big_plot.example_data.getSinWithNoise(1e7,1/fs,1/2,'double'); 
xy = big_plot.streaming_data(1/fs,1e7,'initial_data',init_data);
plotBig(xy)

%After calling this the plot should scale accordingly
xy.setCalibration(2,1)

%Let's reset to the original - unity scaling, 0 offset
xy.setCalibration(1,0)

%Now let's shift alot and shrink, and invert
xy.setCalibration(-0.1,100)

%Another reset
xy.setCalibration(1,0)
```

