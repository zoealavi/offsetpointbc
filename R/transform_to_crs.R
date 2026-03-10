# FUNCTION: Transform to specified CRS Code  ---------------------------------
#' @title transform_to_crs
#'
#' @description
#' Transform CRS Code
#'
#' Used in offset_points_within_boundary(); ensures both point and polygon sf objects are in the same crs
#'
#' @keywords internal
#'
#' @param sf_object sf object's crs to evaluate and transform if needed
#' @param desired_crs_code default 3005; any BC meters based crs will work
#'
#' @return returns an sf object
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
#' @importFrom sf st_crs st_transform
transform_to_crs <- function(sf_object,
                             desired_crs_code = 3005
) {

  ## store all crs info pertaining to sf object
  crs_info <- st_crs(sf_object)
  ## pull crs code number only
  crs_code <- crs_info$epsg

  ## if the crs code does not match desired crs code then transform it
  if(crs_code != desired_crs_code){
    transformed_data <- st_transform(sf_object,
                                     crs = desired_crs_code)

    ## else keep as is
  } else {
    transformed_data <- sf_object
  }

  return(transformed_data)
}
