function compile()
%x This function compiles the code necessary for this repo.
%
%      big_plot.compile()

%TODOs
%-------------------------
%1) Make verbose optional
%2) Support compiler switching
%3) build in try/catch support
%4) Finish mac support

%TODO: List supported compilers and try and acquire them

%This code uses https://github.com/JimHokanson/mex_maker
verbose = true;
c = mex.compilers.gcc('./private/same_diff_mex.c','verbose',verbose);
c.build();

c = mex.compilers.gcc('./private/reduce_to_width_mex.c','verbose',verbose);
c.addLib('openmp');
c.build();



end

