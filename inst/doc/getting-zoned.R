## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  cache = FALSE,
  out.width = "100%"
)

## ----load_pkgs, message=FALSE--------------------------------------------
library(usps)
library(zipcode)
library(ggplot2)
library(dplyr)
library(tidyr)

## ------------------------------------------------------------------------
data(zips_zones)
zips_zones

## ------------------------------------------------------------------------
data(zipcode)
zipcode %>% 
  as_tibble()

## ----load_zips-----------------------------------------------------------
zips <- 
  zipcode %>% 
  as_tibble() %>% 
  mutate(
    zip_trim = substr(zip, 1, 3)
  )

zips

## ----usps_zips-----------------------------------------------------------
(usps_zips <-
  tibble(
    zip =
      unique(zips_zones$origin_zip) %>% 
      c(unique(zips_zones$dest_zip)) 
  ) %>% 
  distinct())

## ----zips_lat_long-------------------------------------------------------
(zips_lat_long <- 
  zips %>% 
  distinct(zip_trim, .keep_all = TRUE) %>% 
  left_join(usps_zips, by = c("zip_trim" = "zip")) %>% 
  select(zip_trim, latitude, longitude))

## ----zips_zones_lat_long-------------------------------------------------
(zips_zones_lat_long <- 
  zips_zones %>% 
  select(origin_zip, dest_zip, zone) %>% 
  left_join(zips_lat_long, by = c("origin_zip" = "zip_trim")) %>% 
  rename(
      lat_origin = latitude,
      long_origin = longitude) %>% 
  left_join(zips_lat_long, by = c("dest_zip" = "zip_trim")) %>% 
  rename(
      lat_dest = latitude,
      long_dest = longitude) %>% 
  drop_na(zone))

## ---- eval=FALSE---------------------------------------------------------
#  get_googlemap("us", zoom = 4)
#  # or
#  get_map("us", zoom = 4, maptype = "toner-lite")

## ----us_map--------------------------------------------------------------
us <- 
  map_data("state") %>%
  as_tibble() 

## ------------------------------------------------------------------------
zz_filtered <- 
  zips_zones_lat_long %>% 
  filter(origin_zip == "112") %>% 
  left_join(us, by = c("lat_dest" = "lat", "long_dest" = "long")) %>% 
  filter(as.numeric(dest_zip) > 10 &
           long_dest < -50)

## ----zone_map, eval=FALSE, warning=FALSE---------------------------------
#  ggplot() +
#    geom_polygon(data = us, aes(x = long, y = lat, group = group), fill = "white", color = "black") +
#    geom_density_2d(data = zz_filtered,
#               aes(long_dest, lat_dest, colour = factor(zone)),
#               alpha = 1) +
#    labs(x = "Longitude", y = "Latitude", colour = "Zone") +
#    ggtitle("Shipping Zones from Brooklyn",
#            subtitle = "Origin zone prefix: 112") +
#    scale_colour_brewer(type = "seq", palette = "BrBG") +
#    theme_classic(base_family = "Arial Narrow") +
#    coord_quickmap()

## ---- echo=FALSE---------------------------------------------------------
knitr::include_graphics("../inst/doc/zone_map.jpg")

