function [changePoints] = change_point_detection(area,avcoh,slope,minAm)
%
%
%   Function to detect changepoints in the (log) drainage area - coherence
%   relationship using cummulative sum changepoint detection after Taylor
%   (2000). Coherence data is log-binned by drainage area, then
%   changepoints are calculated using the following statistical metrics:
%   percentile range (95-5th percentile), skewness, standard deviation,
%   median, and mean of each bin. For statistical robustness, this is
%   repeated using multiple bin number and sizes.
%
%   INPUTS:
%       area                GRIDobj of drainage area in sq km
%       avcoh               GRIDobj time-averaged coherence
%       slope               GRIDobj of hillslope angle (degrees)
%       minAm               minimum drainage area size to include, in sq m
%
%   OUTPUTS:
%       changePoints        Object containing the change point location (sq
%                           km) and std. dev. for median, mean, skewnewss,
%                           standard deviation, and percentile range
%
%   Uses function find_chpt.m 
%
%   S. Olen, 19.09.2018


%%  1:  Convert the GRIDobjects to vectors for binning and change poitn detection.

% Convert the area threshold from sq m to sq km
% Performs the conversion for all bin entries
minAkm = minAm ./ (1000^2);

% Convert GRID objects into vectors for plotting
% Create mask of all pixels in the ROI that have greater drinage area than the prescribed area threshold
idx = area.Z >= minAkm;

% Convert drainage area, slope and coherence to vectors
area_vector = area.Z(idx);
coh_vector = avcoh.Z(idx);
slope_vector = slope.Z(idx);


%%  2:
% Initial coherence - drainge area change point estimation for several
% different bin sizes.

% Create log-spaced bins of coherence based on drainage areac
num = 20:2:200;
for j = 1:length(num)
    edges = logspace(log10(minAkm),log10(max(area_vector)),num(j));
    for i = 1:(length(edges)-1)
        current_idx = area_vector >= edges(i) & area_vector < edges(i+1);
        mean_bin{j}(i) = nanmean(coh_vector(current_idx));
        median_bin{j}(i) = nanmedian(coh_vector(current_idx));
        std_bin{j}(i) = nanstd(coh_vector(current_idx));
        prcrange_bin{j}(i) = prctile(coh_vector(current_idx),99) - prctile(coh_vector(current_idx),1);
        skew_bin{j}(i) = skewness(coh_vector(current_idx));
        area_bins{j}(i) = (edges(i+1) + edges(i))/2;
        n{j}(i) = numel(current_idx(current_idx==1));
        clear current_idx
    end
    
    % Record the lowest number of data per bin.
    nmin(j) = min(n{j});
    
    %%
    % Calculate the change point using the find_chpoint.m function after
    % Taylor, 2000 based on cummulative sums.
    
    % Determines changepoint by bin number
    [prcrange_cp,prcrange_sL(j)] = find_chpoint(prcrange_bin{j}');
    [skew_cp,skew_sL(j)] = find_chpoint(skew_bin{j}');
    [median_cp,median_sL(j)] = find_chpoint(median_bin{j}');
    [mean_cp,mean_sL(j)] = find_chpoint(mean_bin{j}');
    [std_cp,std_sL(j)] = find_chpoint(std_bin{j}');
    
    % Projects bin number back to drainage area (sq km)
    prcrange_chpt(j) = area_bins{j}(prcrange_cp);
    skew_chpt(j) = area_bins{j}(skew_cp);
    median_chpt(j) = area_bins{j}(median_cp);
    mean_chpt(j) = area_bins{j}(mean_cp);
    std_chpt(j) = area_bins{j}(std_cp);
    
   clear *_cp *_bin n
end


%%  3:
% Create histograms of change points to find most probable changepoint of
% the different binning schemes.

% Set some things up for dynamic variable naming
cp = {prcrange_chpt,skew_chpt,median_chpt,mean_chpt,std_chpt};
cp_labels = {'prctileRange','skewness','median','mean','std'};
cp2 = {'prcrange_bin','skew_bin','median_bin','mean_bin','std_bin'};

% Look through variables
for k = 1:length(cp)
    
    fig = figure('Visible','Off');
    h = histogram(cp{k},20,'Normalization','Probability');
    for i = 1:length(h.BinEdges)-1
        h_area(i) = mean([h.BinEdges(i),h.BinEdges(i+1)]);
    end
    idx = h.Values == max(h.Values);
    hold on, grid on
    p1 = plot([nanmean(h_area(idx)) nanmean(h_area(idx))],ylim,'--k','LineWidth',2);
    legend(p1,['Predicted Changepoint = ',num2str(nanmean(h_area(idx)))],'Location','SouthOutside');
    xlabel('Drainage Area (km^2)')
    ylabel('Probability');
    title(cp_labels{k})
    set(gca,'FontSize',14)
    
    % Save the histogram as an eps file
    print(fig,[cp2{k},'_histogram_chpoint_coherence.eps'],'-depsc');
    
    % Calculate correct change point based on the most probable histogram
    % value
    cmd = ['changePoints',cp_labels{k},'.chpt = nanmean(h_area(idx));'];
    eval(cmd); clear cmd;
    cmd = ['changePoints',cp_labels{k},'.std = nanstd(cp{k});'];
    eval(cmd); clear cmd;
      
    clear cmd h idx p1 fig

end


%%  4:
% Output change points to a text file
output_file = 'coherence_changepoint_locations.txt';
fid = fopen(output_file,'w');
fprintf(fid,'Changepoint Locatoins for Tributary \n');
fprintf(fid,'Prctile Range Change Point , Std.: %f, %f \n',changePoints.prctileRange.chpt,changePoints.prctileRange.std);
fprintf(fid,'Skewness Change Point , Std.: %f, %f \n',changePoints.skewness.chpt,changePoints.skewness.std);
fprintf(fid,'Std. Change Point , Std.: %f, %f \n',changePoints.std.chpt,changePoints.std.std);
fprintf(fid,'Median Change Point , Std.: %f, %f \n',changePoints.median.chpt,changePoints.median.std);
fprintf(fid,'Mean Change Point , Std.: %f, %f \n',changePoints.mean.chpt,changePoints.mean.std);
fclose(fid);
