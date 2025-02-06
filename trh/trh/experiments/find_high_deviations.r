library(sf)
library(data.table)
library(lubridate)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_trips.geojson"
observations <- data.table(st_read(trh_utrecht))


# add the trips
observations <- add_trips(observations)


library(mgcv)
temperature <- observations[type == 'temperature']
ggplot(temperature, aes(x = as.ITime(time), y = value_delta)) +
  geom_point(alpha = 0.1) + 
  scale_x_continuous(name = '', breaks = seq(0, 86400, by = 21600),
   labels = function(x) strftime(as.POSIXct(x, origin = "1970-01-01", tz = "UTC"), format = "%H:%M:%S")) + 
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cc"), se = FALSE) +
  theme_minimal()
hist(temperature$value_delta)




ggplot(temperature, aes(x = as.ITime(time), y = value_delta)) +
  geom_point(alpha = 0.1) + 
  geom_path(aes(group = trip_id), alpha = 0.1) + 
  scale_x_continuous(name = '', breaks = seq(0, 86400, by = 10800),
   labels = function(x) strftime(as.POSIXct(x, origin = "1970-01-01", tz = "UTC"), format = "%H:%M:%S")) + 
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cc"), se = FALSE) +
  theme_minimal()

# find the interesting trip at night where the temperature goes up a lot
special <- temperature[value_delta > 18 & hour(time) >= 22] 
plot(special$value)

special <-temperature[trip_id == names(table(special$trip_id))[1]]
ggplot(special , aes(x = as.ITime(time), y = value_delta)) +
  geom_point() + 
  geom_path(aes(group = trip_id), alpha = 0.1) + 
  scale_x_continuous(name = '', breaks = seq(0, 86400, by = 10800),
   labels = function(x) strftime(as.POSIXct(x, origin = "1970-01-01", tz = "UTC"), format = "%H:%M:%S")) + 
  geom_smooth() +
  theme_minimal()

ggplot() +
    annotation_map_tile(type = "osm", zoom = 15) +  # Add OSM tiles as background
    geom_sf(data = st_as_sf(special), aes(color = time, shape = value >= 30 ), size = 5) +  # Add points
    theme_minimal() +
    theme(axis.title = element_blank(),
          axis.ticks = element_blank(),
      legend.position = "right",
      panel.grid = element_blank()
      ) +
    labs( )

# or maybe find trips with high temp differentials in general. 


hot_spots <- temperature[value_delta > 15]

table(hot_spots$device_id)


cold_spots <- temperature[value_delta < 0]
table(cold_spots$value_delta)

range(hot_spots$resultTime)

dim(hot_spots)
dim(cold_spots)

plot_points_static(hot_spots, color_column = 'time')
plot_points_static(cold_spots, color_column = 'time')
