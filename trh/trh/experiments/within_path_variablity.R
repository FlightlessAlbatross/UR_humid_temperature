library(data.table)
library(patchwork)
library(glue)
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")


index_drop <- with(data, 
                   gps_outlier == 'jumpy' &  !is.na(gps_outlier)  | 
                   distance_building == 0  | 
                   distance_water == 0 )

outliers <- data[index_drop,]
trh      <- data[!index_drop,]

# st_write(outliers, './data/temp/outliers_filtered_angle_dist.geojson')
# st_write(trh     , './data/temp/trh_filtered_angle_dist.geojson')

get_short_trip_ids <- function(trh, cutoff_length = 3) {
  short_trip_ids <- table(trh$trip_id) < cutoff_length
  short_trip_ids <- names(short_trip_ids) [short_trip_ids]
  return(as.numeric(short_trip_ids))
}


trh <- trh[!trh$trip_id %in% get_short_trip_ids(trh, 10), ]


# Look for temperature changes within a path. 
# Standard deviation could be a start, but we want to find smooth changes, probably?

setDT(trh)

variability <- trh[
  , .SD[trip_index > 3 & trip_index < (.N - 3), .(temp_sd = sd(temp_value), humi_sd = sd(humi_value))]
  , by = trip_id
][order(humi_sd, decreasing = TRUE)]




double_plot <- function(d){
  
  d$humidity <- d$humi_value
  d$temperature <- d$temp_value
  
  (layout_top <- (plot_humidity(d) +
                    ggplot(d, aes(x = temperature, y = humidity, color = time)) + geom_point() + theme_minimal() +
                    plot_temperature(d)))
  
  (layout_bottom <- (plot_path_static(d, color_column = 'humidity') + 
                       plot_path_static(d, color_column = 'time') + 
                       plot_path_static(d, color_column = 'temperature')))
  
  (layout_top / layout_bottom) + plot_layout(heights = c(1, 2)) + # Top row is 1 unit, bottom row is 2 units
  plot_annotation(
    caption = glue('trip_id: {unique(d$trip_id)}')
  )
}



# it would be cool to still display the points we removed. Maybe in light grey. 

i <- 15

d <- trh[trip_id == variability$trip_id[i]]
d$temp_X.iot.id[1]
double_plot(d)

ggsave(filename = glue("./markdown/double_map_{d$temp_X.iot.id[1]}.png"))

d2 <- data[data$trip_id ==6200004,]
d2$temp_X.iot.id[1]
double_plot(d2)
ggsave(filename = glue("./markdown/green_julianapark_double_map_{d2$temp_X.iot.id[1]}.png"))

# Big timejump
"20ca8c8c-3c60-11ef-8772-df518b28030f"


green_effect            <- c("17ee0e0e-4ddb-11ef-9c4c-efa23cd0a080", "20ca8c8c-3c60-11ef-8772-df518b28030f", 
                             "b27cb644-45d6-11ef-9f72-4b8fa5353146", "59fa7fd0-4e76-11ef-9c4c-07e26aa0eb66", 
                             "61d866fa-4812-11ef-ab2f-eb6d70269eee") # we do have 
gradual                 <- c(2900001, 6100002, 1500003)
ends_effects             <- c("75bb4922-5978-11ef-8f50-cfdea75cb1f2")
interesting_trip_ids    <- c(5000011, 100003, 3700011, 3700015, 1500003)
indoor_trip_ids_maybe   <- c(100003, 1400011)
outliers_still          <- c("676685b2-46ae-11ef-9f72-876eb1177ce2", 4200023)
sudden_drop_and_recover <- c("20ca8c8c-3c60-11ef-8772-df518b28030f",
                             "676685b2-46ae-11ef-9f72-876eb1177ce2",
                             "7f78aa3a-6b8a-11ef-9769-4bc8f1e8814a", 
                             "62209ba8-4e95-11ef-9c4c-8b780afbe07f")
too_fast <- "20ca8c8c-3c60-11ef-8772-df518b28030f" # the speed changes too drastically.


d <- trh[trip_id == 5600012 ]
double_plot(d)



# Julianpark
point <- st_sfc(st_point(c(3984728, 3233137)), crs = 3035)

# Create a 1000m buffer
circle_around_julianpark <- st_buffer(point, dist = 200)
julianpark <- data[sapply(st_intersects(data$geometry, circle_around_julianpark), length) >0 ,]
julianpark_trips <- data[data$trip_id %in% unique(julianpark$trip_id), ]

plot_points_static(julianpark, 'temp_deviation')

plot_points_static(julianpark_trips, 'temp_deviation')

unique(julianpark$trip_id)
d <- data[data$trip_id == 6200004    ,]
double_plot(d)



data$trip_id[data$temp_X.iot.id == "b27cb644-45d6-11ef-9f72-4b8fa5353146"]
