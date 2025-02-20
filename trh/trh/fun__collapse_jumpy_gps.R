library(sf)
library(data.table)



collapse_jumpy <- function(data){
  
  
  setDT(data)
  
  # extend the gps_outlier column at the start and the end. 
  data <- extend_outlier(data)
  
  # find jumpy points that are close to each other
  # same trip
  # consecutive
  data[ , jumpy_group := rleid(gps_outlier) , trip_id ]
  
  data[ , max(jumpy_group) , .(trip_id, device_id) ][order(V1, decreasing = T)]
  
  testdata <- data[trip_id == 4300006,]
  testdata$predictions <- predict(angle_model, testdata, type = "class")
  testdata$predictions <- 1*(testdata$predictions == 'jumpy')
  
  # depending if this is at the start, middle or end of a trip, we want to aggregate differently?
  # it is easier to just drop them!!
  # if it is at the beginning, we want to use the last?
  # if it is at the end, we want the first ones
  # or do we want a spatial center?
  
  # we need to choose a point, temperature, 
  
}



extend_outlier <- function(dt){
  
  # Fill NA at start with next available value
  dt[, gps_outlier_numeric := nafill(as.numeric(factor(gps_outlier, levels = c('jumpy', 'line'))), type = "locf"), trip_id]  # Fill forward
  dt[, gps_outlier_numeric := nafill(gps_outlier_numeric, type = "nocb"), trip_id]  # Fill backward
  dt[, gps_outlier := as.character(factor(gps_outlier_numeric, levels = c(1,2), labels = c('jumpy', 'line')))]
  dt[ ,gps_outlier_numeric := NULL , ]
  
  dt
}
