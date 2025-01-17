library(sf)


data_path <- "./data/processed/trh/utrecht.geojson"
output_path <- "./data/cleaned/trh/utrecht.geojson"
polygon_path = "./data/reference/LAU_utrecht_4326.geojson"

utrecht <- st_read(polygon_path)

data <- st_read(data_path)

print(quantile(table(data$device_id), (1:10)/10 ))

# which device has more than 20k observations. 
table(data$device_id)[which(table(data$device_id) > 20000)]


utrecht_points <- st_intersection(data, utrecht)
utrecht_points$id <- NULL

st_write(utrecht_points, output_path)
