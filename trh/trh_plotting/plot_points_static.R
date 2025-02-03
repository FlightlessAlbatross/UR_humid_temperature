
library(sf)
library(ggplot2)
library(ggspatial)
library(viridis)
library(dplyr)
library(lubridate)

# Needs buffer around the points to get orientated
# map in map, to see where in utrecht one is would be a neat feature for the future.


adjust_bbox_to_aspect_ratio <- function(bbox, aspect_ratio = 16/9){
  width <- bbox['xmax'] - bbox['xmin']
  height <- bbox['ymax'] - bbox['ymin']

  input_aspect_ratio <- width / height

  if (input_aspect_ratio >  aspect_ratio){
    # add too the heigth 
    target_height <- width / aspect_ratio
    offset <- (target_height - height)/2
    bbox['ymax'] <- bbox['ymax'] + offset
    bbox['ymin'] <- bbox['ymin'] - offset
  } else {
    target_width <- height * aspect_ratio
    offset <- (target_width - width) /2
    bbox['xmax'] <- bbox['xmax'] + offset
    bbox['xmin'] <- bbox['xmin'] - offset
  }
  return (bbox)
}

# Define the function
plot_points_static <- function(sf_object, color_column = "resultTime", output_file = NULL) {
  # Ensure the color column exists in the sf object
  if (!color_column %in% colnames(sf_object)) {
    stop("Specified color column not found in the sf object.")
  }

# cast to sf object if needed
  if (!'sf' %in% class(sf_object)){
    sf_object <- st_as_sf(sf_object)
  }

  bbox <- st_bbox(sf_object$geometry)

  bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)

#   zoom_level <- ifelse(
#     diff(range(bbox[c("xmin", "xmax")])) > 10 || diff(range(bbox[c("ymin", "ymax")])) > 10,
#     4,  # Low zoom for large areas
#     12  # High zoom for smaller areas
#   )
  
  # Create the static map
  map <- ggplot() +
    annotation_map_tile(type = "osm", zoom = 15) +  # Add OSM tiles as background
    geom_sf(data = sf_object, aes(color = !!sym(color_column)), size = 5) +  # Add points
    geom_path(
      data = sf_object, 
      aes(x = st_coordinates(geometry)[, 1], 
          y = st_coordinates(geometry)[, 2],
          color = !!sym(color_column)), 
      inherit.aes = FALSE, 
      lwd = 1.5
      ) + 
    scale_color_datetime( 
      labels = scales::date_format("%b-%d %H:%M"),
      low = viridis(1, option = "D"),  # Start of the viridis palette
      high = viridis(1, option = "D", direction = -1) ) + 
    theme_minimal() +
    theme(axis.title = element_blank(),
          axis.ticks = element_blank(),
      legend.position = "right",
      panel.grid = element_blank()
      ) +
    labs( )
  
  # Save or display the map
  if (!is.null(output_file)) {
    ggsave(output_file, map, width = 10, height = 8, dpi = 300)
    message("Map saved to: ", output_file)
<<<<<<< HEAD
    return (0)
  }   else {
    print(map)
  }

  }
=======
    return (1)
  }  else {
    print(map)
    return (1)
  }
  
  
}
>>>>>>> 378a4ac70d1446e7b56bdd8395869939bedf7e16

# Example usage
# sf_data <- st_read("your_geojson_file.geojson")
# map <- plot_points_static(sf_data, color_column = "phenomenonTime", output_file = "static_map.png")
<<<<<<< HEAD
# print(map)
=======
# print(map)
>>>>>>> 378a4ac70d1446e7b56bdd8395869939bedf7e16
