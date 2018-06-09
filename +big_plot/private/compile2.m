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

if ismac
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

