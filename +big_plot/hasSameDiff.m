function flag = hasSameDiff(x_data)
%
%   flag = big_plot.hasSameDiff(x_data)
%   
%   Access to the private function same_diff_mex()
%
%   Checks for consistency of differences
%
%   i.e. this would pass:
%   
%   x = [1     1.5     2     2.5     3 etc.]
%   diff   0.5     0.5   0.5     0.5
%   
%   this would not
%
%   x = [1      1.8      2      3.3     5]
%   diff    0.8      0.2    1.3     1.7
%   

    flag = same_diff_mex(x_data);

end