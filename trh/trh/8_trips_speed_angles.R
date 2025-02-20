setwd("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature")

# find spatial outliers
library(sf)
library(data.table)
library(lubridate)
library(dplyr)
library(glue)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")
source("./trh/trh/fun_calculate_angle.R")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_temperature.geojson"
observations_raw <- (st_read(trh_utrecht))

observations <- st_transform(observations_raw, 'EPSG:3035')

setDT(observations)
# Order by time within each device and trip
observations <- observations[order(device_id, time)]


trip_lenght_seconds <- 15*60
observations <- add_trips(observations, trip_lenght_seconds = trip_lenght_seconds)
observations[ , trip_index := 1:.N ,.(trip_id)]

glue("For a trip breaking time of {trip_lenght_seconds/60} minutes, we have {length(unique(observations$trip_id))} trips.")

quantile_of_trips <- function(x , short = 5){
  
  quantile(observations[ , .N , .(trip_id)]$N)
  
}
quantile_of_trips(observations)

calculate_distance_lag <- function(geometry, lead = 1){
  
  n <- length(geometry)
  if(n < lead + 1){
    return (as.numeric(rep(NA, n))) # TODO set NA to numeric
  }
  
  # Drop the start and beginning of the series
  distances <- as.numeric(st_distance(geometry[-((n+1-lead):n)], geometry[-(1:lead)], by_element = T))
  
  output <- c(distances, as.numeric(rep(NA, lead))) 
  
  if (!'double' %in% class(output)){
    
    glue("The distances should be numeric, but they are of class: {class(output)}"  )
    glue("This is how it looks like: {output}")
    output <- as.double(output)
  }
  
  return(output)
  
}

observations <- observations[ , N := .N , .(trip_id)][N > 5,]

# 2 point statistics
observations[, dist :=   calculate_distance_lag(geometry), by = trip_id]
# drop 0 distance observations as it makes calculating angles impossible. 
observations <- observations[dist>0 ]
observations[, dist :=   calculate_distance_lag(geometry), by = trip_id]

observations[, time_diff := shift(time, type = "lead") - time, by = .(device_id, trip_id)]
observations[, time_diff := as.numeric(time_diff)]
observations[, speed := 3.6 *  dist / time_diff]


# 3point statistics
# calculate angles between 3 points. This helps identifying noisy GPS. 
observations[, angle := angle_between_points_sf(geometry), , .(trip_id)]

# calculate the walking distance on these angles
observations[ , angle_walking_length := dist + shift(dist, type = 'lag')  , .(trip_id)]

#calculate air distance 
# this function on its own calculates the distance to 2 obs ahead. 
# we will want to shift it so we have the angle distance. 
observations[, dist_2ahead   :=   calculate_distance_lag(geometry, lead = 2), by = trip_id]
observations[, opposite_angle_length := shift(dist_2ahead, type = 'lag'), ]
observations[, dist_2ahead := NULL, by = trip_id]

observations[ ,gps_quality_cat := cut(gps_quality, c(-99,1,2,5,10,200),
                                      labels = 1:5) , ]

'88901ccb-88c0-435a-af7f-fb37fc890bcb' %in% observations$trip_id
dim(observations)

st_write(st_as_sf(observations), './data/cleaned/trh/temperature_GPS_speed.geojson', delete_dsn = T)
