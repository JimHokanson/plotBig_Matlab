function pb008_nanBoundariesTightPlot

%Plot shouldn't jump around (limits change back and forth without user
%interaction). It used to with tight because of the way we padded.

T2 = NaN(1,1e8);
T2(1e6:9e7) = 1e6:9e7;
h = plotBig(T2);
axis tight

end