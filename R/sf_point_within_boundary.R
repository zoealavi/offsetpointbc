# FUNCTION: Determine the Boundaries that Points Fall Within -----------------------
#' @title sf_point_within_boundary
#'
#' @description
#' Point Within Boundary
#'
#' Used in offset_points_within_boundary(); identifies which boundaries the points fall within.
#' The function is used to flag offset points that land outside their original boundary polygon and correct their placement back into the original polygon
#'
#' @keywords internal
#'
#' @param sf_point_data point data of interest
#' @param sf_boundary_data boundary of interest joining to
#' @param sf_boundary_id_col boundary id col desired to identify boundary assigned to point based on current geometry
#' @param sf_boundary_id_col_new_name customize output column name of id column from polygon object
#'
#' @return returns an sf object with a new column showing which boundary id the point falls inside
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
sf_point_within_boundary <- function(sf_point_data,
                                     sf_boundary_data,
                                     sf_boundary_id_col,
                                     sf_boundary_id_col_new_name = "boundaryid"
) {

  # Rename the column in sf_boundary_data being joined to point data
  names(sf_boundary_data)[names(sf_boundary_data) == sf_boundary_id_col] <- sf_boundary_id_col_new_name

  ## join boundary id col to point data
  sf_joined <- st_join(sf_point_data,
                       sf_boundary_data[, sf_boundary_id_col_new_name],
                       join = st_within)

  return(sf_joined)

}
