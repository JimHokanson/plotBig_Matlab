function s = e001_interestingInput(varargin)
%
%   s = big_plot_tests.examples.e001_interestingInput()
%   
%   Most of the time comes from data intialization ...
%
%   This code is based on:
%           FEX: #40790
%
%   Outputs
%   -------
%   s :
%       .y
%       .t
%       .h - output from the plot
%
%   Optional Inputs
%   ---------------
%   n: (default 5e7 + randi(1000))
%       %For 1e8 we run about 3.2GB given 3 signals and 1 time
%
%   type:
%       - 0 - plotBig
%       - 1 - reduce_plot (FEX 40790) https://github.com/tuckermcclure/matlab-plot-big
%       - 2 - plot() normal Matlab function ...
%

%{
    big_plot_tests.examples.e001_interestingInput('type',0)
    big_plot_tests.examples.e001_interestingInput('type',1)
    big_plot_tests.examples.e001_interestingInput('type',2)
%}
in.n = 5e7 + randi(1000);
in.type = 0;
in.y = [];
in.t = [];
in.get_data_only = false;
in = big_plot.sl.in.processVarargin(in,varargin); 
    
    n = in.n;
    
    if in.type == 1
       if isempty(which('reduce_plot'))
          error('Reduce plot not found, can be downloaded from: https://github.com/tuckermcclure/matlab-plot-big')
       end
    end
        
    
    fprintf('Initializing data with %d samples\n',n);
    if ~isempty(in.y) && ~isempty(in.t)
        y = in.y;
        t = in.t;
    else
        t = linspace(0,100,n);
        y = [(sin(0.10 * t) + 0.05 * randn(1, n))', ...
            (cos(0.43 * t) + 0.001 * t .* randn(1, n))', ...
            round(mod(t/10, 5))'];
        y(t > 40 & t < 50,:) = 0;                      % Drop a section of data.
        y(randi(numel(y), 1, 20)) = randn(1, 20);       % Emulate spikes.
    end
    fprintf('Done initializing data\n');
    
    s = struct;
    s.y = y;
    s.t = t;
    
    if in.get_data_only
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
    ax(1) = subplot(2,1,1);
    tic
    switch in.type
        case 0
            plotBig(y,'dt',t(2)-t(1));
        case 1
            reduce_plot(t,y);
        case 2
            plot(t,y) 
    end
    drawnow
    fprintf('test001: time to process and plot was: %0.3f seconds\n',toc);
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
            all_lines = temp.h_and_l.h_plot;
            h = vertcat(all_lines{:});
        case 1
            h = reduce_plot(t,y);
        case 2
            h = plot(t,y);
    end
    s.h = h;
    linkaxes(ax);
    
end
