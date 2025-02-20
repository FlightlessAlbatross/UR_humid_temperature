setwd("C:/Users/hofer/Documents/urbanreleaf/UR_humid_temperature")

# find spatial outliers
library(sf)
library(data.table)
library(lubridate)
library(dplyr)
library(glue)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")
source("./trh/trh/fun_calculate_angle.R")

observations <- st_read('./data/cleaned/trh/temperature_GPS_speed.geojson')

setDT(observations)


observations[ , metric := opposite_angle_length / angle_walking_length , ]
hist(observations$metric)
hist(observations$angle)


table(observations$dist == 0)

odd_device <- observations[observations$device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb',]
observations <- observations[observations$device_id != '88901ccb-88c0-435a-af7f-fb37fc890bcb',]

quantile(observations$metric, na.rm = T, seq(0,1, length.out =  11))
plot(quantile(observations$metric, na.rm = T, seq(0,1, length.out =  11))[-11])

#4400219 trip has some oddness. device_id = 88901ccb-88c0-435a-af7f-fb37fc890bcb
use_ML <- function(){
split_odd_trip <- function(geom){
  
  library(mclust)
  points <- data.frame(st_coordinates(geom))
  # Fit Gaussian Mixture Model
  gmm_model <- Mclust(points)
  
  # Extract cluster assignments
  points$cluster <- as.factor(gmm_model$classification)
  
  # Plot clusters
  # ggplot(points, aes(x = X, y = Y, color = cluster)) +
  #   geom_point(size = 3) +
  #   theme_minimal() +
  #   labs(title = "GMM Clustering of Points", color = "Cluster")
  # 
  # 
  
  return(points$cluster)
  
  }

odd_trip <- observations[observations$trip_id == 4400219,]
observations <- observations[observations$trip_id != 4400219,]

odd_trip$new_group <- split_odd_trip(odd_trip$geometry)

plot_path_static(odd_trip[new_group == 1], color_column = 'time')
plot_path_static(odd_trip[new_group == 2], color_column = 'time')
plot_path_static(odd_trip[new_group == 3], color_column = 'time')
plot_path_static(odd_trip[new_group == 4], color_column = 'time')
plot_path_static(odd_trip[new_group == 5], color_column = 'time')
plot_path_static(odd_trip[new_group == 6], color_column = 'time')


plot_paths_static(odd_trip[ , .(new_group = as.numeric(new_group), time, geometry)  , ], color_column = 'new_group', group_column = 'new_group')
}

# threshold the inputs
quantile(observations$speed, na.rm = T)

panel.hist <- function(x, ...)
{
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(usr[1:2], 0, 1.5) )
  h <- hist(x, plot = FALSE)
  breaks <- h$breaks; nB <- length(breaks)
  y <- h$counts; y <- y/max(y)
  rect(breaks[-nB], 0, breaks[-1], y, ...)
}

observations$gps_colors <- c("blue", "green", "yellow", "orange", "red")[as.numeric(observations$gps_quality_cat)]


pairs(observations[,.(speed, angle_walking_length, angle, opposite_angle_length, metric)])

pairs(observations[,.(speed, angle_walking_length, angle, opposite_angle_length, metric)],
      col = observations$gps_colors)

pairs(observations[,.(speed, angle_walking_length, angle, opposite_angle_length, metric)], col = observations$gps_colors,
      diag.panel=panel.hist)


# it is a bit of a distributional question
# the points to filter will come from a different distribution than the ones in straight lines. 

selected_plots <- function(){
  
  trip_names <- unique(observations$trip_id)
  i_trip <- trip_names[3]
  
  forplot <- observations[observations$trip_id == i_trip,]
  forplot$funky <- forplot$time > "2024-07-22 11:16:58 CEST"
  
  plot_path_static(forplot, color_column = 'funky')
  
  forplot[ , metric := opposite_angle_length * angle_walking_length , ]
  plot(forplot$metric , forplot$funky)
    
  pairs(forplot[,.(opposite_angle_length, angle_walking_length, metric)], col = ifelse(forplot$funky, 'red', 'black'), 
        diag.panel = panel.hist)
  
  # from this we learned that the angle_walking length should be short --> beak looking movement
  
  
  
  library(e1071)
  library(ggplot2)
  
  # Convert 'funky' to a factor for classification
  forplot$funky <- as.factor(forplot$funky)
  forplot <- forplot[!is.na(angle)]
  
  # Train an SVM model
  svm_model <- svm(funky ~ opposite_angle_length + angle_walking_length,
                   data = forplot,
                   kernel = "linear",
                   cost = 1)
  
  table(forplot$funky,predict(svm_model) )
  
  predict(svm_model)
  summary(svm_model)
  
  
}


selected_plots<- function(){
  
  trip_names <- unique(observations$trip_id)
  i_trip <- trip_names[14]
  
  forplot <- observations[observations$trip_id == i_trip,]
  forplot$funky <- forplot$time > "2024-09-04 19:09:58 CEST"
  
  plot_path_static(forplot, color_column = 'gps_quality')
  plot_path_static(forplot, color_column = 'time')
  
  plot_path_static(forplot, color_column = 'angle')
  plot_path_static(forplot, color_column = 'metric')
  
  plot(forplot$angle ~ forplot$time)
  
  forplot$funky <- forplot$time > "2024-08-09 18:10:20 CEST" | forplot$time < "2024-08-09 17:45:20 CEST"
  
  plot_path_static(forplot, color_column = 'funky')
  
  forplot$funky <- forplot$angle < 70
  
  forplot <- forplot[angle > 70]
  plot_path_static(forplot, color_column = 'angle')
  
  
  pairs(forplot[,.(angle, angle_walking_length, metric)], col = ifelse(forplot$funky, 'red', 'black'), 
        diag.panel = panel.hist)
  
}

selected_plots <- function(){
  
  trip_names <- unique(observations$trip_id)
  i_trip <- trip_names[8]
  
  forplot <- observations[observations$trip_id == i_trip,]
  forplot$funky <- forplot$time > "2024-09-04 19:09:58 CEST"
  
  plot_path_static(forplot, color_column = 'funky')
  plot_path_static(forplot, color_column = 'time')
  plot_path_static(forplot, color_column = 'angle')
  
  plot(forplot$metric, forplot$angle, col = ifelse(forplot$funky, 'red', 'black'))
  plot(forplot$time, forplot$angle, col = ifelse(forplot$funky, 'red', 'black'))

  hist(forplot$angle[forplot$funky])  
  hist(forplot$angle[!forplot$funky])  
  
  hist((forplot$angle[forplot$funky] - 180))  

  # when the angles follow a uniform, we probably have GPS_issues
  
  plot_path_static(forplot, color_column = 'angle')
  
  
  pairs(forplot[,.(angle, opposite_angle_length, angle_walking_length, metric, speed)], col = ifelse(forplot$funky, 'red', 'black'), 
        diag.panel = panel.hist)
  
  forplot_long <- melt(forplot, id.vars = c('time', 'funky'), measure.vars = c('dist', 'speed', 'angle', 'angle_walking_length',
                                                                       'opposite_angle_length', 'metric'))
  
  
  forplot_long[ , norm := ( (value-mean(value, na.rm = T) )/ sd(value, na.rm = T))  , by = (variable)]
  
  ggplot(forplot_long, aes(x = time, y = norm, group = variable, color = variable)) + geom_line() + 
    geom_point(data = forplot_long[funky == T]) + theme_minimal()
  
  
  # from this we learned that the angle_walking length should be short --> beak looking movement
  
  
  
  library(e1071)
  library(ggplot2)
  
  # Convert 'funky' to a factor for classification
  forplot$funky <- as.factor(forplot$funky)
  forplot <- forplot[!is.na(angle)]
  
  # Train an SVM model
  svm_model <- svm(funky ~ opposite_angle_length + angle_walking_length,
                   data = forplot,
                   kernel = "linear",
                   cost = 1)
  
  table(forplot$funky,predict(svm_model) )
  
  predict(svm_model)
  summary(svm_model)
  
  
}





outlier_threshold_speed <- 30
observations[ , trip_with_outlier := any(speed > outlier_threshold_speed, na.rm = T) , .(trip_id)]

has_outlier <- observations[trip_with_outlier == TRUE]
has_no_outlier <- observations[trip_with_outlier == FALSE]


length(unique(has_outlier$trip_id))
length(unique(has_outlier$device_id))
observations$trip_with_outlier <- NULL

trips_with_outlier <- has_outlier[ , .( speed_bumps =  sum(speed > outlier_threshold_speed, na.rm = T)) , .(trip_id, device_id)]


# plot trips with no outliers
observations[, deviation := value - value_reference, ]
dim(observations[observations$trip_id %in% unique(has_no_outlier$trip_id),])
dim(observations[!observations$trip_id %in% unique(has_no_outlier$trip_id),])

plot_paths_static(observations[observations$trip_id %in% unique(has_no_outlier$trip_id),], color_column = 'deviation', group_column = 'trip_id')

hist(has_no_outlier[, .N , .(trip_id)]$N)
has_no_outlier[, trip_length := .N , .(trip_id)]

for (i_trip_id in unique(has_no_outlier[trip_length > 10 ]$trip_id)){
  
  p <- plot_path_static(observations[trip_id == i_trip_id], color_column = 'value')
  plot_path <- paste0('./plots/temperature_trip_', i_trip_id , '.png')
  ggsave(plot = p, filename = plot_path)
  
}




observations[, angle := angle_between_points_sf(geometry), , .(trip_id)]

plot_path_static(observations[observations$trip_id == 300007,], color_column = 'angle')
plot_path_static(observations[observations$trip_id == 6000009,], color_column = 'angle')
plot_path_static(observations[observations$trip_id == 1100016,], color_column = 'angle')


observations[, acute_angle_iter := index_to_remove_acute_angle_iterative(.SD), , .(trip_id)]

plot_path_static(observations[observations$trip_id == 300007,], color_column = 'acute_angle_iter')
plot_path_static(observations[observations$trip_id == 6000009,], color_column = 'acute_angle_iter')
plot_path_static(observations[observations$trip_id == 1100016,], color_column = 'acute_angle_iter')




