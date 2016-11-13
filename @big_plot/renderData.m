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

obj.render_info.incrementRenderCount();

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

%NOTE: This doesn't support stairs or plotyy
temp_h_plot = obj.data.plot_fcn(plot_args{:});

obj.h_and_l.initializePlotHandles(obj.data.n_plot_groups,temp_h_plot,temp_h_indices);

%This needs to be fixed
%The idea is to be able to fetch the raw data from the line ...
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
obj.h_and_l.intializeListeners();

h__setupTimer(obj);

drawnow();

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
%the screen. I've not just hardcoded a "large" screen size.
%
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

for iG = 1:n_plot_groups
    %Reduce the data.
    %----------------------------------------
    [x_r, y_r, range_I] = big_plot.reduce_to_width(obj.data.x{iG}, obj.data.y{iG}, n_samples_plot, [-Inf Inf]);
    
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
    obj.render_info.logRenderCall(iG,x_r,y_r,range_I,true,NaN);
    
    plot_args = [plot_args {x_r y_r}]; %#ok<AGROW>
    
    cur_linespecs = obj.data.linespecs{iG};
    if ~isempty(cur_linespecs)
        plot_args = [plot_args {cur_linespecs}]; %#ok<AGROW>
    end
    
end

%TODO: Can we just grab the first and the last ????
%TODO: We might have NaNs
orig_x_limits = [min(group_x_min) max(group_x_max)];
obj.render_info.logOriginalXLim(orig_x_limits);

obj.render_info.incrementReductionCalls();

if ~isempty(obj.data.extra_plot_options)
    plot_args = [plot_args obj.data.extra_plot_options];
end



end

%1.3) Timer setup
function h__setupTimer(obj)
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

end

%--------------------------------------------------------------------------
%---------------------   Replotting      ----------------------------------
%2) Main function for replotting
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

new_x_limits = s.new_xlim;

redraw_option = obj.render_info.determineRedrawCase(new_x_limits);

use_original = false;
switch redraw_option
    case 0
        %no change needed
        return
    case 1
        %reset data to original view
        use_original = true;
        %obj.last_redraw_used_original = true;
    case 2
        %recompute data for plotting
        %obj.last_redraw_used_original = false;
        obj.render_info.incrementReductionCalls();
    otherwise
        error('Uh oh, Jim broke the code')
end

for iG = 1:obj.data.n_plot_groups
    
    %TODO: Verify that the lines are good
    
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
        %sl.plot.big_data.LinePlotReducer.reduce_to_width
        [x_r, y_r, range_I, same_range] = big_plot.reduce_to_width(x_input, obj.data.y{iG}, obj.n_samples_to_plot, new_x_limits, last_I);
        
        if same_range
            obj.render_info.logNoRenderCall(new_x_limits);
            continue
        end
    end
    
    %disp([x_r(1) x_r(end)])
    
    obj.render_info.logRenderCall(iG,x_r,y_r,range_I,use_original,new_x_limits);
    
    %TODO: At some point we might not be rendering everything due to:
    %1) No changes in the range_I
    %2) Invalid handles ...
    
    local_h = obj.h_and_l.h_plot{iG};
    
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
    
    %pause(0.1)
    %drawnow()
end

end

%--------------------------------------------------------------------------
%---------------------- Cleanup -------------------------------------------
%1) Not currently used ...
function h__decrementPlotCount(obj,iGroup,iLine)

obj.n_active_lines = obj.n_active_lines - 1;
delete(obj.plot_listeners{iGroup}{iLine});

if obj.n_active_lines <= 0
    %I don't like this name, I might change it ...
    obj.cleanup_figure();
end

end

function h__runTimer(obj)

cur_xlim = get(obj.h_and_l.h_axes,'xlim');

if ~isequal(obj.render_info.last_rendered_xlim,cur_xlim)
    
    %TODO: This will most likely be changing
    %once I reimplement the plot listeners
    n_plot_groups = obj.data.n_plot_groups;
    h_plot = obj.h_and_l.h_plot;
    for iG = 1:n_plot_groups
        if any(~ishandle(h_plot{iG}))
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
        try
            fprintf(2,'Killing timer, no more redraws of the current plot will occur\n');
            t = obj.timer;
            stop(t)
            delete(t)
        end
    end
end
end