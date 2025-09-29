# FUNCTION: Offset Points within Boundary ---------------------------------
## Handles the entire offsetting procedure. Depends on other functions in package to execute.

#' @title offset_points_within_boundary
#'
#' @description
#' Offsets point data to maintain confidentiality.
#' Designed for BC data; default crs output is 3005 (NAD 1983 / BC Albers) but can input other meter based crs like 26910 (NAD83 / UTM zone 10).
#' Acknowledgement that BCCDC provided resources and offsetting (geomasking) methodology.
#'
#' Offsetting methodology:
#'
#'     x offset formula: x' = x0 + RandDist * cos(RandAngle)
#'
#'     y offset formula: y' = y0 + RandDist * sin(RandAngle)
#'
#'
#' Key Background:
#'
#' To offset points, you must have an sf point object in a meters based x/y crs good for BC data such as crs 3005 or 26910.
#'
#' You also need an sf polygon object to act as a boundary and ensure offset points remain within the area of interest (for example, bcmaps::health_chsa).
#'
#' IMPORTANT: if possible, ensure this polygon layer contains a column with total population within each boundary (ex PEOPLE data).
#'
#' Offsetting is most appropriately done when using the average distance between people within a given area; this is estimated by the square root of the inverse of population density.
#' From this, we generate a minimum offset (1 to 2 times the average distance, 1 is used in this function) and a maximum offset (3 to 5 times the average distance, 3 is used in this function)
#'
#' During data preparation before using function, consider excluding cases in low population areas.
#'
#' @param sf_point_data a point sf object that requires offsetting
#' @param sf_boundary a polygon sf object required to constrain offsetting within their original boundary
#' @param sf_boundary_id_col id column from polygon sf object used to track join to point sf object
#' @param sf_boundary_id_col_new_name if desired, customize output column name of id column from polygon sf object
#' @param sf_boundary_total_pop_col if included in polygon sf object (highly encouraged), input column name containing total population, default is NULL
#' @param crs_code default is 3005 (NAD83 / BC Albers); any meter based crs for x/y (for BC) will work like 26910 (NAD83 / UTM zone 10)
#' @param buffer_dist_to_correct_by_meters distance to buffer polygon boundaries towards the inside ensuring offsetting remains within original polygon
#' @param rand_dist_min min value for random distance range to be sampled if population data not provided
#' @param rand_dist_max max value for random distance range to be sampled if population data not provided
#' @param rand_angle_min min value for random angle range to be sampled if population data not provided
#' @param rand_angle_max max value for random angle range to be sampled if population data not provided
#'
#' @return Returns sf point object where geometry of points have been offset from original input.
#'
#' The sf object will contain several new columns providing an idea as to how the offsetting occurred, including: the original x/y coordinates, the offset x/y coordinates; the original boundaryid, offset boundary id and the corrected boundaryid; and the final geometry column uses the corrected x/y coordinates.
#'
#' Corrected x/y coordinates ensures any points that got offset beyond their original polygon boundary line (ex placed in water or a neighbouring boundary) are nudged back into their original boundary.
#' Also prints a summary in console.
#'
#' @examples
#' \dontrun{
#'   offset_points_within_boundary(postal_code, bcmaps::health_chsa, "cmnty_hlth_serv_area_code", "chsa")
#'   }
#'
#' @export
#'
#' @importFrom sf st_join st_within
#' @importFrom dplyr %>% select
offset_points_within_boundary <- function(sf_point_data,
                                          sf_boundary,
                                          sf_boundary_id_col,
                                          sf_boundary_id_col_new_name = "boundaryid",
                                          sf_boundary_total_pop_col = NULL,
                                          crs_code = 3005,
                                          buffer_dist_to_correct_by_meters = 5,
                                          rand_dist_min = 50,
                                          rand_dist_max = 200,
                                          rand_angle_min = 1,
                                          rand_angle_max = 360
){

  ## STEP 1.A: transform sf object to crs 3005
  point_data <- transform_to_crs(sf_point_data,
                                 desired_crs_code = crs_code)

  boundary_data <- transform_to_crs(sf_boundary,
                                    desired_crs_code = crs_code)

  ## confirm the inputted crs is a meter based x/y unit; if not stop function and print error
  if(get_crs_cs_units(point_data) != "metre"){

    stop("
    The input for crs_code is not a meters based unit for x/y.
    Suggested crs code inputs are 3005 (NAD83 / BC Albers) or 26910 (NAD83 / UTM zone 10).
    Reminder to use BC data only with this function.
         ")

  } else {

    ## STEP 1.B: check if a population column was inputted;
    ##    if so, we need to derive min/max average distance between population for random distance input in offset
    if(!is.null(sf_boundary_total_pop_col)) {

      ## determine the population density and average distance of people per boundary
      boundary_data <- boundary_data %>%
        ave_dist_btw_ppl(.,
                         total_pop_col = sf_boundary_total_pop_col)

      ## assign min and max average distance to be offset by into point data
      point_data <- point_data %>%
        st_join(.,
                boundary_data %>%
                  select(min_ave_dist,
                         max_ave_dist),
                join = st_within)

      ## assign the rand_dist_min/max values to average distance instead of defaults
      rand_dist_min <- point_data$min_ave_dist
      rand_dist_max <- point_data$max_ave_dist

    }

    ## STEP 2: identify which polygon boundaries point data falls into
    joined_data <- sf_point_within_boundary(sf_point_data = point_data,
                                            sf_boundary_data = boundary_data,
                                            sf_boundary_id_col = sf_boundary_id_col,
                                            sf_boundary_id_col_new_name = paste0(sf_boundary_id_col_new_name, "_original")
    )

    ## STEP 3: generate offset x/y coordinates
    offset_data <- offset_point(sf_data_to_offset = joined_data,
                                crs_code = crs_code,
                                rand_dist_min = rand_dist_min,
                                rand_dist_max = rand_dist_max,
                                rand_angle_min = rand_angle_min,
                                rand_angle_max = rand_angle_max
    )

    # STEP 4: identify polygon boundaries the new offset points fall into
    #    Note: used to determine if any are outside their original boundary and should be corrected
    offset_data_joined <- sf_point_within_boundary(sf_point_data = offset_data,
                                                   sf_boundary_data = boundary_data,
                                                   sf_boundary_id_col = sf_boundary_id_col,
                                                   sf_boundary_id_col_new_name = paste0(sf_boundary_id_col_new_name, "_offset")
    )

    ## STEP 5: correct any offset coordinates that are now outside their original polygon boundary
    offset_data_corrected <- offset_corrections(offset_data = offset_data_joined,
                                                offset_boundary_id_col_name_original = paste0(sf_boundary_id_col_new_name, "_original"),
                                                offset_boundary_id_col_name_offset = paste0(sf_boundary_id_col_new_name, "_offset"),
                                                sf_boundary = boundary_data,
                                                sf_boundary_id_col = sf_boundary_id_col,
                                                buffer_dist_to_correct_by_meters = buffer_dist_to_correct_by_meters
    )

    ## STEP 6: confirm corrected coordinates have resulted in correct boundary placement
    offset_active_cases_confirmed <- sf_point_within_boundary(sf_point_data = offset_data_corrected,
                                                              sf_boundary_data = boundary_data,
                                                              sf_boundary_id_col = sf_boundary_id_col,
                                                              sf_boundary_id_col_new_name = paste0(sf_boundary_id_col_new_name, "_corrected")
    )

    ## STEP 7: provide summary of results in console for end user to review
    summary_offset_result <- summary_offset_corrections(offset_active_cases_confirmed,
                                                        sf_boundary_id_col_new_name = sf_boundary_id_col_new_name)



    return(summary_offset_result)
  }

}
