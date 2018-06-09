function s = s001_speed_test_1(varargin)
%
%   s = big_plot_tests.speed.s001_speed_test_1(varargin)
%
%   Outputs
%   -------
%   s : struct
%       
%
%   Optional Inputs
%   ---------------
%   n_samples : array (default [1e5 1e6 1e7 1e8 2e8 3e8])
%       # of samples to test
%   reps : scalar (default 3)
%   

%{
profile on
s1 = big_plot_tests.speed.s001_speed_test_1('n_samples',[1e5 1e6 1e7 5e7 1e8 2e8]);
profile off

s1 = big_plot_tests.speed.s001_speed_test_1('n_samples',[1e5 1e6 1e7 5e7 1e8 2e8],'data_type','int16');


s1 = big_plot_tests.speed.s001_speed_test_1('n_samples',[1e5 1e6 1e7 5e7 1e8 2e8 3e8]);

%Let's not wait forever ...
s1 = big_plot_tests.speed.s001_speed_test_1('n_samples',[1e5 1e6 1e7 5e7 1e8 2e8]);

s1 = big_plot_tests.speed.s001_speed_test_1('n_samples',[1e5 1e6 1e7 5e7 1e8 2e8],'data_type','single');
s1 = big_plot_tests.speed.s001_speed_test_1('n_samples',[1e5 1e6 1e7 5e7 1e8 2e8],'data_type','uint8');
%}

    %NYI
    s = struct;

    in.n_samples = [1e5 1e6 1e7 1e8 2e8 3e8];
    in.data_type = 'double';
    in.reps = 3;
    in = big_plot.sl.in.processVarargin(in,varargin);

    n_samples = in.n_samples;
    %3e8 => 2.4 GB (for double)

    reps = in.reps;
    speeds_old = ones(reps,length(n_samples));
    speeds_tm  = ones(reps,length(n_samples));
    speeds_new = ones(reps,length(n_samples));

    %Requires:
    %https://github.com/tuckermcclure/matlab-plot-big
    use_tm = ~isempty(which('reduce_plot'));
    
    figure
    %We make this reasonably large ...
    set(gcf,'Position',[1 1 1000 800]);
    gca;
	%Testing
    %-----------------------------------------
    for iRep = 1:reps
        fprintf('Starting rep %d ----------------\n',iRep);
        for iSamples = 1:length(n_samples)
            cur_n_samples = n_samples(iSamples);
            s1 = sprintf('Plotting %d samples',cur_n_samples);
            fprintf('%s\n',s1);
            
            clf
            gca;
            title(sprintf('Creating %d samples in memory',cur_n_samples));
            drawnow
            
            %data = 1:cur_n_samples;
            
            %TODO: Support int
                        
            switch in.data_type
                case 'double'
                    data = rand(1,cur_n_samples,'double');
                case 'single'
                    data = rand(1,cur_n_samples,'single');
                case 'uint32'
                    data = randi(intmax('uint32'),1,cur_n_samples,'uint32');
                case 'uint16'
                    data = randi(intmax('uint16'),1,cur_n_samples,'uint16');
                case 'uint8'
                    data = randi(intmax('uint8'),1,cur_n_samples,'uint8');
             	case 'int32'
                    data = randi(intmax('int32'),1,cur_n_samples,'int32');
                case 'int16'
                    data = randi(intmax('int16'),1,cur_n_samples,'int16');
                case 'int8'
                    data = randi(intmax('int8'),1,cur_n_samples,'int8');    
                otherwise
                    error('Unrecognized data type')
                    %get data type min and max
            end

            clf
            gca;
            title(sprintf('%s using Matlab, rep %d',s1,iRep));
            drawnow
            t1 = tic;
            plot(data);
            drawnow %Seems to block execution until the rendering has finished
            speeds_old(iRep,iSamples) = toc(t1);

            if use_tm
                clf
                gca;
                title(sprintf('%s using tm code, rep %d',s1,iRep));
                drawnow
                t1 = tic;
                reduce_plot(data);
                drawnow
                speeds_tm(iRep,iSamples) = toc(t1);
            end
            
            clf
            gca;
            title(sprintf('%s using this library, rep %d',s1,iRep));
            drawnow
            t1 = tic;
            plotBig(data);
            toc(t1)
            drawnow
            speeds_new(iRep,iSamples) = toc(t1);
        end
    end

    s.speeds_old = speeds_old;
    s.speeds_new = speeds_new;
    s.speeds_tem = speeds_tm;
    s.n_samples = in.n_samples;
    s.data_Type = in.data_type;
    s.n_reps = in.reps;
    
    figure
    %Summary Data
    %-----------------------------------------
    ax(1) = subplot(1,2,1);
    
    plot(n_samples/1e6,mean(speeds_old,1),'-o','linewidth',2);
    hold on
    plot(n_samples/1e6,mean(speeds_new,1),'-o','linewidth',2);
    if use_tm
        plot(n_samples/1e6,mean(speeds_tm,1),'-o','linewidth',2);
    end
    hold off

    legend_strings = {'Old Speed','This Speed'};
    if use_tm
        legend_strings = [legend_strings 'matlab-plot-big'];
    end
    legend(legend_strings)
    xlabel('n samples to plot (millions)')
    ylabel('time to plot (s)')
    title(sprintf('Data type:%s',in.data_type))
    set(gca,'FontSize',18)
    
    
    
    ax(2) = subplot(1,2,2);
    
    r = mean(speeds_old,1)./mean(speeds_new,1);
    disp('Avg speed ratios')
    disp(r)
    disp('New Speeds')
    disp(mean(speeds_new,1))
    plot(n_samples/1e6,r,'-o','linewidth',2);
    legend_strings = {'ML/this'};
    if use_tm
        legend_strings = [legend_strings 'ML/mpb' 'mpb/this'];
    end
    if use_tm
        hold on
        plot(n_samples/1e6,mean(speeds_old,1)./mean(speeds_tm,1),'-o','linewidth',2);
        plot(n_samples/1e6,mean(speeds_tm,1)./mean(speeds_new,1),'-o','linewidth',2);
        hold off
    end
    xlabel('n samples to plot')
    ylabel('relative speedup')
    legend(legend_strings)
    set(gca,'FontSize',18)
    
    s.ax = ax;
    
    keyboard

end