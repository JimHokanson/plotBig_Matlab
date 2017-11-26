classdef big_plot < handle
    %
    %   Class:
    %   big_plot
    %
    %   Manages the information in a standard MATLAB plot so that only the
    %   necessary number of data points are shown. For instance, if the
    %   width of the axis in the plot is only 500 pixels, there's no reason
    %   to have more than 1000 data points along the width (Technically
    %   slightly more may be desireable due to anti-aliasing). This tool
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
    %   Examples
    %   --------
    %   b = big_plot(t, y)
    %
    %   b = big_plot(t, y, 'r:', t, y2, 'b', 'LineWidth', 3);
    %
    %   big_plot(@plot, t, x);
    %
    %
    %   Based On
    %   --------
    %   This code is based on:
    %   http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-/
    %
    %   Differences include:
    %       - inclusion of time option (dt,t0) to reduce memory usage
    %       - min/max reduction based on samples, rather than finding
    %         which samples should procssed based on a time vector,
    %         resulting in much faster processing
    %       - multi-thread processing
    %       
    %
    %   See Also
    %   --------
    %   plotBig
    
    %Classes
    %--------
    %big_plot.handles_and_listeners
    
        
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
        
        %- This could be less, but requires extra processing
        %- This is actually 1/2 the # of plotted values, since the current
        %  processor returns min/max for each "sample to plot"
        n_samples_to_plot = 4000;
                
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
        
        perf_mon    %big_plot.perf_mon
        
        h_and_l     %big_plot.handles_and_listeners
        
        data        %big_plot.data
        
        render_info %big_plot.render_info
        
        callback_manager %big_plot.callback_manager
    end
    
    %------------------------     Debugging    ----------------------------
    properties
        render_in_progress = false
        
        %This gets set by the callback_manager
        last_render_error %ME
        
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
            
            obj.perf_mon = big_plot.perf_mon;
            
            %We need to be able to reference back to the timer so
            %we pass in the object
            t = tic;
            obj.h_and_l = big_plot.handles_and_listeners(obj);
            obj.perf_mon.init_h_and_l = toc(t);
            
            %Population of the input data and plotting instructions ...
            %We might update the axes, so we pass in h_and_l
            t = tic;
            obj.data = big_plot.data(obj.h_and_l,varargin{:});
            obj.perf_mon.init_data = toc(t);
            
            t = tic;
            obj.render_info = big_plot.render_info(obj.data.n_plot_groups);
            obj.perf_mon.init_render = toc(t);
            
            obj.callback_manager = big_plot.callback_manager(obj);
            
            %At this point nothing has been rendered. We wait until 
            %the user chooses to render the class. This is done
            %automatically with plotBig. It can also be done manually with
            %renderData()
        end

    end
    
end


