%%

%This is an alternative method for compiling this code.
%
%It must be run from the private directory
%
%  Steps
%  --------
%  1) Change directory to this folder
%  2) Change flags as desired
%  3) Select all code and evaluate
%
%   Improvements
%   -------------
%   1) Switch on selected compiler ...
%       cc = mex.getCompilerConfigurations

%------ EDIT THESE AS DESIRED ------
%- Both can be true
%- Due to memory bandwidth it may not be beneficial.
%- I tend to prefer max speed within a thread and leaving 
%   the other threads on my computer to do whatever they want.
USE_OPENMP = 1; %use multiple threads
USE_SIMD = 1;   %make parallel within thread
%-------------------------

SIMD = '-DENABLE_SIMD';
OPENMP = '-DENABLE_OPENMP';
OPENMP_SIMD = '-DENABLE_OPNEMP_SIMD';

F1 = 'reduce_to_width_mex.c';

%Note regarding architecture flags
%Setting the architecture flag lets the compiler choose
%its approach but doesn't mean that the custom SIMD code
%will be enabled. In general the compiler is not smart
%enough to generate the SIMD code from the naive loop

if ismac
    %This currently assumes XCode even though I had been
    %using GCC for its superior OpenMP support
    
    %To resolve library dependencies
    %-------------------------------
    %otool -L reduce_to_width_mex.mexmaci64
    
    %This is designed for XCode
    %---------------------------
    %- This post describes how to point to openmp
    %- NYI
    %https://iscinumpy.gitlab.io/post/omp-on-high-sierra/
    if USE_OPENMP
        error('This isn''t working yet ...')
    options = {
        'CFLAGS="$CFLAGS -march=native -fopenmp"'
        };
    else
    options = {
        'CFLAGS="$CFLAGS -march=native"'
        };    
    end
elseif ispc
    %Currently assuming VSs
    if USE_OPENMP
    options = {
        'CFLAGS="$CFLAGS /arch:AVX2 /arch:AVX2"'
        };
    else
    options = {
        'CFLAGS="$CFLAGS /arch:AVX2"'
        };    
    end
else
    
    
end

if USE_OPENMP
    options = [options; OPENMP]; %#ok<UNRCH>
end
if USE_SIMD
    options = [options; SIMD];
end

options = [options; F1];

mex(options{:})


%Now for the simple files
%------------------------
mex same_diff_mex.c
mex simd_check.c

