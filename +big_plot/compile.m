function compile(varargin)
%x This function compiles the code necessary for this repo.
%
%      big_plot.compile()

%{
big_plot.compile();
big_plot.compile('use_simd',false)
big_plot.compile('use_openmp',false)
%}

in.use_simd = true;
in.use_openmp = true;
in = big_plot.sl.in.processVarargin(in,varargin);

%TODOs
%-------------------------
%1) Make verbose optional
%2) Support compiler switching
%3) build in try/catch support
%4) Finish mac support
%5) remove output before compiling - move as a function of the build

%TODO: List supported compilers and try and acquire them

%This code uses https://github.com/JimHokanson/mex_maker
verbose = true;
c = mex.compilers.gcc('./private/same_diff_mex.c','verbose',verbose);
c.build();

c = mex.compilers.gcc('./private/reduce_to_width_mex.c','verbose',verbose);
c.addCompileFlags('-mavx2');
if in.use_simd
    c.addCompileFlags('-DENABLE_SIMD');
end
if in.use_openmp
    c.addCompileFlags('-DENABLE_OPENMP');
end
c.addLib('openmp');
c.build();



end

