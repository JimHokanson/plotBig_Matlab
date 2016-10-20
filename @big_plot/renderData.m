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

if nargin == 1
    h__handleFirstPlotting(obj)
else
    h__replotData(obj,s)
end

if ~isempty(obj.post_render_callback)
    obj.post_render_callback();
end

end



%--------------------------------------------------------------------------
%-----------------   Initialization  --------------------------------------
function h__handleFirstPlotting(obj)
%
%

%Setup for plotting
%----------------------------------------
%Axes and figure initialization
plot_args = h__initializeAxes(obj);

[plot_args,temp_h_indices] = h__setupInitialPlotArgs(obj,plot_args);

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

%This needs to be fixed ...
%
%--------------------------------------------------------------------------
% % % % %TODO: Make sure this is exposed in the documentation
% % % % %sl.plot.big_data.line_plot_reducer.line_data_pointer
% % % % for iG = 1:obj.n_plot_groups
% % % %     cur_group_h = obj.h_plot{iG};
% % % %     for iH = 1:length(cur_group_h)
% % % %         cur_h = cur_group_h(iH);
% % % %         temp_obj = big_plot.line_data_pointer(obj,iG,iH);
% % % %         setappdata(cur_h,'BigDataPointer',temp_obj);
% % % %     end
% % % % end

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
%the screen. I've not just hardcoded a "large" screen size.
new_axes_width = obj.n_samples_to_plot;

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
obj.last_rendered_xlim = obj.x_lim_original;

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

t = timer();
set(t,'Period',0.1,'ExecutionMode','fixedSpacing')
set(t,'TimerFcn',@(~,~)h__runTimer(obj));
start(t);
obj.timer = t;

obj.axes_listeners = event.listener(obj.h_axes,'ObjectBeingDestroyed',@(~,~)obj.cleanup_figure());

n_groups = length(obj.h_plot);

obj.plot_listeners = cell(1,n_groups);

%What we really need is when the # of plots drops, we clear the timer ...

% % % % %Is this causing problems???
% % % % n_active_lines = 0;
% % % % for iG = 1:length(obj.h_plot)
% % % %     cur_group = obj.h_plot{iG};
% % % %     
% % % %     
% % % %     n_plots_in_group = length(cur_group);
% % % %     lhs = cell(1,n_plots_in_group);
% % % %     %TODO: Ask about this online ....
% % % %     for iLine = 1:1  %length(cur_group) 
% % % %         cur_line_handle = cur_group(iLine);
% % % %         %this can fail if the line has already been deleted ...
% % % %         try
% % % %             %TODO: I'm not sure what we want to do if this happens
% % % %             %Why not add listeners to every line ????
% % % %             lhs{iG} = addlistener(cur_line_handle, 'ObjectBeingDestroyed',@(~,~)h__decrementPlotCount(obj,iG,iLine));
% % % %             n_active_lines = n_active_lines + 1;
% % % %         end
% % % %     end
% % % %     obj.plot_listeners{iG} = lhs;
% % % % end
% % % % obj.n_active_lines = n_active_lines;
% % % % 
% % % % if n_active_lines == 0
% % % %    stop(t);
% % % %    delete(t);
% % % % end

end

%--------------------------------------------------------------------------
%---------------------   Replotting      ----------------------------------
%Main entry call
function h__replotData(obj,s)
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

for iG = 1:obj.n_plot_groups
    
    %TODO: Verify that the lines are good
    
    %Reduce the data.
    %----------------------------------------
    if use_original
        x_r = obj.x_r_orig{iG};
        y_r = obj.y_r_orig{iG};
    else
        %sl.plot.big_data.LinePlotReducer.reduce_to_width
        [x_r, y_r] = obj.reduce_to_width(obj.x{iG}, obj.y{iG}, obj.n_samples_to_plot, new_x_limits);
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

obj.n_x_reductions = obj.n_x_reductions + 1;

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

new_x_limits  = s.new_xlim;
x_lim_changed = ~isequal(obj.last_rendered_xlim,new_x_limits);

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
    %By definition now this shouldn't be called ...
    redraw_option = NO_CHANGE;
end

end





%--------------------------------------------------------------------------
%---------------------- Cleanup -------------------------------------------
function h__decrementPlotCount(obj,iGroup,iLine)

obj.n_active_lines = obj.n_active_lines - 1;
delete(obj.plot_listeners{iGroup}{iLine});

if obj.n_active_lines <= 0
    %I don't like this name, I might change it ...
    obj.cleanup_figure(); 
end

end

function h__runTimer(obj)

cur_xlim = get(obj.h_axes,'xlim');

if ~isequal(obj.last_rendered_xlim,cur_xlim)
    
    
    

    for iG = obj.n_plot_groups
        if any(~ishandle(obj.h_plot{iG}))
            t = obj.timer;
            try
               stop(t)
               delete(t)
            end
            return;
        end
    end    
    
    
    
    
    s = struct;
    s.new_xlim = cur_xlim;
    
    try
        obj.renderData(s);
    catch ME
        obj.last_timer_error = ME;
        disp(ME)
        ME.stack(1)
        ME.stack(2)
    end
end
end