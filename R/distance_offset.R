# FUNCTION: Add Distance Offset and Flag New Points Offset within 50m from Original Location  -----------------------
#' @title distance_offset
#'
#' @description
#' Add distance offset from original point location
#'
#'
#' @keywords internal
#'
#' @param sf_point_data point data
#'
#' @return returns column for distance point was offset by. If any below 50m, throws a warning and additional T/F "flag_within_50m" column
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
#' @importFrom sf st_join
distance_offset <- function(sf_point_data) {

  flag_50m <- sf_point_data %>%
    mutate(
      ## create old geometry from numeric x/y columns
      old_geom = st_sfc(
        mapply(function(x, y) st_point(c(x, y)), x_original, y_original, SIMPLIFY = FALSE),
        crs = st_crs(sf_point_data)
      ),
      ## compute point-to-point distance
      dist_offset_m = st_distance(old_geom, geometry, by_element = TRUE),
      ## flag < 50 m
      flag_within_50m = as.numeric(dist_offset_m) < 50
    ) %>%
    select(-old_geom)


  ## need to set up warning to force print if triggered
  old_warn <- getOption("warn")
  options(warn = 1)

  ## confirm the inputted crs is a meter based x/y unit; if not stop function and print error
  if(any(flag_50m$flag_within_50m)) {

    warning(
    "At least one point was offset or nudged back within less than 50m of its original location. Review flag_within_50m column.\n",
    "Suggestions: rerun offset function until all points are over 50m")

  } else {

    flag_50m <- flag_50m %>%
      select(
        -flag_within_50m
      )

  }

  ## reset warning
  options(warn = old_warn)

  return(flag_50m)

}
