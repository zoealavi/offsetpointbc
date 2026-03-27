# FUNCTION: Summarize Success of Corrected Offsets ------------------------
#' @title summary_offset_corrections
#'
#' @description
#' Summarize Success of Corrected Offset Points
#'
#' Used in offset_points_within_boundary(); summarizes success of corrected offsetting
#'
#' @keywords internal
#'
#' @param corrected_offset_data an offset point sf object that requires adjustments due to offset point falling outside their original boundary polygon
#' @param sf_boundary_id_col_new_name beginning part id col being used to track join (ex: "boundaryid")
#'
#' @return returns an sf point object with a new column flagging rows as TRUE if still in original polygon boundary or FALSE if a mismatch still occurs. Also prints summary in console
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
#' @importFrom sf st_drop_geometry st_crs
#' @importFrom dplyr %>% summarize
summary_offset_corrections <- function(corrected_offset_data,
                                       sf_boundary_id_col_new_name) {

  summary_counts <- corrected_offset_data

  # Create a logical column comparing original vs corrected boundary IDs
  summary_counts$offset_boundary_match_original <- summary_counts[[paste0(sf_boundary_id_col_new_name, "_original")]] ==
    summary_counts[[paste0(sf_boundary_id_col_new_name, "_corrected")]]

  ## need to set up warning to force print if triggered
  old_warn <- getOption("warn")
  options(warn = 1)

  ## confirm the inputted crs is a meter based x/y unit; if not stop function and print error
  if(!any(summary_counts$offset_boundary_match_original)) {

    warning(
      "At least one point was not nudge back within its original boundary. Review FALSE under `offset_boundary_match_original` column.\n",
      "Try adjusting the 'buffer_dist_to_correct_by_meters' input (in meters) (never do <=0m), otherwise contact author.")

  } else {

    cat("
  Offsetting Succesful
  "
    )

  }

  ## reset warning
  options(warn = old_warn)

  return(summary_counts)


}
