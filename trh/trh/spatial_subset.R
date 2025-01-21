library(sf)


data_path <- "./data/processed/trh/utrecht_global.geojson"
output_path <- "./data/cleaned/trh/utrecht.geojson"
polygon_path = "./data/reference/LAU_utrecht_4326.geojson"

utrecht <- st_read(polygon_path)

data <- st_read(data_path)

utrecht_points <- st_intersection(data, utrecht)
utrecht_points$id <- NULL

dir.create(dirname(output_path), showWarnings = FALSE)
st_write(utrecht_points, output_path, delete_dsn = TRUE)
