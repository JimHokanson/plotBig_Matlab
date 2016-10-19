function tests
    %
    %   Class:
    %   sl.plot.big_data.tests_LinePlotReducer
    %
    %   See Also:
    %   sl.plot.big_data.LinePlotReducer
    %   sl.plot.big_data.reduceToWidth
    
    
    %   JAH: Things to fix:
    %
    %   POINTS 1 & 2 are handled by just always plotting the extents of the
    %   data (1st and last data points). This is done in reduce_to_width
    %
    %   -------------------------
    %   1) I zoomed in and then zoomed out. On zooming out, I added a bit
    %   more data, which caused a figure resize, which allowed a bit more
    %   data to be added, which caused a figure resize. How do I detect
    %   this and stop it from happening????
    %
    %   2) Similarly - it doesn't seem like I can zoom out to the original
    %   values. Why is this?
    %   Hypothesis - When zooming out, the data doesn't encompass the
    %   zoomed out size, so the auto resize shrinks it
    %   Setting a line to maximize this space causes a slight toggle
    %   in the x-limit, which is really annoying, since you get
    %   oscillations back and forth.
    %   Count:1 - xlim:[1.4e-06 1e+02] - position:[0.13 0.11 0.78 0.81]
    %   Count:1 - xlim:[0 1e+02] - position:[0.13 0.11 0.78 0.81]
    %   Callback 2 called for: 90090430 at 273.61
    %   Count:1 - xlim:[1.4e-06 1e+02] - position:[0.13 0.11 0.78 0.81]
    %   Count:1 - xlim:[0 1e+02] - position:[0.13 0.11 0.78 0.81]
    %   Callback 2 called for: 90090430 at 273.704
    %   Count:1 - xlim:[1.4e-06 1e+02] - position:[0.13 0.11 0.78 0.81]
    %   Count:1 - xlim:[0 1e+02] - position:[0.13 0.11 0.78 0.81]
    %   Callback 2 called for: 90090430 at 273.766
    %
    %
    %   -------------------------
    %   3) Plotting a new object, what does that do for the old object 
    %   since presumably the listeners still exist.
    %
    %   
    
end
    
        
        %TYPES OF TESTS - TODO: break up into these tests
        %----------------------------
        %1) Speed
        %2) Previous Bugs
        %3) Coverage
        
        
        
        %   For Coverage:
        %   ---------------
        %   1) plot(x1,y1)
        %      hold on
        %      plot(x2,y2)
        %      hold off
        %   2) plot(x1,y1,x2,y2) %See test001
        %   3) plot(ax,x1,y1)
        
        
        %TODO: On close, support rerendering (low priority)
        
function bugTestingInFEXVersion()
   %See comment from Robbert:
   %12 Dec 2014
   %http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-
   %
   %
   %The last peak is apparently not being shown in the FEX version
   y = [0 1 zeros(1,1e6) 1 zeros(1,1e6) 1 0]; 
   x = 1:length(y);
   wtf = sl.plot.big_data.LinePlotReducer(x,y,'*-');
   wtf.renderData();
end
function testSpeed()

    %sl.plot.big_data.tests_LinePlotReducer.testSpeed

    %This tests normal plotting, we need to test the same thing
    %for the LinePlotReducer class

    n_samples = [1e5 1e6 1e7 1e8 2e8 3e8];

    reps = 3;
    speeds_old = zeros(reps,length(n_samples));
    speeds_new = zeros(reps,length(n_samples));

    for iRep = 1:reps
        for iSamples = 1:length(n_samples)
            cur_n_samples = n_samples(iSamples);
            data = 1:cur_n_samples;

            close all
            tic
            plot(data);
            drawnow %Seems to block execution until the rendering has finished
            speeds_old(iRep,iSamples) = toc;

            close all
            tic
            wtf = sl.plot.big_data.LinePlotReducer(data);
            wtf.renderData;
            drawnow
            speeds_new(iRep,iSamples) = toc;
        end
    end

    %TODO: Implement nice display here ...
    %Compare
    %speeds_old
    %speeds_new
    keyboard
end
function test001_MatrixMultipleInputs()
    %
    %
    %   This works but it is still a bit slow


    profile on

    t = 1:1e8;
    t_fast = sci.time_series.time(1,length(t));
    y = rand(length(t),4);
    y2 = y;

    tic;
    wtf = sl.plot.big_data.LinePlotReducer(t_fast,4-y,'r',t_fast,y2,'c','Linewidth',2);
    %wtf = sl.plot.big_data.LinePlotReducer(t,4-y,'r',t,y2,'c','Linewidth',2);
    wtf.renderData;
    set(gca,'ylim',[-1 5])
    toc;
    %profile off
    %profile viewer
end
function test002_singleLongChannel()
    profile on
    t = 1:1e8;
    t_fast = sci.time_series.time(1,length(t));
    y = rand(length(t),1);
    y2 = y;

    tic;
    wtf = sl.plot.big_data.LinePlotReducer(t_fast,4-y,'r',t_fast,y2,'c','Linewidth',2);
    %wtf = sl.plot.big_data.LinePlotReducer(t,4-y,'r',t,y2,'c','Linewidth',2);
    wtf.renderData;
    set(gca,'ylim',[-1 5])
    toc;
    %profile off
    %profile viewer 
end
function test003_interestingInput()
    %From FEX: 40790

    n = 1e7 + randi(1000);                          % Number of samples
    t = sort(100*rand(1, n));                       % Non-uniform sampling
    x = [sin(0.10 * t) + 0.05 * randn(1, n); ...
        cos(0.43 * t) + 0.001 * t .* randn(1, n); ...
        round(mod(t/10, 5))];
    x(:, t > 40 & t < 50) = 0;                      % Drop a section of data.
    x(randi(numel(x), 1, 20)) = randn(1, 20);       % Emulate spikes.

    %Why do I get the correct orientation when I do this ...
    %I think it should be many channels with only a few samples,
    %where is the correction coming into play???
    %
    %   I think it comes with the size of t not matching 
    %   the size of x, because they only match in the long
    %   direction then x becomes by 3 channels, instead of having 
    %   tons of channels
    tic
    profile on
    wtf = line_plot_reducer(t,x);
    wtf.renderData;
    profile off
    toc
    profile viewer
end
function test004_simpleLine()
   y = 1:1e8+3457;
   x = y;
   tic
    %wtf = sl.plot.big_data.LinePlotReducer(x,y);
    wtf = line_plot_reducer(x,y);
    wtf.renderData;
    toc
end
function test004_simpleLineWithTimeObject()
   y = 1:1e8+3457;
   x = sci.time_series.time(0.01,length(y));
   tic
    wtf = sl.plot.big_data.LinePlotReducer(x,y);
    wtf.renderData;
    toc
end
        function testMemoryLeak()
            for i = 1:200
                n = 1e7 + randi(1000);                          % Number of samples
                t = sort(100*rand(1, n));                       % Non-uniform sampling
                x = [sin(0.10 * t) + 0.05 * randn(1, n); ...
                    cos(0.43 * t) + 0.001 * t .* randn(1, n); ...
                    round(mod(t/10, 5))];
                x(:, t > 40 & t < 50) = 0;                      % Drop a section of data.
                x(randi(numel(x), 1, 20)) = randn(1, 20);       % Emulate spikes.
                
                %TODO: Why do I get the correct orientation when I do this ...
                %I think it should be many channels with only a few samples,
                %where is the correction coming into play???
                wtf = sl.plot.big_data.LinePlotReducer(t,x);
                wtf.renderData;
                set(gca,'xlim',[20 40])
                drawnow
                pause(2)
                close all
                
            end
        end
        %TODO: Add axes that are linked via x
    end
    
end

