# Calculate change points
After the coherence time-series and temporally-averaged coherence image is calculated (see **create_coherence_stack.md**), we can run the hillslope-to-fluvial and fluvial-to-alluval changepoint estimation. In addition to the coherence stack and temorally-averaged coherence map, you will need the following geotiffs:

1. Digital elevation model (DEM)
2. Drainage area (sq km)
3. Drainage basins* as geotiff (each basin should be designated by a number)
4. Hillslope gradient or slope
5. Normalized Difference Vegetation Index (NDVI)

\* If basins overlap, they will need to be separated into different geotiffs.


#### Define I/O and input parameters
In addition to the input/output parameters (for reading in and writing out files), here you will need to supply a minimum drainage area to be considered in the changepoint analysis. This should be small enough to still cover the hillslope domain.

```matlab
% Define some I/O variables
inputLabel = 'S1_QdT_tandemx';
outputLabel = 'S1_QdT_tandemx_Rg7Az2_fullres';

% This is the minimum upstream drainage area in square meters to go into
% the change point analysis. This might get removed at a later date.
minAm = 100;
```

#### Read in the required geotiffs
Geotiffs should be the same spatial extent and resolution of the coherence map.

```matlab
% Load in gridded geotifs
fprintf('Loading DEM....\n')
dem = GRIDobj([inputLabel,'_dem.tif']);
ndvi = GRIDobj([inputLabel,'_ndvi.tif']);
db = GRIDobj([inputLabel,'_db.tif']);
slope = GRIDobj([inputLabel,'_slope.tif']);
area = GRIDobj([inputlabel,'_area.tif']); % Area should be in sq km
avcoh = GRIDobj([outputLabel,'_median_coherence.tif')
```

#### Mask out vegetated regions
Because the wavelength of most SAR signals is short enough to interact with surface vegetation, dense vegeatation cover and changes in vegetation can result in coherence loss unrelated to sediment movement. Therefore, we advise masking out vegetated areas (NDVI > 0.2-0.3) before performing any gemorphic analysis. 

```matlab
% Mask out areas with vegetation cover (NDVI > 0.3)
avcoh.Z(ndvi.Z > 0.3) = NaN;
```

We calculated NDVI from Landsat-8 images covering the same time frame as our SAR coherence time-series. The same could be done, however, with Sentinel-2 data for higher resolution NDVI (but a shorter time-series) or MODIS data (for a longer time-series, but lower resolution NDVI). See here [here](https://developers.google.com/earth-engine/tutorial_api_06) for an example on how to make NDVI using Google Earth Engine.

#### Set up drainge basins to loop through
We will estimate the change points for more than one drainage basin at a time. We load in a geotiff containing non-overlapping drainage basins (each assigned an integer value).

```matlab
dbIDs = unique(db.Z);
dbIDs = dbIDs(dbIDs>0);
```

Here the drainage basin IDs are integers ascending from 1. We suggest using this convention for ease of setting up the for-loop.

#### Run loop through all drainage basins and predict change points
Looping through each drainage basin, mask out all data outside of the current basin being analyzed. Because some of the output is generalized (e.g., the `calculate_change_points.m` function only outputs a text called *changepoint_locations.txt* for each basin, we recommend either:

(1) Creating a new directory for each basin within the loop and running the `calculate_change_points.m` and other functions from within the subdirectory,

```matlab
mkdirCMD = ['!mkdir Basin_',num2str(i)]; eval(mkdirCMD);
chdirCMD = ['!chdir Basin_',num2str(i)]; eval(chdirCMD);
```

or;

(2) Editing the `calculate_change_points.m` file to dynamically change output filenames to correspond to the present basin. This should be fairly straigtforward and only involves passing the basin ID ot the function, then adding a line to incoprorate that ID in the output name.

```matlab
for i = 1:length(dbIDs)
    current_ws = db == i;
    ws_idx = crop(current_ws,current_ws);
    dem_ws = crop(dem,current_ws);
    avcoh_ws = crop(avcoh,current_ws); avcoh_ws.Z(~ws_idx.Z) = NaN;
    slope_ws = crop(slope,current_ws); slope_ws.Z(~ws_idx.Z) = NaN;
    area_ws = crop(area,current_ws); area_ws.Z(~ws_idx.Z) = NaN;
    aspect_ws = crop(aspect,current_ws); aspect_ws.Z(~ws_idx.Z) = NaN;
    relief_ws = crop(relief,current_ws); relief_ws.Z(~ws_idx.Z) = NaN;
```

Detect change points for each basin; they will be stored (the change point location and standard deviation) in a cell structure corresponding to each basin. Additionally, a text file will be written with the changepoint location and standard deviation for each basin.

```matlab
    [changePoints{i}] = change_point_detection(area_ws,avcoh_ws,slope_ws,minAm);
```

Output ESRI shapefiles and Google Earth kml files of the changepoint locations.
 
```matlab
map_change_points(dem_ws,area_ws,changePoints{i}.median.cp,'median',outputLabel,-19,'wgs84');
map_change_points(dem_ws,area_ws,changePoints{i}.skewness.cp,'skewness',outputLabel,-19,'wgs84');
```
Finally, make some plots of the channel profile (slope area and chi plots) for each basin. The `make_stream_plots` function will automatically output a PNG and EPS file.

```matlab
    [s,t,~,~] = calculate_stream_network(dem_ws,0.1);
    make_stream_plots(s,dem_ws);
end
```




