# Merge the button presses with the relative humidity and temperature measures
library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Output path
button_path <- './data/cleaned/trh/utrecht_comfort_button.geojson'

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_observations.geojson"
observations_raw <- data.table(st_read(trh_utrecht))

table(observations_raw$type)

trh <- split(observations_raw, observations_raw$type)

trh$thermal_stress <- trh$thermal_stress[,.(X.iot.id, device_id, time, gps_quality, geometry)]

trh$temperature <- trh$temperature[, .(device_id, time, value, X.iot.id)]
names(trh$temperature)[3:4] <- paste0('temp_', names(trh$temperature)[3:4])

trh$relative_humidity <- trh$relative_humidity[, .(device_id, time, value, X.iot.id)]
names(trh$relative_humidity)[3:4] <- paste0('humi_', names(trh$relative_humidity)[3:4])


# Merge Temperature and Humidity
x <- trh$temperature[trh$relative_humidity, on = c("device_id", "time"), roll = "nearest", ]

# then merge this to the button 
button <- x[trh$thermal_stress, on = c("device_id", "time"), roll = "nearest", ]


# now we can match it back using either temp or humid iod. 
x[, button := temp_X.iot.id %in% button$temp_X.iot.id]

st_write(st_as_sf(button), dsn = button_path)
st_write(st_as_sf(button), dsn = button_path)
