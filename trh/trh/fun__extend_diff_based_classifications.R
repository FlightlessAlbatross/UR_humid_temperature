library(data.table)
# this function extends NAs at the start and end of trips with the first nonNA. 

extend_jumpy_classification <- function(dt){
  
  setDT(dt)
  
  # Fill NA at start with next available value
  dt[, gps_outlier_numeric := nafill(as.numeric(factor(gps_outlier, levels = c('jumpy', 'line'))), type = "locf"), trip_id]  # Fill forward
  dt[, gps_outlier_numeric := nafill(gps_outlier_numeric, type = "nocb"), trip_id]  # Fill backward
  dt[, gps_outlier         := as.character(factor(gps_outlier_numeric, levels = c(1,2), labels = c('jumpy', 'line')))]
  dt[ ,gps_outlier_numeric := NULL , ]
  
  data <- as.data.frame(dt)
  data <- st_set_geometry(data, data$geometry)
  
  return (data)
}
