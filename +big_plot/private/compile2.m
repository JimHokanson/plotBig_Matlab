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

if ~exist('reduce_to_width_mex.c') %#ok<EXIST>
    error('Code must be run from the same directory as this file, change path to this directory')
end

cc = mex.getCompilerConfigurations('C','Selected');

switch cc.ShortName
    %------------------------------------------
    case 'gcc'
        if USE_OPENMP
            options = {
                'CFLAGS="$CFLAGS -std=c11 -mavx2 -fopenmp"'
                'LDFLAGS="$LDFLAGS -fopenmp"'
                };
        else
            options = {
                'CFLAGS="$CFLAGS -std=c11 -mavx2"'
                };
        end
    %------------------------------------------    
    case 'Clang'
        %TODO: Switch on Apple vs other ...
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
            error('OpenMP with XCode not working yet ...')
            options = {
                'CFLAGS="$CFLAGS -march=native -fopenmp"'
                };
        else
            options = {
                'CFLAGS="$CFLAGS -march=native"'
                };
        end
    %------------------------------------------    
    case 'mingw64'
        if USE_OPENMP
            options = {
                'CFLAGS="$CFLAGS -std=c11 -mavx2 -fopenmp"'
                'LDFLAGS="$LDFLAGS -fopenmp"'
                };
        else
            options = {
                'CFLAGS="$CFLAGS -std=c11 -mavx2"'
                };
        end
    %------------------------------------------
    case {'MSVC140' 'MSVC150'}
        %Note VS uses a really old OpenMP implementation ...
        if USE_OPENMP
            options = {
                'COMPFLAGS="$COMPFLAGS /openmp /arch:AVX2"'
                };
        else
            options = {
                'COMPFLAGS="$COMPFLAGS /arch:AVX2"'
                };
        end
    otherwise
        error('Unsupported compiler')
end

if USE_OPENMP
    options = [options; OPENMP];
end
if USE_SIMD
    options = [options; SIMD];
end

options = [options; F1];

mex(options{:})


%Now for the simple files
%------------------------
if ismac || isunix
    %To try and handle my // comments
    mex CFLAGS="$CFLAGS -std=c11" same_diff_mex.c
else
    mex same_diff_mex.c
end

mex simd_check.c

