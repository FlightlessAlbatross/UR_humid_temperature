library(sf)

data_path <- "./data/processed/utrecht.geojson"
output_path <- "./data/cleaned/utrecht_global.geojson"

data_raw <- st_read(data_path)

data <- data_raw

names(data)[1] <- "IOT_id"
columns_select <- c("phenomenonTime", "type",
                    "value", "location_quality", "geometry_altitude",
                    "geometry")


data <- data [order(data$device_id, data$phenomenonTime),]


coords <- data.frame(st_coordinates(data$geometry))
# check which coordinates are outside of the WGS ranges.
faulty_gps_idx <- which(coords$X > 180 | coords$X < -180 |
                        coords$Y > 90 | coords$Y < -90)

data <- data[-faulty_gps_idx, ]
coords <- data.frame(st_coordinates(data$geometry))

hist(coords$X)
hist(coords$Y)

st_write(data, output_path)