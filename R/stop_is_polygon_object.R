# FUNCTION: Transform to specified CRS Code  ---------------------------------
#' @title Stop Flags - Is Poylgon Object
#'
#' @description
#' built in checks that stop function if not met
#'
#' @keywords internal
#'
#' @param sf_polygon_object polygon object
#'
#' @return stops function if not a polygon/multipolygon object
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

is_polygon_sf <- function(sf_polygon_object) {

  arg <- deparse(substitute(sf_polygon_object))

  types <- unique(as.character(sf::st_geometry_type(sf_polygon_object)))
  if (!all(types %in% c("POLYGON", "MULTIPOLYGON"))) {
    stop(sprintf(
      "`%s` must contain only POLYGON or MULTIPOLYGON geometries. Found: %s",
      arg, paste(types, collapse = ", ")
    ), call. = FALSE)
  }
  invisible(TRUE)
}
