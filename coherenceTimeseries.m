function [dates,prc] = coherence_timeseries(stack,mask,plotFlag)
%
%
%   Function to create timeseries of coherence averaged over the current
%   tributary.
%
%   INPUTS:
%
%       stack       coherence stack created by createStack.m
%       mask        optoinal mask to use only coherence values from
%                   particular region of interest (e.g., basin). Note areas
%                   OUTSIDE of the mask will be set to NaN.                
%                   If mask will not be used, set to 1.
%       plotFlag    0 = do not plot, 1 = create plot.
%
%
%   OUTPUT:
%
%       dates       string of matlab dates from the coherence stack
%       prc         object containing 10-90th percentiles (every 10th
%                   percentile) corresponding to the dates vector
%
%   Uses the brewermap function https://de.mathworks.com/matlabcentral/fileexchange/45208-colorbrewer-attractive-and-distinctive-colormaps
%
%   S. Olen, 07.11.2019

%% 1:
for i = 1:(length(stack))
    dates(i) = stack{i}.date(1);
end

%% 2:
%   Mask out areas outside of area of interest (usually a drainage basin)
%   Areas OUTSIDE OF THE MASK will be set to NaN;
if isfloat(mask) == 0
    for i = 1:length(stack)
        stack{i}.coh.Z(~mask.Z) = NaN;
    end
end

%% 3:
%   Calculate statistics for the timeseries in percentiles from 5th to
%   95th.

% Loop through coherence stack
for i = 1:length(stack)
    % Extract only coherence values within the watershed
    cohvec = stack{i}.coh.Z(~isnan(stack{i}.coh.Z));
    cohvec = cohvec(~isnan(cohvec));
    
    % Calculate percentiles
    for j = 10:10:90
        cmd = ['prc.prc_',num2str(j),'(i) = prctile(cohvec,',num2str(j),');'];
        eval(cmd);
    end
end
clear i j cmd

save('coherence_percentiles.mat','dates','prc');

%% 3:
%   Create timeseries plot.
if plotFlag == 1
    c = flipud(brewermap(length(10:10:90),'RdYlBu'));

    % Begin plotting figure.
    fig = figure('Position',[0 0 2000 500]); hold on;
    i = 0;
    for j = 10:10:90
        i = i+1;
        cmd = ['current_var = prc.prc_',num2str(j),';']; eval(cmd);
        plot(dates,current_var,'LineWidth',2,'Color',c(i,:,:));
        plot_legend{i} = [num2str(j),'th Percentile'];
    end
    plot(dates,prc.prc_50,'LineWidth',3,'color','y');
    plot(dates,prc.prc_50,'LineWidth',2,'color','k','LineStyle',':');
    s = scatter(dates,prc.prc_50,30,'w','filled');
    set(s,'MarkerEdgeColor','k')
    hold off
    grid on
    ylabel('Interferogram Coherence')
    legend(plot_legend,'Location','EastOutside')
    ylim([0.2 1])
    xlim([dates(2) max(dates)])
    title('Descending Track 10, S23 S24')
    set(gca,'FontSize',14,'box','on','LineWidth',1.5)

    export_fig coherence_percentile_timeseries.png
    print(fig,'-depsc','coherence_percentile_timeseries.eps')
end
end

