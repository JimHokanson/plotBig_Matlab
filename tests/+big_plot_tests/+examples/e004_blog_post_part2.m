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

n_flags = length(flags);
n_types = length(types);
r = zeros(n_flags,n_types);

for i = 1:n_flags
    fprintf('Running flag: %s\n',flags{i});
    big_plot.compile('flags',flags{i},'verbose',false);
    for j = 1:n_types
        s = big_plot_tests.examples.e004_blog_post('data_type',types{j});
        r(i,j) = s.ratio;
    end
end

keyboard

end