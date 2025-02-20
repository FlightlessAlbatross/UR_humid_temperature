# Load required libraries
library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load observations
# trh_utrecht <- "./data/cleaned/trh/utrecht_observations.geojson"
# observations_raw <- data.table(st_read(trh_utrecht))

merge_temperature_and_humidity <- function(data) {
  if (!inherits(data, "sf")) {
    stop("Input must be an sf")
  }
  
  setDT(data)
  setnames(data, 'resultTime',  'time')
  # add coordinates, since we can match on them. There are perfect geometry matches. 
  data[, c('x', 'y') := as.data.table(st_coordinates(geometry)), ]
  
  
  # Split by type
  trh <- split(data, data$type)
  
  # Select relevant columns for each dataset. Keep geometry for one of them so it is present in the final join.
  trh$thermal_discomfort <- trh$thermal_discomfort[, .(button_X.iot.id = X.iot.id, device_id, time, x, y)]
  
  trh$temperature <- trh$temperature[, .(device_id, time, value, X.iot.id, gps_quality, x,y, geometry)]
  setnames(trh$temperature, c('value', 'X.iot.id'), paste0('temp_', c('value', 'X.iot.id')))
  
  trh$relative_humidity <- trh$relative_humidity[, .(device_id, time, value, X.iot.id, x, y)]
  setnames(trh$relative_humidity, c('value', 'X.iot.id'), paste0('humi_', c('value', 'X.iot.id')))
  
  trh$relative_humidity[, humi_time  := time , ] # add a copy of the time column so it stays when we use it to join
  
  # Merge Temperature and Humidity using nearest time match
  # this loses 50 obervations. Not clear why
  merged_trh <- trh$temperature[trh$relative_humidity, on = c("device_id", "time", "x", "y")]
  
  button <- merged_trh[trh$thermal_discomfort, on = c("device_id", "time"), roll = "nearest", ]
  
  # add the button presses as a column
  merged_trh$discomfort_X.iot.id <- button$button_X.iot.id[match(merged_trh$temp_X.iot.id, button$temp_X.iot.id)]
  merged_trh$discomfort <- !is.na(merged_trh$discomfort)
  
  check_match_closesness <- function() {
    # Compute time difference (how close matches are in time)
    merged_trh[, time_diff := as.numeric(abs(difftime(time, humi_time, units = "secs")))]
    
    quantile(merged_trh$time_diff)
    
    rowwise_equals <- mapply(st_equals,
                             merged_trh$geometry,
                             merged_trh$i.geometry,
                             SIMPLIFY = TRUE)
    
    table(sapply(rowwise_equals, length))
    which (sapply(rowwise_equals, length) == 0)
    
    merged_trh[2935:2936, ]
    
    
    all(unlist(rowwise_equals) == 1)
    
    # Compute spatial difference (how close matches are in space)
    merged_trh[, space_diff := st_distance(geometry, i.geometry, by_element = TRUE)]
    
    
  }
  
  # Retain relevant columns
  merged_trh <- data.frame(merged_trh[, .(device_id,
                                          time,
                                          temp_value,
                                          temp_X.iot.id,
                                          humi_value,
                                          humi_X.iot.id,
                                          discomfort,
                                          discomfort_X.iot.id,
                                          gps_quality,
                                          geometry)])
  
  # Convert geometries back to `sf` format
  merged_trh <- st_as_sf(merged_trh, sf_column_name = "geometry")
  
  if (!inherits(merged_trh, "sf")) {
    stop("Output must be an sf")
  }
  
  return(merged_trh)
}
