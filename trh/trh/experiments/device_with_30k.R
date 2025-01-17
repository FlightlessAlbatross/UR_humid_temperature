

library(sf)


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

outlier <- utrecht_points[utrecht_points$device_id == '88901ccb-88c0-435a-af7f-fb37fc890bcb', ]

hist(outlier$phenomenonTime, breaks = 'weeks')
outlier <- outlier[outlier$phenomenonTime < "2024-07-22 00:00:00 CEST", ]

hist(outlier$phenomenonTime, breaks = 'days',  freq = T)
outlier <- utrecht_points[as.Date(utrecht_points$phenomenonTime) == "2024-07-09", ]
hist(outlier$phenomenonTime, breaks = 'hours',  freq = T)

st_write(outlier, './data/temp/too_many_obs.geojson')