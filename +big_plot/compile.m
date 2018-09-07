function compile(varargin)
%
%   **********************************************************************
%   It is recommended that you use compile2.m inside the private directory
%   instead.
%   **********************************************************************
%



%x This function compiles the code necessary for this repo.
%
%   For people that are not Jim is probably best to run the script
%   'compile2.m' in the private folder.
%
%      big_plot.compile()
%
%   Flags (space delimited)
%   -----
%   'simd' :
%       Allows within thread parallel execution
%   'openmp' : 
%       Enables parallel code across threads
%   'openmp_simd' :
%       This allows openmp to try and use simd constructs inside. It
%       isn't necessary for explicit SIMD calls in openmp.
%
%   Examples
%   -----------
%   big_plot.compile('flags','simd openmp')


if ~exist('mex.compilers.gcc') %#ok<EXIST>
    fprintf(2,'This is a bit experimental, it might be better to use compile2.m\n')
    error('Mex maker library missing')
end

%Switching notes
%- need to update Windows path to point to correct "bin" folder
%   where gcc


%{
big_plot.compile();

%SIMD with ...
big_plot.compile('flags','simd openmp_simd')
big_plot.compile('flags','simd openmp')
%Individually ...
big_plot.compile('flags','openmp_simd')
big_plot.compile('flags','openmp')
big_plot.compile('flags','simd')

%No SIMD or OpenMP
big_plot.compile('flags','base');

%}

in.verbose = true;
in.flags = {};
in.use_simd = true;
in.use_openmp_with_simd = true;
in.use_openmp = true;
in = big_plot.sl.in.processVarargin(in,varargin);

if ~isempty(in.flags)
    in.flags = regexp(in.flags,'\s','split');
    in.use_simd = any(strcmp(in.flags,'simd'));
    in.use_openmp_with_simd = any(strcmp(in.flags,'openmp_simd'));
    in.use_openmp = any(strcmp(in.flags,'openmp'));
end

%TODOs
%-------------------------
%1) DONE Make verbose optional
%2) Support compiler switching
%3) build in try/catch support
%4) Finish mac support
%5) remove output before compiling - move as a function of the build

%TODO: List supported compilers and try and acquire them

%{
clear +big_plot\private\reduce_to_width_mex


%}

clear +big_plot\private\reduce_to_width_mex

%Step 1
%---------------------------------


%This code uses https://github.com/JimHokanson/mex_maker

c = mex.compilers.gcc('./private/reduce_to_width_mex.c','verbose',in.verbose);
c.addCompileFlags('-mavx2');



%Needed for mingw64
%TDM-GCC seems to do this by default
%https://stackoverflow.com/questions/13768515/how-to-do-static-linking-of-libwinpthread-1-dll-in-mingw
if strcmp(c.gcc_type,'mingw64')
    c.addStaticLibs({'pthread'})
end


if in.use_simd
    c.addCompileFlags('-DENABLE_SIMD');
end
if in.use_openmp_with_simd 
    c.addCompileFlags('-DENABLE_OPNEMP_SIMD');
elseif in.use_openmp
    c.addCompileFlags('-DENABLE_OPENMP');
end
c.addLib('openmp');
c.build();


c = mex.compilers.gcc('./private/same_diff_mex.c','verbose',in.verbose);
c.build();


end

