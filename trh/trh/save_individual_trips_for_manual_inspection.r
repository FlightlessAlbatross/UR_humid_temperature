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


observations <- st_read( './data/cleaned/trh/temperature_GPS_speed.geojson')

odd_device <- observations[observations$device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb',]
observations <- observations[observations$device_id != '88901ccb-88c0-435a-af7f-fb37fc890bcb',]


for (trip_id in unique(observations$trip_id)) {
  data <- observations[observations$trip_id == trip_id,]
  
  if (nrow(data) < 5) {
    next
  }
  
  path_line   <- glue("./data/cleaned/trh/trips/trip_{trip_id}_linesegment.geojson")
  path_points <- glue("./data/cleaned/trh/trips/trip_{trip_id}_points.geojson")
  
  keep.cols <- c('X.iot.id', 'time' , 'gps_quality_cat', 'speed', 'angle' , 'trip_id','geometry')
  
  data_line <- data[1,]
  data_line$geometry <- st_combine(data) %>% st_cast("LINESTRING")

  st_write(data[,keep.cols], path_points)
  st_write(data_line[,keep.cols], path_line)
  
  }



