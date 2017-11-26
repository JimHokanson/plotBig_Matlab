function s = s002_speed_test_2__zoom_speed(varargin)
%
%   s = big_plot_tests.speed.s002_speed_test_2__zoom_speed(varargin)
%
%   Outputs
%   -------
%   s - NYI
%
%   Optional Inputs
%   ---------------
%   data_type : default 'double'
%   zoom : array default: 0.1:0.1:0.9;
%   n_samples : scalar
%       # of samples to test
%   reps : scalar (default 3)
%   

%{
profile on
s2 = big_plot_tests.speed.s002_speed_test_2__zoom_speed();
profile off

%}

    %NYI
    s = struct;

    in.n_samples = 5e7;
    in.zoom = 0.1:0.1:0.9;
    in.data_type = 'double';
    in.reps = 3;
    in = big_plot.sl.in.processVarargin(in,varargin);

    n_samples = in.n_samples;
    %3e8 => 2.4 GB (for double)

    n_reps = in.reps;
    zoom = in.zoom;
    speeds_best = NaN(n_reps,length(zoom)+2);
    speeds_old = NaN(n_reps,length(zoom)+2);
    speeds_tm  = NaN(n_reps,length(zoom)+2);
    speeds_new = NaN(n_reps,length(zoom)+2);

    %Requires:
    %https://github.com/tuckermcclure/matlab-plot-big
    use_tm = ~isempty(which('reduce_plot'));
    
    p_temp = cell(1,n_reps);
    
    figure
    gca;
	%Testing
    %-----------------------------------------
    for iRep = 1:n_reps
        fprintf('Starting rep %d ----------------\n',iRep);
        

        
%         switch in.data_type
%             case 'double'
%                 data = rand(1,n_samples,'double');
%             case 'single'
%                 data = rand(1,n_samples,'single');
%             case 'uint32'
%                 data = randi(intmax('uint32'),1,n_samples,'uint32');
%             case 'uint16'
%                 data = randi(intmax('uint16'),1,n_samples,'uint16');
%             case 'uint8'
%                 data = randi(intmax('uint8'),1,n_samples,'uint8');
%             case 'int32'
%                 data = randi(intmax('int32'),1,n_samples,'int32');
%             case 'int16'
%                 data = randi(intmax('int16'),1,n_samples,'int16');
%             case 'int8'
%                 data = randi(intmax('int8'),1,n_samples,'int8');    
%             otherwise
%                 %get data type min and max
%         end
        
        [data,t] = h__getData(n_samples,in);
        [data2,t2] = h__getData(10000,in);
        
            clf
            gca
            t1 = tic;
            plot(t2,data2);
            drawnow
            speeds_old(iRep,end) = toc(t1);
            speeds_old(iRep,1:end-2) = h__runZoom(zoom);
        
            clf;
            gca;
            t1 = tic;
            plot(t,data);
            drawnow %Seems to block execution until the rendering has finished
            speeds_best(iRep,end) = toc(t1);
            speeds_best(iRep,1:end-2) = h__runZoom(zoom);
            
            if use_tm
                clf;
                gca;
                t1 = tic;
                reduce_plot(t,data);
                drawnow
                speeds_tm(iRep,end) = toc(t1);
                speeds_tm(iRep,1:end-2) = h__runZoom(zoom);
            end
            
            clf;
            gca;
            t1 = tic;
            obj = plotBig(data,'obj',true,'t0',0,'dt',t(2)-t(1));
            p_temp{iRep} = obj.perf_mon;
            drawnow
            speeds_new(iRep,end) = toc(t1);
            speeds_new(iRep,1:end-2) = h__runZoom(zoom);
            obj.perf_mon.truncate();
        
    end
    
    s.perf_mon = [p_temp{:}];
    
    zoom_plot = [zoom 0.99 1];
    figure
    %Summary Data
    %-----------------------------------------
    subplot(1,2,1)
    set(gca,'FontSize',18)
    plot(zoom_plot,mean(speeds_old,1),'-o');
    hold on
    plot(zoom_plot,mean(speeds_new,1),'-o');
    plot(zoom_plot,mean(speeds_best,1),'-o');
    if use_tm
        plot(zoom_plot,mean(speeds_tm,1),'-o');
    end
    hold off

    legend_strings = {'Old Speed','New Speed','Best Speed'};
    if use_tm
        legend_strings = [legend_strings 'matlab-plot-big'];
    end
    legend(legend_strings,'Location','northwest')
    xlabel('zoom pct, 1 = plot time')
    ylabel('time to plot (s)')
    set(gca,'xlim',[0 1.1])
    
    
    subplot(1,2,2)
    set(gca,'FontSize',18)
    r = mean(speeds_old,1)./mean(speeds_new,1);
    disp('Avg speed ratios')
    disp(r)
    disp('New Speeds')
    disp(mean(speeds_new,1))
    plot(zoom_plot,r,'-o');
    legend_strings = {'ML/New'};
    if use_tm
        legend_strings = [legend_strings 'ML/mpb' 'mpb/new'];
    end
    if use_tm
        hold on
        plot(zoom_plot,mean(speeds_old,1)./mean(speeds_tm,1),'-o');
        plot(zoom_plot,mean(speeds_tm,1)./mean(speeds_new,1),'-o');
        hold off
    end
    xlabel('zoom pct, 1 = plot time')
    ylabel('relative speedup')
    legend(legend_strings,'Location','northwest')
    set(gca,'xlim',[0 1.1])

end

function speeds = h__runZoom(zoom)
    speeds = zeros(1,length(zoom));
    for i = 1:length(zoom)
        t1 = tic;
        xlim = [0 zoom(i)];
        set(gca,'xlim',xlim)
        drawnow
        speeds(1,i) = toc(t1);
    end
end

function [data,t] = h__getData(n_samples,in)
        data = zeros(n_samples,1,in.data_type);
        t = linspace(0,1,n_samples);
        n_frac = n_samples/100;
        end_I = 0;
        for i = 1:100
            start_I = end_I + 1;
            end_I = start_I + n_frac;
            if end_I > n_samples
                end_I = n_samples;
            end
            data(start_I:end_I) = i;
        end
end