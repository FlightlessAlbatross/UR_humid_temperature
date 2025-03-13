
library(sf)
library(ggplot2)
library(ggspatial)
library(viridis)
library(dplyr)
library(lubridate)

# Needs buffer around the points to get orientated
# map in map, to see where in utrecht one is would be a neat feature for the future.

get_color_scale <- function(data, column) {
  if (inherits(data[[column]], "POSIXt")) {
    return(scale_color_datetime(
      labels = scales::date_format("%b-%d %H:%M"),
      name = 'Time:',
      breaks = range(data[[column]], na.rm = TRUE),
      low = viridis(1, option = "D"),
      high = viridis(1, option = "D", direction = -1)
    ))
  } else if (is.numeric(data[[column]])) {
    return(scale_color_gradient(
      low = "blue", high = "red"  # Choose any two colors that fit your needs
    ))
  } else if (is.logical(data[[column]])) {
    return(scale_color_discrete()) 
  } else {
    stop("Color column must be either a datetime or numeric type.")
  }
}

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

plot_points_static <- function(sf_object, color_column = "resultTime", output_file = NULL) {
  if (!color_column %in% colnames(sf_object)) stop("Specified color column not found in the sf object.")
  
  if (!"sf" %in% class(sf_object)) sf_object <- st_as_sf(sf_object)
  
  sf_object <- st_transform(sf_object, 'EPSG:3857')
  
  bbox <- st_bbox(sf_object$geometry)
  bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)
  
  color_scale <- get_color_scale(sf_object, color_column)
  
  map <- ggplot() +
    annotation_map_tile(type = "osm", zoom = 15) +
    geom_sf(data = sf_object, aes(color = !!sym(color_column)), size = 2) +
    color_scale +
    coord_sf(xlim = c(bbox_16_9["xmin"], bbox_16_9["xmax"]),
             ylim = c(bbox_16_9["ymin"], bbox_16_9["ymax"]),
             expand = FALSE) +
    theme_void() +
    theme(axis.title = element_blank(), axis.ticks = element_blank(),
          legend.position = "right", panel.grid = element_blank())

  if (!is.null(output_file)) {
    ggsave(output_file, map, width = 10, height = 8, dpi = 300)
    message("Map saved to: ", output_file)
  } else {
    print(map)
  }
}



# Plot paths
plot_paths_static <- function(sf_object, color_column = "resultTime", group_column = 'trip_id', output_file = NULL) {
  if (!color_column %in% colnames(sf_object)) stop("Specified color column not found in the sf object.")
  if (!group_column %in% colnames(sf_object)) {
    
    warning("Specified group column not found in the sf object using the same group for all")
    
    sf_object[[group_column]] <- 1
    
    }
  
  
  if (!"sf" %in% class(sf_object)) sf_object <- st_as_sf(sf_object)
  
  sf_object <- st_transform(sf_object, 'EPSG:3857')
  
  
  bbox <- st_bbox(sf_object$geometry)
  bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)

  color_scale <- get_color_scale(sf_object, color_column)

  # convert to data frame for geom_path and take the lead of the color, to color in the correct segment. 
  sf_object <- sf_object %>%
  mutate(lead_color = lead(!!sym(color_column)))  # Apply lead() within sf

map <- ggplot() +
  annotation_map_tile(type = "osm", zoom = 15) +
  geom_sf(data = sf_object, aes(color = !!sym(color_column)), size = 2) +
  geom_path(
    data = sf_object, 
    aes(x = st_coordinates(geometry)[, 1], 
        y = st_coordinates(geometry)[, 2],
        color = lead_color, 
        group = !!sym(group_column)),  # Now uses precomputed lead()
    inherit.aes = FALSE, 
    lwd = 1.5
  ) +
  color_scale +
  coord_sf(xlim = c(bbox_16_9["xmin"], bbox_16_9["xmax"]),
           ylim = c(bbox_16_9["ymin"], bbox_16_9["ymax"]),
           expand = FALSE) +
  theme_void() + theme(legend.position = 'bottom' )

  if (!is.null(output_file)) {
    ggsave(output_file, map, width = 10, height = 8, dpi = 300)
    message("Map saved to: ", output_file)
  } else {
    print(map)
  }
}


plot_path_static <- function(sf_object, color_column = "resultTime", output_file = NULL) {
  if (!color_column %in% colnames(sf_object)) stop("Specified color column not found in the sf object.")
  
  if (!"sf" %in% class(sf_object)) sf_object <- st_as_sf(sf_object)
  
  sf_object <- st_transform(sf_object, 'EPSG:3857')
  
  
  bbox <- st_bbox(sf_object$geometry)
  bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)
  
  color_scale <- get_color_scale(sf_object, color_column)
  
  # convert to data frame for geom_path and take the lead of the color, to color in the correct segment. 
  sf_object <- sf_object %>%
    mutate(lead_color = lead(!!sym(color_column)))  # Apply lead() within sf
  
  map <- ggplot() +
    annotation_map_tile(type = "osm", zoom = 15) +
    geom_sf(data = sf_object, aes(color = !!sym(color_column)), size = 2) +
    geom_path(
      data = sf_object, 
      aes(x = st_coordinates(geometry)[, 1], 
          y = st_coordinates(geometry)[, 2],
          color = lead_color),  # Now uses precomputed lead()
      inherit.aes = FALSE, 
      lwd = 1.5
    ) +
    color_scale +
    coord_sf(xlim = c(bbox_16_9["xmin"], bbox_16_9["xmax"]),
             ylim = c(bbox_16_9["ymin"], bbox_16_9["ymax"]),
             expand = FALSE) +
    theme_void()+ theme(legend.position = 'bottom' )
  
  if (!is.null(output_file)) {
    ggsave(output_file, map, width = 10, height = 8, dpi = 300)
    message("Map saved to: ", output_file)
  } else {
    return(suppressMessages(map))
  }
}




plot_background_static <- function(sf_object, color_column = "resultTime", output_file = NULL) {
  if (!color_column %in% colnames(sf_object)) stop("Specified color column not found in the sf object.")
  
  if (!"sf" %in% class(sf_object)) sf_object <- st_as_sf(sf_object)
  
  sf_object <- st_transform(sf_object, 'EPSG:3857')
  
  
  bbox <- st_bbox(sf_object$geometry)
  bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)
  
  # convert to data frame for geom_path and take the lead of the color, to color in the correct segment. 
  sf_object <- sf_object %>%
    mutate(lead_color = lead(!!sym(color_column)))
  
  map <- ggplot() +
    annotation_map_tile(type = "osm", zoom = 15) +
    geom_sf(data = sf_object, aes(color = !!sym(color_column)), size = 2) +
    geom_path(
      data = sf_object, 
      aes(x = st_coordinates(geometry)[, 1], 
          y = st_coordinates(geometry)[, 2],
          color = lead_color),
      inherit.aes = FALSE, 
      lwd = 1.5
    ) +
    coord_sf(xlim = c(bbox_16_9["xmin"], bbox_16_9["xmax"]),
             ylim = c(bbox_16_9["ymin"], bbox_16_9["ymax"]),
             expand = FALSE) +
    theme_void()
  
  return(map)
}
