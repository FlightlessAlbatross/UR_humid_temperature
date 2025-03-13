library(sf)
library(data.table)
library(lubridate)

add_reference_data <- function(data, reference_data_path){
  if (!inherits(data, "sf")) {
    stop("Input must be an sf")
  }
  
  if (!inherits(reference_data_path, "character")) {
    stop("reference_data_path must be an character string")
  }

  
  all_reference_data <- data.table(readRDS(reference_data_path))
  
  stopifnot(all(names(all_reference_data) == c("time", "temperature", "relative_humidity")))
  
  setnames(all_reference_data, c('temperature', 'relative_humidity'), c('temp_reference', 'humi_reference'))
  
  # Ensure proper datetime format
  all_reference_data[, time := as.POSIXct(time, tz = "CET")]
  # setnames(all_reference_data, )
  
  observations <- data.table(data)
  
  # Set keys for fast merging
  setkey(observations, time)
  setkey(all_reference_data, time)
  
  # Merge using rolling join to get the nearest reference temperature
  observations <- all_reference_data[observations, roll = "nearest", on = c("time")]
  
  observations[ , temp_deviation := temp_value - temp_reference, ]
  observations[ , humi_deviation := humi_value - humi_reference, ]
  
  names(observations)
  output <- data.frame(observations[,.(temp_X.iot.id, humi_X.iot.id, discomfort_X.iot.id, device_id,
                                          time,
                                          temp_value, humi_value, discomfort,
                                          temp_reference, humi_reference, 
                                          temp_deviation, humi_deviation, 
                                          gps_quality, geometry)])
  
  output <- st_as_sf(output, sf_column_name = 'geometry')
  return(output)
  }
