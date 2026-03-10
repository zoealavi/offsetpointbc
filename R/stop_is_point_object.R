# FUNCTION: Transform to specified CRS Code  ---------------------------------
#' @title Stop Flags - Is Point Object
#'
#' @description
#' built in checks that stop function if not met
#'
#' @keywords internal
#'
#' @param sf_point_object point object
#'
#' @return stops function if not a point/multipoint object
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
#' @importFrom sf st_geometry_type

is_point_sf <- function(sf_point_object) {

  arg <- deparse(substitute(sf_point_object))

  types <- unique(as.character(sf::st_geometry_type(sf_point_object)))

  if (!all(types %in% c("POINT", "MULTIPOINT"))) {
    stop(sprintf(
      "`%s` must contain only POINT or MULTIPOINT geometries. Found: %s",
      arg, paste0(types, collapse = ", ")
    ), call. = FALSE)
  }
  invisible(TRUE)
}
