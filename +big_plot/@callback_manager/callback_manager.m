classdef (Hidden) callback_manager < handle
    %
    %   Class:
    %   big_plot.callback_manager
    %
    %   Handles code related to triggering replot callbacks.
    %
    %   Currently the code replots when the XRuler is updated.
    %
    %
    %   https://www.mathworks.com/matlabcentral/answers/368964-queue-addlistener-events-or-place-event-on-edt
    %
    %   JAH Status: This class needs significant cleanup work. It has
    %   undergone a lot of changes as I tried to figure out what 
    %   call methods would yield the behavior that I wanted.
    
    properties
        parent
        fig_handle
        axes_handle
        
        j_comp
        callback_obj
        h_container
        
        %This gets toggled between 1 and 2 to force a change that throws
        %an event on the EDT
        last_string_index = 1;
        
        L3
        
        %This gets update ASAP when entering rendering
        last_processed_xlim
        perf_mon
        
        kill_already_run = false
        
        n_edt = 0
        t_edt = 0
    end
    
    
    
    methods
        function obj = callback_manager(parent)
            obj.parent = parent;
            obj.perf_mon = parent.perf_mon;
            obj.fig_handle = big_plot.persistent_figure.getFigure();
        end
        function initialize(obj,axes_handle)
            %
            %   This gets initialized in the first call to
            %   big_plot.renderData
            %
            %   For some details:
            %   https://www.mathworks.com/matlabcentral/answers/368964-queue-addlistener-events-or-place-event-on-edt
            
            
            %TODO: Break up by options ...
            
            %[obj.j_comp, temp] = javacomponent('javax.swing.JButton',[],obj.fig_handle);
            %obj.h_container = handle(temp);
            %set(obj.h_container,'BusyAction','queue','Interruptible','off');
            
            
            %Suggested solution, don't attach to figure
            %- doesnt' work ges to wrong figure
            %[obj.j_comp,temp] = javacomponent('javax.swing.JButton');
            
            
            
            obj.axes_handle = axes_handle;
            
            obj.L3 = addlistener(axes_handle.XRuler,'MarkedClean',@(~,~) obj.xrulerMarkedClean);
            
            
            %obj.j_comp.setActionCommand(@(~,~)obj.renderDataCallback());
            
            %set(obj.j_comp,'MouseClickedCallback',@(~,~)obj.renderDataCallback());
            
            %addActionListener
            
            %obj.j_comp.addActionListener(@(~,~)obj.renderDataCallback());
            
            
            %set(obj.j_comp,'PropertyChangeCallback',@(~,~)obj.renderDataCallback());

            %set(obj.j_comp,'ActionPerformedCallback',@(~,~)obj.renderDataCallback());
            
            
            obj.callback_obj = handle(com.mathworks.jmi.Callback,'callbackProperties');
             
            set(obj.callback_obj,'delayedCallback',@(~,~)obj.renderDataCallback());
            %callbackObj.postCallback;
        end
        function xrulerMarkedClean(obj)
            
            %No need to render if the xlim hasn't changed from what we last
            %rendered
            if isequal(obj.last_processed_xlim,get(obj.axes_handle,'XLim'))
                return
            end
            obj.throwCallbackOnEDT();
        end
        function throwCallbackOnEDT(obj)
            %This should trigger a EDT callback from the listener
            %
            %By doing this we queue the callbacks.
            %
            %This appears to be a bit slow - roughly 10 ms on my machine
            %- I'm not sure if another Java approach would be faster ...
            
            obj.n_edt = obj.n_edt + 1;
            
            h_tic = tic;
            %This can become invalid with user interaction
            try %#ok<TRYNC>
                %fprintf('1 %s\n',mat2str(get(obj.axes_handle,'xlim')));
                
                %OPTION 1
                %------------------
                %250 ms on my mac
                %obj.j_comp.doClick();
                
                %OPTION 2
                %-------------------
                %150 ms on my mac
%                 if obj.last_string_index == 1
%                     obj.last_string_index = 2;
%                     setText(obj.j_comp,'a');
%                     %obj.j_comp.setText('a');
%                 else
%                     obj.last_string_index = 1;
%                     setText(obj.j_comp,'b');
%                     %obj.j_comp.setText('b');
%                 end

                %OPTION 3
                %----------------------
                obj.callback_obj.postCallback();
                
                %fprintf('2 %s\n',mat2str(get(obj.axes_handle,'xlim')));
            end
            obj.t_edt = obj.t_edt + toc(h_tic);
        end
        function renderDataCallback(obj)
            %I generally expect failures to occur when the axes object
            %is being deleted during the rendering process.
            try
                obj.parent.renderData();
<<<<<<< HEAD
            catch ME 
                %This could probably use a little bit of cleanup work
                %
                %Basically, some of the properties in this class can
                %become invalid which triggers an error in the catch
                %which is not what we want - we never want an error thrown
                %in the catch
                try
                    obj.killCallbacks();
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
                catch
                    if strcmp(ME.identifier,'MATLAB:class:InvalidHandle')
                        obj.killCallbacks();
                    else
                        disp(ME);
                    end
=======
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
>>>>>>> 900880835e46c57b9cece7842743ffdeabca8eba
                end
                obj.killCallbacks();
                
            end
        end
        function killCallbacks(obj)
            %
            %   Who kills?
            %   1) Delete method
            %   2) big_plot>renderData - if none of the lines being 
            %   monitored are valid
            
            if obj.kill_already_run
                return
            else
                obj.kill_already_run = true;
            end
            
            obj.parent = [];
            
            try %#ok<TRYNC>
                delete(obj.h_container);
            end
            %delete(obj.j_comp);
            
            try %#ok<TRYNC>
                delete(obj.L3)
            end
            
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
