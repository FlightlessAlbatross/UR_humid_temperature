 # Polygon overlap function
library(sf)
library(terra)


load_example_data <- function(){
temp_X.iot.id_tripexample <<- "17ee0e0e-4ddb-11ef-9c4c-efa23cd0a080"
tripid_tripexample        <<- data$trip_id[data$temp_X.iot.id == temp_X.iot.id_tripexample]
point_vector              <<- data$geometry[data$trip_id == tripid_tripexample]
osm_gras_polygon          <<- read_union_polygon("./data/processed/osm/utrecht_grass.geojson")
osm_building_polygon      <<- read_union_polygon("./data/processed/osm/utrecht_buildings.geojson")
osm_water_polygon         <<- read_union_polygon("./data/processed/osm/utrecht_water.geojson")

lookup_map_path = "./data/raw/trees/Utrecht_tree_crown_map_v_1_0.tif"
points <- point_vector

building_polygon |> plot(add = TRUE, border = 'grey')
gras_polygon |> plot(add = TRUE, border = 'lightgreen')
water_polygon |> plot(add = TRUE, border = 'blue')



}

read_union_polygon <- function(path){
  sf_poly <- st_read(path, quiet = TRUE)
  st_union(sf_poly$geometry)
  
}


area_around_points <- function(points, buffer_size, lookup_map) {
  
  # Ensure CRS compatibility
  stopifnot(st_crs(points) == st_crs(lookup_map))
  
  # Create buffered geometries for all points
  buffered <- st_buffer(points, dist = buffer_size)
  
  # Check for intersections: Returns a list where each entry contains intersecting indices
  intersects <- st_intersects(buffered, lookup_map)
  
  # Identify which points have at least one intersection
  has_intersection <- lengths(intersects) > 0
  
  # Initialize output vector with NA for all points
  output <- rep(0, length(points))
  
  # Compute areas only for points that have intersections
  if (any(has_intersection)) {
    intersected_areas <- st_area(st_intersection(buffered[has_intersection], lookup_map))
    
    # Sum areas for cases with multiple overlaps
    output[has_intersection] <- sapply(seq_along(intersected_areas), function(i) sum(intersected_areas[[i]]))
  }
  
  return(output)
}

# Example Usage:
# water_10m    <- area_around_points(data$geometry, buffer_size, osm_water_polygon)
# building_10m <- area_around_points(data$geometry, buffer_size, osm_building_polygon)
# grass_10m    <- area_around_points(data$geometry, buffer_size, osm_gras_polygon)


area_around_points_from_raster <- function(points, buffer_size, lookup_map_path) {
  
  lookup_map <- rast(lookup_map_path)

  points <- vect(points)

  # Ensure CRS compatibility
  if (crs(points) != crs(lookup_map)) {
    stop("The CRS of points and raster do not match.")
  }
  # Create buffered geometries for all points
  buffered <- buffer(points, width = buffer_size)

  # Initialize output vector with NA for all points
  output <- rep(NA, length(points))
  
  # Loop through each point and calculate area
  for (i in seq_along(points)) {
    # Get the current point's buffer
    buffer <- buffered[i, ]
    
    # Mask the raster again, but only for the current buffer area
    single_buffer_raster <- mask(lookup_map, buffer)
    
    # Convert to binary raster where the value is 1 (TRUE) for relevant cells
    binary_raster <- single_buffer_raster == 1
    
    # Calculate the area of the binary raster (sum of grid cells that are 1)
    cell_area <- res(lookup_map)[1] * res(lookup_map)[2]  # Area of each cell
    total_area <- sum(values(binary_raster), na.rm = TRUE) * cell_area
    
    # Store the area in the output vector
    output[i] <- total_area
  }
  
  return(output)
}
