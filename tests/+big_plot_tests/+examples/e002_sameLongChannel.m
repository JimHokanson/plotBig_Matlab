function e002_sameLongChannel()
%
%   big_plot_tests.examples.e002_sameLongChannel
%   
%   This example plots two lines on a plot, each with 1e8 samples.

    t = 1:1e8;
    y = rand(length(t),1);
    y2 = y;

    clf
    tic;
    %Testing time inputs and line attributes
    plotBig(t,4-y,'r',t,y2,'c','Linewidth',2)
    set(gca,'ylim',[-1 5])
    toc;

end