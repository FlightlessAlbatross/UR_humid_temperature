library(sf)

data_path <- "./data/processed/trh/utrecht_global.geojson"
output_path <- "./data/processed/trh/utrecht.geojson"

data <- st_read(data_path)


coords <- data.frame(st_coordinates(data$geometry))
# check which coordinates are outside of the WGS ranges.
faulty_gps_idx <- which(coords$X > 180 | coords$X < -180 |
                        coords$Y > 90 | coords$Y < -90)


#check the faulty entries:
table(data[faulty_gps_idx,]$device_id)

data <- data[-faulty_gps_idx, ]
coords <- data.frame(st_coordinates(data$geometry))

dir.create(dirname(output_path), showWarnings = FALSE)
st_write(data, output_path)