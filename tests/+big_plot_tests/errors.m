classdef errors
    %
    %   Class:
    %   big_plot_tests.errors
    
    properties
    end
    
    methods (Static)
        function NOT_YET_IMPLEMENTED()
            error('JAH:big_plot_tests:NYI','Functionality placed in test code that is not yet implemented')
        end
        function ERROR_DETECTED()
            error('JAH:big_plot_tests:generic_error','Error detected in the test code')
        end
        function ERROR_NOT_THROWN()
            error('JAH:big_plot_tests:error_not_thrown','An error was not thrown when it should have been')
        end
    end
    
end

