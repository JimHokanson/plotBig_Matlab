function e004_blog_post()

%%
y = [1 2 3 4 5 6 7 8 9 8 7 6 7 6 5 4 3 2 4 8 9 7 4 5 6 7 7 7 7 7];
subplot(1,2,1)
plot(y,'Linewidth',2)
set(gca,'FontSize',16)
subplot(1,2,2)
plot(y,'Linewidth',2)
set(gca,'xlim',[-1e6 1e6],'FontSize',16)
set(gcf,'position',[1,1,800,400]);



end