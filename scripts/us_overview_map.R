# Example interactive map using sf and tmap

library(sf)
library(tmap)
library(here)

us_states<-read_sf(here("data", "us_states_shape", "cb_2018_us_state_20m.shp"))
us_dctt_data<-read.csv(here("data", "state_dctt_data.csv"))
us_states_data<-merge(us_states, us_dctt_data, by = "NAME")

map<-tm_shape(us_states_data) + 
  tm_polygons("DCTT", palette = "BuGn", title = "Using a DCTT", popup.vars = c("DCTT", "APP_NAME", "TECHNOLOGY")) +
  tm_scale_bar(breaks = c(0, 100, 200), text.size = 1) + 
  tm_minimap() + 
  tm_view(set.view = c(-120, 53, 3)) + 
  tmap_mode("view")

map
