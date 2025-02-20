# look at beginning of trips / clusters

# THe accuracy 
# https://www.gps-forums.com/threads/estimating-accuracy-from-raw-nmea-data.46273/

library(sf)
library(data.table)
library(lubridate)
library(dplyr)
library(ggplot2)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_temperature.geojson"
trh_rosevelt <- "./data/cleaned/trh/rooseveltlaan.geojson"

roosevelt <- st_read(trh_rosevelt)

utrecht <- st_read(trh_utrecht)
utrecht <- st_as_sf( add_trips(data.table(utrecht)))


dt <- data.table(st_drop_geometry(utrecht), st_coordinates(utrecht))

# whithin each trip is the accuracy higher at the end then the beginning of the trip. 
dt[ , trip_index := 1:.N , .(trip_id)]
dt[ , trip_time := time-time[1] , .(trip_id)]


plot(dt$trip_time, dt$trip_index)
summary(lm(as.numeric(trip_time) ~ trip_index,dt))
# TODO: look at this plot  for different cutoffs of trips. 


plot(dt$trip_index, dt$gps_quality)
plot(dt$trip_time, dt$gps_quality)

# identif trips with issues of low accuracy
trips_with_bad_gps <- dt[trip_id %in% dt[ gps_quality > 2, unique(trip_id)]]


ggplot(trips_with_bad_gps, aes(x = trip_index, y = gps_quality, group = trip_id)) +
  geom_point() + geom_path()

trip_id_in <-  unique(trips_with_bad_gps$trip_id)[5]

trip_id_in <- 200001 

library(patchwork)
for (trip_id_in in unique(trips_with_bad_gps$trip_id)){
  
lineplot <- ggplot(trips_with_bad_gps[trip_id == trip_id_in], aes(x = trip_index, y = gps_quality, group = trip_id)) +
  geom_point() + geom_path() + theme_minimal()

mapplot <- plot_path_static(observations_raw[utrecht$trip_id == trip_id_in, ], color_column = 'gps_quality') +
  geom_sf(data = observations_raw[utrecht$trip_id == trip_id_in, ][1,], stroke = 2, size = 10, shape = 2)

 print(lineplot + mapplot)
 Sys.sleep(5)
  }
trips_with_bad_gps


ggplot(trips_with_bad_gps, aes(x = trip_time, y = gps_quality, group = trip_id)) + geom_point()


# plot the first obs of each trip of each device.
# only look at paths that have more than N points
# only roosevelt 

first_N <- 3
start_trips <- dt[ trip_index <= first_N & trip_id %in% dt[ .N > first_N, unique(trip_id)] & 
                     X.iot.id %in% roosevelt$X.iot.id,]

match(fist_n$X.iot.id, dt$X.iot.id)
match(fist_n$X.iot.id, dt$X.iot.id)

first_n <- utrecht[utrecht$X.iot.id  %in% start_trips$X.iot.id, ]
first_n <- cbind(first_n,  dt[ match(first_n$X.iot.id, dt$X.iot.id),  .(trip_index, trip_time)]   )

table(first_n$device_id)
plot_points_static(first_n, color_column = 'trip_index')
# 

