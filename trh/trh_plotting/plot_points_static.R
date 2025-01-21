library(sf)
library(ggplot2)
library(ggspatial)
library(viridis)
library(dplyr)

# Define the function
plot_points_static <- function(sf_object, color_column = "phenomenonTime", output_file = NULL) {
  # Ensure the color column exists in the sf object
  if (!color_column %in% colnames(sf_object)) {
    stop("Specified color column not found in the sf object.")
  }

# cast to sf object if needed
  if (!'sf' %in% class(sf_object)){
    sf_object <- st_as_sf(sf_object)
  }

  bbox <- st_bbox(sf_object$geometry)

#   zoom_level <- ifelse(
#     diff(range(bbox[c("xmin", "xmax")])) > 10 || diff(range(bbox[c("ymin", "ymax")])) > 10,
#     4,  # Low zoom for large areas
#     12  # High zoom for smaller areas
#   )
  
  # Create the static map
  map <- ggplot() +
    annotation_map_tile(type = "osm", zoom = 15) +  # Add OSM tiles as background
    geom_sf(data = sf_object, aes(color = !!sym(color_column)), size = 3) +  # Add points
    geom_path(
    data = sf_object, 
    aes(x = st_coordinates(geometry)[, 1], 
        y = st_coordinates(geometry)[, 2]), 
    inherit.aes = FALSE, 
    color = "black", 
    size = 0.5
  ) +
    scale_color_viridis_c() + # Use viridis color scale
    theme_minimal() +
    theme(
      legend.position = "right",
      panel.grid = element_blank()
    ) +
    labs(
      title = "Static Map with OSM Background",
      subtitle = paste("Points colored by:", color_column)
    )
  
  # Save or display the map
  if (!is.null(output_file)) {
    ggsave(output_file, map, width = 10, height = 8, dpi = 300)
    message("Map saved to: ", output_file)
  }
  
  return(map)
}

# Example usage
# sf_data <- st_read("your_geojson_file.geojson")
# map <- plot_points_static(sf_data, color_column = "phenomenonTime", output_file = "static_map.png")
# print(map)

