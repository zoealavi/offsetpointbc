
<!-- README.md is generated from README.Rmd. Please edit that file -->

# offsetpointbc

<!-- badges: start -->
<!-- badges: end -->

The goal of offsetpointbc is to offset point data to help maintain
confidentiality. The package is designed for BC data projected to a
meters based crs like crs 3005 (NAD 1983 / BC Albers) (default) or crs
26910 (NAD83 / UTM zone 10).

Appreciation and acknowledgement goes to Sunny Mak from BCCDC who
provided resources and offsetting (geomasking) methodology.

Offsetting methodology:

- x offset formula: x’ = x0 + RandDist \* cos(RandAngle)
- y offset formula: y’ = y0 + RandDist \* sin(RandAngle)

Key Background:

- code relies on sf package for spatial data manipulation.

- A point and polygon object in a meters based crs compatible for BC
  data (crs 3005 or 26910) is required. The polygon boundary layer
  ensures offset points remain within the area of interest (example, use
  bcmaps::health_chsa())

- Important: if possible, in the polygon boundary layer, include a
  column with total population for each boundary (for example,
  bcmaps::health_chsa() comes with a census population column
  “chsa_population_census”).

  - Offsetting is most appropriately done when using the average
    distance between people within a given area. This is estimated by
    the square root of the inverse of population density.
  - From this, we generate a minimum offset (1 to 2 times the average
    distance, 1 is used in this function) and a maximum offset (3 to 5
    times the average distance, 3 is used in this function)

- Note: During data preparation, before using this function, consider
  excluding cases in low population areas.

## Installation

You can install the offsetpointbc package with the following code:

``` r
devtools::install_github("https://github.com/zoealavi/offsetpointbc")
```

## Example

This is a basic example on how to run the function:

``` r
library(offsetpointbc)

pacman::p_load(dplyr,
               janitor,
               bcmaps,
               ggplot2,
               ggthemes,
               sf,
               knitr
)

# Boundary Layer ---------------------------------------------
boundary_chsa <- bcmaps::health_chsa() %>%
  clean_names() %>% 
  select(cmnty_hlth_serv_area_code,
         cmnty_hlth_serv_area_name,
         chsa_population_census, ## census population data comes with bcmaps::health_chsa() layer
         local_hlth_area_code,
         local_hlth_area_name,
         hlth_service_dlvr_area_code,
         hlth_service_dlvr_area_name,
         hlth_authority_code,
         hlth_authority_name,
         feature_area_sqm,
         feature_length_m
         ) %>% 
  filter(hlth_authority_code == "2") %>% ## filtering to Fraser Health only
  mutate(cmnty_hlth_serv_area_code = as.numeric(cmnty_hlth_serv_area_code))

# Point Layer (to offset) ---------------------------------------------
point_bc_cities <- bcmaps::bc_cities() %>% 
  clean_names() %>% 
  select(id,
         fcode,
         bcmj_tag,
         name,
         long_type) %>% 
  filter(lengths(sf::st_within(., boundary_chsa)) > 0) ## keep cities within Fraser Health only

# Apply Function ------------------------------------------------------------
offset_pop_density <- offset_points_within_boundary(
  sf_point_data = point_bc_cities,
  sf_boundary = boundary_chsa,
  sf_boundary_id_col = "cmnty_hlth_serv_area_code", 
  sf_boundary_id_col_new_name = "chsa",
  sf_boundary_total_pop_col = "chsa_population_census", ## polygon data contains population data so offsetting will be based off of population density
  crs_code = 3005 #default or can use 26910
)

# Visualize ------------------------------------------------------------
ggplot(data = boundary_chsa) + ## create a base layer
  
  ## adjust base layer (grey)
  geom_sf(lwd = .5,
          fill = "ghostwhite",
          color = "white") +
  
  ## original point data
  geom_sf(data = point_bc_cities,
          shape = 21,
          colour = "white",
          fill = "green4") +
  
  ## offset point data
  geom_sf(data = offset_pop_density,
          shape = 21,
          colour = "white",
          fill = "orange") +
  
  theme_map()
```

# Function output

- top 5 rows from offset_pop_density

| id                                              | fcode      | bcmj_tag | name               | long_type             | min_ave_dist | max_ave_dist | chsa_original | x_original | y_original |  rand_dist | rand_angle | x_offset | y_offset | geometry                 | chsa_offset | chsa_corrected | offset_boundary_match_original |
|:------------------------------------------------|:-----------|---------:|:-------------------|:----------------------|-------------:|-------------:|--------------:|-----------:|-----------:|-----------:|-----------:|---------:|---------:|:-------------------------|------------:|---------------:|:-------------------------------|
| WHSE_BASEMAPPING.BC_MAJOR_CITIES_POINTS_500M.52 | AR08750000 |       52 | Hope               | DISTRICT MUNICIPALITY |    833.47486 |    2400.4246 |          2110 |    1331330 |   495251.2 | 2288.82318 |        191 |  1329491 | 496612.8 | POINT (1329491 496612.8) |        2110 |           2110 | TRUE                           |
| WHSE_BASEMAPPING.BC_MAJOR_CITIES_POINTS_500M.53 | AR05500000 |       54 | Abbotsford         | CITY                  |     96.16909 |     188.5073 |          2132 |    1279162 |   456226.8 |  146.05486 |        162 |  1279192 | 456083.9 | POINT (1279192 456083.9) |        2132 |           2132 | TRUE                           |
| WHSE_BASEMAPPING.BC_MAJOR_CITIES_POINTS_500M.54 | AR08750000 |       55 | Langley (District) | DISTRICT MUNICIPALITY |    137.46812 |     312.4044 |          2316 |    1249824 |   460260.4 |  174.32369 |        270 |  1249996 | 460229.7 | POINT (1249996 460229.7) |        2316 |           2316 | TRUE                           |
| WHSE_BASEMAPPING.BC_MAJOR_CITIES_POINTS_500M.55 | AR05500000 |       56 | Langley (City)     | CITY                  |     68.78651 |     106.3595 |          2311 |    1244230 |   460036.7 |   95.31552 |        311 |  1244134 | 460038.3 | POINT (1244134 460038.3) |        2311 |           2311 | TRUE                           |
| WHSE_BASEMAPPING.BC_MAJOR_CITIES_POINTS_500M.56 | AR05500000 |       57 | Surrey             | CITY                  |     68.00867 |     104.0260 |          2335 |    1233373 |   463621.2 |   93.24190 |         67 |  1233324 | 463541.4 | POINT (1233324 463541.4) |        2335 |           2335 | TRUE                           |

# Visualize offsetting

- Green is original point location
- Orange is offset location

<img src="man/figures/README-visualize_offset-1.png" alt="" width="100%" />
