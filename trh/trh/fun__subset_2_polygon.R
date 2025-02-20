library(sf)
# data_path <- "./data/processed/trh/utrecht_global.geojson"
# output_path <- "./data/cleaned/trh/utrecht.geojson"
# polygon_path = "./data/reference/LAU_utrecht_4326.geojson"


subset_to_polygon <- function(data, polygon_path) {
  if (!inherits(data, "sf")) {
    stop("Input must be an sf")
  }
  if (!inherits(polygon_path, "character")) {
    stop("Input must be an sf")
  }
  
  poly <- st_read(polygon_path)
  
  utrecht_points <- st_intersection(data, poly)
  utrecht_points$id <- NULL
  
  return(data)
}

# dir.create(dirname(output_path), showWarnings = FALSE)
# st_write(utrecht_points, output_path, delete_dsn = TRUE)
