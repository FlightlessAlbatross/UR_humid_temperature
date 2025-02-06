# find spatial outliers
library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_temperature.geojson"
observations <- (st_read(trh_utrecht))
observations <- st_transform(observations, 'EPSG:3035')


setDT(observations)
observations <- add_trips(observations, trip_lenght_seconds = 5*60)

# Order by time within each device and trip
observations <- observations[order(device_id, trip_id, time)]

# Compute time difference
observations[, time_diff := shift(time, type = "lead") - time, by = .(device_id, trip_id)]


observations <- observations %>%
  group_by(device_id, trip_id) %>%
  mutate(
    lead = geometry[row_number() + 1],
    dist = st_distance(geometry, lead, by_element = T),
  )

observations$lead <- NULL

setDT(observations)

#shif all the difference based values, such that they measure the distance to the previous obs. 
# this identifies the rows with faulty observations better. 
observations[, c("time_diff", "dist") := lapply(.SD, shift, type = "lag"), .SDcols = c("time_diff", "dist")]
observations[.N, c("time_diff", "dist") := NA]


observations[, speed := 3.6 *  as.numeric(dist) / as.numeric(time_diff)]



quantile(observations$speed[is.finite(observations$speed)], 
    probs = c(0.8, 0.85, 0.9, 0.99))

outlier_threshold_speed <- 50
observations[ , trip_with_outlier := any(speed > outlier_threshold_speed, na.rm = T) , .(trip_id)]

has_outlier <- observations[trip_with_outlier == TRUE]
length(unique(has_outlier$trip_id))
length(unique(has_outlier$device_id))
observations$trip_with_outlier <- NULL

# even speed outliers indicate 
trips_with_outlier <- has_outlier[ , .( speed_bumps =  sum(speed > outlier_threshold_speed, na.rm = T)) , .(trip_id, device_id)]
View(trips_with_outlier)
table(trips_with_outlier$device_id)



# the only 3 trips with outliers that aren't from 88901ccb-88c0-435a-af7f-fb37fc890bcb
 
plot_path_static(observations[trip_id == 3800023], color_column = 'speed')
plot_path_static(observations[trip_id == 2400001], color_column = 'speed')
plot_path_static(observations[trip_id == 1300027], color_column = 'speed')


# this trip has a lot goin gon observations[trip_id == 300024]
plot_path_static(observations[trip_id == 300024], color_column = 'speed')
testcase <- observations[trip_id == 300024]
testcase$device_id


super_bad <- observations[device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb']
