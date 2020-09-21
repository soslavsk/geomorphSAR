function make_stream_plots(s,dem)

%% Figure 1: Long profile of river segment

z = getnal(s,dem);
[zmax,~] = maplateral(s,dem,5000,@max);
g = gradient(s,dem);

fig = figure;
hold on
plotdzshaded(s,[z zmax],'FaceColor',[.6 .6 .6])
scatter(s.distance,z,30,g,'filled')
caxis([0 0.5])
colormap(jet)
%plotdz(s,dem,'color',g,'colormap',jet,'LineWidth',6,'colorbar',false)
grid on, box on
xlim([-Inf Inf])
ylim([-Inf Inf])
c = colorbar('Location','SouthOutside');
ylabel(c,'Stream Gradient [m/m]')
set(gca,'FontSize',14)
title('Stream Long Profile')

export_fig stream_long_profile.png
print(fig,'stream_long_profile.eps','-depsc');

clear fig


%% Figure 2: Chi-plot
fd = FLOWobj(dem,'preprocess','carve');
fa = flowacc(fd);
db = drainagebasins(fd,s);
clear fd

fig = figure;
chiplot(s,dem,fa);
grid on

export_fig chiplot.png
print(fig,'chiplot.eps','-depsc');

clear fig


%% Figure 3: Slope-area plot

fig = figure;
sa = slopearea(s,dem,fa);
grid on

export_fig slope_area_plot.png
print(fig,'slope_area_plot.eps','-depsc');

clear fig


%% Figure 4: Map view of region

fig = figure;
imageschs(dem,db,'colormap',gray,'caxis',[-1 1]);
hold on; grid on;
plot(s,'k');

export_fig watershed_map.png
print(fig,'watershed_map.eps','-depsc');

clear fig

%%

fig = figure;
hold on
plotdzshaded(s,[z zmax],'FaceColor',[.6 .6 .6])
plotdz(s,dem,'color',g,'colormap',jet,'LineWidth',6,'colorbar',false)
grid on, box on
xlim([-Inf Inf])
ylim([-Inf Inf])
c = colorbar('Location','SouthOutside');
ylabel(c,'Stream Gradient [m/m]')
set(gca,'FontSize',14)
title('Stream Long Profile')

export_fig stream_long_profile.png
print(fig,'stream_long_profile.eps','-depsc');

clear fig
end