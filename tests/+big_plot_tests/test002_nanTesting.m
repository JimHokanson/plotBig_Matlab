function test002_nanTesting()
%
%   big_plot_tests.test002_nanTesting

%3 lines
h = plotBig(NaN(10,3));
h2 = plot(NaN(10,3));

h = plotBig(NaN(1e8,3));
h2 = plot(NaN(1e8,3));

y = NaN(1e8,2);
y(1e7:end,1) = 1e7:1e8;
y(1:9e7,2) = (1:9e7) + 2e7;
%h = plotBig(y,'obj',true); %for debugging
h = plotBig(y);
h2 = plot(y);

y = NaN(1e8,2);
y(1e7:end,1) = 1e7:1e8;
y(5e7:7e7,2) = (5e7:7e7) + 2e7;
h = plotBig(y);

%Had error where I was padding withe zeros
y = int16(round(rand(1e8,2)*255))+10;
h = plotBig(y);
set(gca,'xlim',[-1e7 1e8+1e7])
end