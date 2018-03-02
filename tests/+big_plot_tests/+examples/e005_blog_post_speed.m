function e005_blog_post_speed()

%{
    profile on
    big_plot_tests.examples.e005_blog_post_speed()
    profile off
    profile viewer
%}

data_types = {'double' 'single' 'int16'};
%data_types = {'double'};
n_samples = [1000 50000 1e6 1e7 5e7 1e8 1.5e8 2e8 3e8];
n_repeats = 10;

n_types = length(data_types);
n_sizes = length(n_samples);
times = zeros(3,n_types,n_sizes,n_repeats);

figure(1)
clf
subplot(2,1,1)
for iRepeat = 1:n_repeats
    
    for iType = 1:n_types
        for iSize = 1:n_sizes
            fprintf('Running ijk of %d %d %d ------------\n',iRepeat,iType,iSize)
            s = big_plot_tests.examples.e001_interestingInput(...
                'get_data_only',true,'single_channel',true,...
                'n',n_samples(iSize),...
                'data_type',data_types{iType});
            
            options = {'y',s.y,'t',s.t,'single_plot',true};
            
            for m = 1:3
                cla
                s2 = big_plot_tests.examples.e001_interestingInput(...
                    'type',m-1,options{:});
                times(m,iType,iSize,iRepeat) = s2.elapsed_time;
                clear s2
                pause(1)
            end
            
            clear s
            pause(1)
            %             s2 = big_plot_tests.examples.e001_interestingInput(...
            %                 'type',1,options{:});
            %
            %             s2 = big_plot_tests.examples.e001_interestingInput(...
            %                 'type',2,options{:}));
        end
    end
end

keyboard

figure(1);
clf
n = length(data_types);
for i = 1:n
ax(i) = subplot(2,n,i);
data = squeeze(mean(times(:,i,:,:),4))';
plot(n_samples/1e6,data,'-o')
%semilogy(n_samples/1e6,data,'-o')
if i == 1
    ylabel('Elapsed time (s)')
    legend({'this','TM','ML'})
end
title(data_types{i})

end

linkaxes(ax);
set(gca,'xlim',[0 n_samples(end)/1e6])

for i = 1:n
ax(i) = subplot(2,n,i+n);
data = squeeze(mean(times(:,i,:,:),4))';
plot(n_samples/1e6,data(:,2)./data(:,1),'-o')
% hold on
% plot(n_samples,data(:,3)./data(:,1),'-o')
% hold off
if i == 1
    ylabel('Speed Ratio')
end
if i == 2
xlabel('# of samples (millions)')
end
end

linkaxes(ax);
set(gca,'xlim',[0 n_samples(end)/1e6],'ylim',[0 150])

set(gcf,'Position',[1 1 600 400])

save('2017a','times','n_samples')

end




