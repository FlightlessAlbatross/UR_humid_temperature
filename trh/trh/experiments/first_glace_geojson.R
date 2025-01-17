library(sf)
library(ggplot2)
library(lubridate)
library(data.table)
library(terra)

data_path <- "./data/cleaned/utrecht.geojson"

data <- st_read(data_path)
data$day <- yday(data$phenomenonTime)
data$hour <- hour(data$phenomenonTime)

temperature <- data[data$type == 'temperature', ]
humidity    <- data[data$type == 'relative_humidity', ]
discomfort  <- data[data$type == 'thermal_discomfort', ]

round(range(temperature$value),2)

hist(temperature$value)
hist(humidity$value)


hist(humidity$phenomenonTime, breaks = "months")
hist(humidity$phenomenonTime, breaks = "weeks")

hist(humidity$value)

# time v temperature
ggplot(data = temperature) +
geom_point(aes(x = phenomenonTime, y = value), alpha = 0.1)


# obs per day
setDT(temperature)

plot(temperature[ , .N , .(day)][order(day)])

# plot all the temperatures of a day
ggplot(data = temperature[day %in% 200:201]) + 
geom_point(aes(x = phenomenonTime, y = value), alpha = 0.1)

# plot all the temperatures of a week
ggplot(data = temperature[day %in% 200:206]) + 
geom_point(aes(x = phenomenonTime, y = value), alpha = 0.1)

