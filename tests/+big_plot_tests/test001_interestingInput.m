function test001_interestingInput()
%
%   big_plot_tests.test001_interestingInput()
%   
    %From FEX: 40790

    %TODO: Allow going to smaller values if the computer has less memory
    %For 1e8 we run about 3.2GB given 3 signals and 1 time
    n = 1e8 + randi(1000);                          % Number of samples
    t = linspace(0,100,n);
    y = [(sin(0.10 * t) + 0.05 * randn(1, n))', ...
        (cos(0.43 * t) + 0.001 * t .* randn(1, n))', ...
        round(mod(t/10, 5))'];
    y(t > 40 & t < 50,:) = 0;                      % Drop a section of data.
    y(randi(numel(y), 1, 20)) = randn(1, 20);       % Emulate spikes.

    %Why do I get the correct orientation when I do this ...
    %I think it should be many channels with only a few samples,
    %where is the correction coming into play???
    %
    %   I think it comes with the size of t not matching 
    %   the size of x, because they only match in the long
    %   direction then x becomes by 3 channels, instead of having 
    %   tons of channels
    tic
    wtf = plotBig(y,'dt',t(2)-t(1));
    toc
end
