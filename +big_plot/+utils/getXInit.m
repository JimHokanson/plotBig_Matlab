function out = getXInit(x,sz)
%
%   out = big_plot.utils.getXInit(x,sz)
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
   if isa(x.start_datetime,'datetime')
       out = NaT(sz);
   elseif isa(x.start_datetime,'duration')
       out = NaT(sz) - NaT(1,1);
   else
       out = NaN(sz);
   end
else
    out = NaN(sz);
end

end