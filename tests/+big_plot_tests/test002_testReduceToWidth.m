%{
%Some test code
N = 1e8;
r = rand(N,1);
tic; [xr,yr,extras] = big_plot.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf]); toc;

r = rand(N,1);
tic; [xr,yr,extras] = big_plot.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf],'use_quick',true); toc;

r = rand(N,2);
tic; [xr,yr,extras] = big_plot.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf]); toc;

r = rand(N,1);
tic; [xr,yr,extras] = big_plot.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf],'use_quick',true); toc;

%Under the return everything limit
r = rand(9000,4);
t = sci.time_series.time(0.01,9000);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%This should throw an error
r = rand(11000,4);
t = sci.time_series.time(0.01,N);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Just over the return everything limit
r = rand(11000,4);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Single channel is just over the limit
r = rand(11000,1);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Single channel just under limit
r = rand(9000,1);
t = sci.time_series.time(0.01,9000);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Just over the return everything limit, quick
r = rand(11000,4);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',true); toc;

%Single channel is just over the limit, quick
r = rand(11000,1);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',true); toc;

r = rand(1e6,1);
t = sci.time_series.time(0.01,1e6);
tic; [xr,yr,extras] = big_plot.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;


%}