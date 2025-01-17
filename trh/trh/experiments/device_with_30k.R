

library(sf)
library(lubridate)

source("./trh/trh_plotting/plot_temperature.R")

data_path <- "./data/processed/trh/utrecht.geojson"
output_path <- "./data/cleaned/trh/utrecht.geojson"
polygon_path = "./data/reference/LAU_utrecht_4326.geojson"

utrecht <- st_read(polygon_path)

data <- st_read(data_path)

print(quantile(table(data$device_id), (1:10)/10 ))

# which device has more than 20k observations. 
table(data$device_id)[which(table(data$device_id) > 20000)]


utrecht_points <- st_intersection(data, utrecht)
utrecht_points$id <- NULL


quantile(utrecht_points$gps_quality)
hist(utrecht_points$gps_quality)


outlier <- utrecht_points[utrecht_points$device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb', ]

hist(outlier$phenomenonTime, breaks = 'weeks')
outlier <- outlier[outlier$phenomenonTime < "2024-07-22 00:00:00 CEST", ]
with(outlier[outlier$type == 'temperature',], plot(value ~ phenomenonTime))


hist(outlier$phenomenonTime, breaks = 'days',  freq = T)
outlier <- utrecht_points[as.Date(utrecht_points$phenomenonTime) == "2024-07-09", ]
hist(outlier$phenomenonTime, breaks = 'hours',  freq = T)
outlier <- outlier[order(outlier$phenomenonTime),]
with(outlier[outlier$type == 'temperature',], plot(value ~ phenomenonTime, type = 'l'))

outlier <- outlier[hour(outlier$phenomenonTime) == 17,]


hist(outlier$value[outlier$type == 'relative_humidity'])
hist(outlier$value[outlier$type == 'temperature'])


outlier <- outlier[minute(outlier$phenomenonTime) == 38,]
hist(outlier$phenomenonTime, breaks = 'secs')



outlier$gps_quality
# looks legit, actually. 
forplot <- outlier[outlier$type == 'temperature',]
names(forplot)[c(4, 2)] <- c('temperature', 'time')
plot_temperature(forplot)

st_write(outlier, './data/temp/too_many_obs.geojson')
