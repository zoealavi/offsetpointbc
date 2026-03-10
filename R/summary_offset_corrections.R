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

  # Create a frequency table of TRUE vs FALSE
  #summary_table <- table(summary_counts$offset_correction_successful)
  summary_table <- summary_counts %>%
    st_drop_geometry() %>%
    summarize(total = n(),
              .by = offset_boundary_match_original) %>%
    as.data.frame()

  ## print out summaries into console for end user review
  #print(st_crs(summary_counts))

  cat("

  Summary of Offsetting Performance

  Definitions for summary table:
      TRUE: Offset succesful, original boundary id matches final (corrected) offset boundary id
      NA: Offset succesful, but original point data contains x/y coordinates that originated beyond the sf polygon object inputted into sf_boundary.
      FALSE: Potential error/failure in function.
             Try adjusting the 'buffer_dist_to_correct_by_meters' input (in meters) (never do <=0m), otherwise contact author.

  Summary Table:

  "

  )

  print(format(summary_table,
               justify = "right"),
        row.names = FALSE)


  return(summary_counts)


}
