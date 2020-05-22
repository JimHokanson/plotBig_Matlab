function [x_reduced, y_reduced, s] = reduceToWidth(x, y,... 
                            axis_width_in_pixels, x_limits, last_range_I)
%x  Reduces the # of points in a data set
%
%   [x_reduced, y_reduced, s] = ...
%       reduceToWidth(x, y, axis_width_in_pixels, x_limits, *last_range_I)
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
%   x : array OR big_plot.time
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

%TODO: This should be a class ...
s = struct(...
    'range_I',[NaN NaN],...
    'same_range',false,...
    'mex_time',0,...
    'plot_all',false,...
    'show_everything',false);

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

x_reduced = [];
y_reduced = [];

if isobject(y)
    n_y_samples = y.n_samples;
    %We'll impose this limitation for now ...
    n_chans = 1;
else
    n_y_samples = size(y,1);
    n_chans = size(y,2);
end

%A problem here may indicate a problem with:
%big_plot.data>h__parseDataAndLinespecs

if n_chans > N_CHANS_MAX
    %We might be able to handle more, but I ran into problems when
    %accidentally plotting the transpose of the actual data which had
    %tons of samples ...
    error('Cowardly refusing to process more than 100 channels using this code ...')
end

%Plotting all data, early exit ...
%--------------------------------------------------------------
if n_y_samples < N_SAMPLES_JUST_PLOT
    s.plot_all = true;
    if isobject(y)
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
    s.range_I = [1 n_y_samples];
    s.same_range = isequal(s.range_I,last_range_I);
    return
end

%Not plotting all data - get reduced values
%--------------------------------------------------------------------------
if isobject(y)
   %NOTE: This doesn't support datetime x_limits ...
   r = y.getDataReduction(x_limits,axis_width_in_pixels);
   x_reduced = r.x_reduced;
   y_reduced = r.y_reduced;
   s.range_I = r.range_I;
   %This is difficult because we might be recalibrating
   %which causes problems
   s.same_range = false; %isequal(s.range_I,last_range_I);
   s.mex_time = r.mex_time;
   return
end

if isobject(x) && x.n_samples ~= n_y_samples
    error('Size mismatch between time object and input data')
elseif size(x,2) > 1
    error('Multiple x channels not yet handled')
end

if isobject(x)
    x_1   = x.getTimesFromIndices(1);
    x_end = x.getTimesFromIndices(x.n_samples);
else
    x_1   = x(1);
    x_end = x(end);
end


show_everything = isinf(x_limits(1)) || ...
    (x_limits(1) <= x_1 && x_limits(2) >= x_end);

if show_everything
    s.show_everything = true;
    if isobject(x)
        range_I = [1 x.n_samples];
    else
        range_I = [1 length(x)];
    end
    s.range_I = range_I;
    same_range = isequal(range_I,last_range_I);
    s.same_range = same_range;
    if same_range
        return
    end
    
    %Not sure if I want before if ceil or floor
    %ceil - less samples out
    %floor - more samples out
    samples_per_chunk = ceil(n_y_samples/axis_width_in_pixels);
    
    t = tic;
    y_reduced = reduce_to_width_mex(y,samples_per_chunk);
    s.mex_time = toc(t);
    n_y_reduced = size(y_reduced,1);
    if ~isobject(x) && ~isLinearTime(x)
        error('Non-uniform x spacing not yet supported');
    end
    
    %Note, rather than carrying about exactly where the min and max
    %occur, we just do a linear spacing of points. This should be fine
    %as long as we sample sufficiently high. Once the # of points gets
    %low, so that you can see individual points (due to zooming or just
    %a low # of samples originally), then we plot everything (correctly)
    x_reduced = linspace(x_1,x_end,n_y_reduced)';
else
    if isobject(x)
        dt = x.dt;
        diff1 = x_limits(1)- x_1;
        if isobject(diff1)
            diff1 = seconds(diff1);
        end
        I1 = floor(diff1./dt) + 1;
        
        %Note, we need these checks here, otherwise our times will be off
        if I1 < 1
            I1 = 1;
        end
        
        if isinf(x_limits(2))
            I2 = size(y,1);
        else
            diff2 = x_limits(2)- x_1;
            if isobject(diff2)
                diff2 = seconds(diff2);
            end
            I2 = ceil(diff2./dt) + 1;
            if I2 > x.n_samples
                I2 = x.n_samples;
            end
        end
        x_end = x.getTimesFromIndices(x.n_samples);
        x_I1 = x.getTimesFromIndices(I1);
        x_I2 = x.getTimesFromIndices(I2);
        n_samples = x.n_samples;
    else
        if isLinearTime(x)
            dt = x(2)-x(1);
            I1 = floor((x_limits(1)-x(1))./dt) + 1;
            if I1 < 1
                I1 = 1;
            end
            I2 = ceil((x_limits(2)-x(1))./dt) + 1;
            if I2 > length(x)
                I2 = length(x);
            end
        else
            error('Non-uniform x spacing not yet supported')
        end
        x_I1 = x(I1);
        x_I2 = x(I2);
        n_samples = length(x);
    end
    
    %Out of range check ...
    %---------------------------------------------------
    if I1 > n_samples || I2 < 1
       %zooming too far right or left ... 
       range_I = [0 0]; %This is arbitrary ...
       s.range_I = range_I;
       s.same_range = isequal(range_I,last_range_I);
       if s.same_range
          return
       else
           y_reduced = vertcat(y(1,:), y(end,:));
           x_reduced = [x_1; x_end];
           return
       end
    end
    
    %General same range check ...
    %----------------------------------
    range_I = [I1 I2];
    s.range_I = range_I;
    s.same_range = isequal(range_I,last_range_I);
    if s.same_range
        return
    end

    %With a subset we might want to plot everything
    %----------------------------------------------------------------
    n_samples = I2 - I1 + 1;
    if n_samples < N_SAMPLES_JUST_PLOT
        %*** We also need the edges to prevent resizing ...
        y_reduced = vertcat(y(1,:), y(I1:I2,:), y(end,:));
        x_reduced = [x_1; linspace(x_I1,x_I2,n_samples)'; x_end];
        return
    end
    
    
    samples_per_chunk = ceil(n_samples/axis_width_in_pixels);
    t = tic;
    y_reduced   = reduce_to_width_mex(y,samples_per_chunk,I1,I2);
    s.mex_time = toc(t);
    n_y_reduced = size(y_reduced,1);
    %chunk_time_width = (samples_per_chunk-1)*dt;
    
    if isa(x_1,'datetime')
        x_reduced = NaT(n_y_reduced,1);
    else
        x_reduced = zeros(n_y_reduced,1);
    end
    
    %The first and last sample stay still
    x_reduced(1) = x_1;
    x_reduced(end) = x_end;
    %We fill in the middle based on the start and stop indices selected ...
    x_reduced(2:end-1) = linspace(x_I1,x_I2,n_y_reduced-2);
end



end

function linear_time = isLinearTime(x)
linear_time = same_diff_mex(x);
end
