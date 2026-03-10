# FUNCTION: Offset X/Y coordinates ----------------------------------------
#' @title offset_point
#'
#' @description
#' Offset Coordinates
#'
#' Used in offset_points_within_boundary()
#' Offset points to maintain confidentiality using the following offsetting methodology:
#'     x offset formula: x' = x0 + RandDist * cos(RandAngle)
#'     y offset formula: y' = y0 + RandDist * sin(RandAngle)
#'     Note: default min/max range for random distance number is between 50:200 and for random angle its between 1:360
#' Note: offsetting MUST be done in a crs fit for BC mapping like 3005 (pcs NAD 1983 BC Albers)
#'
#' Note: offsetting is best done based off of a population density min/max handled in ave_dist_btw_ppl() and offset_points_within_boundary()
#'
#' @keywords internal
#'
#' @param sf_data_to_offset sf point object requiring offsetting
#' @param rand_dist_min default min = 50
#' @param rand_dist_max default max = 200
#' @param rand_angle_min default min = 1
#' @param rand_angle_max default max = 360
#'
#' @return returns an sf point object with offset points
#'
#' @examples
#' \dontrun{
#'   offset_points_within_boundary(
#'     sf_point_data = bcmaps::bc_cities(),
#'     sf_boundary = bcmaps::health_chsa(),
#'     sf_boundary_id_col = "cmnty_hlth_serv_area_code",
#'     sf_boundary_id_col_new_name = "chsa",
#'     sf_boundary_total_pop_col = "chsa_population_census"
#'     )
#'   }
#'
#' @export
#'
#' @importFrom sf st_coordinates st_drop_geometry st_as_sf
#' @importFrom dplyr mutate
offset_point <- function(sf_data_to_offset,
                         crs_code = 3005,
                         rand_dist_min = 50,
                         rand_dist_max = 200,
                         rand_angle_min = 1,
                         rand_angle_max = 360
) {

  ## extract the original x coordinate into its own column (taken from sf's geometry col)
  sf_data_to_offset$x_original <- st_coordinates(sf_data_to_offset)[, "X"]

  ## extract the original y coordinate into its own column (taken from sf's geometry col)
  sf_data_to_offset$y_original <- st_coordinates(sf_data_to_offset)[, "Y"]

  ## run random offsetting calculation
  sf_data_to_offset <- sf_data_to_offset %>%
    ## get a random value within min/max range for distance and angle
    mutate(

      ## if the input for rand_dist_min/max is length 1 (not population based),
      rand_dist = if(length(rand_dist_min) == 1 && length(rand_dist_max) == 1){

        ## then select a random number between those min/max values
        sample(rand_dist_min[1]:rand_dist_max[1], n(), replace = TRUE)

      } else {

        ## else, us the column defined min/max for a given row on that row (population based)
        mapply(function(min, max) runif(1, min, max), rand_dist_min, rand_dist_max)

      },

      ## get random angle value between 1 and 360
      rand_angle = sample(rand_angle_min[1]:rand_angle_max[1], n(), replace = TRUE)

    ) %>%

    ## offset original x and y
    mutate(x_offset = x_original + rand_dist * cos(rand_angle),
           y_offset = y_original + rand_dist * sin(rand_angle)) %>%
    ## drop current (original) geometry of sf object to create a new one using the offset values
    st_drop_geometry() %>%

    ## transform into an sf object using new x/y offset coordinates
    st_as_sf(.,
             ## use offset coordinates
             coords = c("x_offset",
                        "y_offset"),
             ## identify the crs of the offset x/y
             crs = crs_code,
             ## do not remove the offset cols so they can be compared against original
             remove = FALSE)

  return(sf_data_to_offset)

}
