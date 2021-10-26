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
%   force_rerender : Added to allow streaming data to get updated
%           even if xlims don't change. This is needed for calibration
%           that changes the scale of the data but not the time.
%
%   Inputs
%   ------
%   s : (struct)
%       new_xlim
%
%   Relevant objects
%   ----------------
%   big_plot.render_info
%
%   See Also
%   --------
%   big_plot.reduceToWidth

perf_mon = obj.perf_mon;
ri = obj.render_info;
call_logger = obj.call_logger;

%Initial Checks
%------------------------------------------------

call_logger.addEntry('renderData called')

perf_mon.n_calls_all = perf_mon.n_calls_all + 1;

forced = false;
if obj.force_rerender
    %This was created for calibration, where it doesn't seem like we should
    %need to rerender, but we need to because the data has changed, even
    %if the limits haven't.
    
    forced = true;
elseif ~ri.isChangedXLim()
    call_logger.addEntry('renderData called, xlimit did not change, quit early')
    return
end

h_tic = tic;
%Start rendering process
%--------------------------------------------------------------------------
obj.render_in_progress = true;

%Update xlims to block any calls above
%---------------------------------------------
%- I don't think we can have any async access, but this updates the xlims
%to minimize callbacks from the callback_manager.
h_axes = obj.h_and_l.h_axes;
if ~isempty(h_axes)
    obj.callback_manager.last_processed_xlim = get(h_axes,'XLim');
    
    %- We need to block reentry, thus updating the callback_manager
    %with the updated limits.
    %- However, we can't update the rendering info with these new limits
    %otherwise we won't render since checks below will think we've already
    %rendered these limits
    %- 'last_xlim_processed' - a different property for logging as opposed
    %to 'last_rendered_xlim'
    ri.last_xlim_processed = obj.callback_manager.last_processed_xlim;
end

ri.incrementRenderCount();

%Call render handlers
%----------------------------------------------
if obj.render_info.n_render_calls == 1
    call_logger.addEntry('renderData called, first plotting done')
    h__handleFirstPlotting(obj)
    type = 1;
else
    redraw_option = h__replotData(obj);
    type = redraw_option+2;
end

obj.force_rerender = false;

%Log rendering
%---------------------------
xlim = ri.last_rendered_xlim;
perf_mon.logRenderPerformance(toc(h_tic),type,xlim,forced);

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
%1) Main function for initializing plotting
function h__handleFirstPlotting(obj)
%
%

%Axes and figure initialization
plot_args = obj.h_and_l.initializeAxes();

[plot_args2,temp_h_indices] = h__setupInitialPlotArgs(obj,plot_args);
plot_args = plot_args2; %for debugging, can't access output ....

%Do the plotting
%--------------------------------------------------------------------------
%NOTE: We plot everything at once, as failing to do so can cause lines to
%be dropped.
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

%We might not get any handles  (??? - what do we want to do here)
%- no data (non-dynamic)
%- no data but streaming
%
%2018/03 - JAH: Made no y-data equal to plot(0,NaN)
%        - we might want to eventually support no plotting if no data
%        exists

%**** The actual plotting ****
temp_h_line = obj.data.plot_fcn(plot_args{:});

%Logging information and class info setup
%--------------------------------------------------
obj.h_and_l.initializePlotHandles(obj.data.n_plot_groups,temp_h_line,temp_h_indices);

obj.render_info.ax_handle = obj.h_and_l.h_axes;

%This allows us to get the raw data from the Matlab line handle
obj.data.initRawDataPointers(obj,obj.h_and_l);

%Init callbacks for replotting when zooming
obj.callback_manager.initialize(obj.h_and_l.h_axes);

end

%1.2) Setup of plotting arguments (for initial plotting)
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
n_min_max_pairs = obj.n_min_max_pairs;

%h - handles
end_h = 0;
n_plot_groups = obj.data.n_plot_groups;

temp_h_indices = cell(1,n_plot_groups);


%TODO: Are we plotting datetime values?
%big_plot.data
use_datetime = obj.data.datetimePresent();

if use_datetime
    group_x_min = NaT(1,n_plot_groups);
    group_x_max = NaT(1,n_plot_groups);
else
    group_x_min = NaN(1,n_plot_groups);
    group_x_max = NaN(1,n_plot_groups);
end

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
                obj.data.x{iG}, obj.data.y{iG}, n_min_max_pairs, [-Inf Inf]);
    perf_mon.logReducePerformance(s,toc(t));
            
    %We get an empty value when the line is not in the range of the plot
    %Note, this may no longer be true as we always keep the first and last
    %points ...
    
    if ~isempty(x_r)
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
ri = obj.render_info;
%ri : big_plot.render_info
call_logger = obj.call_logger;


%As lines are deleted groups of lines may be come invalid
%---------------------------------------------------------
%- If we don't have any valid lines, we kill the callback handler
%- Possible early exit
is_valid_group_mask = obj.h_and_l.getValidGroupMask();
if ~any(is_valid_group_mask)
    call_logger.addEntry('renderData called for replotting, no valid groups, all callbacks killed')
    obj.callback_manager.killCallbacks();
    redraw_option = ri.NO_CHANGE;
    return
end

new_x_limits = get(ax,'XLim');

%Determine redraw option
%------------------------------------
if obj.force_rerender
    %Note, if we have an object, the object needs to determine
    %whether it wants to rerender ...
    redraw_option = ri.RECOMPUTE_DATA_FOR_PLOTTING;
elseif obj.data.y_object_present
    %Note, if we want to support multiple objects
    %this will need to be pushed down ...
    %
    %Eventually we could automatically iterate over all groups
    %and ask this question for each group ...
    redraw_option = obj.data.y{1}.checkRedrawCase(new_x_limits);      
else
    redraw_option = ri.determineRedrawCase(new_x_limits);
end

%log accordingly
%------------------------
use_original = false;
perf_mon = obj.perf_mon;
switch redraw_option
    case ri.NO_CHANGE
        if isa(new_x_limits,'datetime')
            call_logger.addEntry('no x-limit change detected, x-lim: %s, %s',...
                new_x_limits(1),new_x_limits(2));
        else
            call_logger.addEntry('no x-limit change detected, x-lim: %g, %g',...
                new_x_limits(1),new_x_limits(2));
        end
        %no change needed
        perf_mon.n_render_no_ops = perf_mon.n_render_no_ops + 1;
        return
    case ri.RESET_TO_ORIGINAL
        if isa(new_x_limits,'datetime')
            call_logger.addEntry('resetting to original x-limit rendering: %s, %s',...
                new_x_limits(1),new_x_limits(2));
        else
            call_logger.addEntry('resetting to original x-limit rendering: %g, %g',...
                new_x_limits(1),new_x_limits(2));
        end
        %reset data to original view
        perf_mon.n_render_resets = perf_mon.n_render_resets + 1;
        use_original = true;
    case ri.RECOMPUTE_DATA_FOR_PLOTTING
        if isa(new_x_limits,'datetime')
            call_logger.addEntry('renderData called for replotting, recomputing data, new x-lim: %s, %s',...
            new_x_limits(1),new_x_limits(2));
        else
            call_logger.addEntry('renderData called for replotting, recomputing data, new x-lim: %g, %g',...
            new_x_limits(1),new_x_limits(2));
        end
        %recompute data for plotting
        obj.render_info.incrementReductionCalls();
    otherwise
        error('Uh oh, Jim broke the code')
end


%Recompute data for plotting
%------------------------------------------------
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
        
        if isequal(last_I,range_I) && ~obj.force_rerender
            obj.render_info.logNoRenderCall(new_x_limits);
            continue
        end
        
    else
        h_tic = tic;
        
        if obj.force_rerender
            last_I = [];
        end
            
        %sl.plot.big_data.LinePlotReducer.reduce_to_width
        [x_r, y_r, s] = big_plot.reduceToWidth(...
                x_input, obj.data.y{iG}, obj.n_min_max_pairs, new_x_limits, last_I);
        perf_mon.logReducePerformance(s,toc(h_tic));
        range_I = s.range_I;
        
        if s.skip || s.same_range
            if s.skip
                call_logger.addEntry('skipping render, out of range');
            else
                call_logger.addEntry('skipping render, same range');
            end
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