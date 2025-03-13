# That one device

# are devices biased?

library(sf)
library(data.table)
library(lubridate)
library(dplyr)

# Load functions
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")
source("./trh/trh/fun__make_trips.r")

# Load observations
trh_utrecht <- "./data/cleaned/trh/utrecht_observations.geojson"

observations_raw <- (st_read(trh_utrecht))
one_device <- observations_raw[observations_raw$device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb',]
one_device$xtime <- one_device$time
library(mclust)

data <- one_device %>%
  subset(type == 'temperature')%>%
  st_coordinates() %>%
  as.data.frame() %>%
  mutate(time = xtime)  # Adding time variable to the dataset

# Combine spatial and time data into a feature matrix
feature_matrix <- data %>%
  select(X, Y, time)  # X and Y are the spatial coordinates

# Fit a Gaussian Mixture Model (GMM)
gmm_model <- Mclust(feature_matrix, G = 300)

# View the clustering result
summary(gmm_model)

# Add the GMM cluster labels back to the sf object
one_device$cluster <- gmm_model$classification

# Visualize the results on a map
plot_points_static(one_device, 'cluster')

plot_points_static(one_device[one_device$cluster < 10,], 'cluster')

