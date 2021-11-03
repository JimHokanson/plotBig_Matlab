function times = indexToTime(x,I)
%
%   times = big_plot.utils.indexToTime(x,I)

if isobject(x)
    times = x.getTimesFromIndices(I);
else
    times = x(I);
end

end