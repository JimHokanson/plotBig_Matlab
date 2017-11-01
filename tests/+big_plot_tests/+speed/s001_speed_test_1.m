function s001_speed_test_1()
%
%   big_plot_tests.speed.s001_speed_test_1
%

    n_samples = [1e5 1e6 1e7 1e8 2e8 3e8];
    %3e8 => 2.4 GB

    reps = 3;
    speeds_old = ones(reps,length(n_samples));
    speeds_tm  = ones(reps,length(n_samples));
    speeds_new = ones(reps,length(n_samples));

    %Requires:
    %https://github.com/tuckermcclure/matlab-plot-big
    use_tm = ~isempty(which('reduce_plot'));
    
	%Testing
    %-----------------------------------------
    for iRep = 1:reps
        fprintf('Starting rep %d ----------------\n',iRep);
        for iSamples = 1:length(n_samples)
            cur_n_samples = n_samples(iSamples);
            fprintf('Plotting %d samples\n',cur_n_samples);
            data = 1:cur_n_samples;

            close all
            tic
            plot(data);
            drawnow %Seems to block execution until the rendering has finished
            speeds_old(iRep,iSamples) = toc;

            if use_tm
                close all
                tic
                reduce_plot(data);
                drawnow
                speeds_tm(iRep,iSamples) = toc;
            end
            
            close all
            tic
            plotBig(data);
            drawnow
            speeds_new(iRep,iSamples) = toc;
        end
    end

    %Summary Data
    %-----------------------------------------
    subplot(1,2,1)
    set(gca,'FontSize',18)
    plot(n_samples,mean(speeds_old,1),'-o');
    hold on
    plot(n_samples,mean(speeds_new,1),'-o');
    if use_tm
        plot(n_samples,mean(speeds_tm,1),'-o');
    end
    hold off

    legend_strings = {'Old Speed','New Speed'};
    if use_tm
        legend_strings = [legend_strings 'matlab-plot-big'];
    end
    legend(legend_strings)
    xlabel('n samples to plot')
    ylabel('time to plot (s)')
    
    
    subplot(1,2,2)
    set(gca,'FontSize',18)
    plot(n_samples,mean(speeds_old,1)./mean(speeds_new,1),'-o');
    if use_tm
        hold on
        plot(n_samples,mean(speeds_old,1)./mean(speeds_tm,1),'-o');
        hold off
    end
    xlabel('n samples to plot')
    ylabel('relative speedup')

end