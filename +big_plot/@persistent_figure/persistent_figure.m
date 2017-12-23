classdef (Hidden) persistent_figure
    %
    %   big_plot.persistent_figure.getFigure()
    
    properties
    end
    
    methods (Static)
        function value = getFigure()
            %
            %   value = big_plot.persistent_figure.getFigure()
            
            persistent fig_handle
            if isempty(fig_handle) || ~isvalid(fig_handle)
                fig_handle = figure(1e8);
                set(fig_handle,'Visible','off','HandleVisibility','off');
            end
            value = fig_handle;
        end
    end
    
end

