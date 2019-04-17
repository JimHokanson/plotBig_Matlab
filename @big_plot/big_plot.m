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
    
    %   Code in other files
    %   big_plot.renderData
    
    %Classes
    %--------
    %big_plot.data
    %big_plot.handles_and_listeners
    %big_plot.render_info
    
    
    %{
    Other functions for comparison:
        http://www.mathworks.com/matlabcentral/fileexchange/15850-dsplot-downsampled-plot
        http://www.mathworks.com/matlabcentral/fileexchange/27359-turbo-plot
        http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-/
        http://www.mathworks.com/matlabcentral/fileexchange/42191-jplot
    %}
        
    %------------           User Options         --------------------
    properties
        %These are not currently being used
        d0 = '------- User options --------'
                
        %This value doesn't appear to be critical although it should be
        %larger than the # of pixels on the screen
        n_min_max_pairs = 4000;
        
        post_render_callback = [] %This can be set to render
        %something after the data has been drawn .... Any inputs
        %should be done by binding to the anonymous function.
        %
        %   e.g. obj.post_render_callback = @()doStuffs(obj)
        %
        %   'obj' will now be available in the callback
    end
    
    properties
        d1 = '-------- Internal Properties --------'
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
    
    %---------------------    Internal    -----------------------------
    properties
        force_rerender = false;
    end
    
    %--------------------------------------------------------
    %               Public/Static Methods
    %--------------------------------------------------------
    methods (Static)
%         function setAxisZeroedTime(h_axes,zero_time)
%             
%         end
%         function zero_time = getAxisZeroedTime(h_axes)
%             
%         end
        function cleanFigure(h_fig,varargin)
            %Currently this clears the plot callbacks
            %
            %- Eventually this should allow replacing with the actual data
            h_line = findall(h_fig,'type','line');
            for i = 1:length(h_line)
                ptr = big_plot.getRawDataPointer(h_line(i));
                if ~isempty(ptr)
                    ptr.disconnectFromFigure();
                end
            end
        end
        function setAxisAbsoluteStartTime(h_axes,start_time)
            %
            %   big_plot.setAxisAbsoluteStartTime(h_axes,start_time)
            %
            %   Inputs
            %   ------
            %   h_axes : Matlab axes handle
            %   start_time :
            %       TODO: Describe
            %
            %   See Also
            %   ---------
            %   big_plot.axis_time
            %   big_plot.axis_time.setStartTime
            
             big_plot.axis_time.setStartTime(h_axes,start_time)
        end
        function start_time = getAxisAbsoluteStartTime(h_axes)
            %
            %  start_time = big_plot.getAxisAbsoluteStartTime(h_axes)
            
             start_time = big_plot.axis_time.getStartTime(h_axes);
        end
        function ptr = getRawDataPointer(h_line)
            %
            %   ptr = big_plot.getRawDataPointer(h_line)
            %
            %   Inputs
            %   ------
            %   h_line : Matlab line handle
            %
            %   Outputs
            %   -------
            %   ptr : [] OR big_plot.line_data_pointer
            %       The pointer class holds simple references to objects
            %       of interest, notably to a big_plot instance.
            %
            
            
            ptr = big_plot.line_data_pointer.retrieveFromLineHandle(h_line);
            
            
        end
        function s = getRawLineData(h_line,varargin)
            %
            %   s = big_plot.getRawLineData(h_plot,varargin)
            %
            %   This method allows retrieval of the underlying line data. This is
            %   needed because big_plot may only render a small percentage of the data,
            %   so queries of the
            %
            %   Inputs
            %   ------
            %   h_line
            %
            %   Optional Inputs (see big_plot.raw_line_data_options)
            %   -----------------------------------------------------------
            %   get_x_data : default true
            %       If false, the corresponding x-data are not returned. 
            %       This can save on memory if it isn't needed.
            %   xlim : [min_time  max_time] (default [])
            %       When empty all data are returned.
            %   get_calibrated : default true
            %       If true, calibration data is returned when available.
            %   get_raw : default false
            %       If true, raw data is returned. Both raw and calibrated 
            %       data can be returned.
            %
            %   Outputs
            %   -------
            %   s : big_plot.raw_line_data
            %
            %   Improvements
            %   ------------
            %   - Allow processing of a vector of handles ...
            
            in = big_plot.raw_line_data_options;
            in = big_plot.sl.in.processVarargin(in,varargin);
            
            %Note we might want both raw and calibrated so get_raw is not
            %~in.get_calibrated
            if ~in.get_calibrated
                in.get_raw = true;
            end
            
            %This is populated during line creation. It is a bit awkward
            %which is why this function was created.
            ptr = big_plot.getRawDataPointer(h_line);
            
            if isempty(ptr)
                s = big_plot.raw_line_data.fromStandardLine(h_line,in);
            else
                s = ptr.getRawLineData(in);
            end
            
            
        end
        function forceRender(line_handles)
            %
            %   big_plot.forceRender(line_handles)
            
            for i = 1:length(line_handles)
                ptr = big_plot.getRawDataPointer(line_handles(i));
                if ~isempty(ptr)
                   ptr.forceRerender(); 
                end
            end
        end
        function setCalibration(h_line,calibration)
            %
            %
            %   big_plot.setCalibration(h_plot,calibration)
            %
            %   Inputs
            %   ------
            %   h_line :
            %   calibration :
            %
            %   Written for use with interactive_plot
            %
            %   See Also
            %   --------
            %   interactive_plot.data_interface
            
            ptr = big_plot.getRawDataPointer(h_line);
            
            if isempty(ptr)
                %Then we just have raw data, nothing fancy
                y = get(h_line,'YData');
                y2 = y*calibration.m + calibration.b;
                set(h_line,'YData',y2);
            else
                ptr.setCalibration(calibration);
            end
        end
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
            obj.data = big_plot.data(obj,obj.h_and_l,varargin{:});
            obj.perf_mon.init_data = toc(t);
            
            t = tic;
            obj.render_info = big_plot.render_info(obj.data.n_plot_groups);
            obj.perf_mon.init_render = toc(t);
            
            obj.callback_manager = big_plot.callback_manager(obj);
            
            %If our data contains an object, then update that object
            %with the appropriate callbacks
            %--------------------------------------------------------------
            if obj.data.y_object_present
                %Add callback
                if length(obj.data.y) > 1
                    error('Case not yet handled')
                else
                    obj.data.y{1}.calibration_callback = @obj.calibrationUpdated;
                    obj.data.y{1}.data_added_callback = @(new_x_start) h__dataAdded(obj,new_x_start);
                end
            end
            
            %At this point nothing has been rendered.
            
            %We wait until the user chooses to render the class. This is
            %done automatically with plotBig. It can also be done manually
            %with renderData()
        end
        function h = getAllLineHandles(obj)
            all_lines = obj.h_and_l.h_line;
            h = vertcat(all_lines{:});
        end
    end
    
    methods (Hidden)
        function calibrationUpdated(obj)
            %
            %   TODO: Who calls this? Interactive plot? Streaming Data
            %
            %   See Also
            %   --------
            %   big_plot.setCalibration
            
            obj.forceRerender();
        end
        function forceRerender(obj)
            try %#ok<TRYNC>
                obj.force_rerender = true;
                obj.callback_manager.throwCallbackOnEDT();
            end
        end
        function killAll(obj)
            obj.callback_manager.killCallbacks();
            delete(obj.data)
            delete(obj.h_and_l)
            delete(obj.callback_manager);
            delete(obj.render_info);
            obj.data = [];
            obj.h_and_l = [];
            obj.render_info = [];
            obj.callback_manager = [];
            %disp('killing all')
        end
        function delete(obj)
            %disp('delete running')
        end
    end
end


function h__dataAdded(obj,new_x_start)
%For adding data we'll assume we're adding onto the right end
%
%   Thus we might want to rerendering if we have something like the
%   following.
%
%   Axes     x------------------------------x
%   Old Data x---------x
%   New Data           x------x
%
%   We want to rerender to force visualization of the new data
%
%   We don't necessarily want to rerender if we have:
%   Axes     x---------------x
%   Old Data x------------------x
%   New Data                    x------x
%
%   i.e. from zooming in on the old data
%
%   Usage
%   -----
%   This callback is placed into streaming data objects to be called
%   if the user adds any data to the streaming data class. If this is
%   done the streaming data class should call this callback.
%

%handle might become invalid from user ...
try %#ok<TRYNC>
    cur_xlim = get(obj.h_and_l.h_axes,'XLim');
    %if obj.rerender_on_adding_in_bounds_data && new_x_start <= cur_xlim(2)
  	if new_x_start <= cur_xlim(2)
        %Normally we check on the xlims to determine if we want to rerender
        %or not. Thus we have this variable which says to rerender even
        %though the xlims haven't changed
        obj.forceRerender();
    end
end
end


