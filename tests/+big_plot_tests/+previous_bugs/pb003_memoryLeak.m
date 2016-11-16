function testMemoryLeak()

%I want to be able to query the memory usage, which is diffcult
%on a mac

error('Not yet implemented')

    for i = 1:200
        n = 1e7 + randi(1000);                          % Number of samples
        t = sort(100*rand(1, n));                       % Non-uniform sampling
        x = [sin(0.10 * t) + 0.05 * randn(1, n); ...
            cos(0.43 * t) + 0.001 * t .* randn(1, n); ...
            round(mod(t/10, 5))];
        x(:, t > 40 & t < 50) = 0;                      % Drop a section of data.
        x(randi(numel(x), 1, 20)) = randn(1, 20);       % Emulate spikes.

        %TODO: Why do I get the correct orientation when I do this ...
        %I think it should be many channels with only a few samples,
        %where is the correction coming into play???
        
        plotBig(t,x)
        set(gca,'xlim',[20 40])
        drawnow
        pause(0.1)
        close all

    end
end