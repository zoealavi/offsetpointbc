# FUNCTION: Correct Offset Points --------------------------------------
#' @title offset_corrections
#'
#' @description
#' Correct Offset Point Positions
#'
#' Used in offset_points_within_boundary(); corrects offset points that fell beyond their original boundary polygon
#' Have to review offset point geometry location and if any fall outside their original polygon location, nudge their placement back into original polygon
#'
#' @keywords internal
#'
#' @param offset_data sf object containing offset geometry needing review
#' @param offset_boundary_id_col_name_original boundary id col from original x/y coordinates in offset_data
#' @param offset_boundary_id_col_name_offset boundary id col from offset x/y coordinates in offset_data
#' @param sf_boundary sf boundary of interest
#' @param sf_boundary_id_col sf boundary id col desired to identify boundary assigned to point based on current geometry
#' @param buffer_dist_to_correct_by_meters buffer distance to be made within boundary
#'
#' @return returns an sf point object with adjusted offset points that now fall within their original polygon boundary
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
#' @importFrom sf st_drop_geometry st_buffer st_nearest_points st_cast
#' @importFrom dplyr filter %>%
offset_corrections <- function(offset_data,
                               offset_boundary_id_col_name_original,
                               offset_boundary_id_col_name_offset,
                               sf_boundary,
                               sf_boundary_id_col,
                               buffer_dist_to_correct_by_meters = 5
) {

  ## remove geometry from offset data to be able to list ids for "mismatched" step otherwise geometry col is part of list
  no_geom <- offset_data %>%
    st_drop_geometry()

  ## identify which points got offset beyond original boundary (ex: neighboring or into water) in order to fix them.

  ## flag any cases where original id does not match offset id boundary
  mismatched <- no_geom[, offset_boundary_id_col_name_original] != no_geom[, offset_boundary_id_col_name_offset] |
    ## OR if their is an NA (example offset into water)
    is.na(no_geom[, offset_boundary_id_col_name_original]) != is.na(no_geom[, offset_boundary_id_col_name_offset])


  ## Adjust mismatched points
  for (i in which(mismatched)) {

    ## identify the correct boundary id needed for fixing the incorrect point placement
    target_boundary_filtered <- sf_boundary %>%
      dplyr::filter(.data[[sf_boundary_id_col]] == no_geom[[offset_boundary_id_col_name_original]][i])
      #filter(.data[[sf_boundary_id_col]] == no_geom[i, offset_boundary_id_col_name_original]) ##2026-03-09: deprecated in dplyr 1.1.0: returns a 1×1 tibble/data.frame (or a 1‑column matrix), not a scalar vector value. Starting with dplyr 1.1.0, using one‑column matrices/data frames as logical inputs in filter() is deprecated. filter() expects a one-dimensional logical vector (or a scalar value when used in a comparison), not a data frame/matrix.

    ## create a buffered edge INSIDE the correct boundary to ensure adjusted points land inside boundary
    target_boundary_buffered <- st_buffer(target_boundary_filtered, dist = -buffer_dist_to_correct_by_meters)

    if (nrow(target_boundary_buffered) > 0) {
      ## Find nearest point location along the correct (buffered) boundary line that the incorrect offset point is closest to
      ## note that st_nearest_points() returns a LINESTRING that connects two points
      ##    so st_cast helps us get the point location of the second point in that linestring
      ##    - st_cast(nearest_line, "POINT")[1] gives you the original point from offset_corrections[i, ].
      ##    - st_cast(nearest_line, "POINT")[2] gives you the nearest point within buffered sf_boundary
      nearest_line <- st_nearest_points(offset_data[i, ], target_boundary_buffered) ## output is a LINESTRING
      nearest_point <- st_cast(nearest_line, "POINT")[2] ## output is a POINT

      ## Replace geometry with corrected offset (now within correct boundary)
      st_geometry(offset_data[i, ]) <- nearest_point
    }
  }
  return(offset_data)
}
