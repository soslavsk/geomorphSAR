function [stack] = createStack(base_file,datesFile,spatialExtent)
%
%
%   This function creates a stack of georeferenced coherence images that
%   are cropped to an area of interest and ordered by ascending dates. 
%
%   INPUT:
%
%       base_file   string containign the directory structure and file name for
%                   the coherence images that will be loaded into the stack. The base_file
%                   variable should have string wildcards (%s) that will be replaced by the
%                   list of dates.  (e.g., '/dir1/dir2/coherence_%s_%s_image.tif')
%
%       datesFile   path to the file containing primary and secondary dates.
%                   Should be a Nx2 list of primary and secondary dates for each image,
%                   in the format yyyyMMdd (year-month-day). First column should be the
%                   primary dates, the second column should be secondary dates.
%
%       spatialExtent   a vector containing the spatial extents to crop the
%                       coherence images to. Should be in the form:
%                       [Xmin Xmax Ymin Ymax]
%
%       'mask'
%
%
%   OUTPUT:
%
%       stack       x by y by n stack of coherence images with same spatial
%                   extent in ascending order by date. Stacks will have two
%                   compenents
%
%                       .coh containing the GRIDobj coherence image
%                       .dates containing the primary and secondary dates





%% 1:   Read in dates and convert to matlab date format

% Read in dates from the datesFile. Should be in comma-delimited text file
% in which all dates are in the format yyyyMMdd.
fid = fopen(datesFile);
dates = textscan(fid,'%s%s','delimiter',',');
fclose(fid); clear fid;

% Convert dates to matlab dates object.
for i = 1:(length(dates{1}))
    primary_dates(i) = datetime(dates{1}(i),'InputFormat','yyyyMMdd'); % lower-case m is minutes
    secondary_dates(i) = datetime(dates{2}(i),'InputFormat','yyyyMMdd'); % lower-case m is minutes
end

%% 2:   Loop through all specified dates to create the coherence stack.

for i = 1:(length(dates{1})-1)
  % Load all coherence files correspondign to the specified dates into the
  % coherence stack.
  coherence_file = sprintf(base_file,dates{1}{i},dates{2}{i});
  try
    coherence = GRIDobj(coherence_file);
  catch
    fprintf('Could not locate coherence for %s - %s \n',dates{1}{i},dates{2}{i});
    return
  end

  % Clip the coherence files to consistent spatial extents
  coherence = crop(coherence,spatialExtent(1:2),spatialExtent(3:4));
  
  % Convert any 0 values to NaN. Some SAR software will designate noData
  % areas as 0 coherence. Replace with NaN.
  zero_mask = coherence == 0;
  coherence.Z(zero_mask.Z) = NaN;
  clear zero_mask

  % Build the coherence stack
  % Create stack of coherence in .mat file
  stack{i}.coh = coherence;
  stack{i}.date = [primary_dates(i), secondary_dates(i)];

end

