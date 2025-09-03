# FUNCTION: Identify sf point object's crs units; used in offset_points_within_boundary() to confirm a meters based x/y --------
#' @title get_crs_cs_units
#'
#' @description
#' Check crs' cs unit of measure for x/y coordinates
#'
#' Used in function offset_points_within_boundary() to flag if a meters based x/y unit is used or not
#'
#' @keywords internal
#'
#' @param sf_obj sf object to identify crs' units used
#'
#' @return crs unit inputed; when used in offset_points_within_boundary(), if in meters, runs the rest of the function, otherwise returns an error in console
#'
#' @examples
#' \dontrun{
#'   offset_points_within_boundary(postal_code, bcmaps::health_chsa, "cmnty_hlth_serv_area_code", "chsa", crs_code = 3005)
#'   }
#'
#' @export
#'
#' @importFrom sf st_crs
get_crs_cs_units <- function(sf_obj) {

  wkt <- st_crs(sf_obj)$wkt
  if (is.null(wkt)) return(NA)

  # Split WKT into lines
  lines <- strsplit(wkt, "\n")[[1]]

  # Find the start of the CS section
  cs_start <- grep("^\\s*CS\\[", lines)
  if (length(cs_start) == 0) return(NA)

  # Extract lines from CS onward
  cs_lines <- lines[cs_start:length(lines)]

  # Find ANGLEUNIT or LENGTHUNIT lines within CS
  angle_units <- grep("ANGLEUNIT\\[", cs_lines, value = TRUE)
  length_units <- grep("LENGTHUNIT\\[", cs_lines, value = TRUE)

  # Extract unit names
  extract_unit <- function(unit_line) {
    sub('.*\\["([^"]+)".*', '\\1', unit_line)
  }

  units <- c()
  if (length(angle_units) > 0) {
    units <- c(units, sapply(angle_units, extract_unit))
  }
  if (length(length_units) > 0) {
    units <- c(units, sapply(length_units, extract_unit))
  }

  return(unique(units))
}
