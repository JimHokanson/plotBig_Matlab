classdef (Hidden) data < handle
    %
    %   Class:
    %   big_plot.data
        
    properties
        parent
        
        plot_fcn %e.g. @plot
        
        linespecs %cell
        %Each element is paired with the corresponding pair of inputs
        %
        %   plot(x1,y1,'r',x2,y2,'c')
        %
        %   linspecs = {{'r'} {'c'}}
        
        extra_plot_options = {} %cell
        %These are the parameters that go into the end of a plot function,
        %such as {'Linewidth', 2}
        
        x %cell Each cell corresponds to a different pair of inputs.
        %
        %   plot(x1,y1,x2,y2)
        %
        %   x = {x1 x2}
        
        y %cell, same format as 'x'
        % - contains either column vector, matrix or data object
        %   such as big_plot.streaming_data
        
        
        y_object_present = false;
    end
    
    properties (Dependent)
        n_plot_groups %The number of sets of x-y pairs that we have. See
        %example above for 'x'. In that data, regardless of the size of
        %x1 and x2, we have 2 groups (x1 & x2).
    end
    methods
        function value = get.n_plot_groups(obj)
            value = length(obj.x);
        end
    end
    
    methods
        function obj = data(parent, hl, varargin)
            %Call into helper to reduce indentation ...
            obj.parent = parent;
           h__init(obj, hl, varargin{:}); 
        end
        function initRawDataPointers(obj,parent,h_and_l)
            %Place ability to fetch raw data in the line object
            %--------------------------------------------------
            
            for iG = 1:h_and_l.n_plot_groups
                cur_group_h = h_and_l.h_line{iG};
                for iH = 1:length(cur_group_h)
                    cur_h = cur_group_h(iH);
                    temp_obj = big_plot.line_data_pointer(parent,iG,iH);
                    setappdata(cur_h,'BigDataPointer',temp_obj);
                end
            end
        end
        function setCalibration(obj,calibration,group_I,line_I)
            %setCalibration
            y_group = obj.y{group_I};
            x_group = obj.x{group_I};
            if obj.y_object_present
                %For y objects we currrently limit this to 1 object
                y_group.setCalibration(calibration);
                return
            end
            %1) It would be great if we could avoid any data copying ...
            y_group(:,line_I) = y_group(:,line_I)*calibration.m + calibration.b;
            obj.y{group_I} = y_group;
            obj.parent.calibrationUpdated();
        end
        function s = getRawLineData(obj,group_I,line_I,in)
            %
            %   Outputs
            %   -------
            %   s : big_plot.raw_line_data
            
            y_group = obj.y{group_I};
            x_group = obj.x{group_I};
            
            if obj.y_object_present
                %For y objects we currrently limit this to 1 object
                s = y_group.getRawLineData(in);
                return
            end
            
            s = big_plot.raw_line_data;
            
            if ~isobject(x_group)
                error('Unhandled case')
            end
            
            if ~isempty(in.xlim)
                I = x_group.getIndicesFromTimes(in.xlim);
                if I(1) < 1
                    I = 1;
                end
                if I(2) > x_group.n_samples
                    I(2) = x_group.n_samples;
                end
                %We'll assume we are not calibrated
                s.y_raw = y_group(I(1):I(2),line_I);
                s.x = x_group.getTimeArray('start_index',I(1),'end_index',I(2));
            else
                s.y_raw = y_group(:,line_I);
                s.x = x_group.getTimeArray();
            end 
            s.y_final = s.y_raw;
            
        end
    end
    
end

function h__init(obj,hl,varargin)
%x Initializing of the object via parsing of inputs
%
%   big_plot.init
%
%   Inputs
%   ------
%   hl: big_plot.handles_and_listeners
%       hl is short for handles and listeners.
%   varargin: cell 
%       Inputs from the user to this "plot" function
%   
%   See Also:
%   line_plot_reducer.renderData



% The first argument might be a function handle or it might
% just be the start of the data.
cur_I = 1;

%Function handle determination
%---------------------------------------
if isa(varargin{cur_I}, 'function_handle')
    obj.plot_fcn = varargin{1};
    cur_I = cur_I + 1;
else
    obj.plot_fcn = @plot;
end

%Axes specified??
%---------------------------------------
%If not, handle on first renderData ...
if isscalar(varargin{cur_I}) && ...
   ishandle(varargin{cur_I}) && ...
   strcmp(get(varargin{cur_I}, 'Type'), 'axes')
    
    hl.h_axes   = varargin{cur_I};
    hl.h_figure = get(hl.h_axes, 'Parent');

    cur_I = cur_I + 1;
end

h__parseDataAndLinespecs(obj,varargin{cur_I:end})

%Data integrity
%--------------
%x1 spacing ...

end

function h__parseDataAndLinespecs(obj,varargin)
%x  Parses data and linepecs
%
%   Populates properties:
%   ---------------------
%   x :
%   y :
%   linespecs : 
%   extra_plot_options : 

NON_LINE_SPEC_PATTERN = '[^rgbcmykw\-\:\.\+o\*xsd\^v\>\<ph]';

% Function to check if something's a line spec
is_line_spec_fh = @(x) ischar(x) && isempty(regexp(x, NON_LINE_SPEC_PATTERN, 'once'));

% A place to store the linespecs as we find them.
temp_specs = {};
temp_x = {};
temp_y = {};

%TODO: This needs to handle poor inputs better
%case : flipping plot(x,y) with plot(y,x) where x is an object
% Loop through all of the inputs.
%--------------------------------------------------------------------------
previous_type = 's'; 
%s - start
%x - x value specification
%y - y value specification
n_groups      = 0; %Increment when both x & y are set ...
n_inputs      = length(varargin);
for k = 1:n_inputs
    current_argument = varargin{k};
    %TODO: Anything that acts like a time object would be fine here ...
    if isnumeric(current_argument) || isobject(current_argument) 
        %%isa(current_argument,'sci.time_series.time') || isa(current_argument,'big_plot.time')
        
        % If we already have an x, then this must be y.
        if previous_type == 'x'
            
            % Rename for simplicity.
            ym = current_argument;
            xm = varargin{k-1};
            
            % We can accept data in rows or columns. If this is
            % 1-by-n -> 1 series from columns
            % m-by-n -> n series from columns
            % m-by-1 -> 1 series from rows (transpose)
            
            if isobject(xm)
                %Assume of type sci.time_series.time for now
                if size(ym,1) ~= xm.n_samples
                   ym = ym'; 
                end
            else
                if size(xm, 1) == 1
                    xm = xm.';
                end
                if size(ym, 1) == 1
                    ym = ym.';
                end
                % Transpose if necessary.
                if size(xm, 1) ~= size(ym, 1)
                    ym = ym';
                end
            end
            
            % Store y, x, and a map from y index to x index.
            temp_x{end+1} = h__simplifyX(xm); %#ok<AGROW>
            temp_y{end+1} = ym; %#ok<AGROW>
            n_groups = n_groups + 1;
            % We've now matched this x.
            previous_type = 'y';
            
            % If we don't have an x, this must be x.
        elseif isnumeric(current_argument)
            previous_type = 'x';
        elseif any(strcmp(fieldnames(current_argument),'is_xy'))
            obj.y_object_present = true;
            xy = current_argument;
            temp_x{end+1} = xy; %#ok<AGROW>
            temp_y{end+1} = xy; %#ok<AGROW>
            n_groups = n_groups + 1;
            previous_type = 'y';
        else %Assume x object for now    
            previous_type = 'x';
        end
    elseif is_line_spec_fh(varargin{k})
        %TODO: Should ensure correct previous type - x or y
        previous_type = 'l';
        %Must be a linespec or the end of the data
        temp_specs{n_groups} = current_argument; %#ok<AGROW>
    else
        %Must be done with everything, remainder are options ...
        obj.extra_plot_options = varargin(k:end);
        break
    end
end

if previous_type == 'x'
    % If we had an x and were looking for a y, it
    % probably was actually a y with an implied x.
    
    % Rename for simplicity.
    ym = varargin{k};
    
    % We can accept data in rows or columns. If this is
    % 1-by-n -> 1 series from columns
    % m-by-n -> n series from columns
    % m-by-1 -> 1 series from rows (transpose)
    if size(ym, 1) == 1
        ym = ym.';
    end
    
    % Make the implied x explicit. %TODO: Allow being empty ...
    %It would be easier to make a time_series object
    %   - same memory benefit, already implemented
    %temp_x{end+1} = (1:size(ym, 1))';
    temp_x{end+1} = big_plot.time(1,size(ym,1),'sample_offset',1);
    temp_y{end+1} = ym;
    n_groups = n_groups + 1;
    temp_specs{n_groups} = {};
elseif previous_type == 'y'
    temp_specs{n_groups} = {};
end

if n_groups == 0
   error('Unable to find any plot groups') 
end

obj.x = temp_x;
obj.y = temp_y;
obj.linespecs = temp_specs;

end

function x_data_out = h__simplifyX(x_data)
%
%   Changes a vector x into a time series specification if the data are 
%   evenly sampled.
%

x_data_out = x_data;

%This length here is somewhat arbitrary, although it can't be less than 2
%otherwise we can't calculate dt
if ~isobject(x_data) && length(x_data) > 2 && big_plot.hasSameDiff(x_data)
    dt = (x_data(end)-x_data(1))/(length(x_data)-1);
    t0 = x_data(1);
    x_data_out = big_plot.time(dt,length(x_data),'start_offset',t0);
end

end