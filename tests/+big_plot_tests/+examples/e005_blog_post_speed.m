function e005_blog_post_speed()

%TODO: run up to 2e8

%{
big_plot_tests.examples.e005_blog_post_speed()
%}

%   n: (default 5e7 + randi(1000))
%       For 1e8 we run about 3.2GB given 3 signals and 1 time
%   type:
%       - 0 - plotBig (this repo)
%       - 1 - reduce_plot (FEX 40790) https://github.com/tuckermcclure/matlab-plot-big
%       - 2 - plot() normal Matlab function ...
%       - 3 - animatedline
%   data_type : default 'double'
%   y
%   t
%   get_data_only : default false

%data_types = {'double' 'single' 'int16'};
data_types = {'double'};
n_samples = [1000 1e7 5e7 1e8 1.5e8 2e8];
n_repeats = 10;

n_types = length(data_types);
n_sizes = length(n_samples);
times = zeros(3,n_types,n_sizes,n_repeats);





figure(1)
clf
subplot(2,1,1)
for i = 1:n_repeats
    
    for j = 1:n_types
        for k = 1:n_sizes
            fprintf('Running ijk of %d %d %d ------------\n',i,j,k)
            s = big_plot_tests.examples.e001_interestingInput(...
                'get_data_only',true,'single_channel',true,...
                'n',n_samples(k),...
                'data_type',data_types{j});
            
            options = {'y',s.y,'t',s.t,'single_plot',true};
            
            for m = 1:3
                cla
                s2 = big_plot_tests.examples.e001_interestingInput(...
                    'type',m-1,options{:});
                times(m,j,k,i) = s2.elapsed_time;
            end
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
plot(n_samples,data,'-o')
if i == 1
    ylabel('Elapsed time (s)')
    legend({'this','TM','ML'})
end
title(data_types{i})
end

linkaxes(ax);

for i = 1:n
ax(i) = subplot(2,n,i+n);
data = squeeze(mean(times(:,i,:,:),4))';
plot(n_samples,data(:,2)./data(:,1),'-o')
% hold on
% plot(n_samples,data(:,3)./data(:,1),'-o')
% hold off
if i == 1
    ylabel('Speed Ratio')
end
end

linkaxes(ax);

set(gcf,'Position',[1 1 600 400])


end




