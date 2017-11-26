classdef callback_manager < handle
    %
    %   Class:
    %   big_plot.callback_manager
    %
    %   TODO: Switch to use Java callbacks ...
    %   https://www.mathworks.com/matlabcentral/answers/368964-queue-addlistener-events-or-place-event-on-edt
    
    properties
        parent
        fig_handle
        timer_h
        j_comp
        h_container
        last_string_index = 1;
        L1
        L2
    end
    

    
    methods
        function obj = callback_manager(parent)
            obj.parent = parent;
            obj.fig_handle = big_plot.persistent_figure.getFigure();
        end
        function initialize(obj,axes_handle)
            [obj.j_comp, temp] = javacomponent('javax.swing.JButton',[],obj.fig_handle);
            obj.h_container = handle(temp);
            set(obj.h_container,'BusyAction','queue','Interruptible','off');
            
            %TODO: do this when listeners are ready
            
            
            %TODO: Add listeners 
            
            
            if verLessThan('matlab', '8.4')
                size_cb = {'Position', 'PostSet'};
            else
                size_cb = {'SizeChanged'};
            end
            
            obj.L1 = addlistener(axes_handle, 'XLim',  'PostSet', @(~,~) obj.listenerCallback);
            obj.L2 = addlistener(axes_handle, size_cb{:}, @(~,~) obj.listenerCallback);
            
            set(obj.j_comp,'PropertyChangeCallback',@(~,~)obj.renderDataCallback());
            
%             timer_callback = @(~,~)obj.renderDataCallback();        
%             t = timer();
%             set(t,'Period',0.1,'ExecutionMode','fixedSpacing')
%             set(t,'TimerFcn',timer_callback);
%             start(t);
%             obj.timer_h = t;
        end
        function listenerCallback(obj)
            %This should trigger a EDT callback from the listener
            %
            %By doing this we queue the callbacks. Listeners don't queue so
            %we can miss them. Ideally this runs fast enough so that we
            %don't ever miss a valid change.
            
            %This can become invalid with user interaction
            try
                if obj.last_string_index == 1
                    obj.last_string_index = 2;
                    obj.j_comp.setText('a');
                else
                    obj.last_string_index = 1;
                    obj.j_comp.setText('b');
                end
            end
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
            try %#ok<TRYNC>
                delete(obj.j_comp);
            end
            try %#ok<TRYNC>
                delete(obj.h_container);
            end
            
%             t = obj.timer_h;
%             try %#ok<TRYNC>
%                 stop(t)
%                 delete(t)
%             end
        end
        function delete(obj)
            obj.killCallbacks();
        end
    end
end


    %{
    [j,btn] = uicomponent('style','javax.swing.JButton');
j.Interruptible = 'on';
j.Interruptible = 'off';
j.BusyAction = 'cancel'; %queue
j.BusyAction = 'queue';
btn.setText('LD')
%jButton = handle(jButton, 'CallbackProperties')
set(btn,'PropertyChangeCallback',@(a,b)cbwtf(a,b));


wtf = uicontrol('Parent', gcf, 'Style', 'edit','String','hello','Callback',@cbwtf);

set(wtf,'String','test')

%We could look at the value of the button text to handle
%which thing to process or whether to process or not ...

plot(1:100)

L = addlistener(gca, 'XLim', 'PostSet', @(~,~) cbwtf);

set(gcf,'HandleVisibility','off','Visible','off')
    
    
     javaComp = feval('javax.swing.JButton');
     [jcomp, hcontainer] = javacomponent(javaComp,position,parent);
    
    
    [comp, container] = javacomponent('javax.swing.JSpinner');
    
    %}
