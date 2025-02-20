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

temp <- observations_raw[observations_raw$device_id != '88901ccb-88c0-435a-af7f-fb37fc890bcb',]


temp <- st_as_sf( add_trips(data.table(temp)))

temp$deviation <- temp$value - temp$value_reference


# handeling table related tasks is easier with data.table
dt <- data.table(st_drop_geometry(temp), st_coordinates(temp))

# is the deviation very dependend on the time of day or month
forplot <- dt[ , .(mean = mean(deviation), sd = sd(deviation)) , .(hour(time))][order(hour)]

# between 10 and 20, the deviations are quite stable around +4C. the nights are measured even warmer than the reference data. 
plot(forplot$hour , forplot$mean)
plot(forplot$hour , forplot$sd)

# write daytime temperature 
daytime_sf <- temp[hour(temp$time) >= 10 & hour(temp$time) <= 20,]
daytime <- dt[hour(time) >= 10 & hour(time) <= 20]
st_write(daytime_sf, "./data/temp/daytime_temperature.geojson")

# what if we demean the devices as well?
daytime[ , deviation_withindevice := deviation - mean(deviation) , .(device_id)]
daytime[ , value_withindevice := value - mean(value) , .(device_id)]


daytime_sf$deviation_withindevice <- daytime$deviation_withindevice[match(daytime$X.iot.id, daytime_sf$X.iot.id)]
pairs(daytime[,.(value, value_reference, deviation, deviation_withindevice)])


# plot hot device and cold device?
hot_ones <- tail(dt[hour(time) >= 10 & hour(time) <= 20 , mean(deviation) , .(device_id)][order(V1)]$device_id,1)
cold_ones <- head(dt[hour(time) >= 10 & hour(time) <= 20 , mean(deviation) , .(device_id)][order(V1)]$device_id,1)

plot_paths_static(temp[temp$device_id %in% hot_ones,], color_column = 'deviation')
plot_paths_static(temp[temp$device_id %in% cold_ones,], color_column = 'deviation')

plot_paths_static(temp[temp$device_id %in% c(cold_ones, hot_ones),], color_column = 'deviation')


# Are the devices biased?
# we only look at the window 10 to 20, as there the time seems to have less impact on the deviation. 
# they are still highly spatially correlated
mA <- lm(deviation ~ factor(device_id) + hour(time) + yday(time), data = dt[hour(time) >= 10 & hour(time) <= 20] )
m0 <- lm(deviation ~ 1 + hour(time)+ yday(time), data = dt[hour(time) >= 10 & hour(time) <= 20] )
anova(m0, mA)
hist(sort(mA$coefficients[-1]))


hist(dt[, .(x = mean(deviation)),.(device_id)]$x)
plot(dt[, .(N = .N, x = mean(deviation)),.(device_id)][,.(x, N)])
