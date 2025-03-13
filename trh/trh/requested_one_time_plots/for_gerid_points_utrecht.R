data <- st_read('./data/cleaned/trh/utrecht_temperature_modeled_outliers.geojson')



library(ggplot2)

color_column = 'value_bins'
sf_object <- st_transform(data, 'EPSG:3857')


sf_object$value_bins <- cut(sf_object$value, quantile(sf_object$value,  seq(0,1, 0.2)  ))



bbox <- st_bbox(sf_object$geometry)
bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)


map <- ggplot() +
  annotation_map_tile(type = "osm", zoom = 15) +
  geom_sf(data = sf_object, aes(color = value_bins), size = 1) +
  scale_color_manual(values = c( "#ffffff",
                                 "#ffe6e6",
                                 "#ffb3b3",
                                 "#ff8080",
                                 "#ff3333" ) ) +
  coord_sf(xlim = c(bbox_16_9["xmin"], bbox_16_9["xmax"]),
           ylim = c(bbox_16_9["ymin"], bbox_16_9["ymax"]),
           expand = FALSE) +
  theme_void() +
  theme(axis.title = element_blank(), axis.ticks = element_blank(),
        legend.position = "right", panel.grid = element_blank())


ggsave(plot = map, filename = "./plots/utrecht_all_temperatures_300dpi.png", dpi = 300)




sf_object <- sf_object[st_coordinates(sf_object$geometry)[,2] > 6817108,]


bbox <- st_bbox(sf_object$geometry)
bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)


map <- ggplot() +
  annotation_map_tile(type = "osm", zoom = 15) +
  geom_sf(data = sf_object, aes(color = value_bins), size = 1) +
  scale_color_manual(values = c( "#ffffff",
                                 "#ffe6e6",
                                 "#ffb3b3",
                                 "#ff8080",
                                 "#ff3333" ) ) +
  coord_sf(xlim = c(bbox_16_9["xmin"], bbox_16_9["xmax"]),
           ylim = c(bbox_16_9["ymin"], bbox_16_9["ymax"]),
           expand = FALSE) +
  theme_void() +
  theme(axis.title = element_blank(), axis.ticks = element_blank(),
        legend.position = "right", panel.grid = element_blank())


ggsave(plot = map, filename = "./plots/utrecht_north_temperatures_300dpi.png", dpi = 300)
