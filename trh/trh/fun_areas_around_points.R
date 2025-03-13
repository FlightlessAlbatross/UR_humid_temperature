 # Polygon overlap function
library(sf)


load_example_data <- function(){
temp_X.iot.id_tripexample <<- "17ee0e0e-4ddb-11ef-9c4c-efa23cd0a080"
tripid_tripexample        <<- data$trip_id[data$temp_X.iot.id == temp_X.iot.id_tripexample]
point_vector              <<- data$geometry[data$trip_id == tripid_tripexample]
osm_gras_polygon          <<- read_union_polygon("./data/processed/osm/utrecht_grass.geojson")
osm_building_polygon      <<- read_union_polygon("./data/processed/osm/utrecht_buildings.geojson")
osm_water_polygon         <<- read_union_polygon("./data/processed/osm/utrecht_water.geojson")

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
