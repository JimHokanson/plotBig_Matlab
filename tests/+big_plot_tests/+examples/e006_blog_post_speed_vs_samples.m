function e006_blog_post_speed_vs_samples()

%Basically this is just looking at how long it takes
%to plot data of different lengths at low sizes
%
%Specifically does it matter that we downsample to 20000 data points versus
%2000 points ....

%TODO: 



%{
big_plot_tests.examples.e006_blog_post_speed_vs_samples()
%}

n_repeats = 50;
sizes = [2:100:20000];
n_sizes = length(sizes);

times = zeros(n_repeats,n_sizes);
figure
cla
for i = 1:n_repeats
    for j = 1:length(sizes)
        cla
        d = 1:sizes(j);
        h_tic = tic;
        plot(d,d);
        drawnow();
        times(i,j) = toc(h_tic);
    end
end


keyboard

plot(sizes,mean(times(2:end,:),1))
ylabel('Elapsed time (s)')
xlabel('# of samples plotted')




end