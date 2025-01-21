library(sf)
library(data.table)

trh_utrecht <-  "./data/cleaned/trh/utrecht.geojson"

observations <- data.table(st_read(trh_utrecht))
observations


observations[ , obs_per_minute := .N  , .(device_id, type, year(phenomenonTime), yday(phenomenonTime), hour(phenomenonTime), minute(phenomenonTime))]
observations[ , instance := .GRP , .(device_id, type, year(phenomenonTime), yday(phenomenonTime), hour(phenomenonTime), minute(phenomenonTime))]

high_temporal_frequency <- observations[obs_per_minute > 60]
dim(high_temporal_frequency)
# View(testcase)

# if we were to group them all how many observations are left?
library(sf)

averaged <- observations[ , .(
  obs_per_minute = .N,
  avg_value = mean(value),
  sd_value = sd(value),
  max_distance = max(as.vector(st_distance(geometry))), 
  gps_max_quality = max(gps_quality), 
  gps_med_quality = median(gps_quality)
), by = .(device_id, instance, type, year(phenomenonTime), yday(phenomenonTime), hour(phenomenonTime), minute(phenomenonTime))]

View(averaged)
averaged <- averaged[order(device_id, yday, hour, minute), , ]

# this device had large spatial distances in one second!
# testcase <- observations[observations$instance == 441,]
# st_write(testcase, './data/temp/bigarea_in_second.geojson')
testcase <- observations[observations$instance == 441,]
st_write(testcase, './data/temp/bigarea_in_second_high_gps_accuracy.geojson', overwrite = T)



# are some devices more prone to oversharing?
observations_by_device_witin_minute <- averaged[,  .(number_obs         = .N,
                                                     average_per_minute = mean(obs_per_minute),
                                                     sd_per_minute      = sd(obs_per_minute)
                                                     ) , .(device_id, type)]
View(observations_by_device_witin_minute)


hist(observations_by_device_witin_minute$number_obs[observations_by_device_witin_minute$type == 'temperature'], breaks = 20, 
     xlab = "Number of minutes with observations by device", freq = TRUE)

hist(observations_by_device_witin_minute$number_obs[observations_by_device_witin_minute$type == 'temperature' &
                                                    observations_by_device_witin_minute$number_obs > 1],
                                                    breaks = 20, 
     xlab = "Number of minutes with observations by device", freq = TRUE)


# this device had an NA for sd ob observations per second. 
testcase <- observations[observations$device_id == "968419c4-fe72-49ae-a757-733e6458707e",]
st_write(testcase, './data/temp/testcase_onesecond.geojson')


# can we find trips?
# define a trip. A string of observations with no larger gap than? 10 minutes?

averaged[type == 'temperature', , .(device_id, type, yday, hour minute)]
