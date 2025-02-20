# add the trips 
library(data.table)
library(lubridate)

add_trips <- function(data, trip_lenght_seconds = 5*60, time_column = 'time'){

  if (!inherits(data, "sf")) {
    stop("Input must be an sf")
  }
  
  if (! 'device_id' %in% names(data)){
    stop("data must contain the column device_id")
  }
  
  setDT(data)
  data <- data[order(device_id, time)]

  threshold <- trip_lenght_seconds
  
  if ('type' %in% names(data)) {
    data [, time_diff     := c(NA, make_difftime(diff(get(time_column)), units = "seconds")), .(type, device_id)]
  } else {
    data [, time_diff     := c(NA, make_difftime(diff(get(time_column)), units = "seconds")), .(device_id)]
  }
  
  
  data[, trip_id := .GRP * 100000 + cumsum(is.na(time_diff) | time_diff > threshold), by = .(device_id)]
  data$time_diff <- NULL
  data[ , trip_index := 1:.N ,.(trip_id)]
  
  output <- data.frame(data)
  
  # Convert geometries back to `sf` format
  output <- st_as_sf(output, sf_column_name = "geometry")
  
  return(output)
}
