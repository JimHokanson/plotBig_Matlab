function [x_reduced, y_reduced] = reduce_to_width(x, y, axis_width_in_pixels, x_limits)
%x Reduces the # of points in a data set
%
%   [x_reduced, y_reduced] = reduce_to_width(...
%           x, y, axis_width_in_pixels, x_limits)
%
%   For a given data set, this function returns the maximum and minimum
%   points within non-overlapping subsets of the data, bounded by the
%   specified limits.
%
%   This helps us to increase the rate at which we can plot data.
%
%   Inputs:
%   -------
%   x : {array, sci.time_series.time, }
%       [samples x channels]
%       The samples may be evenly spaced or not evenly spaced.
%   y : array
%       [samples x channels]
%   axis_width_in_pixels :
%       This is used to determine the number of min/max pairs to generate.
%   x_limits :
%       2 element vector [min,max], can be [-Inf Inf] to indicate everything
%       This limit is applied to the 'x' input to exclude any points that
%       are outside the limits.
%
%   Optional Inputs:
%   ----------------
%   use_quick : logical (default false)
%       A quick approach just downsamples the data rather than finding
%       local maximums and minimums.
%
%   Outputs
%   -------
%   x_reduced :
%   y_reduced :
%
%
%   Example
%   -------
%   plot(x,y)
%   hold all
%   [xr, yr] = sl.plot.big_data.reduce_to_width(x, y, 500, [5 10]);
%
%   plot(xr, yr); % This contains many fewer points than plot(x, y)
%                 %but looks the same.
%   hold off

%{
%Some test code
N = 1e8;
r = rand(N,1);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf]); toc;

r = rand(N,1);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf],'use_quick',true); toc;

r = rand(N,2);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf]); toc;

r = rand(N,1);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(sci.time_series.time(0.01,N),r,4000,[0 Inf],'use_quick',true); toc;

%Under the return everything limit
r = rand(9000,4);
t = sci.time_series.time(0.01,9000);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%This should throw an error
r = rand(11000,4);
t = sci.time_series.time(0.01,N);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Just over the return everything limit
r = rand(11000,4);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Single channel is just over the limit
r = rand(11000,1);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Single channel just under limit
r = rand(9000,1);
t = sci.time_series.time(0.01,9000);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;

%Just over the return everything limit, quick
r = rand(11000,4);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',true); toc;

%Single channel is just over the limit, quick
r = rand(11000,1);
t = sci.time_series.time(0.01,11000);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',true); toc;

r = rand(1e6,1);
t = sci.time_series.time(0.01,1e6);
tic; [xr,yr,extras] = sl.plot.big_data.LinePlotReducer.reduce_to_width(t,r,4000,[0 Inf],'use_quick',false); toc;




%}

% % % % x_reduced = (1:5)';
% % % % y_reduced = (1:5)';
% % % % extras = [];
% % % % return
%Mex code calls:
%---------------

if isobject(x) && x.n_samples ~= size(y,1)
    error('Size mismatch between time object and input data')
elseif size(x,2) > 1
    error('Multiple x channels not yet handled')
end

show_everything = isinf(x_limits(1));

if show_everything
    %Not sure if I want before if ceil or floor
    %ceil - less samples out
    %floor - more samples out
    samples_per_chunk = ceil(size(y,1)/axis_width_in_pixels);
    
    y_reduced = reduce_to_width_mex(y,samples_per_chunk);
    n_y = size(y_reduced,1);
    if isobject(x)
        x_1 = x.getTimesFromIndices(1);
        x_end = x.getTimesFromIndices(x.n_samples);
    else
        %Test if approximately equal ..., otherwise throw an error
        if isLinearTime(x)
            x_1 = x(1);
            x_end = x(end);
        else
           error('Non-uniform x spacing not yet supported') 
        end
    end
    %TODO: This will need to change
    %Need to go into the time array, not just generate indices
    x_reduced = linspace(x_1,x_end,n_y)';
else
    if isobject(x)
        dt = x.dt;
        x_1 = x.getTimesFromIndices(1);
        I1 = floor((x_limits(1)- x_1)./dt) + 1;
        if isinf(x_limits(2))
            I2 = size(y,1);
        else
            I2 = ceil((x_limits(2)-x_1)./dt) + 1;
        end
        x_end = x.getTimesFromIndices(x.n_samples);
        x_I1 = x.getTimesFromIndices(I1);
        x_I2 = x.getTimesFromIndices(I2);
    else
      	if isLinearTime(x)
           dt = x(2)-x(1);
           I1 = floor((x_limits(1)-x(1))./dt) + 1;
           I2 = ceil((x_limits(2)-x(1))./dt) + 1;
        else
           error('Non-uniform x spacing not yet supported') 
        end 
        x_1 = x(1);
        x_end = x(end);
        x_I1 = x(I1);
        x_I2 = x(I2);
    end
    
    n_samples = I2 - I1;
    samples_per_chunk = ceil(n_samples/axis_width_in_pixels);
    y_reduced = reduce_to_width_mex(y,samples_per_chunk,I1,I2);
    n_y = size(y_reduced,1);
    %chunk_time_width = (samples_per_chunk-1)*dt;
    x_reduced = zeros(n_y,1);
    
    %The first and last sample stay still
    x_reduced(1) = x_1;
    x_reduced(end) = x_end;
    %We fill in the middle based on the start and stop indices selected ...
    x_reduced(2:end-1) = linspace(x_I1,x_I2,n_y-2);   
end



end

function linear_time = isLinearTime(x)
%This is a crappy check, ideally we would check everything
%
%TODO: Perhaps check everything ....
    dt = x(2) - x(1);
    last_x_estimated = x(1) + dt*(length(x)-1);
    linear_time =  abs(last_x_estimated - x(end)) < eps;
end
