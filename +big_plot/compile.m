function compile()
%x This function compiles the code necessary for this repo.
%
%      big_plot.compile()
%
%
%   Setup
%   -----------------------------------------------------------------------
%   Most of the difficulty comes from trying to compile openmp
%   code for reduce_to_width_mex.c
% 
%   Windows
%   -------
%
%   TODO: You might also be able to use Visual Studio, although this might
%   require changing the file extension to ".cpp" and adding a
%   "/openmp" compile flag.
%
%   1) You might need to install this first:
%       https://www.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-the-mingw-w64-c-c++-compiler-from-tdm-gcc
%
%   2) Download and install TDM-GCC 5.1 (or other version) WITH OPENMP ENABLED 
%         - this requires checking the openmp box (under gcc?)
%
%   3) Run this command in Matlab
%
%         setenv('MW_MINGW64_LOC','C:\TDM-GCC-64')
%
%         I do this in my startup.m file.
%
%   4) Make sure that "mex -setup" points to TDM-GCC
%
%   Mac
%   ---
%   These instructions assume that Apple has still not built openmp
%   support into XCode. If they do, then no instructions would be needed.
%
%   0) Make sure homebrew is installed
%   1) in the terminal run:
%       brew update xcode-select
%       brew search gcc
%
%   2) Install a version of gcc without multilib
%       brew install homebrew/versions/gcc6 --without-multilib
%       
%       This can take a really long time (70ish minutes on my laptop)
%
%   3) These steps may not be necessary
%       brew link --overwrite --force gcc6
%       brew unlink gcc6 && brew link gcc6 
%       brew install --with-clang llvm

%TODOs
%-------------------------
%1) Make verbose optional
%2) Support compiler switching
%3) build in try/catch support
%4) Finish mac support



CURRENT_FUNCTION_NAME = 'big_plot.compile';
LIB_PATH = 'C:\TDM-GCC-64\lib\gcc\x86_64-w64-mingw32\5.1.0\libgomp.a';
LIB_FILENAME = 'libgomp.a';

%NYI
MAC_COMPILER_PATH = '/usr/local/Cellar/gcc6/6.1.0/bin/gcc-6';

if ismac()
    error('mac compiling not yet updated')
elseif isunix()
    error('unix compiling not yet written')
end

package_path = fileparts(which(CURRENT_FUNCTION_NAME));
mex_path = fullfile(package_path, 'private');
current_path = cd;
cd(mex_path);


%------------------------------------------------------
if ismac()
    %TODO: make sure we link the openmp library statically
    %mex CC='/usr/local/Cellar/gcc6/6.1.0/bin/gcc-6' COPTIMFLAGS="-O3 -DNDEBUG"  CFLAGS="$CFLAGS -std=c11 -fopenmp -mavx" LDFLAGS="$LDFLAGS -fopenmp" COPTIMFLAGS="-O3 -DNDEBUG" -O reduce_to_width_mex.c 
end

if ispc %pc
    CC = mex.getCompilerConfigurations;
    if isempty(CC)
        error('A compiler is required but none were found')
    end
    for iCompiler = 1:length(CC)
       cur_compiler = CC(iCompiler); 
       if strcmp(cur_compiler.Language,'C')
           break
       end
    end
    %TODO: We might need to verify tht this is a professional version ...
    is_ms = strcmp(cur_compiler.Manufacturer,'Microsoft');
    is_gnu = strcmp(cur_compiler.Manufacturer,'GNU');
    if is_ms
        %I'm not if we c99 would work ...
    	copyfile('reduce_to_width_mex.c','reduce_to_width_mex.cpp');
      	mex -O CFLAGS="$CFLAGS /openmp" reduce_to_width_mex.cpp -v
     	delete('reduce_to_width_mex.cpp')
    elseif is_gnu
        if ~exist(LIB_PATH,'file')
            error('Specified LIB_PATH is not valid')

        end
        mex_lib_path = fullfile(mex_path, LIB_FILENAME);
        copyfile(LIB_PATH, mex_path);
        mex -O LDFLAGS="$LDFLAGS -fopenmp" CFLAGS="$CFLAGS -std=c11 -fopenmp" reduce_to_width_mex.c -v libgomp.a
        delete(mex_lib_path);
    else
        error('Compiler option not recognized')
    end
    
end

cd(current_path);

end

