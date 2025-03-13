# fun__nearest_polygon_distance. 


# water_poly_path <- "./data/processed/osm/utrecht_water.geojson"
# points <- trh$geometry
# 
# poly_sf <- st_read(water_poly_path)
# poly <- poly_sf$geometry

distance_to_grass <- function(points){
  poly_path <- "./data/processed/osm/utrecht_grass.geojson"
  poly_sf <- st_read(poly_path)
  
  add_distance_nearest_polygon (points, poly_sf$geometry)
}


distance_to_water <- function(points){
  poly_path <- "./data/processed/osm/utrecht_water.geojson"
    poly_sf <- st_read(poly_path)
    
    add_distance_nearest_polygon (points, poly_sf$geometry)
  }


distance_to_building <- function(points){
  poly_path <- "./data/processed/osm/utrecht_buildings.geojson"
  poly_sf <- st_read(poly_path)
  
  add_distance_nearest_polygon (points, poly_sf$geometry)
}



add_distance_nearest_polygon <- function(points, poly){
  
  "sfc" %in% class(poly)
  "sfc" %in% class(points)
  
  stopifnot(
    st_crs(poly) == 
      st_crs(points)
  )
  
  index_nearest <- st_nearest_feature(points, poly)
  
  distance_to_nearest <- st_distance(points, poly[index_nearest], by_element = T)
  distance_to_nearest <- as.numeric(distance_to_nearest)
  return(distance_to_nearest)
  
}
