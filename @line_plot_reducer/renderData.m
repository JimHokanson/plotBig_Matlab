function renderData(obj,s)
% Draws all of the data.
%
%   This is THE main function which actually plots data.
%
%   Inputs:
%   -------
%   s : (struct)
%       Data from a callback event with fields:
%       h : Axes
%       event_data : matlab.graphics.eventdata.SizeChanged (>= 2014b)
%                    ??? (pre 2014b)
%       axes_I : 
%           Which axes 
%   is_quick : logical
%       If true this is a request to update the plot as quickly as
%       possible.
%
%   This function is called:
%       1) manually
%       2) from the timer ...
%
%   line_plot_reducer.renderData

obj.n_render_calls = obj.n_render_calls + 1;

%This code shouldn't be required but I had troubles when it was gone :/
if ~obj.needs_initialization
    for iG = obj.n_plot_groups
        if any(~ishandle(obj.h_plot{iG}))
            obj.h_axes = [];
            obj.needs_initialization = true;
            break
        end
    end
end

if obj.needs_initialization
    h__handleFirstPlotting(obj,obj.max_axes_width)
else
    h__replotData(obj,s,obj.max_axes_width)
end

if ~isempty(obj.post_render_callback)
    obj.post_render_callback();
end

end



%--------------------------------------------------------------------------
%-----------------   Initialization  --------------------------------------
function h__handleFirstPlotting(obj,initial_axes_width)
%
%

%Setup for plotting
%----------------------------------------
%Axes and figure initialization
plot_args = h__initializeAxes(obj);

[plot_args,temp_h_indices] = h__setupInitialPlotArgs(obj,plot_args,initial_axes_width);

%Do the plotting
%----------------------------------------
%NOTE: We plot everything at once, as failing to do so can
%cause lines to be dropped.
%
%e.g.
%   plot(x1,y1,x2,y2)
%
%   If we did:
%   plot(x1,y1)
%   plot(x2,y2)
%
%   Then we wouldn't see plot(x1,y1), unless we changed
%   our hold status, but this could be messy

%NOTE: This doesn't support stairs or plotyy
temp_h_plot = obj.plot_fcn(plot_args{:});

%Log some property values
%-------------------------
obj.last_redraw_used_original = true;
obj.last_rendered_xlim = get(obj.h_axes,'xlim');
obj.needs_initialization = false;

%Break up plot handles to be grouped the same as the inputs were
%---------------------------------------------------------------
%e.g.
%plot(x1,y1,x2,y2)
%This returns one array of handles, but we break it back up into
%handles for 1 and 2
%{h1 h2} - where h1 is from x1,y1, h2 is from x2,y2
obj.h_plot = cell(1,obj.n_plot_groups);
if ~isempty(temp_h_plot)
    for iG = 1:obj.n_plot_groups
        obj.h_plot{iG} = temp_h_plot(temp_h_indices{iG});
    end
end

%TODO: Make sure this is exposed in the documentation
%sl.plot.big_data.line_plot_reducer.line_data_pointer
for iG = 1:obj.n_plot_groups
    cur_group_h = obj.h_plot{iG};
    for iH = 1:length(cur_group_h)
        cur_h = cur_group_h(iH);
        temp_obj = line_plot_reducer.line_data_pointer(obj,iG,iH);
        setappdata(cur_h,'BigDataPointer',temp_obj);
    end
end

%Setup callbacks and timers
%-------------------------------
h__setupCallbacksAndTimers(obj);

drawnow();

end

%1) Axes Initialization
function plot_args = h__initializeAxes(obj)

    %The user may have already specified the axes.
    if isempty(obj.h_axes)

        %TODO: ???? Not sure what I meant by this ...
        %   set(0, 'CurrentFigure', o.h_figure);
        %   set(o.h_figure, 'CurrentAxes', o.h_axes);


        obj.h_axes   = gca;
        obj.h_figure = gcf;
        plot_args = {};
    else
        %TODO: Verify that the axes exists if specified ...
        if isempty(obj.h_figure)
            obj.h_figure = get(obj.h_axes(1),'Parent');
            plot_args = {obj.h_axes};
        else
            plot_args = {obj.h_axes};
        end

    end
end

%2) Setup of plotting arguments
function [plot_args,temp_h_indices] = h__setupInitialPlotArgs(obj,plot_args,initial_axes_width)
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
%the screen. I've not just hardcoded a "large" screen size.
new_axes_width = initial_axes_width;
obj.last_rendered_axes_width = new_axes_width;

%h - handles
end_h = 0;
temp_h_indices = cell(1,obj.n_plot_groups);

group_x_min = zeros(1,obj.n_plot_groups);
group_x_max = zeros(1,obj.n_plot_groups);

for iG = 1:obj.n_plot_groups
    
    start_h = end_h + 1;
    end_h = start_h + size(obj.y{iG},2) - 1;
    temp_h_indices{iG} = start_h:end_h;
    %Reduce the data.
    %----------------------------------------
    [x_r, y_r] = obj.reduce_to_width(obj.x{iG}, obj.y{iG}, new_axes_width, [-Inf Inf]);
    
    if isempty(x_r) %or equivalently y_r would work
        group_x_min(iG) = NaN;
        group_x_max(iG) = NaN;

        %I'm not sure what impact setting these to NaN will have ...
        obj.x_r_orig{iG} = NaN;
        obj.y_r_orig{iG} = NaN;

        obj.x_r_last{iG} = NaN;
        obj.y_r_last{iG} = NaN;    
    else
    group_x_min(iG) = min(x_r(1,:));
    group_x_max(iG) = max(x_r(end,:));
    
    obj.x_r_orig{iG} = x_r;
    obj.y_r_orig{iG} = y_r;
    
    obj.x_r_last{iG} = x_r;
    obj.y_r_last{iG} = y_r;
    end
    
    
    plot_args = [plot_args {x_r y_r}]; %#ok<AGROW>
    
    cur_linespecs = obj.linespecs{iG};
    if ~isempty(cur_linespecs)
        plot_args = [plot_args {cur_linespecs}]; %#ok<AGROW>
    end
    
end
%TODO: Can we just grab the first and the last ????
%TODO: We might have NaNs
obj.x_lim_original = [min(group_x_min) max(group_x_max)];

%Don't set to 1 as the figure could close. Calling renderData would
%again run this code. Instead the value is initialized to 0 and we keep
%counting up from there.
obj.n_x_reductions = obj.n_x_reductions + 1;

if ~isempty(obj.extra_plot_options)
    plot_args = [plot_args obj.extra_plot_options];
end



end

function h__setupCallbacksAndTimers(obj)
%
%   This function runs after everything has been setup...
%
%   Called by:
%   line_plot_reducer.renderData>h__handleFirstPlotting
%
%   JAH: I'm not thrilled with the layout of this code but it is fine for
%   now.

n_axes = length(obj.h_axes);

obj.timers = cell(1,n_axes);
obj.resize_times = zeros(1,n_axes);
obj.resize_data = cell(1,n_axes);
obj.processed_resize_times = zeros(1,n_axes);
obj.timer_null_run_count = zeros(1,n_axes);
obj.resize_ids = zeros(1,n_axes);
obj.processed_ids = zeros(1,n_axes);
for iTimer = 1:n_axes
    t = timer();
    set(t,'Period',0.1,'ExecutionMode','fixedSpacing')
    set(t,'TimerFcn',@(~,~)h__runTimer(obj,iTimer));
    start(t);
    obj.timers{iTimer} = t;
end

% Listen for changes to the x limits of the axes.
obj.axes_listeners = cell(1,n_axes);

%Double-clicking to zoom out doesn't trigger this ...
if verLessThan('matlab', '8.4')
    size_cb = {'Position', 'PostSet'};
else
    size_cb = {'SizeChanged'};
end

for iAxes = 1:n_axes
    l1 = addlistener(obj.h_axes(iAxes), 'XLim', 'PostSet', @(h, event_data) h__resize(obj,h,event_data,iAxes));
    
    l2 = addlistener(obj.h_axes(iAxes), size_cb{:}, @(h, event_data) h__resize(obj,h,event_data,iAxes));
    
    %TODO: Also update the object that the axes are dirty ...
    l3 = addlistener(obj.h_axes(iAxes), 'ObjectBeingDestroyed',@(~,~)h__handleAxesBeingDestroyed(obj));
    
    obj.axes_listeners{iAxes} = [l1 l2 l3];
end

n_groups = length(obj.h_plot);

obj.plot_listeners = cell(1,n_groups);

for iG = 1:length(obj.h_plot)
    cur_group = obj.h_plot{iG};
    %NOTE: Technically I think we only need to add on one listener
    %because if one gets deleted, all the others should as well ...
    try
        obj.plot_listeners{iG} = addlistener(cur_group(1), 'ObjectBeingDestroyed',@(~,~)h__handleLinesBeingDestroyed(obj));
    catch ME %#ok<NASGU>
        obj.needs_initialization = true;
        sl.warning.formatted('Warning: failed to add listener to deleted line\n');
    end
end

end

%--------------------------------------------------------------------------
%---------------------   Replotting      ----------------------------------
%Main entry call
function h__replotData(obj,s,new_axes_width)
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

redraw_option = h__determineRedrawCase(obj,s);

use_original = false;
switch redraw_option
    case 0
        %no change needed
        return
    case 1
        %reset data to original view
        use_original = true;
        obj.last_redraw_used_original = true;
    case 2
        %recompute data for plotting
        obj.last_redraw_used_original = false;
        obj.n_x_reductions = obj.n_x_reductions + 1;
    otherwise
        error('Uh oh, Jim broke the code')
end

new_x_limits  = s.new_xlim;
obj.last_rendered_xlim = new_x_limits;
obj.last_rendered_axes_width = new_axes_width;

for iG = 1:obj.n_plot_groups
    
    %Reduce the data.
    %----------------------------------------
    if use_original
        x_r = obj.x_r_orig{iG};
        y_r = obj.y_r_orig{iG};
    else
        %sl.plot.big_data.LinePlotReducer.reduce_to_width
        [x_r, y_r] = obj.reduce_to_width(obj.x{iG}, obj.y{iG}, new_axes_width, new_x_limits);
    end
    
    local_h = obj.h_plot{iG};
    % Update the plot.
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

function redraw_option = h__determineRedrawCase(obj,s)
%
%   redraw_option = h__determineRedrawCase(obj,s)
%
%   Outputs:
%   --------
%   redraw_option:
%       - 0 - no change needed
%       - 1 - reset data to original view
%       - 2 - recompute data for plotting
%       - 3 - partial window overlap (NOT YET IMPLEMENTED)
%       - 4 - zoom out - could use some data that had already been computed



%Possible changes and approaches:
%--------------------------------
%1) Axes wider: (1)
%       Our current approach is to oversample at a given location, so no
%       change is needed. 
%
%2) TODO: Finish this based on below




%
%Possible changes:
%1) Axes is now wider    - redraw if not sufficiently oversampled
%2) Axes is now narrower - don't care
%3) Xlimits have changed :
%       - Gone back to original - use original values
%       -
%
%   Hold onto:
%   - last axes width
%   - original axes width
%
%   ???? How can we subsample appropriately???

new_x_limits  = s.new_xlim;
x_lim_changed = ~isequal(obj.last_rendered_xlim,new_x_limits);

%TODO: Check for overlap

NO_CHANGE = 0;
RESET_TO_ORIGINAL = 1;
RECOMPUTE_DATA_FOR_PLOTTING = 2;

if x_lim_changed
    %x_lim changed almost always means a redraw
    %Let's build a check in here for being the original
    %If so, go back to that
    if new_x_limits(1) <= obj.x_lim_original(1) && new_x_limits(2) >= obj.x_lim_original(2)
        redraw_option = RESET_TO_ORIGINAL;
    else
        redraw_option = RECOMPUTE_DATA_FOR_PLOTTING;
    end
else
    %We could resize but not redraw, then resize again ...
    %Let's do nothing for now ...
    redraw_option = NO_CHANGE;
% % % % % %     disp(s)
% % % % % %     error('Not sure what happened to cause this to be called')
% % % % % %     %???? Why does this callback get called???
% % % % % %     %Width changed:
% % % % % %     %NOTE: We are currently not doing any width based changes, so we really
% % % % % %     %don't know if the axes changed or not
% % % % % %     if obj.last_redraw_was_quick
% % % % % %         redraw_option = 2;
% % % % % %     else
% % % % % %         redraw_option = 0;
% % % % % %     end   
end




end





%--------------------------------------------------------------------------
%---------------------- Cleanup -------------------------------------------
function h__deleteThingsNow(obj)

obj.needs_initialization = true;

for iAxes = 1:length(obj.h_axes)
   cur_listeners = obj.axes_listeners{iAxes};
   delete(cur_listeners)
   
   t = obj.timers{iAxes};
    obj.timers{iAxes} = [];
    if ~isempty(t)
        try %#ok<TRYNC>
            stop(t)
            delete(t)
        end
    end
end

%h__handleLinesBeingDestroyed(obj)



for iG = 1:length(obj.h_plot)
   cur_listener = obj.plot_listeners{iG};
   try %#ok<TRYNC>
       %This might fail if the line wasn't able to be created
    delete(cur_listener)
   end
end

end

function h__handleAxesBeingDestroyed(obj)

h__deleteThingsNow(obj)

% % % % for iAxes = 1:length(obj.h_axes)
% % % %    cur_listeners = obj.axes_listeners{iAxes};
% % % %    delete(cur_listeners)
% % % % end
% % % % 
% % % % obj.needs_initialization = true;
% % % % h__handleLinesBeingDestroyed(obj)
% % % % 
% % % % t = obj.timers{axes_I};
% % % % obj.timers{axes_I} = [];
% % % % if ~isempty(t)
% % % %     try %#ok<TRYNC>
% % % %         stop(t)
% % % %         delete(t)
% % % %     end
% % % % end

end

function h__handleLinesBeingDestroyed(obj)

h__deleteThingsNow(obj)

% % % % for iG = 1:length(obj.h_plot)
% % % %    cur_listener = obj.plot_listeners{iG};
% % % %    try %#ok<TRYNC>
% % % %        %This might fail if the line wasn't able to be created
% % % %     delete(cur_listener)
% % % %    end
% % % % end
% % % % 
% % % % %TODO: Might want to delete timers as well ...
% % % % %obj.timers
% % % % 
% % % % 
% % % % 
% % % % obj.needs_initialization = true;
end






%--------------------------------------------------------------------------
%---------------------      Callbacks -------------------------------------
function h__resize(obj,h,event_data,axes_I)
    %
    %   Called when the xlim property of an axes object changes or
    %   when an axes is resized.
    %
    %   In older versions of Matlab this is also called when the
    %   figure is moved. TODO: When did this change?
    %
    %   Inputs:
    %   -------
    %   h :
    %   event_data :
    %   axes_I :
    %       Index of internal axes being modified
    %
    %   See Also:
    %   sl.plot.big_data.LinePlotReducer.renderData>h__setupCallbacksAndTimers
    
    obj.n_resize_calls = obj.n_resize_calls + 1;
    

    new_xlim = get(obj.h_axes(axes_I),'xlim');

    s = struct;
    s.h = h;
    s.event_data   = event_data;
    s.axes_I       = axes_I;
    s.new_xlim     = new_xlim;
    
    disp(s)

    obj.resize_times(axes_I) = cputime; %array
    obj.resize_ids(axes_I) = obj.resize_ids(axes_I) + 1;
    obj.resize_data{axes_I} = s;

end

function h__runTimer(obj,axes_I)

    resized_time = obj.resize_times(axes_I);
    resize_id = obj.resize_ids(axes_I);
    processed_id = obj.processed_ids(axes_I);
    
    if (cputime > resized_time + obj.update_delay && resize_id ~= processed_id) ...
        || (resize_id - processed_id >= obj.n_timers_max_before_redraw)

        %This second clause should be sufficient, since the only
        %thing that will delay a drawing is to fire more resize events
    
        %This is where it would be useful to have a lock ...
        obj.processed_ids(axes_I) = resize_id;
        
        s = obj.resize_data{axes_I};
        obj.processed_resize_times(axes_I) = resized_time;
        try
            obj.renderData(s);
        catch ME
            %Store locally?
            obj.last_error = ME;
           disp(ME)
           ME.stack(1)
           ME.stack(2)
        end
    end
end