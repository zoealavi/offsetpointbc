
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
  column with total population for each boundary (ex link to BC Stats’
  PEOPLE data).

  - Offsetting is most appropriately done when using the average
    distance between people within a given area. This is estimated by
    the square root of the inverse of population density.
  - From this, we generate a minimum offset (1 to 2 times the average
    distance, 1 is used in this function) and a maximum offset (3 to 5
    times the average distance, 3 is used in this function)

- Note: During data preparation, before using this function, consider
  excluding cases in low population areas.

## Installation

You can install the development version of offsetpointbc like so:

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
               sf
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

    #> Simple feature collection with 5 features and 17 fields
    #> Geometry type: POINT
    #> Dimension:     XY
    #> Bounding box:  xmin: 1233277 ymin: 456244.9 xmax: 1330268 ymax: 497280.1
    #> Projected CRS: NAD83 / BC Albers
    #> # A tibble: 5 × 18
    #>   id      fcode bcmj_tag name  long_type min_ave_dist max_ave_dist chsa_original
    #>   <chr>   <chr>    <int> <chr> <chr>            <dbl>        <dbl>         <dbl>
    #> 1 WHSE_B… AR08…       52 Hope  DISTRICT…        833.         2400.          2110
    #> 2 WHSE_B… AR05…       54 Abbo… CITY              96.2         189.          2132
    #> 3 WHSE_B… AR08…       55 Lang… DISTRICT…        137.          312.          2316
    #> 4 WHSE_B… AR05…       56 Lang… CITY              68.8         106.          2311
    #> 5 WHSE_B… AR05…       57 Surr… CITY              68.0         104.          2335
    #> # ℹ 10 more variables: x_original <dbl>, y_original <dbl>, rand_dist <dbl>,
    #> #   rand_angle <int>, x_offset <dbl>, y_offset <dbl>, geometry <POINT [m]>,
    #> #   chsa_offset <dbl>, chsa_corrected <dbl>,
    #> #   offset_boundary_match_original <lgl>

# Visualize offsetting

- Green is original point location
- Orange is offset location

<img src="man/figures/README-visualize_offset-1.png" alt="" width="100%" />
