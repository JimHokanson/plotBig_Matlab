function e004_blog_post_part2()

%{
    big_plot_tests.examples.e004_blog_post_part2();
%}

%{
big_plot.compile('flags','simd openmp_simd')
big_plot.compile('flags','simd openmp')
%Individually ...
big_plot.compile('flags','openmp_simd')
big_plot.compile('flags','openmp')
big_plot.compile('flags','simd')

%No SIMD or OpenMP
big_plot.compile('flags','base');

%}

flags = {...
    'simd openmp_simd'
    'simd openmp'
    'openmp_simd'
    'openmp'
    'simd'
    'base'
    };

types = {'double' 'single' 'int64' 'uint64' ...
    'int32' 'uint32' 'int16' 'uint16' 'int8' 'uint8'};

n_outer_loops = 5;

n_flags = length(flags);
n_types = length(types);
r = zeros(n_flags,n_types,n_outer_loops);

for k = 1:n_outer_loops
    fprintf('Running outer loop %d\n',k)
for i = 1:n_flags
    fprintf('Running flag: %s for loop %d\n-------------------\n',flags{i},k);
    big_plot.compile('flags',flags{i},'verbose',false);
    for j = 1:n_types
        s = big_plot_tests.examples.e004_blog_post('data_type',types{j});
        r(i,j,k) = s.ratio;
    end
end
end

%TODO: File moving would be better since it wiuoldn't change the file
%Reset
big_plot.compile();

r2 = r;
r = mean(r2,3);

keyboard

plot(r','LineWidth',3)
set(gca,'FontSize',18,'xticklabels',types,'xtick',1:10);
legend(flags, 'Interpreter', 'none','Location','northwest')
xtickangle(60)
set(gcf,'Position',[1 1 600 600])
ylabel('Speedup Relative to Matlab')


end