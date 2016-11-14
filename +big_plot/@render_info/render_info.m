classdef render_info < handle
    %
    %   Class:
    %   big_plot.render_info
    
    properties (Hidden)
        n_groups
    end
    
    properties
        orig_x_r %cell
        orig_y_r %cell
        
        %We'll keep track of this so that we can potentially do a
        %no-operation ...
        last_I
        last_x_r
        last_y_r
        
        original_xlim
        last_rendered_xlim
        
        last_render_time = 0
        
        n_render_calls = 0
        n_reduction_calls = 0
        n_same_range_calls = 0;
    end
    
    methods
        function obj = render_info(n_groups)
            obj.n_groups = n_groups;
            
            obj.orig_x_r = cell(1,n_groups);
            obj.orig_y_r = cell(1,n_groups);
            
            obj.last_x_r = cell(1,n_groups);
            obj.last_y_r = cell(1,n_groups);
            
            obj.last_I = cell(1,n_groups);
        end
        function logNoRenderCall(obj,x_limits)
            obj.last_rendered_xlim = x_limits;
            obj.n_same_range_calls = obj.n_same_range_calls + 1;
        end
        function incrementRenderCount(obj)
            obj.n_render_calls = obj.n_render_calls + 1;
        end
        function incrementReductionCalls(obj)
            obj.n_reduction_calls = obj.n_reduction_calls + 1;
        end
        %I'm not thrilled with this layout, I think this might change ...
        function logOriginalXLim(obj,x_limits)
            obj.last_rendered_xlim = x_limits;
            obj.original_xlim = x_limits;
        end
        function logRenderCall(obj,group_I,x_r,y_r,range_I,is_original,x_limits)
            obj.last_x_r{group_I} = x_r;
            obj.last_y_r{group_I} = y_r;
            obj.last_I{group_I} = range_I;
            
            obj.last_rendered_xlim = x_limits;
            
            if is_original
                obj.orig_x_r{group_I} = x_r;
                obj.orig_y_r{group_I} = y_r;
                obj.original_xlim = x_limits;
            end
        end
        function redraw_option = determineRedrawCase(obj,new_x_limits)
            %
            %   redraw_option = h__determineRedrawCase(obj,s)
            %
            %   Outputs:
            %   --------
            %   redraw_option:
            %       - 0 - no change needed
            %       - 1 - reset data to original view
            %       - 2 - recompute data for plotting
            
            x_lim_changed = ~isequal(obj.last_rendered_xlim,new_x_limits);
            
            NO_CHANGE = 0;
            RESET_TO_ORIGINAL = 1;
            RECOMPUTE_DATA_FOR_PLOTTING = 2;
            
            if x_lim_changed
                %x_lim changed almost always means a redraw
                %Let's build a check in here for being the original
                %If so, go back to that
                if new_x_limits(1) <= obj.original_xlim(1) && new_x_limits(2) >= obj.original_xlim(2)
                    redraw_option = RESET_TO_ORIGINAL;
                else
                    redraw_option = RECOMPUTE_DATA_FOR_PLOTTING;
                end
            else
                %By definition now this shouldn't be called ...
                redraw_option = NO_CHANGE;
            end
            
        end
    end
    
end

