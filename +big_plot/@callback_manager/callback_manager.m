classdef callback_manager < handle
    %
    %   Class:
    %   big_plot.callback_manager
    %
    %   TODO: Switch to use Java callbacks ...
    %   https://www.mathworks.com/matlabcentral/answers/368964-queue-addlistener-events-or-place-event-on-edt
    
    properties
        parent
        timer_h
    end
    
    methods
        function obj = callback_manager(parent)
            obj.parent = parent;
        end
        function initialize(obj)
            timer_callback = @(~,~)obj.renderDataCallback();
            
            t = timer();
            set(t,'Period',0.1,'ExecutionMode','fixedSpacing')
            set(t,'TimerFcn',timer_callback);
            start(t);
            obj.timer_h = t;
        end
        function renderDataCallback(obj)
            %I generally expect failures to occur when the axes object
            %is being deleted during the rendering process.
            try
                obj.parent.renderData();
            catch ME
                obj.parent.last_render_error = ME;
                is_valid_group_mask = obj.parent.h_and_l.getValidGroupMask();
                if any(is_valid_group_mask)
                    %We will only display an error if the lines are still
                    %valid
                    disp(ME)
                    disp(ME.stack(1));
                    disp(ME.stack(2));
                    fprintf(2,'Killing timer, no more redraws of the current plot will occur\n');
                end
                obj.killCallbacks();
                
            end
        end
        function killCallbacks(obj)
            t = obj.timer_h;
            try %#ok<TRYNC>
                stop(t)
                delete(t)
            end
        end
        function delete(obj)
            obj.killCallbacks();
        end
    end
end

