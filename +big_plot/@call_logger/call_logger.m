classdef call_logger < handle
    %
    %   Class:
    %   big_plot.call_logger

    properties
        enabled = false
        I = 0;
        data = {}
        %Must be manually enabled by grabbing this object
        %
        %   h = plotBig(data,'obj',true);
        %   h.call_logger.print_on_entry = true;

        print_on_entry = false
    end

    methods
        function obj = call_logger()
        end
        function enable(obj)
            obj.enabled = true;
            obj.data = cell(1,1000);
        end
        function addEntry(obj,varargin)
            if obj.enabled
                str = sprintf(varargin{:});
                obj.I = obj.I + 1;
                if obj.I > length(obj.data)
                    obj.I = 1;
                end
                obj.data{obj.I} = str;
                if obj.print_on_entry
                    fprintf('%s\n',str);
                end
            end
        end
    end
end