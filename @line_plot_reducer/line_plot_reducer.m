classdef line_plot_reducer < handle
    %
    %   Class:
    %   line_plot_reducer
    %
    %   Manages the information in a standard MATLAB plot so that only the
    %   necessary number of data points are shown. For instance, if the
    %   width of the axis in the plot is only 500 pixels, there's no reason
    %   to have more than 1000 data points along the width. This tool
    %   selects which data points to show so that, for each pixel, all of
    %   the data mapping to that pixel is crushed down to just two points,
    %   a minimum and a maximum. Since all of the data is between the
    %   minimum and maximum, the user will not see any difference in the
    %   reduced plot compared to the full plot. Further, as the user zooms
    %   in or changes the figure size, this tool will create a new map of
    %   reduced points for the new axes limits automatically (it requires
    %   no further user input).
    %
    %   Using this tool, users can plot huge amounts of data without their
    %   machines becoming unresponsive, and yet they will still "see" all
    %   of the data that they would if they had plotted every single point.
    %   Zooming in on the data engages callbacks that replot the data with
    %   higher fidelity.
    %
    %   Examples:
    %   ---------
    %   line_plot_reducer(t, x)
    %
    %   line_plot_reducer(t, x, 'r:', t, y, 'b', 'LineWidth', 3);
    %
    %   line_plot_reducer(@plot, t, x);
    %
    %   line_plot_reducer(@stairs, axes_h, t, x);
    %
    %   Based On:
    %   ---------
    %   This code is based on:
    %   http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-/
    %
    %   This code is organized a bit better than that code, it handles
    %   callbacks a bit better, and it should run much faster.
    %
    %   See Also:
    %   ---------
    %   sci.time_series.data
    %   plotBig
    %
    %
    
    %{
    Callbacks:
    ----------
    
    %}
    
    %{
    Other functions for comparison:
    http://www.mathworks.com/matlabcentral/fileexchange/15850-dsplot-downsampled-plot
    http://www.mathworks.com/matlabcentral/fileexchange/27359-turbo-plot
    http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-/
    http://www.mathworks.com/matlabcentral/fileexchange/42191-jplot
    
    %}
    
    %{
    Relevant posts:
    http://blogs.mathworks.com/loren/2015/12/14/axes-limits-scream-louder-i-cant-hear-you/
    TODO: Summarize above post
    
    
    %}
    
    %External Files:
    %---------------
    %1) line_plot_reducer.init
    %2) line_plot_reducer.renderData
    %3) line_plot_reducer.reduce_to_width
    
    properties (Constant,Hidden)
        %This can be changed to throw out more or less error messages
        DEBUG = 0
        %1) Things related to callbacks
        %2) things from 1) and cleanup
        %
        %line_plot_reducer.callback_info
    end
    
    %------------           User Options         --------------------
    properties
        %These are not currently being used
        d0 = '------- User options --------'
        
        n_timers_max_before_redraw = 3;
        
        update_delay = 0.05 %This is how long after a zoom request the code
        %should wait before rendering the update. Ideally this is just long
        %enough to capture all resizing events.
        %
        %For example, if multiple axes are linked, there can be many
        %tens of resize events per single axes resize. Ideally the axes
        %resize is only rendered once for a given resize.
        
        post_render_callback = [] %This can be set to render
        %something after the data has been drawn .... Any inputs
        %should be done by binding to the anonymous function.
        %
        %   e.g. obj.post_render_callback = @()doStuffs(obj)
        %
        %   'obj' will now be available in the callback
        
        max_axes_width = 4000 %Eventually the idea was to make this
        %a function of the screen size. Currently we obtain max & min
        %points when fully zoomed out for this width.
        %
        %Used in renderData()
    end
    
    %------------------------   Handles  ----------------------------
    properties
        d1 = '--------  Handles, Listeners, & Timers ------'
        h_figure  %Figure handle. Always singular.
        
        h_axes %This is normally singular.
        %There might be multiple axes for plotyy - NYI
        %
        %   The value is assigned either as an input to the constructor
        %   or during the first call to renderData()
        %
        
        h_plot %cell, {1 x n_groups} one for each group of x & y
        %
        %   e.g. plot(x1,y1,x2,y2,x3,y3) produces 3 groups
        %
        %   This should really be h_line, to be more specific
        
        
        timers %cell, {1 x n_axes} - these are held onto between the
        %callback and the final call by the timer to render the plot
        
        %TODO: This should be a sub-object that does some of this work
        %for us ...
        resize_times %array
        processed_resize_times %array
        resize_ids
        processed_ids
        
        timer_null_run_count %array
        resize_data %{struct}
        n_resize_calls = 0 %# of times the figure detected a resize
        n_render_calls = 0 %We'll keep track of the # of renders done
        
        
        axes_listeners %cell, {1 x n_axes}
        plot_listeners %cell, {1 x n_groups}
    end
    
    %--------------------------    Input Data       -----------------------
    properties
        d2 = '-------  Input Data -------'
        plot_fcn %e.g. @plot
        
        linespecs %cell
        %Each element is paired with the corresponding pair of inputs
        %
        %   plot(x1,y1,'r',x2,y2,'c')
        %
        %   linspecs = {{'r'} {'c'}}
        
        extra_plot_options = {} %cell
        %These are the parameters that go into the end of a plot function,
        %such as {'Linewidth', 2}
        
        x %cell Each cell corresponds to a different pair of inputs.
        %
        %   plot(x1,y1,x2,y2)
        %
        %   x = {x1 x2}
        
        y %cell, same format as 'x'
    end
    
    %---------------  Intermediate Variables -------------------
    properties
        d3 = '----- Intermediate Variables ------'
        
        %   This is the original reduced data for the full sized plot
        x_r_orig %cell
        y_r_orig %cell
        
        %TODO: These 2 properties aren't being used
        %We will need to use them for sliding
        %----------------------------------------------------
        x_r_last
        %   This contains the last set of reduced data that was plotted
        y_r_last
        
        last_rendered_axes_width %This is currently not valid as we have
        %hardcoded the render width
        
        last_rendered_xlim
        x_lim_original
        
        last_render_time = now
        
        busy %This will be used when quick drawing is enabled to prevent
        %quick drawing from ever getting piled up.
        %
        %Right now it is only being used in the timer callback and even
        %there it is only being set, not really used.
        
        %TODO: Add listeners to lines so that when they are deleted
        %everything is deleted
        needs_initialization = true
        
        last_callback_time
    end
    
    properties (Dependent)
        n_plot_groups %The number of sets of x-y pairs that we have. See
        %example above for 'x'. In that data, regardless of the size of
        %x1 and x2, we have 2 groups (x1 & x2).
    end
    methods
        function value = get.n_plot_groups(obj)
            value = length(obj.x);
        end
    end
    
    %------------------------     Debugging    ----------------------------
    properties
        d4 = '------ Debugging ------'
        last_error
        id %A unique id that can be used to identify the plotter
        %when working with callback optimization, i.e. to identify which
        %object is throwing the callback (debugging)
        
        %callback_info %sl.plot.big_data.line_plot_reducer.callback_info
        %Not sure what I'm going to store here
        

        n_x_reductions = 0 %# of times we needed to reduce the data
        %This is the slow part of the code and ideally this is not called
        %very often.
        
        %TODO: This is no longer relevant ...
        last_redraw_used_original = true
        last_redraw_was_quick = false
        
        %The goal here is to force a maximum time that occurs
        %before a quick redraw occurs
        %-----------------
        earliest_unhandled_plot_callback_time = []
        %When a callback occurs, if this is empty, it gets set
        %It can then later be used to
    end
    
    %Constructor
    %-----------------------------------------
    methods
        function obj = line_plot_reducer(varargin)
            %x
            %
            %   obj = sl.plot.big_data.LinePlotReducer(varargin)
            %
            %   TODO: Add examples
            %
            %   See Also:
            %   plotBig()
            
            
            %I'm hiding the initialization details in another file to
            %reduce the high indentation levels and the length of this
            %function.
            %
            %	line_plot_reducer.init
            obj.init(varargin{:});
            
        end
    end
    
    methods

    end
    
    methods (Static)
        [x_reduced, y_reduced, extras] = reduce_to_width(x, y, axis_width_in_pixels, x_limits, varargin)
    end
    
end


