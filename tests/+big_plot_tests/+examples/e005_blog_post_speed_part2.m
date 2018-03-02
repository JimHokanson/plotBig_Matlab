function e005_blog_post_speed_part2

file_names = {'2013a' '2013b' '2014a' '2014b' ...
    '2015a_sp1' '2015b' '2016a' '2016b' '2017a' '2017b'};

%   1st dim:
%       1 - me
%       2 - TM
%       3 - ML
%   2nd dim:
%       1 - double
%   3rd dim:
%       size
%times(m,iType,iSize,iRepeat)

d1_ML = 3;
d1_TM = 2;
d2 = 1;
d3 = 3;
%d3 - length
%d4 - average

n_files = length(file_names);
data = zeros(n_files,3);

for i = 1:n_files
    file_name = [file_names{i} '.mat'];
    h = load(file_name);
    I = find(h.n_samples == 1e8);
    data(i,1) = mean(h.times(1,d2,I,:),4);
    data(i,2) = mean(h.times(d1_TM,d2,I,:),4);
    data(i,3) = mean(h.times(d1_ML,d2,I,:),4);
end

plot(data,'-o')

xtickangle(45)

set(gca,'xtick',1:n_files,'XTickLabel',file_names,'ylim',[-1 12],'xlim',[0 n_files+1])

legend({'This','TM''s code','Matlab'})

ylabel('Elapsed time (s)')
title('Time to plot 100 million samples')

set(gca,'FontSize',14)

%Avg for my code

mean(data(:,1))

%------------------------------------------------------------


s = big_plot_tests.examples.e001_interestingInput(...
'get_data_only',true,'single_channel',true,...
'n',1e8,...
'data_type','double');

options = {'y',s.y,'t',s.t,'single_plot',true};

data = zeros(1,10);

for i = 1:10
cla
s2 = big_plot_tests.examples.e001_interestingInput(...
    'type',0,options{:});
data(i) = s2.elapsed_time;
% pause(1)
if i ~= 10
    clear s2
end
%pause(1)
end

%Note, hardcoded enabling logging, not yet publicaly exposed

reduce_time = s2.obj.perf_mon.reduce_mex_times(1);

end