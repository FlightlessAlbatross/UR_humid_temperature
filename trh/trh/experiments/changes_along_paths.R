# Here we look for value changes in temperature and humidit
library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")


speed_path <- '../data/cleaned/trh/temperature_GPS_speed.geojson'

observations <- st_read(speed_path, quiet = T)

observations [,value_diff := c(NA, diff(value)), .(trip_id)]

outlier_threshold_speed <- 20
observations[ , trip_with_outlier := any(speed > outlier_threshold_speed, na.rm = T) , .(trip_id)]

has_outlier <- observations[trip_with_outlier == TRUE]
has_no_outlier <- observations[trip_with_outlier == FALSE]


# lets plot some nice trips
has_no_outlier[ , .N , .(trip_id)][order(N, decreasing = T)][1:20]


forplot <- observations[observations$trip_id == 6000009, .(temperature = value, value_diff, time, geometry)]
plot_path_static(forplot, color_column = 'value_diff')
plot_temperature(forplot)


forplot <- observations[observations$trip_id == 300487, .(temperature = value, temperature_diff =  value_diff, time, geometry)]
plot_path_static(forplot, color_column = 'temperature')/
plot_temperature(forplot) + plot_layout(widths = c(4,1))

plot_background_static(forplot, color_column = 'temperature_diff') +
  scale_colour_steps2(low = 'blue', mid = 'grey', high = 'red')
