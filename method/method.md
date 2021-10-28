# Method

**NB** repeat for each country/region

### Load necessary R packages

```
library(tidyverse) ; library(rgdal) ; library(stars) ; library(sf) ; library(rnaturalearth) ; library(osrm)
```

### Load geospatial data

**Scotland / Wales**       
Source: Natural Earth     
URL: [https://www.naturalearthdata.com](https://www.naturalearthdata.com)
```
country <- ne_countries(country = 'united kingdom', type = 'map_units', scale = 'large', returnclass = 'sf') %>% 
  filter(geounit == "Scotland") %>%
  st_transform(crs = 27700)
```

**Regions of England**        
Source: ONS Open Geography Portal        
URL: [https://geoportal.statistics.gov.uk/datasets/regions-december-2020-en-bgc](https://geoportal.statistics.gov.uk/datasets/regions-december-2020-en-bgc)
```
region <- st_read("https://opendata.arcgis.com/datasets/cfa25518ddd7408a8da5c27eb42dd428_0.geojson") %>% 
  st_transform(27700) %>% 
  filter(RGN20NM == "London")
```

**UK population (2011 Census, 1 km x 1 km grid)**        
Source: NERC Environmental Information Data Centre       
URL: [https://catalogue.ceh.ac.uk/documents/0995e94d-6d42-40c1-8ed4-5090d82471e1](https://catalogue.ceh.ac.uk/documents/0995e94d-6d42-40c1-8ed4-5090d82471e1)
```
grid <- readGDAL("data/UK_residential_population_2011_1_km.asc", p4s = '+init=EPSG:4326') %>%
  st_as_stars() %>%
  st_as_sf(as_points = FALSE, merge = TRUE)
```

### Extract centroids from population grid and intersect with country/region
```
centroids <- grid %>%
  st_transform(crs = 27700) %>% 
  st_centroid() %>% 
  st_intersection(region) %>%
  mutate(grid_id = row_number()) %>% 
  select(grid_id, population = band1) %>% 
  st_transform(crs = 4326) 
```

*Check results*
```
plot(st_geometry(st_transform(region, 4326)))
plot(st_geometry(centroids), add = T)
```

### Calculate 4hr drive-time polygons for every population centroid in country/region

**Docker OSRM**       
Source: Open Source Routing Machine; Docker OSRM        
URL: [http://map.project-osrm.org](http://map.project-osrm.org); [https://hub.docker.com/r/osrm/osrm-backend](https://hub.docker.com/r/osrm/osrm-backend)

```
options(osrm.server = "http://localhost:5000/", osrm.profile = "driving")

iso <- select(centroids, -population) %>%
  mutate(iso = map(geometry,
                   osrmIsochrone,
                   breaks = seq(from = 0, to = 240, by = 240),
                   res = 30,
                   returnclass = "sf")) %>%
  st_drop_geometry() %>%
  unnest(iso) %>%
  st_set_geometry("geometry") %>% 
  rename(iso_id = grid_id)
```

*Check results*
```
plot(st_geometry(st_transform(gb, 4326)))
plot(st_geometry(iso), add = T)
```

### Match centroid coordinates to isochrones

```
iso_centroids <- left_join(iso, centroids %>% 
                             mutate(lon = map_dbl(geometry, ~st_coordinates(.x)[[1]]),
                                    lat = map_dbl(geometry, ~st_coordinates(.x)[[2]])) %>% 
                             st_drop_geometry(), by = c("iso_id" = "grid_id"))
```

### Extract centroids from population grid for GB

```
gb_centroids <- grid %>%
  st_transform(crs = 27700) %>% 
  st_centroid() %>% 
  select(grid_id, population = band1) %>% 
  st_transform(crs = 4326) 
```

### Summarise the total population reachable by each centroid
```
pop_centroids <- iso_centroids %>% 
  group_by(iso_id) %>% 
  group_modify(~ st_intersection(gb_centroids, .x, .keep = FALSE)) %>% 
  summarise(total_population = sum(population),
            percentage = round(total_population/sum(gb_centroids$population)*100,3))
```

### Subset centroids 
**Might not be necessary with entire region calculated**
```
left_join(filter(centroids, grid_id %in% pop_centroids$iso_id), pop_centroids,
               by = c("grid_id" = "iso_id"))
```

### Match centroids to grid
```
pop_grid <- st_transform(grid, 4326) %>% 
  filter(apply(st_intersects(., pop_centroids, sparse = FALSE), 1, any))
```

### Subset grid squares which reach 90% of population
```
filter(, percentage >= 90)
```

### Write results
```
st_write(, "polygons/east_midlands.geojson")
```
