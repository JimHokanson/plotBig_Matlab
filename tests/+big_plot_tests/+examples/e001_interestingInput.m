function varargout = e001_interestingInput(varargin)
%
%   s = big_plot_tests.examples.e001_interestingInput(varargin)
%
%   Most of the execution time comes from data initialization.
%
%   This code is based on:
%           FEX: #40790
%
%   Outputs
%   -------
%   s :
%       .y [n x 3] plotted data
%       .t [1 x n] time array
%       .obj big_plot
%       .h - output from the plot
%       .elapsed_time
%
%   Optional Inputs
%   ---------------
%   n: (default 5e7 + randi(1000))
%       For 1e8 we run about 3.2GB given 3 signals and 1 time
%   type:
%       - 0 - plotBig (this repo)
%       - 1 - reduce_plot (FEX 40790) https://github.com/tuckermcclure/matlab-plot-big
%       - 2 - plot() normal Matlab function ...
%       - 3 - animatedline
%   data_type : default 'double'
%   y
%   t
%   get_data_only : default false

%

%{
    s = big_plot_tests.examples.e001_interestingInput('type',0);
    s = big_plot_tests.examples.e001_interestingInput('type',1);
    s = big_plot_tests.examples.e001_interestingInput('type',2);

    s = big_plot_tests.examples.e001_interestingInput('type',0,'data_type','single');

%}

%50 million samples
in.n = 5e7 + randi(1000);
in.type = 0;
in.data_type = 'double';
in.single_channel = false;
in.y = [];
in.t = [];
in.single_plot = false;
in.get_data_only = false;
in = big_plot.sl.in.processVarargin(in,varargin);

n = in.n;

if in.type == 1
    if isempty(which('reduce_plot'))
        error('Reduce plot not found, can be downloaded from: https://github.com/tuckermcclure/matlab-plot-big')
    end
end



if ~isempty(in.y) && ~isempty(in.t)
    y = in.y;
    t = in.t;
else
    fprintf('Initializing data with %d samples\n',n);
    t = linspace(0,100,n);
    if in.single_channel
        y = (sin(0.10 * t) + 0.05 * randn(1, n))';
    else
        y = [(sin(0.10 * t) + 0.05 * randn(1, n))', ...
            (cos(0.43 * t) + 0.001 * t .* randn(1, n))', ...
            round(mod(t/10, 5))'];
    end
    y(t > 40 & t < 50,:) = 0;                      % Drop a section of data.
    y(randi(numel(y), 1, 20)) = randn(1, 20);       % Emulate spikes.
    switch in.data_type
        case 'double'
            %do nothing
        case 'single'
            y = single(y);
        case 'uint32'
            y = bsxfun(@minus,y,min(y,[],1));
            y = bsxfun(@rdivide,y,max(y,[],1));
            y = uint32(y*double(intmax('uint32')));
        case 'uint16'
            y = bsxfun(@minus,y,min(y,[],1));
            y = bsxfun(@rdivide,y,max(y,[],1));
            y = uint16(y*double(intmax('uint16')));            
        otherwise
            %get data type min and max
    end
    fprintf('Done initializing data\n');
end


s = struct;
s.y = y;
s.t = t;

if in.get_data_only
    if nargout
        varargout{1} = s;
    end
    return
end


%Why do I get the correct orientation when I do this ...
%I think it should be many channels with only a few samples,
%where is the correction coming into play???
%
%   I think it comes with the size of t not matching
%   the size of x, because they only match in the long
%   direction then x becomes by 3 channels, instead of having
%   tons of channels
%reduce_plot(t,y);
clf
ax(1) = subplot(2,1,1);
h_tic = tic;
switch in.type
    case 0
        plotBig(y,'dt',t(2)-t(1));
    case 1
        reduce_plot(t,y);
    case 2
        plot(t,y)
    case 3
        for i = 1:size(y,2)
            animatedline(t,y(:,i),'MaximumNumPoints',size(y,1));
        end
end
drawnow
s.elapsed_time = toc(h_tic);
fprintf('test001: time to process and plot (single subplot) was: %0.3f seconds\n',s.elapsed_time );

if ~in.single_plot
ax(2) = subplot(2,1,2);
switch in.type
    case 0
        %Normally we would get h, but I needed the object
        %for a demo
        %
        %i.e. normally this works:
        %
        %   h = plotBig(t,y);
        %
        
        temp = plotBig(y,'dt',t(2)-t(1),'obj',true);
        s.obj = temp;
        h = temp.getAllLineHandles();
    case 1
        h = reduce_plot(t,y);
    case 2
        h = plot(t,y);
    case 3
        for i = 1:size(y,2)
            h = animatedline(t,y(:,i),'MaximumNumPoints',size(y,1));
        end
end
%TODO: This would be better in the first plot
s.h = h;
end

s.ax = ax;
linkaxes(ax);

    if nargout
        varargout{1} = s;
    end

end
