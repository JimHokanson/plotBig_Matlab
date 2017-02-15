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


