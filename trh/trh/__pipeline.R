setwd("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature")

library(sf)

data_path <- "./data/processed/trh/utrecht_global.geojson"
output_path <- "./data/processed/trh/utrecht.geojson"

reference_data_path <- "./trh/trh_plotting/data/utrecht_reference.RDS"


utrecht_poly_path <- "./data/reference/LAU_utrecht_4326.geojson"

create_intermediaries <- FALSE


source("./trh/trh/fun__clean_gps.R")
source("./trh/trh/fun__subset_2_polygon.R")
source("./trh/trh/fun__make_trips.r")
source("./trh/trh/fun__merge_temperature_and_humidity.R")
source("./trh/trh/fun__add_reference_data.R")
source("./trh/trh/fun__make_trips.r")
source("./trh/trh/fun__calculate_angle.R")
source("./trh/trh/fun__speed_dist_angles.R")


funky_device_ids <- c('88901ccb-88c0-435a-af7f-fb37fc890bcb')


data <- 
  st_read(data_path)                                                    |>  # Read data
  subset(resultTime < as.POSIXct("2024-10-01 00:00:00", tz = "CET") & 
         resultTime > as.POSIXct("2024-06-30 23:59:59", tz = "CET") & 
         !device_id %in% funky_device_ids)                              |>   # these can probably be repaired
  clean_gps()                                                           |>  # Drop GPS outside of the range of degrees on the globe.
  subset_to_polygon(poly = utrecht_poly_path)                           |> # subset observations down to utrecht polygon
  merge_temperature_and_humidity()                                      |> # Temperature and humidity come in separate rows, this matches them together. 
  add_reference_data(reference_data_path = reference_data_path)         |>
  add_trips(trip_lenght_seconds = 15*60) |>
  st_transform(crs = 'EPSG:3035') |>
  speed_dist_angles() |>
  # After manual labeling we found, that a short opposite angle length is a great indicator for jumpy gps.
  # This can be improved with more manual labeling and a tree model
  mutate(gps_outlier = ifelse(opposite_angle_length < 55, 'jumpy', 'line'))

# collapse the jumpy gps into one point
# which one? the center, or the lsat obs?
# or cluster them by device_id?



