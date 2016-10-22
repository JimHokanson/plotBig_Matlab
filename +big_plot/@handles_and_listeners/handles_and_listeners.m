classdef handles_and_listeners < handle
    %
    %   Class:
    %   big_plot.handles_and_listeners
    
    properties
        parent %big_plot
        
        h_figure  %Figure handle. Always singular.
        
        h_axes %
        %
        %   The value is assigned either as an input to the constructor
        %   or during the first call to renderData()
        
        h_plot %cell, {1 x n_groups} one for each group of x & y
        %
        %   e.g. plot(x1,y1,x2,y2,x3,y3) produces 3 groups
        %
        %   This should really be h_line, to be more specific
        
        axes_listeners %array
        plot_listeners %cell, {1 x n_groups}{1 x n_lines}
        n_active_lines %We decrement this until it gets to zero, then
        %we clear the timer
    end
    
    methods
        function obj = handles_and_listeners(parent)
            obj.parent = parent;
            %obj.n_plot_groups = n_plot_groups;
        end
        function plot_args = initializeAxes(obj)
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
        function initializePlotHandles(obj,n_plot_groups,temp_h_plot,temp_h_indices)
            %Break up plot handles to be grouped the same as the inputs were
            %---------------------------------------------------------------
            %e.g.
            %plot(x1,y1,x2,y2)
            %This returns one array of handles, but we break it back up into
            %handles for 1 and 2
            %{h1 h2} - where h1 is from x1,y1, h2 is from x2,y2
            obj.h_plot = cell(1,n_plot_groups);
            if ~isempty(temp_h_plot)
                for iG = 1:n_plot_groups
                    obj.h_plot{iG} = temp_h_plot(temp_h_indices{iG});
                end
            end
        end
        function intializeListeners(obj)
            obj.axes_listeners = event.listener(obj.h_axes,'ObjectBeingDestroyed',@(~,~)obj.cleanup_figure());
            
            n_groups = length(obj.h_plot);
            
            obj.plot_listeners = cell(1,n_groups);
            
            %What we really need is when the # of plots drops, we clear the timer ...
            
            %This needs to be fixed, I thought it was causing a problem but it looks
            %like it wasn't ...
            
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
        function delete(obj)
            delete(obj.axes_listeners);
        end
        function cleanup_figure(obj)
            %This should be renamed to close figure callback ...
            %or clear axes ...???

            %TODO: Should really just ignore this, the try is a bit broad
            %MATLAB:class:DestructorError
            
            try
            t = obj.parent.timer;
            
                stop(t);
                delete(t);
            
            obj.parent.timer = [];
            end
        end
    end
    
end

