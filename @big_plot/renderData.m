function renderData(obj)
%x   Draws all of the data.
%
%   MAIN FUNCTION for plotting/replotting data.
%
%   Forms
%   -----
%   obj.renderData()  %user mode
%
%   Called by:
%   big_plot.callback_manager
%
%   Important State Variables
%   -------------------------
%   - force_rerender - added to allow streaming data to get updated
%   even if xlims don't change.
%
%   Inputs
%   ------
%   s : (struct)
%       new_xlim
%
%   Relevant objects
%   ----------------
%   big_plot.render_info

perf_mon = obj.perf_mon;
ri = obj.render_info;

%Initial Checks
%------------------------------------------------
perf_mon.n_calls_all = perf_mon.n_calls_all + 1;

forced = false;
if obj.force_rerender
    %go ahead
    forced = true;
    obj.force_rerender = false;
elseif ~ri.isChangedXLim()
    return
end

t = tic;
%Start rendering process
%--------------------------------------------------------------------------
obj.render_in_progress = true;

%Update xlims to block any calls above
%---------------------------------------------
%- I don't think we can have any async access, but this updates the xlims
%so that we don't get more callbacks thrown
h_axes = obj.h_and_l.h_axes;
if ~isempty(h_axes)
    obj.callback_manager.last_processed_xlim = get(h_axes,'XLim');
    
    %This needs to block above but must be different from
    %last_rendered_xlim otherwise we don't get the correct behavior below
    ri.last_xlim_processed = obj.callback_manager.last_processed_xlim;
end

ri.incrementRenderCount();

%Call render handlers
%----------------------------------------------
if obj.render_info.n_render_calls == 1
    h__handleFirstPlotting(obj)
    type = 1;
else
    redraw_option = h__replotData(obj);
    type = redraw_option+2;
end

%Log rendering
%---------------------------
xlim = ri.last_rendered_xlim;
perf_mon.logRenderPerformance(toc(t),type,xlim,forced);

if ~isempty(obj.post_render_callback)
    obj.post_render_callback();
end

%We'll put this here instead of before the callback to consider the
%callback still a part of the rendering process
obj.render_in_progress = false;

end

%--------------------------------------------------------------------------
%-----------------           Initialization                ----------------
%--------------------------------------------------------------------------
%1) Main function for plotting
function h__handleFirstPlotting(obj)
%
%

%Axes and figure initialization
plot_args = obj.h_and_l.initializeAxes();

[plot_args,temp_h_indices] = h__setupInitialPlotArgs(obj,plot_args);

%Do the plotting
%----------------------------------------
%NOTE: We plot everything at once, as failing to do so can cause lines to be dropped.
%
%e.g. we do:
%   plot(x1,y1,x2,y2)
%
%   If we did:
%   plot(x1,y1)
%   plot(x2,y2)
%
%   Then we wouldn't see plot(x1,y1), unless we changed our hold status,
%   but this could be messy

%- This doesn't support stairs or plotyy
%- The data has been reduced at this point

%We might not get any handles
%- no data (non-dynamic)
%- no data but streaming
%??? - what do we want to do here
temp_h_line = obj.data.plot_fcn(plot_args{:});

obj.h_and_l.initializePlotHandles(obj.data.n_plot_groups,temp_h_line,temp_h_indices);

obj.render_info.ax_handle = obj.h_and_l.h_axes;

%Place ability to fetch raw data in the line object
%--------------------------------------------------
h_and_l = obj.h_and_l;
for iG = 1:h_and_l.n_plot_groups
    cur_group_h = h_and_l.h_line{iG};
    for iH = 1:length(cur_group_h)
        cur_h = cur_group_h(iH);
        temp_obj = big_plot.line_data_pointer(obj,iG,iH);
        setappdata(cur_h,'BigDataPointer',temp_obj);
    end
end

%Setup callbacks
%-------------------------------
obj.callback_manager.initialize(obj.h_and_l.h_axes);

end

%1.2) Setup of plotting arguments
function [plot_args,temp_h_indices] = h__setupInitialPlotArgs(obj,plot_args)
%
%   This function computes the values that will be used for plotting
%   and updates the appropriate internal variables. The size of the
%   data is reduced in this function, but it is passed back to the
%   parent for plotting.
%
%   Inputs:
%   -------
%   plot_args :
%   initial_axes_width :
%
%   Outputs:
%   --------
%   plot_args : cell
%       These are the arguments for the plot function. For something like
%       plot(1:4,2:5) the value of plot_args would be {1:4 2:5}
%   temp_h_indices : cell
%       The output of the plot function combines all handles. For us it is
%       helpful to keep track of the x's and y's are paired.
%
%       In other words if we have plot(x1,y1,x2,y2) we want to have
%       x1 and y1 be paired. Note that x1 could be only a vector but
%       y1 could be a matrix. In this way there is not necessarily a 1 to 1
%       mapping between x and y (i.e. a single x1 could map to multiple
%       output handles coming from each column of y1).
%

%This width is a holdover from when I varied this depending on the width of
%the screen. For now I've not just hardcoded a "large" screen size.
n_samples_plot = obj.n_samples_to_plot;

%h - handles
end_h = 0;
n_plot_groups = obj.data.n_plot_groups;

temp_h_indices = cell(1,n_plot_groups);

group_x_min = zeros(1,n_plot_groups);
group_x_max = zeros(1,n_plot_groups);

for iG = 1:n_plot_groups
    start_h = end_h + 1;
    end_h = start_h + size(obj.data.y{iG},2) - 1;
    temp_h_indices{iG} = start_h:end_h;
end

perf_mon = obj.perf_mon;

for iG = 1:n_plot_groups
    
    %Reduce the data.
    %----------------------------------------
    t = tic;
    [x_r, y_r, s] = big_plot.reduceToWidth(...
                obj.data.x{iG}, obj.data.y{iG}, n_samples_plot, [-Inf Inf]);
    perf_mon.logReducePerformance(s,toc(t));
            
            
    %We get an empty value when the line is not in the range of the plot
    %Note, this may no longer be true as we always keep the first and last
    %points ...
    
    if isempty(x_r)
        group_x_min(iG) = NaN;
        group_x_max(iG) = NaN;
    elseif length(x_r) == 1
        group_x_min(iG) = x_r(1);
        group_x_max(iG) = x_r(1);
    else
        group_x_min(iG) = x_r(1);
        group_x_max(iG) = x_r(end);
    end
    
    %We might change this to two different calls
    %since we don't know the limits yet ...
    is_original = true;
    x_limits = NaN;
    obj.render_info.logRenderCall(iG,x_r,y_r,s.range_I,is_original,x_limits);
    
    plot_args = [plot_args {x_r y_r}]; %#ok<AGROW>
    
    cur_linespecs = obj.data.linespecs{iG};
    if ~isempty(cur_linespecs)
        plot_args = [plot_args {cur_linespecs}]; %#ok<AGROW>
    end
    
end

orig_x_limits = [min(group_x_min) max(group_x_max)];
obj.render_info.logOriginalXLim(orig_x_limits);

obj.render_info.incrementReductionCalls();

if ~isempty(obj.data.extra_plot_options)
    plot_args = [plot_args obj.data.extra_plot_options];
end

end


%==========================================================================
%--------------------------------------------------------------------------
%---------------------          Replotting      ---------------------------
%--------------------------------------------------------------------------
%2) Main function for replotting
function redraw_option = h__replotData(obj)
%
%   Handles replotting data, as opposed to handling the first plot
%
%   Inputs:
%   -------
%   s :
%       See definition in parent function
%   new_axes_width:
%       Currently hardcoded as the max width
%

ax = obj.h_and_l.h_axes;

is_valid_group_mask = obj.h_and_l.getValidGroupMask();
if ~any(is_valid_group_mask)
    obj.callback_manager.killCallbacks();
end

new_x_limits = get(ax,'XLim');

perf_mon = obj.perf_mon;
ri = obj.render_info;

if obj.data.y_object_present
    redraw_option = ri.RECOMPUTE_DATA_FOR_PLOTTING;
else
    redraw_option = ri.determineRedrawCase(new_x_limits);
end

use_original = false;
switch redraw_option
    case ri.NO_CHANGE
        %no change needed
        perf_mon.n_render_no_ops = perf_mon.n_render_no_ops + 1;
        return
    case ri.RESET_TO_ORIGINAL
        %reset data to original view
        perf_mon.n_render_resets = perf_mon.n_render_resets + 1;
        use_original = true;
    case ri.RECOMPUTE_DATA_FOR_PLOTTING
        %recompute data for plotting
        obj.render_info.incrementReductionCalls();
    otherwise
        error('Uh oh, Jim broke the code')
end

for iG = find(is_valid_group_mask)
        
    last_I = obj.render_info.last_I{iG};
    x_input = obj.data.x{iG};
    
    %Reduce the data.
    %----------------------------------------
    if use_original
        x_r = obj.render_info.orig_x_r{iG};
        y_r = obj.render_info.orig_y_r{iG};
        
        if isobject(x_input)
            range_I = [1 x_input.n_samples];
        else
            range_I = [1 length(x_input)];
        end
        
        if isequal(last_I,range_I)
            obj.render_info.logNoRenderCall(new_x_limits);
            continue
        end
        
    else
        h_tic = tic;
        %sl.plot.big_data.LinePlotReducer.reduce_to_width
        [x_r, y_r, s] = big_plot.reduceToWidth(...
                x_input, obj.data.y{iG}, obj.n_samples_to_plot, new_x_limits, last_I);
        perf_mon.logReducePerformance(s,toc(h_tic));
        range_I = s.range_I;
        
        if s.same_range
            obj.render_info.logNoRenderCall(new_x_limits);
            continue
        end
    end    
    
    obj.render_info.logRenderCall(iG,x_r,y_r,range_I,use_original,new_x_limits);
    
    local_h = obj.h_and_l.h_line{iG};
    
    %Update the plot.
    %---------------------------------------
    if size(x_r,2) == 1
        for iChan = 1:length(local_h)
            set(local_h(iChan), 'XData', x_r, 'YData', y_r(:,iChan));
        end
    else
        for iChan = 1:length(local_h)
            set(local_h(iChan), 'XData', x_r(:,iChan), 'YData', y_r(:,iChan));
        end
    end
    
end

end