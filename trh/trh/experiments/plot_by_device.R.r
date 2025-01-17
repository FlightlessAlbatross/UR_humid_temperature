library(sf)
library(ggplot2)

path_data <- "./data/processed/trh/utrecht.geojson"
source("./trh/trh_plotting/plot_temperature.R")

data_all = st_read(path_data)

temperature <- data_all[data_all$type == "temperature", ]
names(temperature)[4] <- 'temperature'
names(temperature)[2] <- 'time'


all_device_ids <- unique(temperature$device_id)
single_device <- temperature[temperature$device_id ==all_device_ids[4], ]
range(single_device$time)
plot_temperature(single_device)
