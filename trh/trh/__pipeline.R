setwd("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature")

library(sf)
options(sf_quiet = TRUE) # Suppresses sf messages

line_length_linter(length = 120L)

data_path <- "./data/processed/trh/utrecht_global.geojson"
output_path <- "./data/processed/trh/utrecht.geojson"

reference_data_path <- "./trh/trh_plotting/data/utrecht_reference.RDS"


utrecht_poly_path <- "./data/reference/LAU_utrecht_4326.geojson"

create_intermediaries <- FALSE


source("./trh/trh/fun__clean_gps.R")
source("./trh/trh/fun__subset_2_polygon.R") #TODO change name 2 -> to
source("./trh/trh/fun__make_trips.r")
source("./trh/trh/fun__merge_temperature_and_humidity.R")
source("./trh/trh/fun__add_reference_data.R")
source("./trh/trh/fun__make_trips.r") # TODO make trips vs add trips names
source("./trh/trh/fun__calculate_angle.R") # this might not be needed here, but only in fun__speed_dist_angles
source("./trh/trh/fun__speed_dist_angles.R")
source("./trh/trh/fun__extend_diff_based_classifications.R")
source("./trh/trh/fun__inside_poly.R")
source("./trh/trh/fun_distance_to_closest_poly.R")
source("./trh/trh/fun_areas_around_points.R")

funky_device_ids <- c("88901ccb-88c0-435a-af7f-fb37fc890bcb")


data <- 
  st_read(data_path)                                                    |>  # Read data
  subset(resultTime < as.POSIXct("2024-10-01 00:00:00", tz = "CET") & 
         resultTime > as.POSIXct("2024-06-30 23:59:59", tz = "CET") & 
         !device_id %in% funky_device_ids)                              |>   # these can probably be repaired
  clean_gps()                                                           |>   # Drop GPS outside of the range of degrees on the globe.
  subset_to_polygon(poly = utrecht_poly_path)                           |>   # subset observations down to utrecht polygon
  merge_temperature_and_humidity()                                      |>   # Temperature and humidity come in separate rows, this matches them together. 
  add_reference_data(reference_data_path = reference_data_path)         |> # HUMI DEVIATION IS WRONG LOOK AT humidity of humi IOD and the one after it: d16a937a-6203-11ef-ab4d-e7efe1dd766b
  add_trips(trip_lenght_seconds = 15*60) |>
  st_transform(crs = "EPSG:3035") |>
  speed_dist_angles() |>
  # After manual labeling we found, that a short opposite angle length is a great indicator for jumpy gps.
  # This can be improved with more manual labeling and a simple tree model
  # we could also (just for exploring) use a RF, and look for uncertain points and see if we want to label them uncertain or in between and feed that back to the simple tree?? is that a good idea?
  mutate(gps_outlier = ifelse(opposite_angle_length < 55, "jumpy", "line")) |>
  mutate(speed_outlier = ifelse(speed > 10, "jumpy", "line")) |>
  extend_jumpy_classification() |> 
  subset(!is.na(gps_outlier))


source("./trh/trh/fun__extract_raster.R")
data <- data|> mutate(sun_exposure_july = extract_raster_values(geometry, raster_path = "./data/processed/shademap/sun_exposure_2024-07-15.tiff"))


data <- data|>
  mutate(distance_grass = distance_to_grass(geometry)) |>
  mutate(distance_building = distance_to_building(geometry))|> 
  mutate(distance_water  = distance_to_water(geometry)) 

osm_gras_polygon          <- read_union_polygon("./data/processed/osm/utrecht_grass.geojson")
osm_building_polygon      <- read_union_polygon("./data/processed/osm/utrecht_buildings.geojson")
osm_water_polygon         <- read_union_polygon("./data/processed/osm/utrecht_water.geojson")

data <- data|>
  mutate(area_gras_10m     = area_around_points(points = geometry, buffer_size = 10, lookup_map = osm_gras_polygon))     |>
  mutate(area_building_10m = area_around_points(points = geometry, buffer_size = 10, lookup_map = osm_building_polygon)) |>
  mutate(area_water_10m    = area_around_points(points = geometry, buffer_size = 10, lookup_map = osm_water_polygon))

data <- data|>
  mutate(area_gras_30m     = area_around_points(points = geometry, buffer_size = 30, lookup_map = osm_gras_polygon))     |>
  mutate(area_building_30m = area_around_points(points = geometry, buffer_size = 30, lookup_map = osm_building_polygon)) |>
  mutate(area_water_30m    = area_around_points(points = geometry, buffer_size = 30, lookup_map = osm_water_polygon))



# Distance to water gets wierdly huge??
st_write(data, "data/temp/qgispipe.geojson", delete_dsn = TRUE, quiet = TRUE)

# need to extend the outliers to the first and last obs. 

 
# To find more outliers I wonder if I should approach it like the tree model. 
# I look at the current leaf nodes and see which ones I like, and which ones I don't. 
# then come up with a variable to split on
# Right now I did split by opposite_angle_length <55


# collapse the jumpy gps into one point
# which one? the center, or the lsat obs?
# or cluster them by device_id?



