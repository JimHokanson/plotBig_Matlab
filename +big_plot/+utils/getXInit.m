function out = getXInit(x,sz)
%X Initializes array of given size given x type
%
%   out = big_plot.utils.getXInit(x,sz)
%
%
%   See Also
%   --------
%   big_plot.utils.indexToTim

if isa(x,'datetime')
    out = NaT(sz);
elseif isa(x,'duration')
    %https://www.mathworks.com/matlabcentral/answers/368435-create-an-array-of-empty-durations
    out = NaT(sz) - NaT(1,1);
elseif isobject(x)

   %JAH 2024-07-05
   %
   %    Not sure if this logic is that great
   %
   %    Technically this works but the logic really is:
   %    if big_plot.datetime
   %        returned = x.start_datetime + duration(values)
   %    if x.start_datetime is a number (0) then we get durations out
   %    
   if isa(x.start_datetime,'datetime')
       out = NaT(sz);
   elseif isa(x,'big_plot.datetime')
       out = NaT(sz) - NaT(1,1);
   else
       out = NaN(sz);
   end
else
    out = NaN(sz);
end

end