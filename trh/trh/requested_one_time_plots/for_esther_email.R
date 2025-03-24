library(ggplot2)
library(data.table)
library(patchwork)
library(glue)
library(data.table)
source("./trh/trh_plotting/plot_points_static.R")
source("./trh/trh_plotting/plot_temperature.R")


data <- st_read("./data/temp/data_for_11_03_25_update.geojson", quiet = TRUE)


index_drop <- with(data, 
                   gps_outlier == 'jumpy' &  !is.na(gps_outlier)  | 
                     distance_building == 0  | 
                     distance_water == 0 )

outliers <- data[index_drop,]
trh      <- data[!index_drop,]

dt <- data.table(trh)

hour(dt$time)


ggplot(dt%>% arrange(discomfort), aes(x = (hour(time) + minute(time) / 60 - 5) %% 24, y = temp_value, color = discomfort)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "gam", formula = y ~ s(x, bs = "cc"), color = "blue") +
  scale_x_continuous(
    breaks = seq(0, 24, 3),  # Label every 3 hours
    labels = function(x) sprintf("%02d:00", (x + 5) %% 24)  # Shift labels back to real time
  ) + 
  scale_color_discrete(type = c("black", 'red'), labels = c("No Press", "Press"), name = "Thermal Discomfort Button") + 
  labs(x = "Time of Day", y = "Temperature", title = "Temperature over time of day") +
  theme_minimal() + theme(legend.position = 'bottom')


ggplot(dt, aes(x = (hour(time) - 5) %% 24, y = temp_value, group = hour(time))) +
  geom_boxplot(alpha = 0.5) +
  scale_x_continuous(
    breaks = seq(0, 24, 3),  
    labels = function(x) sprintf("%02d:00", (x + 5) %% 24)  
  ) + 
  labs(x = "Time of Day", y = "Temperature", title = "Temperature over time of day") +
  theme_minimal()

ggplot(dt[discomfort == T], aes(x = (hour(time) - 5) %% 24, y = temp_value, group = hour(time))) +
  geom_boxplot(alpha = 0.5) +
  scale_x_continuous(
    breaks = seq(0, 24, 3),  
    labels = function(x) sprintf("%02d:00", (x + 5) %% 24)  
  ) + 
  labs(x = "Time of Day", y = "Temperature", title = "Temperature over time of day") +
  theme_minimal()

ggplot(dt[discomfort == T], aes(x = (hour(time) - 5) %% 24)) + geom_bar()

ggplot(dt[discomfort == T], aes(x = temp_value)) + geom_histogram()
ggplot(dt[discomfort == T], aes(x = humi_value)) + geom_histogram()

ggplot(dt%>% arrange(discomfort), aes(x = temp_value, y = humi_value, color = discomfort, fill = discomfort )) + geom_point(alpha = .5) + 
  scale_color_discrete(type = c("black", 'red'), labels = c("No Press", "Press"), name = "Thermal Discomfort Button") + 
  scale_fill_discrete(type = c("black", 'red'), labels = c("No Press", "Press"), name = "Thermal Discomfort Button")  + 
  geom_abline(slope = -5, intercept = 160, color = "red", linetype = "dashed")

# Calculate the predicted y values from the line y = -5x + 165
dt$humi_temp_outlier <- dt$humi_value < -5 * dt$temp_value + 160

# are they part of trips?

dt[ , sum(humi_temp_outlier) , .(trip_id)][order(V1)]

dt[ , trip_has_humitemp_outlier :=  any(humi_temp_outlier) , .(trip_id)]
ggplot(dt%>% arrange(discomfort), aes(x = temp_value, y = humi_value, color = trip_has_humitemp_outlier, fill = trip_has_humitemp_outlier )) + geom_point(alpha = .5) + 
  scale_color_discrete(type = c("black", 'red'), labels = c("No Press", "Press"), name = "Thermal Discomfort Button") + 
  scale_fill_discrete(type = c("black", 'red'), labels = c("No Press", "Press"), name = "Thermal Discomfort Button")  + 
  geom_abline(slope = -5, intercept = 160, color = "red", linetype = "dashed")


sf_data <- st_as_sf(dt)
st_write(sf_data, dsn = './data/temp/humi_temp_outliers.geojson')


# Thermal discomfort by device. 
averages <- dt[, .SD[any(discomfort), .(mean_temp = mean(temp_value, na.rm = T), mean_humi = mean(humi_value, na.rm = T)), .(discomfort) ] , .(device_id)]
# averages$mean_temp[averages$discomfort == FALSE] <- -1 * averages$mean_temp[averages$discomfort == FALSE]
averages$mean_temp <- -1 * averages$mean_temp
averages <- melt.data.table(averages, id.vars = c("device_id", "discomfort"))
ggplot(averages[discomfort == T], aes(x = value, y = device_id, fill = variable)) +  geom_bar(stat = 'identity')

forplot <- dt[ , .SD[any(discomfort)] , .(device_id)]
forplot[ , device_median := (median(temp_value)) , .(device_id)][, device_order := factor(rank(device_median))]
library(patchwork)

ggplot( ) +
  geom_boxplot(data = forplot[discomfort == F], aes(x = temp_value, y = device_order)) + 
  geom_point(data = forplot[discomfort == T], aes(x = temp_value, y = device_order), color = 'red') + 
  scale_y_discrete(name = 'Devices') + scale_x_continuous(name = 'Temperature') + 
  theme_minimal()   +
  theme(
    axis.ticks.y = element_blank(),  # Remove tick marks
    axis.text.y = element_blank()    # Remove labels
  )+ 
ggplot( ) +
  geom_boxplot(data = forplot[discomfort == F], aes(x = humi_value, y = device_order)) + 
  geom_point(data = forplot[discomfort == T], aes(x = humi_value, y = device_order), color = 'red') + 
  scale_y_discrete(name = 'Devices') + scale_x_continuous(name = 'Relative Humidity') + 
  theme_minimal()   +
  theme(
    axis.ticks.y = element_blank(),  # Remove tick marks
    axis.text.y = element_blank()    # Remove labels
  )

ggplot(forplot, aes(y = humi_value, x = temp_value, color = discomfort)) + geom_point() + 
  scale_color_manual(values = c("TRUE" = 'red', "FALSE" = 'black'))
# spatial distribution of hottest and coldest days. 




# 