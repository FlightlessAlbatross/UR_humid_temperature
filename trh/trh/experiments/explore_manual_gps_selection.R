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


observations <- st_read( './data/cleaned/trh/temperature_GPS_speed.geojson')

odd_device <- observations[observations$device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb',]
observations <- observations[observations$device_id != '88901ccb-88c0-435a-af7f-fb37fc890bcb',]

# we can also get rid of the high speed ones. 
setDT(observations)

observations[ , angle_lead := shift(angle, type = 'lead') ,.(trip_id, device_id)]
observations[ , angle_lag := shift(angle, type = 'lag') ,.(trip_id, device_id)]

get_labled_points <- function() {
  
  jumpy <- st_read( './data/cleaned/trh/trips/__jumpy_gps.geojson')
  inter <- st_read( './data/cleaned/trh/trips/__intermediary.geojson')
  solid <- st_read( './data/cleaned/trh/trips/__solid_paths.geojson')
  
  j <- observations [observations$geometry %in% jumpy$geometry,]
  i <- observations [observations$geometry %in% inter$geometry,] # there was a hickup with the map projections
  s <- observations [observations$geometry %in% solid$geometry,]
  
  j$gps <- 'jumpy'
  i$gps <- 'intermediary'
  s$gps <- 'line'
  
  return(rbind(j,i, s))
}
labled <- get_labled_points()

observations$gps <- labled$gps[match(observations$X.iot.id, labled$X.iot.id)]


ggplot(labled, aes(y = angle, x = speed, color = gps)) + geom_point() + theme_bw()
ggplot(labled, aes(y = angle, x = angle_lag, color = gps)) + geom_point() + theme_bw()

ggplot(labled, aes(y = opposite_angle_length, x = speed, color = gps)) + geom_point() + theme_bw()
ggplot(labled, aes(y = opposite_angle_length, x = angle, color = gps)) + geom_point() + theme_bw()
ggplot(labled, aes(y = speed, x = angle, color = gps)) + geom_point() + theme_bw()

ggplot(labled, aes(y = angle_lead * angle_lag, x = angle, color = gps)) + geom_point() + theme_bw()



ggplot(labled, aes(y = speed, x = angle, color = gps)) + geom_point() + theme_bw()

# Split into training (80%) and testing (20%) sets
set.seed(42)
train_indices <- sample(1:nrow(labled), size = 0.8 * nrow(labled))
train_data <- labled[train_indices, ]
test_data  <- labled[-train_indices, ]


# Train decision tree model using only the angles 
angle_model <- rpart(gps ~ angle + dist  + speed + gps_quality + opposite_angle_length, data = train_data, method = "class", 
                    maxdepth = 3)

summary(angle_model)

rpart.plot(angle_model, 
           type = 3,       # Boxed tree nodes
           extra = 104,    # Show class counts and probabilities
           cex = 1.2,      # Increase text size
           box.palette = "RdYlGn", # Add colors to nodes
           fallen.leaves = TRUE)  # Improve layout

# Predict on test data
predictions <- predict(angle_model, test_data, type = "class")

# Compute confusion matrix
conf_matrix <- table(Predicted = predictions, Actual = test_data$gps)
print(conf_matrix)
# Compute accuracy
accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)
print(paste("Accuracy:", round(accuracy * 100, 2), "%"))

# check the false jumpies
false_positive <- labled[labled$gps == 'line' & labled$speed < 3.4 & angle < 60,]
false_positive$trip_id
observations$is_false_positive <- observations$X.iot.id %in% false_positive$X.iot.id

plot_path_static(observations[trip_id == 1300001], color_column = 'is_false_positive')

plot_path_static(observations[trip_id == 900001 ], color_column = 'is_false_positive')
plot_path_static(observations[trip_id == 300002 ], color_column = 'is_false_positive')


# use the tree model to predict all the observations:
observations$gps_outlier <- predict(angle_model, observations, type = "class")
st_write(observations, './data/cleaned/trh/utrecht_temperature_modeled_outliers.geojson')




# for each point take 2 obs lead and lag,, normalize them to 0,0 and get statistics on the distribuitons of angles etc
# Function to create a 5-point line with the middle point at (0,0)
geoms <- observations[trip_id == 100001]$geometry[2:6]

make_centered_line <- function(geoms) {
  coords <- st_coordinates(geoms)
  
  # Find middle point
  mid_idx <- ceiling(nrow(coords) / 2)
  mid_x <- coords[mid_idx, 1]
  mid_y <- coords[mid_idx, 2]
  
  # Center around (0,0)
  centered_coords <- coords - cbind(rep(mid_x, nrow(coords)), rep(mid_y, nrow(coords))   )
  
  # Create LINESTRING
  st_linestring(centered_coords)
}

plot(make_centered_line(geoms))

# Apply rolling function with frollapply
test <- observations[N > 5, .(line_geom = frollapply(
  geometry, n = 5, align = "center", FUN = make_centered_line, fill = NA
)), by = .(trip_id, device_id)]

# Drop NA rows where a full window isn't available
observations <- observations[!is.na(line_geom)]

# Convert to sf object with LINESTRING geometries
observations <- st_as_sf(observations, crs = 4326)