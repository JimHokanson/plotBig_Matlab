classdef (Hidden) handles_and_listeners < handle
    %
    %   Class:
    %   big_plot.handles_and_listeners
    %
    %   This class holds onto all the Matlab handles (figure, axes, line)
    %   as well as listeners that listen for when a line is going to be
    %   destroyed ...
    
    
    %{
    
    
    %}
    
    properties
        parent %big_plot
        
        h_figure  %Figure handle. Always singular.
        
        h_axes %Currently must be singular.
        %
        %   The value is assigned either as an input to the constructor
        %   or during the first call to renderData()
        
        
        %TODO: I'd like to get rid of this and just have a linear array
        %
        %This will later facilitate merging multiple lines in one manager
        h_line %cell, {1 x n_groups} one for each group of x & y
        %
        %   e.g. plot(x1,y1,x2,y2,x3,y3) produces 3 groups
        %
        
        group_to_linear_map %cell
        %index into this to get the index of the relevant line handle 
        %in h_lines_array
        %
        %   e.g obj.group_to_linear_map{2}(3) => 5
        %
        %   This indicates that group 2, the 3rd h_line handle is in the 
        %   linear array at position 5. This was added for mapping 
        %   back to the h_lines_array and listen_array.
        
        h_lines_array %an array of all line handles
        listen_array %cell of listeners
        
        n_plot_groups
        
        n_lines_active %Every time a line object is deleted this is 
        %decremented. When it gets to 0 we have no more active lines in 
        %the big_plot object.
        
    end
    
    methods
        function obj = handles_and_listeners(parent)
            obj.parent = parent;
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
        function mask = getValidGroupMask(obj)
            %TODO: Document this ...
            mask = cellfun(@(x) all(ishandle(x)),obj.h_line);
        end
        function initializePlotHandles(obj,n_plot_groups,temp_h_line,temp_h_indices)
            %
            %   Break up plot handles to be the same as the inputs. When
            %   plotting all objects are returned as an array.
            %
            %   e.g.
            %       plot(x1,y1,x2,y2)
            %
            %   This returns one array of handles, but we break it back up into
            %   handles for 1 and 2
            %
            %   {h1 h2} - where h1 is from x1,y1, h2 is from x2,y2
            %
            %   Inputs
            %   ------
            %   n_plot_groups :
            %   temp_h_line : array of Matlab line handles
            %   temp_h_indices : cell {1 n_groups}
            %       For each group, specifies which indices in the linear
            %       array to grab for that groups lines.
            
            obj.h_lines_array = temp_h_line;
            obj.group_to_linear_map = temp_h_indices;
            
            obj.n_lines_active = length(temp_h_line);
            
            obj.n_plot_groups = n_plot_groups;
            
            obj.h_line = cell(1,n_plot_groups);
            if ~isempty(temp_h_line)
                for iG = 1:n_plot_groups
                    obj.h_line{iG} = temp_h_line(temp_h_indices{iG});
                end
            end
            
            obj.listen_array = cell(1,length(temp_h_line));
            for i = 1:length(temp_h_line)
                %When the line is being destroyed, remove callbacks ...
                obj.listen_array{i} = addlistener(temp_h_line(i), 'ObjectBeingDestroyed',@(~,~) obj.clearLine(i));
            end
        end
        function clearLine(obj,line_I,group_I)
            %
            %   Calling Forms
            %   -------------
            %   obj.clearLine(linear_line_I)
            %
            %   obj.clearLine(line_I,group_I)
            %
            %   
            %   This is called whenever a line is destroyed.
            %
            %   TODO: Eventually it would be nice to be able to call
            %   this directly as well
            %
            %   Inputs
            %   ------
            %   linear_line_I : scalar
            %       This indexes into a linear array of line handles. This
            %       does not map into line indexes that 
            
            if nargin == 3
                line_I = obj.group_to_linear_map{group_I}(line_I);
                if isempty(obj.listen_array{line_I})
                    %Already cleared ...
                   return 
                end
            end
            obj.n_lines_active = obj.n_lines_active - 1;
            h_line2 = obj.h_lines_array(line_I); 
            

            ptr = big_plot.line_data_pointer.retrieveFromLineHandle(h_line2);
            delete(ptr);
            delete(obj.listen_array{line_I});
            
            if obj.n_lines_active == 0
                obj.parent.killAll()
            end
            
        end
    end
    
end

