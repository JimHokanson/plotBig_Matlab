classdef big_plot < handle
    %
    %   Class:
    %   big_plot
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
    %   Usage
    %   -----
    %   1) Call plotBig
    %   
    %   Examples:
    %   ---------
    %   b = big_plot(t, y)
    %
    %   b = big_plot(t, y, 'r:', t, y2, 'b', 'LineWidth', 3);
    %
    %   big_plot(@plot, t, x);
    %
    %
    %   Based On:
    %   ---------
    %   This code is based on:
    %   http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-/
    %
    %   Differences include:
    %       - inclusion of time option
    %
    %   See Also
    %   --------
    %   plotBig
        
    %{
    Other functions for comparison:
        http://www.mathworks.com/matlabcentral/fileexchange/15850-dsplot-downsampled-plot
        http://www.mathworks.com/matlabcentral/fileexchange/27359-turbo-plot
        http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-/
        http://www.mathworks.com/matlabcentral/fileexchange/42191-jplot
    %}
    
    %{
    Relevant post:
    http://blogs.mathworks.com/loren/2015/12/14/axes-limits-scream-louder-i-cant-hear-you/
    Basically this says that you might not always get an event when the
    x-limit changes. Instead I've decided to use a timer ...
    
    %}
    
    %------------           User Options         --------------------
    properties
        %These are not currently being used
        d0 = '------- User options --------'
        
        %TODO: We could get the # of pixels and potentially
        %use much less ...
        n_samples_to_plot = 4000;
        
        min_time_between_callbacks = 0.2;
        
        post_render_callback = [] %This can be set to render
        %something after the data has been drawn .... Any inputs
        %should be done by binding to the anonymous function.
        %
        %   e.g. obj.post_render_callback = @()doStuffs(obj)
        %
        %   'obj' will now be available in the callback
    end
    
    properties
        id %A unique id that can be used to identify the plotter
        %when working with callback optimization, i.e. to identify which
        %object is throwing the callback (debugging)
        
        h_and_l     %big_plot.handles_and_listeners
        
        data        %big_plot.data
        
        render_info %big_plot.render_info
    end
    
    %------------------------     Debugging    ----------------------------
    properties
        %This could all get merged into a timer class ...
        timer %See h__runTimer() in renderData
        
        n_resize_calls = 0 %# of times the figure detected a resize
        
        last_timer_error
    end
    
    properties (Hidden)
        timer_callback %The function that the timer is running. I exposed
        %this here so that it could be called manually. I'm not thrilled
        %with this layout. The callback should probably be moved 
        %so that we can call it directly
        
        manual_callback_running = false
        
        %callback_info %sl.plot.big_data.line_plot_reducer.callback_info
        %Not sure what I'm going to store here
        
    end
    
    %Constructor
    %-----------------------------------------
    methods
        function obj = big_plot(varargin)
            %x
            %
            %   obj = big_plot(varargin)
            %
            %   See Also:
            %   plotBig()
            
            temp = now;
            obj.id = int2str(uint64(floor(1e8*(temp - floor(temp)))));
            
            %We need to be able to reference back to the timer so
            %we pass in the object
            obj.h_and_l = big_plot.handles_and_listeners(obj);
            
            %Population of the input data and plotting instructions ...
            %We might update the axes, so we pass in h_and_l
            obj.data = big_plot.data(obj.h_and_l,varargin{:});
            
            obj.render_info = big_plot.render_info(obj.data.n_plot_groups);
            
            %Now wait for the user to update things and to render the data
            %by calling obj.renderData
        end
        function triggerRender(obj)
            obj.timer_callback();
        end
        function delete(obj)
            t = obj.timer;
            try
                stop(t);
                delete(t);
            end
            obj.timer = [];
        end
    end
    
end


