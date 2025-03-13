

# find spatial outliers
library(sf)
library(data.table)
library(lubridate)
library(dplyr)
library(glue)

# Load functions
source("./trh/trh/fun__calculate_angle.R")


speed_dist_angles <- function(data) {
  if (!inherits(data, "sf")) {
    stop("Input must be an sf")
  }
  
  
  stopifnot(st_crs(data)$epsg == 3035)
  
  setDT(data)
  
  calculate_distance_lag <- function(geometry, lead = 1) {
    n <- length(geometry)
    if (n < lead + 1) {
      return (as.numeric(rep(NA, n))) # TODO set NA to numeric
    }
    
    # Drop the start and beginning of the series
    distances <- as.numeric(st_distance(geometry[-((n + 1 - lead):n)], geometry[-(1:lead)], by_element = T))
    
    output <- c(distances, as.numeric(rep(NA, lead)))
    
    if (!'double' %in% class(output)) {
      glue("The distances should be numeric, but they are of class: {class(output)}")
      glue("This is how it looks like: {output}")
      output <- as.double(output)
    }
    
    return(output)
    
  }
  
  # 2 point statistics
  data[, dist :=   calculate_distance_lag(geometry), by = trip_id]
  
  obs_pre_filter <- ncol(data)
  # drop 0 distance observations as it makes calculating angles impossible.
  data <- data[dist > 0]
  
  obs_post_filter <- ncol(data)
  
  glue("{obs_post_filter - obs_pre_filter} Observations had 0 distance --> filtered out.")
  if ((obs_post_filter - obs_pre_filter) > 0) {
    data[, dist :=   calculate_distance_lag(geometry), by = trip_id]
  }
  
  data[, time_diff := data.table::shift(time, type = "lead") - time, by = .(device_id, trip_id)]
  data[, time_diff := as.numeric(time_diff)]
  data[, speed := 3.6 *  dist / time_diff]
  
  
  # 3point statistics
  # calculate angles between 3 points. This helps identifying noisy GPS.
  data[, angle := angle_between_points_sf(geometry), , .(trip_id)]
  
  # calculate the walking distance on these angles
  data[, angle_walking_length := dist + data.table::shift(dist, type = 'lag')  , .(trip_id)]
  
  #calculate air distance
  # this function on its own calculates the distance to 2 obs ahead.
  # we will want to shift it so we have the angle distance.
  data[, dist_2ahead   :=   calculate_distance_lag(geometry, lead = 2), by = trip_id]
  data[, opposite_angle_length := data.table::shift(dist_2ahead, type = 'lag'), ]
  data[, dist_2ahead := NULL, by = trip_id]
  
  output <- data.frame(data)[, c(
    "temp_X.iot.id",
    "humi_X.iot.id",
    "discomfort_X.iot.id",
    "device_id",
    "trip_id",
    "trip_index",
    "time",
    "temp_value",
    "humi_value",
    "discomfort",
    "temp_deviation",
    "humi_deviation",
    "dist",
    "time_diff",
    "speed",
    "angle",
    "angle_walking_length",
    "opposite_angle_length",
    "gps_quality",
    "geometry"
  )]
  
  # Convert geometries back to `sf` format
  output <- st_as_sf(output, sf_column_name = "geometry")
  
  stopifnot(nrow(output) > 0)
  
  if (!inherits(output, "sf")) {
    stop("Input must be an sf")
  }
  
  return(output)
}