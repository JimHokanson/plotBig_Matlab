function robo_test()

%TODO: Create a figure and maximize it

starts = 20:5:70;
ends = starts + 30;

s = big_plot_tests.examples.e001_interestingInput('get_data_only',true);

% ax = zeros(1,2);
% ax(1) = subplot(2,1,1);
% ax(2) = subplot(2,1,2);

types = {'Jim''s code (this repo)','Tucker McClure''s Plot(Big) code','Default Matlab plotting'};

clf
pause(5)
for iType = 0:2
    for i = 1:100
clf
h_text = uicontrol('style','text','String','','units','normalized','fontsize',16);
set(h_text,'position',[0.15 0.85 0.70 0.05]);
drawnow
set(h_text,'String',sprintf('Drawing %s',types{iType+1}));
t1 = tic;
s = big_plot_tests.examples.e001_interestingInput('y',s.y,'t',s.t,'type',iType);
str = sprintf('Type: %s, Elapsed-Time: %0.1f',types{iType+1},toc(t1));
set(h_text,'String',str);


for iPart = 1:length(starts)
    set(gca,'xlim',[starts(iPart) ends(iPart)])
    if iType == 0
        s.obj.triggerRender();
        %pause(0.15)
    end
    drawnow();
    str = sprintf('Type: %s, Elapsed-Time: %0.1f',types{iType+1},toc(t1));
    set(h_text,'String',str);
end
set(gca,'xlim',[0 100])
drawnow();
str = sprintf('Type: %s, Total Elapsed-Time: %0.1f',types{iType+1},toc(t1));
set(h_text,'String',str);
drawnow();
fprintf('Type %d, Elapsed Time: %0.1f\n',iType,toc(t1));
    end
pause(3)
end

%TODO: Support screen maximizing

end