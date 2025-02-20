# That one device

# are devices biased?

library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_observations.geojson"

observations_raw <- (st_read(trh_utrecht))
one_device <- observations_raw[observations_raw$device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb',]

plot_points_static(one_device[one_device$type == 'temperature', ], color_column = 'value')

plot_points_static(one_device[one_device$type == 'relative_humidity', ], color_column = 'value')


# Check the api response

path <- './data/raw/api_responses/observations_by_sensor_utrecht.jsonl'
library(jsonlite)
lines <- readLines(path)

geojson_list <- lapply(lines, fromJSON)

device_ids <- sapply(geojson_list, function(x) x[[1]] )
which(device_ids == '88901ccb-88c0-435a-af7f-fb37fc890bcb')
geojson_list[[217]]

number_obs <- sapply(geojson_list, function(x) ifelse( class(x[[2]]) == 'data.frame', nrow(x[[2]]), NA   )  )

data.frame(device_ids, number_obs)

