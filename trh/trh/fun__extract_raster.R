library(terra)
library(sf)



extract_raster_values <- function(sf_points, raster_path) {
  # Load the raster
  suppressMessages(rast_data <- rast(raster_path))

  if(length(names(rast_data)) != 1 ) {
    stop("extract_raster_values expects a single layer raster")
  }


  
  # Ensure the sf object is in the same CRS as the raster
  if (st_crs(sf_points)$epsg != crs(rast_data, describe=TRUE)$code) {
    sf_points <- st_transform(sf_points, crs(rast_data))
  }
  
  # Convert sf object to terra SpatVector
  points_vect <- vect(sf_points)
  
  # Extract values at point locations
  values <- extract(rast_data, points_vect)[[names(rast_data)]]

  return(values)
}
