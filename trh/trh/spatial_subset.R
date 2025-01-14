library(sf)

data_path <- "./data/processed/utrecht.geojson"
output_path <- "./data/cleaned/utrecht.geojson"
polygon_path = "./data/reference/LAU_utrecht_4326.geojson"

utrecht <- st_read(polygon_path)

data_raw <- st_read(data_path)
data <- data_raw
names(data)[1] <- "IOT_id"

data <- data [order(data$device_id, data$phenomenonTime),]

utrecht_points <- st_intersection(data, utrecht)

utrecht_points$geoloc_url <- NULL

st_write(utrecht_points, output_path)
