function pb006_incorrectEndpoints()

%Not sure what the bug was here :/


data = (0.2e7:1e7)';
tic
wtf = plotBig(data,'obj',true);
toc
% wtf.render_info

%Second bug discovered, this isn't triggering a callback?!?!?!??
%Because we were zooming out and had the same data :)
%set(gca,'xlim',[0 1.5e7],'ylim',[-0.5e7 1.5e7]);

set(gca,'xlim',[0.5e7 1.5e7],'ylim',[-0.1e7 1.1e7]);

temp = wtf.h_and_l.h_line{1};

last_point = temp.YData(end);

set(gca,'xlim',[-0.2e7 0.5e7]);

first_point = temp.YData(1);

%{
fprintf('First: %g, Last: %g\n',first_point,last_point);
%}

if last_point == 0 || first_point == 0
    error('Invalid handling of boundary elements')
end

end