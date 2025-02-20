library(sf)

# data_path <- "./data/processed/trh/utrecht_global.geojson"
# output_path <- "./data/processed/trh/utrecht.geojson"
# 
# data <- st_read(data_path)


clean_gps <- function(data) {
  
  if (!inherits(data, "sf")) {
    stop("Input must be an Sf.")
  }

  coords <- data.frame(st_coordinates(data$geometry))
  # check which coordinates are outside of the WGS ranges.
  faulty_gps_idx <- which(coords$X > 180 | coords$X < -180 |
                          coords$Y > 90 | coords$Y < -90)
  
  if(length(faulty_gps_idx)> 0){
  data <- data[-faulty_gps_idx, ]
  }
  return(data)
}
