function pb001_missingPointOldFex(options)
%
%   big_plot_tests.previous_bugs.pb001_missingPointOldFex
%
%   Based on a comment for:
%   http://www.mathworks.com/matlabcentral/fileexchange/40790-plot--big-
%
%   Comment from Robbert at 12 Dec 2014
%

if nargin == 1
    USE_OLD = false;
else
    big_plot_tests.errors.NOT_YET_IMPLEMENTED
end

%The last peak is apparently not being shown in the 40790 version
y = [0 1 zeros(1,1e6) 1 zeros(1,1e6) 1 0];
x = 1:length(y);

%   This will only show two peaks (call to 40790 code)
%   --------------------------------------------------
if USE_OLD
    h = reduce_plot(x,y);
else
    h = plotBig(x,y);
end

I = find(h.YData ~= 0);
if length(I) ~= 3 || I(3) == I(2)+1
    %For some reason this will occasionally be 2 long, and other times
    %it will be I =[3 435 436] %which is not right
    big_plot_tests.errors.ERROR_DETECTED
end




end