function bp001_cleanFigureTest()

h_fig = figure();
y = big_plot.example_data.getSinWithNoise();

p = plotBig(y,'obj',true);

h_line = p.h_and_l.h_lines_array;

n_x1 = length(h_line.XData);
big_plot.cleanFigure(gcf);

%Note, unfortunately for reasons I can't remember if we 
%clear all lines then the object itself drops nearly everything


set(gca,'xlim',[10 11]);
n_x2 = length(h_line.XData);

if n_x1 == n_x2
    %good, we're not redrawing on zoom to individual samples
else
   %bad 
end

%Now testing with restoring data
%---------------------------------
clf
p = plotBig(y,'obj',true);

h_line = p.h_and_l.h_lines_array;

n_x1 = length(h_line.XData);

big_plot.cleanFigure(gcf,'restore_data',true);


set(gca,'xlim',[10 11]);
n_x2 = length(h_line.XData);


end