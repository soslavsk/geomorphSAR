# Creating a coherence stack

The first step in our analysis is to create an x-by-y-by-n stack of coherence images (from geotiffs) that we can edit to, e.g., calculate temporal averages, track coherence chagnes through time, or look at seasonal coherence patterns. In MATLAB, we will be using the Topotoolbox v2 functions to create a stack of georeferenced coherence GRIDobjects with corresponding primary and secondary dates attached.

Below follows an example of how you can use the functions here to create such a stack.

#### Set up some I/O parameters
Begin by defining the input/output paramters you will use to read in coherence images, digital elevation model, and other required inputs; as well as defining a prefix for all files to be output form this process (e.g., temporally averaged geotiffs).

```matlab
% Define some I/O variables
inputLabel = 'S1_QdT_tandemx';
outputLabel = 'S1_QdT_tandemx_Rg7Az2_fullres';
baseFileAsc = 'coherence_images_ascending/geo_filt_fine.full.%s_%s.rg7.az2.cor.utm19_30m.tif'
baseFileDesc = 'coherence_images_descending/geo_filt_fine.full.%s_%s.rg7.az2.cor.utm19_30m.tif'
datesAsc = 'ascending_dates.list';
datesDesc = 'descendign_dates.list';
```
**Note:** For ease of reading in multiple coherence images, it is best to use a common naming convention that includes the primary and secondary dates in the file name. These codes are set up to read dates in the format **yyyyMMdd** (year-month-day). The `baseFile` variable should include wildcards (`%s`) that will dynamically fill in the dates included in the `dates.list` file.

>ascending_dates.list
20141127,20150114
20150114,20150207
20150207,20150502
20150502,20150526
20150526,20150619
20150619,20150713
20150713,20150806
20150806,20150830
20150830,20150923
20150923,20151110

If dates are entered in another format, the **createStack.m** function will need to be edited.

#### Load in DEM and extract spatial extents
```matlab
dem = GRIDobj([inputLabel,'_dem.tif']);
spatialExtents = [dem.georef.SpatialRef.XWorldLimits, dem.georef.SpatialRef.YWorldLimits];
```
Alternatively you can manually define the spatial extents as `spatialExtents = [X-min X-max Y-min Y-max]`.

#### Build the ascending and descending coherence stacks
We will now feed the coherence image and date list file directories into the **craeteStack.m** function, as well as the desired spatial extents, to create ascending and descending stacks of georeferenced coherence GRIDobjects all containing the same spatial reference. These stacks will be combined into one stack containing all ascending and descending images in a few steps.

```matlab
% Build the ascending and descending stacks with all images cropped to the DEM extents.
ascStack = createStack(baseFileAsc,datesAsc,spatialExtents);
descStack = createStack(baseFileDesc,datesDesc,spatialExtents);
```

#### Apply incidence angle mask
The local incidence angle incorporates both satellite look direction and angle, as well as the local hillslope angle of the surface topography. Because the SAR satellites image the Earth from an oblique angle, some parts of the surface will not be "visible" to the SAR sensor, especially in steep, mountainous topography. Therefore is important to mask out regions that the satellite doesn't "see," which will not produce reliable or meaningful coherence estimates.

The local incidence angle can easily be calculated from a single SAR image and a reliable DEM using the SNAP software (http://step.esa.int/main/toolboxes/snap/), or by other InSAR software packages.

```matlab
% Load in incidence maks files
inclocAsc = GRIDobj([inputLabel,'_inclocAsc.tif']);
inclocDesc = GRIDobj([inputLabel,'_inclocDesc.tif']);
```
```matlab
% Calculate incidence angle masks and apply to stack
[masked_ascStack,ascMask] = incidence_mask(ascStack,inclocAsc,[10 60]);
[masked_descStack,descMask] = incidence_mask(descStack,inclocDesc,[10 60]);
```

If we want, we can also check the extent of areas masked out of the ascending and descending coherence images at this point.

```matlab
% Create a hillshade map of the ascending and descending incidence angle masks.
subplot(2,1)
imageschs(dem,ascMask,'colormap',bone);
title('Ascending Mask');
subplot(2,2)
imageschs(dem,descMask,'colormap',bone);
title(Descending Mask');
```

#### Combine ascending and descending stacks and create temporal average
After applying the local incidence angle mask (and optionally the delta-Ampltude soil moisture mask, see below), we can combine the ascending and descending coherence images into one stack ordered by ascending date. This may take a moment, and be cautioned that the resulting file will be large(!) if you choose to save the variable (as we do here).

```matlab
% Combine ascending and descending stacks and save output
[stack,dates] = combine_asc_desc(masked_ascStack,masked_descStack);
save([outputLabel,'_coherence_stack.mat','stack','-v7.3');
```
We can now temporally reduce the coherence stack by various statistics (e.g., create a temporal average of all coherence images in the time-series.)

```matlab
% Calculate temporal average of all coherence images and write output to Geotiff
medianStack = reduceStack(stack,'median');
GRIDobj2geotiff(medianStack,[outputLabel,'_median_coherence.tif');
```

In addition to reducing by the median value, you can also choose the following additional statistics: `'mean', 'std', 'prc5','prc10','prc90'`. (All **prc** options refer to percentiles for each pixel over the time series.)

---

#### **Optional:**  Apply soil moisture mask (d-Amplitude)
If you want to mask out regions that may have been affected by soil moisture change, you can calculate and apply a dAmplitude mask before combining and averaging the ascending and descending stacks. Wet surfaces or standing water will have a relatively low amplitude value compared to a dry surface. Therefore we estimate regions with high soil moisture or standing water by first calcuating the standard deviation of amplitude from the coherence time series, then for each amplitude image, mask out regions where the change in amplitude (time_n-1 - time_n) is greater than 2-sigma of the entire coherence time series. 


```matlab
% Point to the amplitude images
ampFileAsc = 'amplitude_images/ascending/S1_amp_%s_%s.tif';
ampFileDesc = 'amplitude_images/descending/S1_amp_%s_%s.tif';
```

```matlab
% Calculate and apply dAmplitude mask
[ampStackAsc,ampMaskAsc] = damp_mask(ampFileAsc,datesAsc,0);
[ampStackDesc,ampMaskDesc] = damp_mask(ampFileDesc,datesDesc,0);
```
The dAmplitude mask is then applied dynamically to the coherence stack (i.e., unique masks for each image/time).

```matlab
% Apply the mask to the coherence stack
masked_ascStack = maskStack(ascStack,ampMaskAsc);
masked_descStack = maskStack(descStack,ampMaskDesc);
