library(sf)
library(data.table)

trh_utrecht <-  "./data/processed/trh/utrecht.geojson"

observations <- data.table(st_read(trh_utrecht))
observations


observations[ , obs_per_minute := .N  , .(device_id, type, year(phenomenonTime), yday(phenomenonTime), hour(phenomenonTime), minute(phenomenonTime))]
high_temporal_frequency <- observations[obs_per_minute > 2]


# if we were to group them all how many observations are left?
library(sf)

averaged <- observations[ , .(
  instance = .GRP,
  obs_per_minute = .N,
  avg_value = mean(value),
  sd_value = sd(value),
  max_distance = max(as.vector(st_distance(geometry))), 
  gps_max_qualaveragedity = max(gps_quality), 
  gps_med_quality = median(gps_quality)
), by = .(device_id, type, year(phenomenonTime), yday(phenomenonTime), hour(phenomenonTime), minute(phenomenonTime))]

View(averaged)
