# Here we look at thermal comfort index

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
observations_raw <- data.table(st_read(trh_utrecht))

table(observations_raw$type)

trh <- split(observations_raw, observations_raw$type)

trh$thermal_stress <- trh$thermal_stress[,.(X.iot.id, device_id, time, gps_quality, geometry)]

trh$temperature <- trh$temperature[, .(device_id, time, value, X.iot.id)]
names(trh$temperature)[3:4] <- paste0('temp_', names(trh$temperature)[3:4])

trh$relative_humidity <- trh$relative_humidity[, .(device_id, time, value, X.iot.id)]
names(trh$relative_humidity)[3:4] <- paste0('humi_', names(trh$relative_humidity)[3:4])


# first we need to match the button presses with the closest instance of temp and humid
x <- trh$temperature[trh$relative_humidity, on = c("device_id", "time"), roll = "nearest", ]
dim(x)

button <- x[trh$thermal_stress, on = c("device_id", "time"), roll = "nearest", ]
dim(button)

# now we can match it back using either temp or humid iod. 
x[, button := temp_X.iot.id %in% button$temp_X.iot.id]
x

# Subset the data
plot_button_presses <- function(){
subset_x <- x[device_id != "88901ccb-88c0-435a-af7f-fb37fc890bcb"]
# Create a color mapping based on `button` factor levels
button_levels <- as.integer(as.factor(subset_x$button))  # Convert to numeric factor

alpha_values <- seq(0.1, 1, length.out = length(unique(button_levels)))  # Define alpha levels
# Assign colors with alpha
colors <- rgb(button_levels-1,  0, 0, alpha = alpha_values[button_levels])  # Red with different transparency
table(colors)
# Run the pairs plot
pl <- pairs(subset_x[, .(humi_value, temp_value)], col = colors, pch = 19,
            labels = c('Realative Humidity', 'Temperature'), main = 'Thermal Discomfort Button presses')
return(pl)
}

print(plot_button_presses())


pairs(button[,.(humi_value, temp_value)], col = factor(button$device_id))
subset_button <- button[device_id == "88901ccb-88c0-435a-af7f-fb37fc890bcb"]
pairs(subset_button[, .(humi_value, temp_value)])



button [ , .(number_presses = .N, mean_temp = mean(temp_value), sd_temp = sd(temp_value), mean_humi = mean(humi_value), 
             sd_humi = sd(humi_value)) , .(device_id)][order(number_presses)]

