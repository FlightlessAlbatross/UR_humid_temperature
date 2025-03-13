# fun__add_label_based_on_polygon

# 
# building_poly_path <- "./data/processed/osm/utrecht_buildings.geojson"
# points <- trh


inside_building <- function(points){
  building_poly_path <- "./data/processed/osm/utrecht_buildings.geojson"
  poly <- st_read(building_poly_path)
  
  add_label_based_on_polygon (points, poly$geometry)
}

add_label_based_on_polygon <- function(points, poly) {
  
  "sfc" %in% class(poly)
  "sfc" %in% class(points)
  
  stopifnot(
    st_crs(poly) == 
      st_crs(points)
  )
  
  lst <- st_intersects(points, poly)

  
  return(lengths(lst) > 0 )
  
}
  

