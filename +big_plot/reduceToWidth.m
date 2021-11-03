function [x_reduced, y_reduced, s] = reduceToWidth(x, y, ...
    axis_width_in_pixels, min_max_t_plot, ...
    last_range_I, edge_info)
%x  Reduces the # of points in a data set
%
%   [x_reduced, y_reduced, s] = ...
%       reduceToWidth(x, y, axis_width_in_pixels, x_limits, *last_range_I, *x_edges)
%
%   For a given data set, this function returns the maximum and minimum
%   points within non-overlapping subsets of the data, bounded by the
%   specified limits.
%
%   This helps us to increase the rate at which we can plot data.
%
%   Known Callers
%   -------------
%   big_plot.renderData
%
%   Inputs:
%   -------
%   x : array OR big_plot.time OR big_plot.datetime
%       [samples x channels]
%       The samples may be evenly spaced or not evenly spaced. Not evenly
%       spaced will throw an error as it is not yet supported.
%   y : array
%       [samples x channels]
%   axis_width_in_pixels :
%       This is used to determine the number of min/max pairs to generate.
%       Note, in the 'big_plot' code this is hardcoded at a large # so that
%       even if the axis resizes we can basically leave this fix. This
%       can help with reusing of the downsampling.
%   min_max_t_plot :
%       2 element vector [min,max], can be [-Inf Inf] to indicate everything
%       This limit is applied to the 'x' input to exclude any points that
%       are outside the limits.
%   last_range_I : [min_I max_I] (default [])
%       This can be used to indicate to the user that the data should
%       not be processed again, if the resultant indices of the new
%       data are the same as the indices used before.
%
%       e.g. consider x = 1:1e8 with last_range_I = [1 1e8]. If the new
%       xlimits were [0.95 1e8+1], then the new range_I would be [1 1e8]
%       Thus, if the renderer has held onto the appropriate y-values
%       associated with this range, there is no need to recompute the
%       values to plot again.
%
%
%   Outputs
%   -------
%   x_reduced :
%   y_reduced :
%           s :
%           - range_I:
%           - same_range: logical
%               This can only be determined when 'last_range_I' is passed
%               in. If true, then 'x_reduced' and 'y_reduced' are not
%               computed. Note, this function does not store the reduced
%               data, so it can't pass out what was last used even if this
%               value is true (without recomputing).
%
%
%   Example
%   -------
%   n = 1e8;
%   x = 1:n;
%   y = 1:n;
%   plot(x,y)
%   hold all
%   axis_width = 2000;
%   [xr, yr] = bg_plot.reduce_to_width(x, y, axis_width, [1 n]);
%
%   plot(xr, yr); % This contains many fewer points than plot(x, y)
%                 %but looks the same.
%   hold off
%
%
%   Called by:
%   big_plot>renderData

s = big_plot.reduction_summary();

N_CHANS_MAX = 100; %This was put in place to catch some fall through cases
%where I was plotting [1 x n] instead of [n x 1] for y. It is also helpful
%for cases of [n x m] where m is large, since this code isn't the best
%at handling large m, although we could probably go up pretty high before
%really causing problems ...

N_SAMPLES_JUST_PLOT = 10000; %If we get less samples than this, then
%just plot all of the samples, rather than computing the max and the min

%This would occur if the user calls this function directly ...
if ~exist('last_range_I','var')
    last_range_I = [];
end

if isobject(y)
    n_y_samples_in = y.n_samples;
    %We'll impose this limitation for now ...
    n_chans = 1;
else
    n_y_samples_in = size(y,1);
    n_chans = size(y,2);
end

if isobject(x) && x.n_samples ~= n_y_samples_in
    error('Size mismatch between time object and input data')
elseif size(x,2) > 1
    error('Multiple x channels not yet handled')
end

%A problem here may indicate a problem with:
%big_plot.data>h__parseDataAndLinespecs

if n_chans > N_CHANS_MAX
    %We might be able to handle more, but I ran into problems when
    %accidentally plotting the transpose of the actual data which had
    %tons of samples ...
    error('Cowardly refusing to process more than 100 channels using this code ...')
end


%Edge cases -----------------------------------------------
if ~isobject(y)
    if isempty(y)
        x_reduced = [];
        y_reduced = [];
        return
    end
end

%Plotting all data, early exit ... ---------------------------------------
if n_y_samples_in < N_SAMPLES_JUST_PLOT
    [x_reduced, y_reduced, s] = h__plotAllSamples(s,x,y,last_range_I);
    return
end

%Object plotting, let object handle details -------------------------------
if isobject(y)
    [x_reduced, y_reduced, s] = h__plotObjectSubset(s,min_max_t_plot,axis_width_in_pixels,y);
    return
end

if ~exist('edge_info','var')
    edge_info = big_plot.edges_info(x,y);
end

if edge_info.nans_only
    x_reduced = big_plot.utils.indexToTime(x,[1; n_y_samples_in]);
    y_reduced = NaN(2,n_chans);
    return
end

x_t1 = edge_info.x_t1;
x_tend = edge_info.x_tend;


x_reduced = [];
y_reduced = [];

s.show_everything = isinf(min_max_t_plot(1)) || (min_max_t_plot(1) <= x_t1 && min_max_t_plot(2) >= x_tend);

if ~(isobject(x) || h__isLinearTime(x))
    error('Non-uniform x spacing not yet supported');
end

%fprintf('x_I1:%g, %g, %g, %g,show: %d\n',x_I1,x_Iend,x_t1,x_tend,s.show_everything);

[x_Istart,x_Istop,x_tstart,x_tstop] = ...
    h__getSampleMinMax(x,s.show_everything,min_max_t_plot,edge_info.x_I1,edge_info.x_Iend,x_t1,x_tend);

%fprintf('x_Istart:%g, %g, %g, %g\n',x_Istart,x_Istop,x_tstart,x_tstop);

%Out of range check ... -----------------------------------------
%Basically we might have zoomed such that we are completely to the
%left or right of our data, so nothing is visible. This had been
%working in code below with linspace on regular numbers but started
%failing on linspace for datetime. So we'll just make this explicit.
if x_tstart > x_tend || x_tstop < x_t1
    s.skip = true;
    %fprintf('Skipped\n');
    return
end

%Same range check ... -------------------------------------------
plot_xI = [x_Istart,x_Istop];
s.range_I = plot_xI;
same_range = isequal(plot_xI,last_range_I);
s.same_range = same_range;
if same_range
    return
end

%JAH, at this point ...
n_y_samples_visible = x_Istop - x_Istart + 1;

%Not sure if I want before if ceil or floor
%ceil - less samples out
%floor - more samples out
%Note, 1 sample per chunk would be no downsizing
s.samples_per_chunk = ceil(n_y_samples_visible/axis_width_in_pixels);

%With a subset we might want to plot everything
%----------------------------------------------------------------
if n_y_samples_visible < N_SAMPLES_JUST_PLOT
    s.plotted_all_subset = true;
    temp_y = y(x_Istart:x_Istop,:);
    %Probably could do min(temp_y(:)) here, not sure of memory implications
    valid_y = min(min(temp_y));
    null_y = zeros(1,n_chans,'like',y);
    null_y(:) = valid_y;
    %Note, instead of adding on the first and the last points which
    %might be NaNs we'll add on zeros. When adding on first and last
    %Matlab was resetting the xlimits for resetting when xlimmode
    %was set to auto.
    y_reduced = vertcat(null_y, temp_y, null_y);
    x_reduced = [x_t1; linspace(x_tstart,x_tstop,n_y_samples_visible)'; x_tend];
    return
end



t = tic;
y_reduced = reduce_to_width_mex(y,s.samples_per_chunk,x_Istart,x_Istop);
s.mex_time = toc(t);

y_reduced(1:2,:) = edge_info.output_y_left;
y_reduced(end-1:end,:) = edge_info.output_y_right;


% % % % % %Ugh, need to remove buffer samples that were put in by mex
% % % % % %default is 0 Nan for floats or 0,0 for ints
% % % % % valid_y = min(min(y_reduced(3:end-2,:)));
% % % % % y_reduced(1,:) = valid_y;
% % % % % y_reduced(end,:) = valid_y;
n_y_reduced = size(y_reduced,1);


x_reduced = big_plot.utils.getXInit(x_tstart,[n_y_reduced 1]);

% if isa(x_tstart,'datetime')
%     x_reduced = NaT(n_y_reduced,1);
% elseif isa(x_tstart,'duration')
%     %x_reduced = duration(nan(n_y_reduced,1));
%     x_reduced = NaT(n_y_reduced,1) - NaT(1);
% else
%     x_reduced = zeros(n_y_reduced,1);
% end

%The first and last sample stay still
%JAH 5/2020 => modified to have 2 samples on each edge, one valid
%and one not (for floats) or just two 0s for integers
%
%- Note, we can't anchor x-limits with NaN values on tight.
%- By why don't we always anchor with valid value (as it should be off
%screen)?
%
%- Note, originally I didn't anchor for the whole subset, but this 
%  caused problems with long starting and closing NaNs
%
x_reduced(1:2) = edge_info.output_x_left;
x_reduced(end-1:end) = edge_info.output_x_right;
%We fill in the middle based on the start and stop indices selected ...
x_reduced(3:end-2) = linspace(x_tstart,x_tstop,n_y_reduced-4);

end

function [x_Istart,x_Istop,x_tstart,x_tstop] = h__getSampleMinMax(x,show_everything,min_max_t_plot,x_I1,x_Iend,x_t1,x_tend)
%
%   1 - first valid sample, normally sample 1
%   end - last valid sample, normally end (or length of array)
%   I - indices
%   t - times

if show_everything
    x_tstart = x_t1;
    x_tstop = x_tend;
    x_Istart = x_I1;
    x_Istop = x_Iend;
elseif isobject(x)
    dt = x.dt;
    diff1 = min_max_t_plot(1)-x_t1;
    if isobject(diff1)
        diff1 = seconds(diff1);
    end
    %How many dt's have we moved
    %
    %   Let's say:
    %   - first valid sample is at 3 - x_I1 = 3
    %   - start plotting at
    %
    %
    I1 = floor(diff1./dt) + x_I1;

    %Note, we need these checks here, otherwise our times will be off
    if I1 < x_I1
        I1 = x_I1;
    end

    if isinf(min_max_t_plot(2))
        I2 = x_Iend;
    else
        diff2 = min_max_t_plot(2)-x_t1;
        if isobject(diff2)
            diff2 = seconds(diff2);
        end
        I2 = ceil(diff2./dt) + x_I1;
        if I2 > x_Iend
            I2 = x_Iend;
        end
    end
    %x_end = x.getTimesFromIndices(x.n_samples);
    x_tstart = x.getTimesFromIndices(I1);
    x_tstop = x.getTimesFromIndices(I2);
    x_Istart = I1;
    x_Istop = I2;
    %n_samples = x.n_samples;
else
    dt = x(2)-x(1);
    I1 = floor((min_max_t_plot(1)-x(1))./dt) + 1;
    if I1 < 1
        I1 = 1;
    end
    I2 = ceil((min_max_t_plot(2)-x(1))./dt) + 1;
    if I2 > length(x)
        I2 = length(x);
    end
    x_Istart = x(I1);
    x_Istop = x(I2);
    %n_samples = length(x);
end
end

function linear_time = h__isLinearTime(x)
linear_time = same_diff_mex(x);
end

function [x_reduced, y_reduced, s] = h__plotObjectSubset(s,x_limits,axis_width_in_pixels, y)
%
%
%   Inputs
%   ------
%
%TODO: What object do we expect y to be ...
%    -> I think this is for streaming data
%NOTE: This doesn't support datetime x_limits ...
r = y.getDataReduction(x_limits, axis_width_in_pixels);
x_reduced = r.x_reduced;
y_reduced = r.y_reduced;
s.range_I = r.range_I;
%This is difficult because we might be recalibrating
%which causes problems
s.same_range = false; %isequal(s.range_I,last_range_I);
s.mex_time = r.mex_time;
end

function [x_reduced, y_reduced, s] = h__plotAllSamples(s,x,y,last_range_I)
%
%   No downsampling 
s.plotted_all_samples = true;

%Y --------------------------------
if isobject(y)
    %big_plot.streaming_data
    y_reduced = y.getRawData();
    %This was added to ensure a valid plot handle
    if isempty(y_reduced)
        y_reduced = NaN;
    end
elseif isempty(y)
    y_reduced = NaN;
else
    y_reduced = y;
end

%X --------------------------------
if isobject(x)
    x_reduced = x.getTimeArray;
    if size(x_reduced,1) == 1
        x_reduced = x_reduced';
    elseif isempty(x_reduced)
        %Not sure what to make this ...
        %x_limits might be invalid (i.e. -inf inf)
        x_reduced = 0;
    end
else
    x_reduced = x;
end

s.range_I = [1 length(x_reduced)];
s.same_range = isequal(s.range_I,last_range_I);
end