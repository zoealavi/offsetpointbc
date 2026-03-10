
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

Key Background: - code relies on sf package for spatial data
manipulation.

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
#> health_chsa was updated on 2026-01-27

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
#> 
#> 
#>   Summary of Offsetting Performance
#> 
#>   Definitions for summary table:
#>       TRUE: Offset succesful, original boundary id matches final (corrected) offset boundary id
#>       NA: Offset succesful, but original point data contains x/y coordinates that originated beyond the sf polygon object inputted into sf_boundary.
#>       FALSE: Potential error/failure in function.
#>              Try adjusting the 'buffer_dist_to_correct_by_meters' input (in meters) (never do <=0m), otherwise contact author.
#> 
#>   Summary Table:
#> 
#>    offset_boundary_match_original total
#>                            TRUE    20
```

# Summary of function output:

``` r
summary(offset_pop_density)
#>       id               fcode              bcmj_tag          name          
#>  Length:20          Length:20          Min.   : 52.00   Length:20         
#>  Class :character   Class :character   1st Qu.: 56.75   Class :character  
#>  Mode  :character   Mode  :character   Median : 82.50   Mode  :character  
#>                                        Mean   : 79.35                     
#>                                        3rd Qu.: 93.50                     
#>                                        Max.   :117.00                     
#>   long_type          min_ave_dist     max_ave_dist     chsa_original 
#>  Length:20          Min.   : 61.12   Min.   :  83.36   Min.   :2110  
#>  Class :character   1st Qu.: 70.81   1st Qu.: 112.43   1st Qu.:2150  
#>  Mode  :character   Median :100.01   Median : 200.03   Median :2238  
#>                     Mean   :201.14   Mean   : 503.43   Mean   :2228  
#>                     3rd Qu.:150.25   3rd Qu.: 350.76   3rd Qu.:2262  
#>                     Max.   :833.47   Max.   :2400.42   Max.   :2342  
#>    x_original        y_original       rand_dist         rand_angle    
#>  Min.   :1217710   Min.   :450637   Min.   :  62.55   Min.   : 22.00  
#>  1st Qu.:1230290   1st Qu.:462781   1st Qu.:  92.78   1st Qu.: 87.25  
#>  Median :1238635   Median :473352   Median : 138.51   Median :138.00  
#>  Mean   :1252586   Mean   :471725   Mean   : 380.77   Mean   :167.40  
#>  3rd Qu.:1271510   3rd Qu.:479963   3rd Qu.: 285.30   3rd Qu.:259.00  
#>  Max.   :1331330   Max.   :495251   Max.   :1907.34   Max.   :312.00  
#>     x_offset          y_offset               geometry   chsa_offset  
#>  Min.   :1217846   Min.   :450665   POINT        :20   Min.   :2110  
#>  1st Qu.:1230259   1st Qu.:462714   epsg:3005    : 0   1st Qu.:2150  
#>  Median :1238701   Median :473442   +proj=aea ...: 0   Median :2238  
#>  Mean   :1252541   Mean   :471548                      Mean   :2228  
#>  3rd Qu.:1272030   3rd Qu.:479645                      3rd Qu.:2262  
#>  Max.   :1329622   Max.   :494404                      Max.   :2342  
#>  chsa_corrected offset_boundary_match_original
#>  Min.   :2110   Mode:logical                  
#>  1st Qu.:2150   TRUE:20                       
#>  Median :2238                                 
#>  Mean   :2228                                 
#>  3rd Qu.:2262                                 
#>  Max.   :2342
```

# Visualize offsetting

Green is original point location Orange is offset location

``` r

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

<img src="man/figures/README-visualize_offset-1.png" alt="" width="100%" />
