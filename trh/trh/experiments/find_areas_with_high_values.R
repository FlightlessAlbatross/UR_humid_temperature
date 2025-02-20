# find areas that are systematically over or under the reference temperature
# we also looked at device bias. There are differences in measurng, but the averages follow a normal distribution. 
# THat is to be expected. Averages from the same distribution follow a normal. 
# so does that mean it is not usefull as an indicator?

# we only found a few cold/hot spots, and we only found them by eyeball, lol

library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_temperature.geojson"
trh_rosevelt <- "./data/cleaned/trh/rooseveltlaan.geojson"


trh_roosevelt <- st_read(trh_rosevelt)

observations_raw <- (st_read(trh_utrecht))
temp <- observations_raw[observations_raw$device_id != '88901ccb-88c0-435a-af7f-fb37fc890bcb' & 
                           observations_raw$type == 'temperature',]


temp <- st_as_sf( add_trips(data.table(temp)))

temp$deviation <- temp$value - temp$value_reference


# handeling table related tasks is easier with data.table
dt <- data.table(st_drop_geometry(temp), st_coordinates(temp))

# write daytime temperature 
daytime_sf <- temp[hour(temp$time) >= 10 & hour(temp$time) <= 20,]
daytime <- dt[hour(time) >= 10 & hour(time) <= 20]

# plot hot device and cold device?
hot_ones <- tail(dt[hour(time) >= 10 & hour(time) <= 20 , mean(deviation) , .(device_id)][order(V1)]$device_id,1)
cold_ones <- head(dt[hour(time) >= 10 & hour(time) <= 20 , mean(deviation) , .(device_id)][order(V1)]$device_id,1)



temp_meters <- st_transform(daytime_sf[daytime_sf$X.iot.id %in% trh_roosevelt$X.iot.id,], 'EPSG:3035')
X <- data.frame(st_coordinates(temp_meters), temp_meters$deviation)
names(X) <- c('x','y', 'temp')
# Generate synthetic 2D temperature data
library(mclust)
library(ggplot2)
library(dplyr)
library(MASS)

temp_meters <- st_transform(daytime_sf[daytime_sf$X.iot.id %in% trh_roosevelt$X.iot.id,], 'EPSG:3035')
dt <- data.frame(st_coordinates(temp_meters), temp_meters)

length(unique(daytime_sf$device_id))

# Fit Gaussian Mixture Model (GMM) to group points with similar measurements
gmm <- Mclust(dt[, c("X", "Y", "deviation")], G = 100)  # G = Number of clusters

# Add cluster assignments to data
dt$cluster <- as.factor(predict(gmm)$classification)

setDT(dt)
cluster_stats <- dt[ , .(mean_temp = mean(value), sd_temp = sd(value), mean_deviation = mean(deviation), 
        number_obs = .N,
        number_trips = length(unique(trip_id)),
        number_devices = length(unique(device_id))) ,
    .(cluster)]



hist(cluster_stats$mean_temp)
hist(cluster_stats$mean_deviation)
hist(cluster_stats$sd_temp)
pairs(cluster_stats[, c('mean_temp', 'sd_temp', 'number_trips')])

hist(cluster_stats$number_trips)
hist(cluster_stats$number_devices)


# Plot deviation_withindevice# Plot the clusters
ggplot(dt, aes(X, Y, color = cluster)) +
  geom_point(size = 2) +
  scale_color_viridis_d() +
  labs(title = "Clusters of Similar Measurements", shape = "Cluster") +
  theme_minimal()

ggsave('data/cleaned/trh/explain_this/GMM_100_deviation_roosevelt.png')

# plot the mean temp per cluster
dt[ , mean_cluster_deviation := mean(deviation), .(cluster)]
ggplot(dt, aes(X, Y, color = mean_cluster_deviation)) +
  geom_point(size = 2) +
  scale_color_viridis_c() +
  labs(title = "Clusters of Similar Measurements", shape = "Cluster") +
  theme_minimal()

# Plot deviation_withindevice# Plot the clusters 
#the hot ones
hot_clusters <- cluster_stats[order(mean_deviation, decreasing = T) ]$cluster[1:3]
cold_clusters <- cluster_stats[order(mean_deviation, decreasing = F) ]$cluster[1:3]
dt[, cluster_rank := frank(mean_cluster_deviation, ties.method = "average"), by = cluster] # Rank clusters based on mean deviation

dt[ , cluster_deviation_categories := cut(mean_cluster_deviation, breaks = 5) , ]

ggplot(dt, aes(X, Y, color = mean_cluster_deviation)) +
  geom_point(size = 2) +
  scale_color_viridis_b() +
  labs(title = "Clusters of Similar Measurements", shape = "Cluster") +
  theme_minimal()

ggplot(dt[as.integer(cluster_deviation_categories) %in% c(1,5)], aes(X, Y, color = mean_cluster_deviation)) +
  geom_point(size = 2) +
  scale_color_viridis_c() +
  labs(title = "Clusters of Similar Measurements", shape = "Cluster") +
  theme_minimal()


ggsave('data/cleaned/trh/explain_this/GMM_100_deviation_highest_and_lowest_clustermeans_roosevelt.png')
forplot <- trh_roosevelt

hot_ids <- dt[as.integer(cluster_deviation_categories) %in% c(5), X.iot.id]
cold_ids <-dt[as.integer(cluster_deviation_categories) %in% c(1), X.iot.id]
forplot$cluster <- case_match(forplot$X.iot.id, hot_ids ~ 'hot', 
                                               cold_ids ~ 'cold',
                                                .default = 'middle')
forplot$color <- case_match(forplot$cluster, 'hot' ~ 'red', 'cold' ~ 'blue', 'middle' ~ 'black')
forplot$alpha <- case_match(forplot$cluster, 'hot' ~ 1, 'cold' ~ 1, 'middle' ~ 0.1)


plot_points_static_d <- function(sf_object) {

  if (!"sf" %in% class(sf_object)) sf_object <- st_as_sf(sf_object)
  
  sf_object <- st_transform(sf_object, 'EPSG:3857')
  
  # sort by alpha, so the low alpha values are plotted first and a below the high alpha ones.
  # we want to highlight the high alpha ones
  sf_object <- sf_object[order(sf_object$alpha),]
  
  bbox <- st_bbox(sf_object$geometry)
  bbox_16_9 <- adjust_bbox_to_aspect_ratio(bbox, 16/9)
  
  map <- ggplot() +
    annotation_map_tile(type = "osm", zoom = 15) +
    geom_sf(data = sf_object, aes(color = color, alpha = alpha), size = 2) +
    scale_color_identity() + scale_alpha_identity() + 
    coord_sf(xlim = c(bbox_16_9["xmin"], bbox_16_9["xmax"]),
             ylim = c(bbox_16_9["ymin"], bbox_16_9["ymax"]),
             expand = FALSE) +
    theme_void() +
    theme(axis.title = element_blank(), axis.ticks = element_blank(),
          legend.position = "right", panel.grid = element_blank())
  return(map)
}

plot_points_static_d(forplot)

plot_points_static_d(forplot[forplot$cluster == 'hot',])


# rasterize