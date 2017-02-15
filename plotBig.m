function varargout = plotBig(varargin)
%x Wrapper for big_plot class
%
%   Provides simple access to the most common usage of the big_plot class.
%
%   Calling Forms
%   -------------
%   1) As a replacement for plot()
%   h = plotBig(x,y)
%   h = plotBig(y)
%   h = plotBig(ax,...)
%   etc.
%
%   2) Build time from options
%   h = plotBig(y,'x',x_data)
%   h = plotBig(y,'dt',0.01,varargin)
%
%
%   Inputs
%   ------
%   y : [samples x chans]
%       The data to plot.
%
%   Outputs
%   -------
%   h : [line handles]
%   p : big_plot object
%
%
%   Optional Inputs
%   ---------------
%   axes : 
%       Specify which axes to plot into. This is only needed for the 
%       calling form in which the time is built bas
%       
%   x : [samples x 1] or [1 x samples]
%       Currently differing times for each y input are not supported.
%   dt : scalar
%       The time difference between two samples, i.e. 1/(sampling_rate)
%   t0 : starting time
%   obj: 
%
%   Examples
%   --------
%   1)
%   n = 1e8;
%   t_end = 100;
%   dt = t_end/(n-1);
%   t = 0:dt:t_end;
%   y = (cos(0.43 * t) + 0.001 * t .* randn(1, n));
%   y = y';
%   plotBig(y,'x',t)
%   %---   or better  -----
%   plotBig(y,'dt',dt)
%

%TODO: We should build in support for returning the object with an 
%input form of (t,y,'obj',true)
%
%Currently we assume that the 2nd input will be a character for any
%optional processing

%Varargin parsing
%-------------------
direct_inputs_to_big_plot = true;
delete_mask = false(1,nargin);
s_in = struct;
for i = 1:(nargin-1)
    if ischar(varargin{i})
        option_string = varargin{i};
        if any(strcmp(option_string,{'axes','x','dt','t0','obj'}))
            direct_inputs_to_big_plot = false;
            s_in.(option_string) = varargin{i+1};
            delete_mask(i:i+1) = true;
        end
    end
end


% % % % if nargin > 1 
% % % %     
% % % %     
% % % %     && ischar(varargin{2})
% % % %     %TODO: Check for fieldnames from below
% % % %     option_string = varargin{2};
% % % %     if any(strcmp(option_string,{'axes','x','dt','t0','obj'}))
% % % %         direct_inputs_to_big_plot = false;
% % % %         y = varargin{1};
% % % %         varargin = varargin(2:end);
% % % %     end
% % % % end

%Shortcut exit for direct call to big_plot
%------------------------------------------
%i.e. we had no optional inputs that are pertinent to this function
if direct_inputs_to_big_plot
    temp = big_plot(varargin{:});
    temp.renderData();
    if nargout
        all_lines = temp.h_and_l.h_plot;
        varargout{1} = vertcat(all_lines{:});
    end
    return
end

%Processing of alternative call method
%--------------------------------------
varargin(delete_mask) = [];

y = varargin{1};
in.axes = [];
in.x = [];
in.dt = [];
in.t0 = 0;
in.obj = false;
in = big_plot.sl.in.processVarargin(in,s_in);

if ~isempty(in.dt)
    n_samples = size(y,1);
    
    %This may occur when the data should be transposed i.e. plotting y'
    %When 'x' is provided, we can adjust y accordingly, but when only
    %time info is provided, we can't resolve between 1 channel with many
    %samples and many channels with 1 sample each.
    if n_samples == 1
        error('Currently 1 sample per channel is not supported')
    end
    x = big_plot.time(in.dt,n_samples,'start_offset',in.t0);
else
    x = in.x;
    if ~any(size(y) == length(x))
        error('Mismatch in # of elements between x and y')
    end
end

if ~isempty(in.axes)
    temp = big_plot(in.axes,x,y);
else
    temp = big_plot(x,y);
end

temp.renderData();

if nargout
    if in.obj
        varargout{1} = temp;
    else
        all_lines = temp.h_and_l.h_plot;
        varargout{1} = vertcat(all_lines{:});
    end
end

end