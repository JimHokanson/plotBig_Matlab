function [x_reduced, y_reduced, extras] = reduce_to_width(x, y, axis_width_in_pixels, x_limits, varargin)
%x Reduces the # of points in a data set
%
%   [x_reduced, y_reduced] = ...
%       sl.plot.big_data.LinePlotReducer.reduce_to_width(...
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
%   x : {array, sci.time_series.time}
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
%   extras :
%       .method
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
%
%   Based on code by:
%   Tucker McClure (Mathworks)

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
    %extra_samples = 
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
    %TODO: Not yet implemented ...
    if isobject(x)
        dt = x.dt;
        x_1 = x.getTimesFromIndices(1);
        I1 = floor((x_limits(1)- x_1)./dt) + 1;
        I2 = ceil((x_limits(2)-x_1)./dt) + 1;
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

function not_called



%TODO: This should be based on how long it takes to plot a set of points
%versus how long it takes to run this code ...
C.ALLOW_MEX = ~ismac;
C.N_SAMPLES_MAX_PLOT_EVERYTHING = 10000;
C.N_POINTS = 2*axis_width_in_pixels;
C.HALF_N_POINTS = axis_width_in_pixels;

in.use_quick = false;
in = sl.in.processVarargin(in,varargin);

%Error checking:
%---------------


if in.use_quick
    %We'll grab a little more when it is quick because of the
    %simplicity of the algorithm
    C.N_POINTS = 8*axis_width_in_pixels;
    C.HALF_N_POINTS = 4*axis_width_in_pixels;
end

s = struct;
s.C = C;
s.in = in;
s.extras = struct;
s.done = false;

% Early exit for small data
%--------------------------
s = h__checkEarlyExitSmallData(s,x,y);
if s.done
    [x_reduced,y_reduced,extras] = h__unpackStruct(s);
    return
end

s = h__initReducedData(s,x,y);

if C.ALLOW_MEX
    s = h__tryApproach1(s,x,y,x_limits);
end
if ~s.done %Couldn't run quicker method
    s = h__runOtherApproaches(s,x,y,x_limits);
end
[x_reduced,y_reduced,extras] = h__unpackStruct(s);

end

function [x_reduced,y_reduced,extras] = h__unpackStruct(s)
%x Small helper to extract values for returning to caller
x_reduced = s.x_reduced;
y_reduced = s.y_reduced;
extras    = s.extras;
end

function s = h__checkEarlyExitSmallData(s,x,y)
% If the data is already small, there's no need to reduce.
% Note that this check also serves to prevent indexing edge cases
%   (e.g. we aren't working with a single data point)
n_samples_y = size(y,1);
C = s.C;

if n_samples_y <= C.N_SAMPLES_MAX_PLOT_EVERYTHING
    s.extras.method = 'early exit for small data';
    s.y_reduced = y;
    if isobject(x)
        s.x_reduced = x.getTimeArray();
        if size(s.x_reduced,1) == 1
            s.x_reduced = x_reduced';
        end
    else
        s.x_reduced = x;
    end
    s.done = true;
end

end

%======  Approach 1 and helpers ============

function s = h__tryApproach1(s,x,y,x_limits)
%
%   Can we use a single channel reshape approach that is relatively quick?
%
%   In order to do this we need:
%       1) Data that are evently sampled in time.
%       2) To be plotting all the data.
%       3) Only to be dealing with a single channel.
%

%1) Are the data evenly sampled?
%TODO: This doesn't consider when x is a vector that is evenly spaced.
%The standard way of doing this in Matlab has a high memory requirement
%(for an assumed large x)
is_evenly_sampled = isobject(x); %We could also test the input data as well

%2) Are we plotting all of the data?
plotting_all_data = h__checkForPlottingAllData(x,x_limits);

%3)
n_channels_y = size(y,2);
multiple_channels = n_channels_y > 1;

if is_evenly_sampled && plotting_all_data && ~multiple_channels
    %For this approach we truncate the array (in mex), reshape it into
    %a matrix, and then use Matlab to compute min and max along the proper
    %dimension so that all chunks are computed together in one call.
    if s.in.use_quick
        s.extras.method = 'quick 1';
        indices = h__getQuickIndices(1,length(y),s.C.N_POINTS);
    else
        s.extras.method = '1: Single Channel Reshape';
        indices = h__getMinMax_approach1(y,s.C.N_POINTS);
    end
    
    s.x_reduced = h__getXReducedGivenIndices(x,s.x_reduced,1,indices);
    s.y_reduced = h__getYReducedGivenIndices(y,s.y_reduced,1,indices);
    s.done = true;
end
end

function plot_all_data = h__checkForPlottingAllData(x,x_limits)
%x Check if we are plotting all of the data
%
%   We are checking that all x values are within the x_limits

if isobject(x)
    plot_all_data =  x_limits(1) <= x.start_time && x_limits(2) >= x.end_time;
else
    plot_all_data = all(x_limits(1) <= x(1,:) & x_limits(2) >= x(end,:));
end

end

function indices = h__getMinMax_approach1(data,n_output_points)
%
%   This approach reshapes a single channel array and calculates
%   the min and max values over the first dimension of the resulting
%   matrix.
%
%   Since the arrray may not be reshapeable nicely - i.e. evenly divisible
%   by the # of output points - we truncate the array (in mex) before
%   reshaping into a matrix and calculating min and max along one of the
%   dimensions (also all done in mex). After this we untruncate the array.
%
%   Some extra Matlab code is used to calculate the max and min over the
%   resulting smaller chunk of data at the end of the array if necessary.

%TODO:
%rename variables so that their meanings are obvious ...

%TODO:
%--------------------------------------
%Using this approach, we are required to have a nice divisor. I was
%plotting 29901 points with 4000 min/max regions. Sticking to 4000 output
%points with even spaces gives us 29901 - 7*4000 => 1901 extra points,
%which is not what we want.
%
%Instead we want to be able to able to adjust our # of output points
%so that the remainder is on the order of the sample sizes (in that last
%case, 7)
%
%   so we could do 7 points and return 4271 (technically 4272 since 29901
%   isn't divisible by 7)
%
%   alternatively we could divide by 8 and return 3737 points
%
%   We are free to choose either (divide by 7 or 8) but both will not
%   return the # requested, which we need to be able to handle ...
%
%   My preference would be to do less and to pad with NaN values in the
%   calling function ...
%



%I'm not thrilled with this nomenclature (more so in the calling function
%than here, here is a bit better)
n_max_min_regions = n_output_points/2;

new_m = floor(length(data)/n_max_min_regions);

%This causes a problem when the # of points per region is small and the
%round error is big:
%35000 points
%4000 min_max regions
%3002 extra samples - looks really bad
%extra_samples = length(data) - new_m*n_max_min_regions;

%NEW CODE ...
n_max_min_regions = floor(length(data)/new_m);
extra_samples = length(data) - new_m*n_max_min_regions;

indices = zeros(2,n_max_min_regions);

%TODO: Update mex documentation
[~,indices(1,:),~,indices(2,:)] = pmex__minMaxViaResizing(data,new_m,n_max_min_regions);

%All of the indices need to be shifted ...
indices = bsxfun(@plus,indices,0:new_m:new_m*(n_max_min_regions-1));

if extra_samples ~= 0
    extra_samples_m1 = extra_samples-1;
    leftover_samples = data(end-extra_samples_m1:end);
    
    [~,last_min_I] = min(leftover_samples);
    last_min_I = last_min_I + new_m*n_max_min_regions;
    
    [~,last_max_I] = max(leftover_samples);
    last_max_I = last_max_I + new_m*n_max_min_regions;
    
    last_column = [last_min_I; last_max_I];
    indices = [indices last_column];
end

indices = h__orderIndices(indices);

end


%====== Other Approaches ===================
function s = h__runOtherApproaches(s,x,y,x_limits)
%
%   Here we:
%   - loop through each channel finding:
%       - data bounds for calculating min & max
%       - the min and max within those bounds

[x_reduced,y_reduced,extras] = h__unpackStruct(s);

C  = s.C;
in = s.in;

n_edges  = C.HALF_N_POINTS + 1;

% Create a place to store the indices we'll need.
%This size allows us to use indices(:) appropriately.
data_indices_use = zeros(2,C.HALF_N_POINTS);

n_channels_x = size(x,2);
n_channels_y = size(y,2);

for iChan = 1:n_channels_y
    
    if iChan == 1 || n_channels_x ~= 1
        %We update bounds for the first time or always if there are
        %multiple x channels
        bound_indices = h__getBoundIndices(x,iChan,n_edges,x_limits);
        %bound_indices is an array of indices where we compute
        %the maximum and minimum between each neighboring pair of indices
        %
        %e.g. if bound_indices = [1 1010 2020 3030]
        %
        %Then we compute the max and min between:
        %      1 and 1010
        %   1010 and 2020
        %   2020 and 3030
    end
    
    if isempty(bound_indices)
        %NOTE: We've initialized with a null case so that the output will
        %still be defined even if we skip things.
        continue
    elseif bound_indices(end) - bound_indices(1) < C.N_SAMPLES_MAX_PLOT_EVERYTHING
        %This occurs when the zoom level is such that we don't actually
        %have that much data from the channel to show given our current
        %x_limits.
        
        data_indices_use = bound_indices(1):bound_indices(end);
    elseif in.use_quick
        extras.method = 'quick 2';
        %This is where we could try the mex ...
        data_indices_use = h__getQuickIndices(...
            bound_indices(1),...
            bound_indices(end),...
            C.N_POINTS);
    elseif C.ALLOW_MEX
        extras.method = '2: mex loop';
        data_indices_use = h__getMinMax_approach2(y,data_indices_use,bound_indices,iChan);
        
        %indices2 = h__getMinMax_approach3(y,indices,bound_indices,iChan);
        
        %         if ~isequal(indices2,indices)
        %             error('Approaches are not equal')
        %         end
    else
        data_indices_use = h__getMinMax_approach3(y,data_indices_use,bound_indices,iChan);
    end
    
    x_reduced = h__getXReducedGivenIndices(x,x_reduced,iChan,data_indices_use);
    y_reduced = h__getYReducedGivenIndices(y,y_reduced,iChan,data_indices_use);
    
end

s.x_reduced = x_reduced;
s.y_reduced = y_reduced;
s.extras = extras;

end

function indices = h__getMinMax_approach2(y,indices,bound_indices,iChan)
%
%   This approach is quite
%

%linearize indices
bound_indices = bound_indices + (iChan-1)*size(y,1);

lefts  = bound_indices(1:end-1);
rights = [bound_indices(2:end-1)-1 bound_indices(end)];

[~,~,indices(1,:),indices(2,:)] = pmex__chunkMinMax(y,lefts,rights);

%delinearize indices
indices = indices - (iChan-1)*size(y,1);

indices = h__orderIndices(indices);

end

function indices = h__getMinMax_approach3(y,indices,bound_indices,iChan)
%
%   This is the simple approach where we just loop through and compute max
%   and min values.
%

lefts  = bound_indices(1:end-1);
rights = [bound_indices(2:end-1)-1 bound_indices(end)];

for iRegion = 1:length(lefts)
    yt = y(lefts(iRegion):rights(iRegion), iChan);
    [~, indices(1,iRegion)] = min(yt);
    [~, indices(2,iRegion)] = max(yt);
end

indices = bsxfun(@plus,indices,lefts-1);
indices = h__orderIndices(indices);

end


function indices = h__orderIndices(indices)
swap_rows = indices(1,:) > indices(2,:);
temp = indices(1,swap_rows);
indices(1,swap_rows) = indices(2,swap_rows);
indices(2,swap_rows) = temp;
end

function s = h__initReducedData(s,x,y)
%This value should either be:
%   - 1,
%   - or the same as n_channels_y, indicating a 1:1 correspondance
%     between x and y.
C = s.C;

n_samples_y  = size(y,1);
n_channels_y = size(y,2);

%+2 for min and max, see note below on extremes
x_reduced = nan(C.N_POINTS+2, n_channels_y);
y_reduced = nan(C.N_POINTS+2, n_channels_y);

%Add data extremes:
%--------------------------------------------------------------------------
%We add on the extremes of the data so that Matlab doesn't zoom in and out
%constantly. When this was not in place, auto-adjustments of the x-axis
%would cause a slow expansion in which more and more data would be plotted
%until the we had "zoomed" out to encompass all of the data.
y_reduced(1,:)   = y(1,:);
y_reduced(end,:) = y(end,:);

if isobject(x)
    x_reduced(1,:)   = x.getTimesFromIndices(1);
    x_reduced(end,:) = x.getTimesFromIndices(n_samples_y);
else
    x_reduced(1,:)   = x(1,:);
    x_reduced(end,:) = x(end,:);
end

s.x_reduced = x_reduced;
s.y_reduced = y_reduced;

end

function y_reduced = h__getYReducedGivenIndices(y,y_reduced,iChan,indices)
if ~isempty(indices)
    end_I = numel(indices)+1;
    y_reduced(2:end_I, iChan) = y(indices(:), iChan);
end
end

function x_reduced = h__getXReducedGivenIndices(x,x_reduced,iChan,indices)

%Note that the # of indices
n_indices = numel(indices);

if isobject(x)
    if n_indices ~= 0
        end_I = n_indices + 1;
        x_reduced(2:end_I, iChan) = x.getTimesFromIndices(indices(:));
    end
    
else
    if n_indices ~= 0
        end_I = n_indices + 1;
        if size(x,2) > 1
            x_reduced(2:end_I, iChan) = x(indices(:), iChan);
        else
            x_reduced(2:end_I, iChan) = x(indices(:), 1);
        end
    end
end



end

function bound_indices = h__getBoundIndices(x,cur_chan_I,n_points,x_limits)
%x Returns the start and stop indices of data that spans a given time
%
%   Inputs:
%   -------
%   x: sci.time_series.time or array
%       Time points for each data sample or time specification for the data
%   cur_chan_I:
%   n_points:
%       # of boundaries to have
%   x_limits:
%       Two element vector
%
%   Outputs:
%   --------
%   bound_indices :
%       length(bound_indices) => n_points , Indices are absolute relative
%       to the original data array. If the data are outside of the limits,
%       then bound_indices is empty.
%
%


% Find the starting and stopping indices for the current limits.

if isobject(x)
    
    if x_limits(1) > x.end_time || x_limits(2) < x.start_time
        bound_indices = [];
        return
    end
    
    %NOTE: These adjustments are overkill when this limit is way off.
    %For example. imagine we are plotting from 1 to 1000 but our data
    %only goes from 900 to 1000. Let's say we are doing 10 points per
    %pixel. This gives us roughly 100 points (1000/10). We update our
    %start to be 900 so we know have roughly 1 point per pixel instead
    %of 10 (100 samples/100 points).
    %
    %TODO: Update the # of bound_indices appropriately ...
    if x_limits(1) < x.start_time
        x_limits(1) = x.start_time;
    end
    
    if x_limits(2) > x.end_time
        x_limits(2) = x.end_time;
    end
    
    index_times   = linspace(x_limits(1),x_limits(2),n_points);
    
    bound_indices = x.getNearestIndices(index_times);
    
    %With rounding we might not bound the data. Thus we get the times
    %of the first and last indices and adjust the index values
    %accordingly if necessary
    times = x.getTimesFromIndices([bound_indices(1) bound_indices(end)]);
    
    if times(1) > x_limits(1)
        bound_indices(1)  = bound_indices(1)-1;
    end
    
    %NOTE: This could cause an empty selection if bound_indices(end-1)
    %is ALSO past the limit. This should only occur with selections
    %which are too small to begin with, and we'll recognize that in the
    %caller and short-circuit accordingly.
    if times(2) < x_limits(2)
        bound_indices(end) = bound_indices(end)-1;
    end
else
    
    if x_limits(1) > x(end) || x_limits(2) < x(1)
        bound_indices = [];
        return
    end
    
    if x_limits(1) < x(1)
        x_limits(1) = x(1);
    end
    
    if x_limits(2) > x(end)
        x_limits(2) = x(end);
    end
    
    xt = x(:, cur_chan_I);
    
    %TODO: Below should use:
    %sl.array.indices.ofEdgesBoundingData
    
    % Map the lower and upper limits to indices.
    nx = size(x, 1);
    lower_limit      = h__binary_search(xt, x_limits(1), 1,           nx);
    [~, upper_limit] = h__binary_search(xt, x_limits(2), lower_limit, nx);
    
    % Make the windows mapping to each pixel.
    x_time_boundaries = linspace(x(lower_limit, cur_chan_I), x(upper_limit, cur_chan_I), n_points);
    
    bound_indices = zeros(1,n_points);
    
    bound_indices(1)   = lower_limit;
    bound_indices(end) = upper_limit;
    
    right = lower_limit;
    for iDivision = 2:n_points-1;
        % Find the window bounds.
        left       = right;
        [~, right] = h__binary_search(xt, x_time_boundaries(iDivision), left, upper_limit);
        bound_indices(iDivision) = right;
    end
end
end

function indices = h__getQuickIndices(start_I,end_I,half_n_points)

indices = zeros(2,half_n_points);
temp = round(linspace(start_I,end_I,2*half_n_points));
indices(1,:) = temp(1:2:end);
indices(2,:) = temp(2:2:end);

end

% Binary search to find boundaries of the ordered x data.
function [L, U] = h__binary_search(x, v, L, U)
%
%   Inputs:
%   -------
%   x :
%       x data
%   v :
%       value to find index bordder of
%   L :
%   U :
%
%   Outputs:
%   --------
%   L :
%       Lower index that encompasses the value 'v'
%   U :
%       Upper index that encompasses the value 'v'
%
%

%TODO: This is not the best way of doing this for sorted data ...

while L < U - 1                 % While there's space between them...
    C = floor((L+U)/2);         % Find the midpoint
    if x(C) < v                 % Move the lower or upper bound in.
        L = C;
    else
        U = C;
    end
end
end
