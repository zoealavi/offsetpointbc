# FUNCTION: Average Distance Between People in each Boundary --------------
#' @title ave_dist_btw_ppl
#'
#' @description
#' Average Distance between People in Each Boundary Polygon
#'
#' Used in offset_points_within_boundary(); calculates polygon area, population density, and min/max average distance values to offset by
#'
#' @keywords internal
#'
#' @param sf_boundary sf boundary with a column containing population data
#' @param total_pop_col name of column containing population data
#'
#' @return returns an sf boundary object with area, population density, and min/max average distance to offset by
#'
#' @examples
#' \dontrun{
#'   offset_points_within_boundary(postal_code, bcmaps::health_chsa, "cmnty_hlth_serv_area_code", "chsa", "sf_boundary_total_pop_col")
#'   }
#'
#' @export
#'
#' @importFrom sf st_area
#' @importFrom dplyr %>% mutate
ave_dist_btw_ppl <- function(sf_boundary,
                             total_pop_col){

  df <- sf_boundary %>%
    mutate(polygon_area = sf::st_area(geometry)) %>%
    mutate(pop_density = .[[total_pop_col]] / .$polygon_area) %>%
    mutate(min_ave_dist = as.numeric((1 * sqrt(1/pop_density))) + 50) %>% ## buffering by 50m ensures a minimum of 50m offset within calculation
    mutate(max_ave_dist = as.numeric((3 * sqrt(1/pop_density))) + 50) ## buffering by 50m ensure a minimum of 50m offset within calculation

}
