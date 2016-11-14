function s001_speed_test_1()
%
%   big_plot_tests.speed.s001_speed_test_1
%
%

    %TODO: This needs to be based on the max memory requirements ...
    
    n_samples = [1e5 1e6 1e7 1e8 2e8 3e8];

    reps = 1;
    speeds_old = ones(reps,length(n_samples));
    speeds_new = ones(reps,length(n_samples));

%     profile on
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
            plotBig(data);
            drawnow
            speeds_new(iRep,iSamples) = toc;
        end
    end



    subplot(1,2,1)
    set(gca,'FontSize',18)
    plot(n_samples,mean(speeds_old,1),'-o');
    hold on
    plot(n_samples,mean(speeds_new,1),'-o');
    hold off
    legend({'Old Speed','New Speed'})
    xlabel('n samples to plot')
    ylabel('time to plot (s)')
    subplot(1,2,2)
    set(gca,'FontSize',18)
    plot(n_samples,mean(speeds_old,1)./mean(speeds_new,1),'-o');
    xlabel('n samples to plot')
    ylabel('relative speedup')

end