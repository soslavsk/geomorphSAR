function map_change_points(dem,area,cp,cp_label,label,zone,datum)
%
%   Function to map changepoints generated in change_point_detection.m into
%   ESRI shapefile and kml files to load into GoogleEarth.
%
%   INPUTS:
%       label       general I/O label for region (for shapefiles and kml)
%       dem         GRIDobj digital elevation model
%       area        GRIDobj drainage area (sq km)
%       cp          predicted changepoint from change_point_detection.m
%       cp_label    string denoting which changepoint statistic was used
%       zone        UTM zone as int or float (south should be negative, e.g. -19)
%       datum       coordinate datum as string (w.g., 'wgs84')
%
%
%   OUTPUTS:
%       shapefile and kml of change point locations
%
%   this function uses utm2ll
%   (https://de.mathworks.com/matlabcentral/fileexchange/45699-ll2utm-and-utm2ll)
%
%   S. Olen 7.11.2019


%% 1:
%   Calculate change-point locations from drainage area
cp_idx = area; cp_idx.Z = [];
cp_idx.Z = area.Z > cp;

%% 2:
%   Calculate flow direction and stream object of change point location (+-STD)
fd = FLOWobj(dem,'preprocess','carve');
S = STREAMobj(fd,cp_idx);
V = streampoi(S,'channelheads','xy');

%%
for i = 1:length(V(:,1))
    [lat(i),lon(i)] = utm2ll(V(i,1),V(i,2),zone,datum);
end

%% 4:
%   Export shapefile and KML of changepoints
MS = STREAMobj2mapstruct(S);
shapewrite(MS,[label,'_stream.shp']);

%%   Set up map structure for the data points
for i = 1:length(lat)
    CPS(i).Geometry = 'Point';
    CPS(i).X = V(i,1);
    CPS(i).Y = V(i,2);
    CPS_latlon(i).Geometry = 'Point';
    CPS_latlon(i).X = lon(i);
    CPS_latlon(i).Y = lat(i);
end

%%  Export shapefiles and kml

shapewrite(CPS,[label,'_',cp_label,'WGS_UTM_19S.shp']);
shapewrite(CPS_latlon,[label,'_',cp_label,'WGS84.shp']);

[Slat,Slon] = STREAMobj2latlon(S);
kmlwriteline([label,'_stream.kml'],Slat,Slon);
kmlwritepoint([label,'_',cp_label,'_point.kml'],lat,lon);

end