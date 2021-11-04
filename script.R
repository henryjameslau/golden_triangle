## Golden Triangle ##

library(tidyverse) 
library(rgdal) 
library(stars) 
library(sf) 
library(rnaturalearth) 
library(osrm)

# 1) Load geospatial data

# Regions of England
# Source: ONS Open Geography Portal
# URL: https://geoportal.statistics.gov.uk/datasets/regions-december-2020-en-bgc
region <- st_read("https://opendata.arcgis.com/datasets/cfa25518ddd7408a8da5c27eb42dd428_0.geojson") %>% 
  st_transform(27700) %>% 
  filter(RGN20NM == "London")

plot(st_geometry(region))

# Scotland / Wales
# Source: Natural Earth
# URL: https://www.naturalearthdata.com
country <- ne_countries(country = 'united kingdom', type = 'map_units', scale = 'large', returnclass = 'sf') %>% 
  filter(geounit != "Northern Ireland") %>%
  st_transform(crs = 27700)

plot(st_geometry(country))

# UK population (2011 Census, 1 km x 1 km grid)
# Source: NERC Environmental Information Data Centre
# URL: https://catalogue.ceh.ac.uk/documents/0995e94d-6d42-40c1-8ed4-5090d82471e1
grid <- readGDAL("data/UK_residential_population_2011_1_km.asc", p4s = '+init=EPSG:4326') %>%
  st_as_stars() %>%
  st_as_sf(as_points = FALSE, merge = TRUE)

centroids <- grid %>%
  st_transform(crs = 27700) %>% 
  st_centroid() %>% 
  st_intersection(country) %>% ## intersect with region / country
  mutate(grid_id = row_number()) %>% 
  select(grid_id, population = band1) %>% 
  st_transform(crs = 4326) %>%
  st_write('gb_centroid.geojson')

plot(st_geometry(st_transform(region, 4326)))
plot(st_geometry(centroids), add = T)

# 2) Create 4hr drive-time polygons for every population grid square

# Source: Open Source Routing Machine; OpenStreetMap
# URL: http://map.project-osrm.org
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

plot(st_geometry(st_transform(gb, 4326)))
plot(st_geometry(iso), add = T)
# st_write(iso, "processed/london.geojson")

# 3) Summarize the total population reachable by each population grid centroid
iso <- st_read("processed/london.geojson")

reachable <- st_intersection(centroids, iso) %>%
  group_by(iso_id) %>%
  summarise(total_population = sum(population),
            percentage = round(total_population/sum(centroids$population)*100,3)) 
  
# 4) Filter those population grid centroids that are accessible to 90% of the population

# 5) Construct polygon(s) using the subset