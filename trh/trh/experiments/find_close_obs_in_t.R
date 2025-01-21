library(sf)
library(data.table)
source("./trh/trh_plotting/plot_points_static.R")
trh_utrecht <-  "./data/cleaned/trh/utrecht.geojson"

observations <- data.table(st_read(trh_utrecht))
observations <- observations[observations$phenomenonTime < "2024-10-01 00:00:00 CET" & 
                             observations$phenomenonTime > "2024-06-30 23:59:59 CET" ]
# hist(observations$phenomenonTime, breaks = 'weeks')




observations[ , obs_per_minute := .N,
             .(device_id, type, year(phenomenonTime),
               yday(phenomenonTime),
               hour(phenomenonTime),
               minute(phenomenonTime))]
observations[ , instance := .GRP,
.(device_id, type, year(phenomenonTime), yday(phenomenonTime), hour(phenomenonTime), minute(phenomenonTime))]

high_temporal_frequency <- observations[obs_per_minute > 60]
dim(high_temporal_frequency)


# if we were to group them all how many observations are left?
library(sf)
library(lubridate)
averaged <- observations[ , .(
  obs_per_minute = .N,
  avg_value = mean(value),
  sd_value = sd(value),
  max_distance = max(as.vector(st_distance(geometry))), 
  gps_max_quality = max(gps_quality), 
  gps_med_quality = median(gps_quality)
), by = .(device_id, instance, type, year(phenomenonTime), yday(phenomenonTime), month(phenomenonTime), day(phenomenonTime), hour(phenomenonTime), minute(phenomenonTime))]

averaged[ , time := ISOdatetime(year = year, month = month, day = day, hour = hour, min = minute, sec = 0) , ]
averaged <- averaged[order(device_id, time), , ]

# this device had large spatial distances in one second!


testcase <- observations[observations$instance == 441,]

plot_points_static(testcase)
st_write(testcase, './data/temp/bigarea_in_second_high_gps_accuracy.geojson', overwrite = T)

testcases_instances <- averaged[averaged$max_distance > 4000]$instance

testcases <- observations[instance %in% testcases_instances]

testcase2 <- testcases[instance == 383]
testcase3 <- testcases[instance == 389]



static_map_filename <- function(dt){
     instance_value <- dt$instance[1]
     device_id <- dt$device_id[1]

     return (paste0("./data/temp/space_time_instance", instance_value, "_", device_id,".png"))
}

testcase[ ,  .(output_file = static_map_filename(.SD) ), by = .(instance), .SDcols = names(testcases)]

testcase[ ,plot_points_static(.SD, output_file = static_map_filename(.SD)) , by = .(instance), .SDcols = names(testcases)]




testcases[type == "temperature" ,plot_points_static(.SD, output_file = static_map_filename(.SD)) , by = .(instance), .SDcols = names(testcases)]

View(testcases)


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
